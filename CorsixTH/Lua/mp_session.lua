--[[ Copyright (c) 2026 CorsixTH-Multiplayer contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]

--! Experimental multiplayer lockstep session.
--!
--! Every peer runs the same simulation. Game time advances in one-hour
--! "steps" (see World:onTick). Player actions are not applied directly: they
--! become commands, scheduled `delay` steps ahead, sent to every peer, and
--! applied by every peer at the start of the scheduled step in a fixed order.
--!
--! After each step a peer sends "S <peer> <step> <fingerprint>". A peer may run
--! step n only once it has every other peer's report for step n - delay + 1.
--! Commands are sent the moment they are issued, before that report, so by
--! then all commands for step n are known. Fingerprints of the same step are
--! compared to detect desyncs.
--!
--! The session is stored on the App (TheApp.mp_session), never on the World,
--! so it is not written into save games.
--!
--! Wire format (one line per message):
--!   C <key=value ...>          a command (see encode_command)
--!   S <peer> <step> <fp>       peer completed <step>, state fingerprint <fp>

class "MultiplayerSession"

---@type MultiplayerSession
local MultiplayerSession = _G["MultiplayerSession"]

local function encode_value(v)
  return (tostring(v):gsub("[%%%s=]", function(c) return string.format("%%%02X", c:byte()) end))
end

local function decode_value(v)
  v = v:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  return tonumber(v) or v
end

--! Serialize a command table of plain values to one line.
function MultiplayerSession.encodeCommand(cmd)
  local keys = {}
  for k in pairs(cmd) do keys[#keys + 1] = k end
  table.sort(keys)
  local parts = {"C"}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. "=" .. encode_value(cmd[k])
  end
  return table.concat(parts, " ")
end

--! Parse a line produced by encodeCommand, or return nil.
function MultiplayerSession.decodeCommand(line)
  if line:sub(1, 2) ~= "C " then return nil end
  local cmd = {}
  for k, v in line:sub(3):gmatch("([%w_]+)=(%S*)") do
    cmd[k] = decode_value(v)
  end
  return cmd
end

local function command_order(a, b)
  if a.step ~= b.step then return a.step < b.step end
  if a.peer ~= b.peer then return a.peer < b.peer end
  return a.seq < b.seq
end

--!param params (table) Fields:
--!  world      (World)  the shared world
--!  peer_id    (int)    this peer's number, 1 = host
--!  peers      (table)  list of all peer numbers, e.g. {1, 2}
--!  transport  (table)  object with :send(line) and :receive() -> line or nil
--!                      (non-blocking)
--!  delay      (int)    steps between issuing and applying a command (>= 2)
--!  handlers   (table)  optional kind -> function(world, cmd) -> ok, reason
--!  fingerprint (function) optional world -> string
--!  log        (function) optional message logger
--!  notify     (function) optional message to show the player (waiting for
--!             the other player, desync). Cosmetic, local only.
--!  clock      (function) optional milliseconds clock for the waiting notice
--!  control    (function) optional; receives every line that is neither a
--!             command nor a step report (messages from the relay server)
--!  request_speed (function) optional; when set, speed and pause changes
--!             made by the player are sent through it instead of being
--!             applied locally (the server shares them with everybody)
--!  observer   (bool) optional; this peer only follows the game (the server's
--!             headless referee): it issues no commands and is not in anybody's
--!             peers list
--!  send_cosmetic (function) optional; sends a table of plain values to the
--!             other players outside the lockstep (e.g. the outline of a room
--!             someone is drawing). Never changes game state.
function MultiplayerSession:MultiplayerSession(params)
  self.world = params.world
  self.peer_id = params.peer_id
  self.peers = params.peers
  self.transport = params.transport
  self.delay = params.delay or 2
  assert(self.delay >= 2, "lockstep delay must be at least 2 steps")
  self.handlers = params.handlers or MultiplayerSession.default_handlers
  self.fingerprint = params.fingerprint or MultiplayerSession.defaultFingerprint
  self.log = params.log or function() end
  self.notify = params.notify or function() end
  local sdl = rawget(_G, "SDL")
  self.clock = params.clock or (sdl and sdl.getTicks) or function() return 0 end
  self.wait_started = nil -- clock time when the current stall began
  self.wait_notified = false
  self.control = params.control
  self.request_speed = params.request_speed
  self.send_cosmetic = params.send_cosmetic
  self.observer = params.observer
  self.applying = false     -- true while command handlers run
  self.remote_blueprints = {} -- peer -> rectangle drawn on the map

  self.step = 0          -- last completed step
  self.seq = 0           -- last sequence number used by this peer
  self.pending = {}      -- commands received or issued, not yet applied
  self.peer_step = {}    -- peer -> last step reported by that peer
  self.peer_fps = {}     -- step -> peer -> fingerprint (awaiting own value)
  self.own_fps = {}      -- step -> own fingerprint (awaiting peer values)
  self.desync = nil      -- first detected mismatch, or nil
  self.stats = {issued = 0, applied = 0, rejected = 0, stalls = 0}
  for _, p in ipairs(self.peers) do
    if p ~= self.peer_id then self.peer_step[p] = 0 end
  end
end

--! Issue a player action. It is sent to every peer immediately and applied
--! everywhere (including here) at step self.step + self.delay.
--!param cmd (table) plain values; must contain `kind`
function MultiplayerSession:issue(cmd)
  if self.observer then return cmd end -- the referee never acts
  self.seq = self.seq + 1
  -- The hospital the action is for: this player's (multiplayer co-op).
  if cmd.hospital == nil then cmd.hospital = self.hospital_index or 1 end
  cmd.step = self.step + self.delay
  cmd.peer = self.peer_id
  cmd.seq = self.seq
  local line = MultiplayerSession.encodeCommand(cmd)
  -- Keep exactly what the other peers will decode (numbers sent as text,
  -- booleans as strings...), so this peer applies the same values.
  cmd = MultiplayerSession.decodeCommand(line)
  self.pending[#self.pending + 1] = cmd
  self.transport:send(line)
  self.stats.issued = self.stats.issued + 1
  return cmd
end

--! Read everything the transport has for us right now.
function MultiplayerSession:poll()
  while true do
    local line = self.transport:receive()
    if not line then break end
    local cmd = MultiplayerSession.decodeCommand(line)
    if cmd then
      if cmd.step <= self.step then
        self:_reportDesync(self.step, "command for step " .. cmd.step .. " arrived after it ran", cmd.peer)
      else
        self.pending[#self.pending + 1] = cmd
      end
    else
      local peer, step, fp = line:match("^S (%d+) (%d+) (.*)$")
      if peer then
        peer, step = tonumber(peer), tonumber(step)
        self.peer_step[peer] = step
        local own = self.own_fps[step]
        if own then
          self:_compare(step, own, fp, peer)
        else
          self.peer_fps[step] = self.peer_fps[step] or {}
          self.peer_fps[step][peer] = fp
        end
      elseif self.control then
        self.control(line)
      end
    end
  end
end

--! Stop waiting for a peer that left the game. Its commands already received
--! are still applied: they are for steps nobody has run yet.
function MultiplayerSession:removePeer(peer)
  self.peer_step[peer] = nil
  for _, fps in pairs(self.peer_fps) do fps[peer] = nil end
  local remaining = {}
  for _, p in ipairs(self.peers) do
    if p ~= peer then remaining[#remaining + 1] = p end
  end
  self.peers = remaining
  self.log(string.format("peer %d left after step %d", peer, self.step))
end

--! The relay server found differing fingerprints at `step`.
function MultiplayerSession:serverDesync(step)
  self:_reportDesync(step, "fingerprints differ (server)")
end

--! A speed or pause change by the player. Returns true if it was sent to the
--! server instead of being applied here (it comes back for everybody).
function MultiplayerSession:requestSpeed(speed)
  if not self.request_speed then return false end
  self.request_speed(speed)
  return true
end

--! Is every other peer far enough along for us to run the next step?
function MultiplayerSession:canStep()
  self:poll()
  local needed = self.step + 1 - self.delay + 1
  for _, step in pairs(self.peer_step) do
    if step < needed then
      self.stats.stalls = self.stats.stalls + 1
      -- Tell the player once per longer stall (the other player may have
      -- paused, or their computer is slower). Cosmetic only.
      local now = self.clock()
      if not self.wait_started then
        self.wait_started = now
      elseif not self.wait_notified and now - self.wait_started > 1500 then
        self.wait_notified = true
        self.notify("Waiting for the other player...")
      end
      return false
    end
  end
  self.wait_started = nil
  self.wait_notified = false
  return true
end

--! Is a player action now to be sent as a command (rather than done here)?
--! False outside multiplayer, and while command handlers run (they use the
--! same game code to actually do it).
function MultiplayerSession.actionsAreCommands()
  local session = TheApp and TheApp.mp_session
  return session ~= nil and not session.applying
end

--! Steps between attempts when a handler asks to retry (see build_room).
MultiplayerSession.RETRY_STEPS = 4
MultiplayerSession.MAX_RETRIES = 12

--! Apply every command scheduled for the step about to run, in the shared order.
function MultiplayerSession:beforeStep()
  local n = self.step + 1
  local due, keep = {}, {}
  for _, cmd in ipairs(self.pending) do
    if cmd.step == n then due[#due + 1] = cmd else keep[#keep + 1] = cmd end
  end
  self.pending = keep
  table.sort(due, command_order)
  for _, cmd in ipairs(due) do
    local handler = self.handlers[cmd.kind]
    local ok, why
    if handler then
      self.applying = true
      local called, res, reason = pcall(handler, self.world, cmd)
      self.applying = false
      if called then
        ok, why = res, reason
      else
        -- Same state, same code: the error happens on every peer alike.
        ok, why = false, "error: " .. tostring(res)
      end
    else
      ok, why = false, "unknown command " .. tostring(cmd.kind)
    end
    if not ok and why == "retry" then
      -- Try again a few steps later, at the same step on every peer.
      cmd.retries = (cmd.retries or 0) + 1
      if cmd.retries <= MultiplayerSession.MAX_RETRIES then
        cmd.step = n + MultiplayerSession.RETRY_STEPS
        self.pending[#self.pending + 1] = cmd
        why = "retry " .. cmd.retries .. " at step " .. cmd.step
      else
        why = "gave up"
        local giveup = self.handlers[cmd.kind .. "_giveup"]
        if giveup then giveup(self.world, cmd) end
      end
    end
    if ok then
      self.stats.applied = self.stats.applied + 1
    else
      self.stats.rejected = self.stats.rejected + 1
    end
    self.log(string.format("step %d: peer %d #%d %s -> %s", n, cmd.peer, cmd.seq,
        tostring(cmd.kind), ok and "ok" or ("rejected: " .. tostring(why))))
  end
end

--! Record and send this peer's fingerprint for the step just completed.
function MultiplayerSession:afterStep()
  self.step = self.step + 1
  local n = self.step
  local fp = self.fingerprint(self.world)
  self.transport:send(string.format("S %d %d %s", self.peer_id, n, fp))
  local waiting = self.peer_fps[n]
  if waiting then
    for peer, peer_fp in pairs(waiting) do self:_compare(n, fp, peer_fp, peer) end
    self.peer_fps[n] = nil
  else
    self.own_fps[n] = fp
  end
  -- Forget fingerprints every peer has already reported.
  local oldest = n
  for _, s in pairs(self.peer_step) do oldest = math.min(oldest, s) end
  for s in pairs(self.own_fps) do
    if s <= oldest then self.own_fps[s] = nil end
  end
end

function MultiplayerSession:_compare(step, own, other, peer)
  if own ~= other then
    self:_reportDesync(step, "fingerprints differ", peer, own, other)
  end
end

function MultiplayerSession:_reportDesync(step, why, peer, own, other)
  if self.desync then return end
  self.desync = {step = step, reason = why, peer = peer, own = own, other = other}
  self.log(string.format("DESYNC at step %d with peer %s: %s", step, tostring(peer), why))
  self.notify(string.format("Multiplayer games are out of sync (step %d). Please restart the game.", step))
  if own then self.log("  local: " .. own) end
  if other then self.log("  peer:  " .. tostring(other)) end
end

--! Tell the other players about the room outline this player is drawing
--! (nil: no outline any more). Cosmetic: only shown, never part of the game.
function MultiplayerSession:showBlueprint(rect)
  if not self.send_cosmetic then return end
  local key = rect and string.format("%s:%d,%d,%d,%d", rect.room or "", rect.x, rect.y, rect.w, rect.h) or ""
  if key == self.last_blueprint then return end
  self.last_blueprint = key
  if rect then
    self.send_cosmetic({kind = "blueprint", room = rect.room, x = rect.x, y = rect.y, w = rect.w, h = rect.h})
  else
    self.send_cosmetic({kind = "blueprint", x = 0, y = 0, w = 0, h = 0})
  end
end

-- Map layer 4 is the UI overlay layer the room editor draws its blue floor
-- on; gameplay never reads it.
local OVERLAY_LAYER, BLUE_FLOOR = 4, 24

local function paint_rect(world, rect, value)
  local th = world.map and world.map.th
  if not th then return end
  local mw, mh = th:size()
  for x = math.max(1, rect.x), math.min(mw, rect.x + rect.w - 1) do
    for y = math.max(1, rect.y), math.min(mh, rect.y + rect.h - 1) do
      th:setCell(x, y, OVERLAY_LAYER, value)
    end
  end
end

--! Show (or with w = 0, remove) another player's room outline as a blue
--! floor on this player's map.
function MultiplayerSession:showRemoteBlueprint(peer, rect)
  local old = self.remote_blueprints[peer]
  if old then paint_rect(self.world, old, 0) end
  self.remote_blueprints[peer] = nil
  if rect and (rect.w or 0) > 0 and (rect.h or 0) > 0 then
    self.remote_blueprints[peer] = {x = rect.x, y = rect.y, w = rect.w, h = rect.h, room = rect.room}
    paint_rect(self.world, rect, BLUE_FLOOR)
    if peer ~= self.peer_id then
      self.log(string.format("showing reserved area of player %d: %s at %d,%d size %dx%d",
          peer, tostring(rect.room), rect.x, rect.y, rect.w, rect.h))
    end
  end
  -- Overlapping outlines were partly cleared; paint the others again.
  for _, other in pairs(self.remote_blueprints) do paint_rect(self.world, other, BLUE_FLOOR) end
end

--! Default fingerprint: an ordered projection of gameplay state (not a save).
function MultiplayerSession.defaultFingerprint(world)
  local TH = require("TH")
  local hospital = world.hospitals[1]
  local parts = {}
  for _, e in ipairs(world.entities) do
    parts[#parts + 1] = (e.humanoid_class or (e.object_type and e.object_type.id) or "?")
        .. "@" .. tostring(e.tile_x) .. "," .. tostring(e.tile_y)
  end
  -- Other hospitals (multiplayer co-op) in short form.
  local others = {}
  for i = 2, #world.hospitals do
    local h = world.hospitals[i]
    others[#others + 1] = string.format(" h%d=%s/%s/%s/%d", i, tostring(h.balance),
        tostring(h.num_visitors or 0), tostring(h.num_cured or 0), #(h.staff or {}))
  end
  return string.format("%s bal=%s visitors=%s entities=%d cured=%s staff=%d ecrc=%08x rng=%08x%s",
      world.game_date:tostring(), tostring(hospital.balance), tostring(hospital.num_visitors or 0),
      #world.entities, tostring(hospital.num_cured or 0), #hospital.staff,
      TH.CRC32File(table.concat(parts, ";")), TH.CRC32File(math.randomdump()), table.concat(others))
end

--! In a multiplayer game, refuse a player action that is not yet sent to the
--! other peers as a command (applying it locally would desync the game).
--! Does nothing outside multiplayer.
--!param ui (UI) optional; used to tell the player
--!return (bool) true if the caller must not perform the action
function MultiplayerSession.blockUnsupported(ui)
  if not (TheApp and TheApp.mp_session) then return false end
  if ui then
    ui:playSound("wrong2.wav")
    if ui.adviser then
      ui.adviser:say({text = "This action is not available in multiplayer yet.", priority = 10})
    end
  end
  return true
end

--------------------------------------------------------------------------------
-- Command handlers. Each must give the same result on every peer for the
-- same state, and must not advance game time.
--------------------------------------------------------------------------------

local handlers = {}
MultiplayerSession.default_handlers = handlers

local function tile_free_for_object(world, hospital, x, y, tile)
  local th = world.map.th
  if not hospital:isInHospital(x, y) or world:getRoom(x, y) then return false end
  local flags = th:getCellFlags(x, y)
  if tile.only_passable then return flags.passable end
  return flags.buildable and flags.passable and not world:getObject(x, y)
end

--! Buy and place a new corridor object: {object, x, y, orientation}.
function handlers.place_object(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  local object_type = world.object_types[cmd.object]
  local orientation = object_type and object_type.orientations[cmd.orientation]
  if not orientation then return false, "unknown object or orientation" end
  for _, t in ipairs(orientation.footprint) do
    if not tile_free_for_object(world, hospital, cmd.x + t[1], cmd.y + t[2], t) then
      return false, "tile not free"
    end
  end
  if world:anyHumanoidObscuringArea(cmd.x, cmd.y) then
    return false, "someone is in the way"
  end
  local cost = hospital:getObjectBuildCost(cmd.object)
  local msg = _S.transactions.buy_object .. ": " .. object_type.name
  hospital:spendMoney(cost, msg, cost)
  world:prepareFootprintTilesForBuild(orientation.footprint, cmd.x, cmd.y)
  world:newObject(cmd.object, cmd.x, cmd.y, cmd.orientation)
  if cmd.object == "reception_desk" then
    hospital:buildReceptionDesksCache()
  end
  return true
end

--! Open the hospital before the opening countdown ends: {hospital}.
function handlers.open_hospital(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  if not hospital or hospital.opened then return false, "already open" end
  hospital.mp_opening = nil
  hospital:open()
  if world.ui then
    for _, window in ipairs(world.ui.windows or {}) do
      if class.is(window, UIWatch) and window.count_type == "initial_opening"
          and window.hospital == hospital then
        window:close()
        break
      end
    end
  end
  return true
end

--! Build a finished room the player drew: {room, x, y, w, h, door_x, door_y,
--! door_wall, windows}. If people stand in the area they are asked to walk
--! out and the command is retried a few steps later (on every peer alike).
function handlers.build_room(world, cmd)
  local builder = corsixth.require("mp_room_builder")
  local hospital = world.hospitals[cmd.hospital or 1]
  if not hospital then return false, "no such hospital" end
  local room, why = builder.build(world, hospital, cmd)
  if why == "people in the area" then
    builder.clearArea(world, cmd.x, cmd.y, cmd.w, cmd.h)
    return false, "retry" -- the reserved outline stays visible meanwhile
  end
  local session = TheApp.mp_session
  if session then session:showRemoteBlueprint(cmd.peer, nil) end
  if room then return true end
  builder.releaseArea(world, cmd.x, cmd.y, cmd.w, cmd.h)
  if cmd.peer == (session and session.peer_id) and world.ui and world.ui.adviser then
    world.ui.adviser:say({text = "The room could not be built: " .. tostring(why) .. ".", priority = 10})
  end
  return false, why
end

function handlers.build_room_giveup(world, cmd)
  corsixth.require("mp_room_builder").releaseArea(world, cmd.x, cmd.y, cmd.w, cmd.h)
  local session = TheApp.mp_session
  if session then session:showRemoteBlueprint(cmd.peer, nil) end
  return false, "not a player command"
end

--! A player's answer to a fax (emergency, VIP, epidemic...): {msg, choice}.
--! The message exists on every peer (shown or still queued).
function handlers.fax_choice(world, cmd)
  local panel = world.ui and world.ui.bottom_panel
  local icon = panel and panel:findMessageIcon(cmd.msg)
  if not icon then return false, "message no longer there" end
  local choices = icon.message and icon.message.choices
  if not choices or not choices[cmd.choice] then return false, "no such choice" end
  if choices[cmd.choice].enabled == false or choices[cmd.choice].choice == "disabled" then
    return false, "choice not available"
  end
  local queued = icon.parent == nil
  icon:removeMessage(cmd.choice)
  if queued then panel:forgetQueuedIcon(icon) end
  return true
end

--------------------------------------------------------------------------------
-- Multiplayer co-op trades between the players' hospitals.
--------------------------------------------------------------------------------

--! Send money to another player's hospital: {hospital (sender), to, amount}.
function handlers.give_money(world, cmd)
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  local amount = math.floor(tonumber(cmd.amount) or 0)
  if not from or not to or from == to then return false, "no such hospital" end
  if amount <= 0 then return false, "nothing to send" end
  if from.balance < amount then return false, "not enough money" end
  from:spendMoney(amount, _S.multiplayer_window.money_sent:format(to.name))
  to:receiveMoney(amount, _S.multiplayer_window.money_received:format(from.name))
  MultiplayerSession.tellPlayer(world, to,
      _S.multiplayer_window.money_received_note:format(from.name, amount))
  return true
end

--! Staff member `index` of a hospital, if their profile still has `key`.
local function find_staff(hospital, index, key)
  local staff = hospital.staff[index]
  if staff and not staff.fired and MultiplayerSession.staffKey(staff) == key then return staff end
  for _, s in ipairs(hospital.staff) do
    if not s.fired and MultiplayerSession.staffKey(s) == key then return s end
  end
end

--! Identity of an employed staff member that does not depend on language.
function MultiplayerSession.staffKey(staff)
  return staff.humanoid_class .. "/" .. MultiplayerSession.staffProfileKey(staff.profile)
end

--! A free corridor tile of `hospital` near its camera start position.
local function arrival_tile(world, hospital)
  local th = world.map.th
  local cx, cy = th:getCameraTile(hospital:getPlayerIndex())
  for r = 0, 25 do
    for dy = -r, r do
      for dx = -r, r do
        if math.max(math.abs(dx), math.abs(dy)) == r then
          local x, y = cx + dx, cy + dy
          if hospital:isInHospital(x, y) and not world:getRoom(x, y) and
              th:getCellFlags(x, y).passable then
            return x, y
          end
        end
      end
    end
  end
end

--! Send a staff member to another player's hospital: {hospital (sender), to,
--! index, key}. They walk out of the old hospital and an identical member of
--! staff (same profile, wage and skills) starts at the new one. No hiring fee
--! and no severance pay.
function handlers.send_staff(world, cmd)
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  if not from or not to or from == to then return false, "no such hospital" end
  local staff = find_staff(from, cmd.index, cmd.key)
  if not staff then return false, "no such staff member" end
  local x, y = arrival_tile(world, to)
  if not x then return false, "no room at the other hospital" end

  -- Leave the old hospital, like Staff:fire() without the penalties.
  local old_profile = staff.profile
  local staff_window = world.ui and world.ui:getWindow(UIStaff)
  if staff_window and staff_window.staff == staff then staff_window:close() end
  staff:removeQueuedStaffMessage()
  staff:setMood("exit", "activate")
  staff.fired = true
  staff.going_home = true
  staff:despawn()
  staff.hover_cursor = nil
  staff:unregisterCallbacks()

  -- Start at the new one with a copy of the profile.
  local profile = setmetatable({}, getmetatable(old_profile))
  for k, v in pairs(old_profile) do profile[k] = v end
  local entity = world:newEntity(profile.humanoid_class, 2, 2)
  entity:setProfile(profile)
  entity:setTile(x, y)
  to.staff[#to.staff + 1] = entity
  entity:setHospital(to)
  to:notifyOfStaffChange(entity)
  entity:onPlaceInCorridor()

  local window = world.ui and world.ui:getWindow(UIStaffManagement)
  if window then window:updateStaffList() end
  MultiplayerSession.tellPlayer(world, to,
      _S.multiplayer_window.staff_received_note:format(from.name, "") .. profile:getFullName())
  return true
end

--! Show a short adviser message, only to the player running `hospital`.
function MultiplayerSession.tellPlayer(world, hospital, text)
  local ui = world.ui
  if ui and ui.adviser and ui.hospital == hospital then
    ui.adviser:say({text = text, priority = 10})
  end
end

--------------------------------------------------------------------------------
-- Hospital settings changed in the game windows. The window computes the new
-- value; the handler checks it and sets it on every peer.
--------------------------------------------------------------------------------

local function hospital_of(world, cmd)
  return world.hospitals[cmd.hospital or 1]
end

--! Take (amount > 0) or repay (amount < 0) a bank loan: {amount}.
function handlers.loan(world, cmd)
  local hospital = hospital_of(world, cmd)
  local amount = math.floor(tonumber(cmd.amount) or 0)
  if not hospital or amount == 0 then return false, "nothing to do" end
  if amount > 0 then
    local max_loan = not world.free_build_mode and
        (math.floor((hospital.value * 0.33) / 5000) * 5000) + 10000 or 0
    if hospital.loan + amount > max_loan then return false, "loan limit" end
    hospital.loan = hospital.loan + amount
    hospital:receiveMoney(amount, _S.transactions.bank_loan)
  else
    amount = -amount
    if amount > hospital.loan or hospital.balance < amount then return false, "cannot repay" end
    hospital.loan = hospital.loan - amount
    hospital:spendMoney(amount, _S.transactions.loan_repayment)
  end
  return true
end

--! Treatment price for a disease: {disease, percent} (50..200).
function handlers.set_price(world, cmd)
  local hospital = hospital_of(world, cmd)
  local entry = hospital and hospital.disease_casebook[cmd.disease]
  local percent = math.floor(tonumber(cmd.percent) or 0)
  if not entry or percent < 50 or percent > 200 then return false, "invalid price" end
  entry.price = percent / 100
  return true
end

--! Concentrate research on a disease (toggles, like the casebook button): {disease}.
function handlers.concentrate_research(world, cmd)
  local hospital = hospital_of(world, cmd)
  if not hospital or not hospital:canConcentrateResearch(cmd.disease) then
    return false, "cannot concentrate research"
  end
  hospital.research:concentrateResearch(cmd.disease)
  return true
end

--! Share of research for an area: {area, frac} (0..100, total at most 100).
function handlers.research_frac(world, cmd)
  local hospital = hospital_of(world, cmd)
  local policy = hospital and hospital.research.research_policy
  local area = policy and policy[cmd.area]
  local frac = math.floor(tonumber(cmd.frac) or -1)
  if type(area) ~= "table" or area.frac == nil or frac < 0 then return false, "invalid research area" end
  if frac > area.frac and not area.current then return false, "nothing to research" end
  local others = (policy.total or 0) - area.frac
  frac = math.min(frac, 100 - others)
  area.frac = frac
  policy.total = others + frac
  return true
end

local POLICY_KEYS = {guess_cure = true, send_home = true, stop_procedure = true,
  goto_staffroom = true, staff_allowed_to_move = true}

--! A hospital policy: {key, value} for the staff-may-move switch (0/1), or
--! {key, base, offset, range} for a slider (value = base + offset / range).
function handlers.set_policy(world, cmd)
  local hospital = hospital_of(world, cmd)
  if not hospital or not POLICY_KEYS[cmd.key] then return false, "unknown policy" end
  if cmd.key == "staff_allowed_to_move" then
    hospital.policies[cmd.key] = tonumber(cmd.value) == 1
  else
    local range = tonumber(cmd.range) or 0
    if range <= 0 then return false, "invalid slider" end
    hospital.policies[cmd.key] = (tonumber(cmd.base) or 0) + (tonumber(cmd.offset) or 0) / range
  end
  return true
end

--! Buy a plot of land: {plot}.
function handlers.buy_plot(world, cmd)
  local hospital = hospital_of(world, cmd)
  if not hospital then return false, "no such hospital" end
  local ui = world.ui
  -- purchasePlot gives cost advice through the UI; only to that player.
  local adviser = ui and ui.adviser
  if ui and ui.hospital ~= hospital then ui.adviser = nil end
  local ok = hospital:purchasePlot(tonumber(cmd.plot))
  if ui then ui.adviser = adviser end
  return ok, not ok and "cannot buy this plot" or nil
end

--! Radiator heat: {level} (1..10, tenths).
function handlers.set_heat(world, cmd)
  local hospital = hospital_of(world, cmd)
  local level = math.floor(tonumber(cmd.level) or 0)
  if not hospital or level < 1 or level > 10 then return false, "invalid heat" end
  if hospital.heating.heating_broke then return false, "heating is broken" end
  hospital.heating.radiator_heat = level / 10
  return true
end

--! Entity of the right class named by a command, or nil.
local function entity_of(world, id, klass)
  local entity = world:getEntityById(tonumber(id))
  if entity and (not klass or class.is(entity, klass)) then return entity end
end
MultiplayerSession.entityOf = entity_of

--! Which plot a handyman looks after: {staff, parcel} (0 = all).
function handlers.handyman_parcel(world, cmd)
  local staff = entity_of(world, cmd.staff, Handyman)
  local parcel = math.floor(tonumber(cmd.parcel) or -1)
  if not staff or staff.fired or parcel < 0 then return false, "no such handyman" end
  if parcel ~= 0 and not table_contains(staff.hospital.ownedPlots, parcel) then
    return false, "not our plot"
  end
  staff.parcelNr = parcel
  return true
end

--! Raise one of a handyman's priorities: {staff, attr}.
function handlers.handyman_prio(world, cmd)
  local staff = entity_of(world, cmd.staff, Handyman)
  if not staff or staff.fired or not staff:getAttribute(cmd.attr) then return false, "no such handyman" end
  UIStaff.raiseHandymanPriority(staff, cmd.attr)
  return true
end

--! Longest queue for a room door or reception desk: {owner, size} (0..30).
function handlers.queue_size(world, cmd)
  local owner = entity_of(world, cmd.owner)
  local size = math.floor(tonumber(cmd.size) or -1)
  if not owner or not owner.queue or size < 0 or size > 30 then return false, "no such queue" end
  owner.queue.max_size = size
  return true
end

--------------------------------------------------------------------------------
-- Actions on one patient, member of staff, machine or rat, named by entity id
-- (World:_numberEntity). Handlers check again that the action still makes
-- sense; a stale click is rejected on every peer alike.
--------------------------------------------------------------------------------

--! Send a patient home: {patient, text (1: show "sent home")}.
function handlers.send_home(world, cmd)
  local patient = entity_of(world, cmd.patient, Patient)
  if not patient or patient.going_home then return false, "no such patient" end
  patient:goHome("kicked")
  if tonumber(cmd.text) == 1 then
    patient:setDynamicInfoText(_S.dynamic_info.patient.actions.sent_home)
  end
  return true
end

--! Guess the cure for a patient (patient window): {patient}.
function handlers.guess_cure(world, cmd)
  local patient = entity_of(world, cmd.patient, Patient)
  if not patient or patient.is_debug or patient.diagnosis_progress == 0 or patient.diagnosed or
      patient.going_home or patient.going_to_die or patient:getRoom() or
      not patient.hospital.disease_casebook[patient.disease.id].discovered then
    return false, "cannot guess the cure"
  end
  patient:setDiagnosed()
  if patient:agreesToPay(patient.disease.id) then
    patient:setNextAction(SeekRoomAction(patient.disease.treatment_rooms[1]):enableTreatmentRoom(), 1)
  else
    patient:goHome("over_priced")
  end
  return true
end

--! Send a queueing patient back to reception: {patient}.
function handlers.to_reception(world, cmd)
  local patient = entity_of(world, cmd.patient, Patient)
  if not patient or patient.going_home then return false, "no such patient" end
  patient:setNextAction(SeekReceptionAction())
  return true
end

--! Pay a member of staff a bonus: {staff}.
function handlers.staff_bonus(world, cmd)
  local staff = entity_of(world, cmd.staff, Staff)
  if not staff or staff.fired then return false, "no such staff member" end
  local bonus = math.floor(staff.profile.wage * 0.1)
  if staff.hospital.balance <= bonus then return false, "not enough money" end
  staff:changeAttribute("happiness", 0.5)
  staff.hospital:spendMoney(bonus, _S.transactions.personal_bonus)
  return true
end

--! Raise a member of staff's wage by 10 percent: {staff}.
function handlers.raise_wage(world, cmd)
  local staff = entity_of(world, cmd.staff, Staff)
  if not staff or staff.fired then return false, "no such staff member" end
  if not staff:increaseWage(math.floor(staff.profile.wage * 0.1)) then return false, "no raise" end
  return true
end

--! Ask a handyman to repair a machine now: {machine}.
function handlers.call_handyman(world, cmd)
  local machine = entity_of(world, cmd.machine, Machine)
  if not machine or machine.times_used == 0 then return false, "nothing to repair" end
  local hospital = machine.hospital
  local task = hospital:getIndexOfTask(machine.tile_x, machine.tile_y, "repairing")
  if task == -1 then
    local call = world.dispatcher:callForRepair(machine, false, true)
    hospital:addHandymanTask(machine, "repairing", 2, machine.tile_x, machine.tile_y, call)
  else
    hospital:modifyHandymanTaskPriority(task, 2, "repairing")
  end
  machine:setRepairingStatus()
  return true
end

--! Replace a worn machine with a new one: {machine}.
function handlers.replace_machine(world, cmd)
  local machine = entity_of(world, cmd.machine, Machine)
  if not machine then return false, "no such machine" end
  local hospital = machine.hospital
  local cost = hospital.research.research_progress[machine.object_type].cost
  if hospital.balance < cost then return false, "not enough money" end
  machine:replaceMachine(cost)
  return true
end

--! Shoot a rat: {rat}.
function handlers.shoot_rat(world, cmd)
  local rat = entity_of(world, cmd.rat, Rat)
  if not rat or rat.shot then return false, "no such rat" end
  rat:shoot()
  return true
end

--! Mark an infected patient for vaccination during an epidemic: {patient}.
function handlers.mark_vaccinate(world, cmd)
  local patient = entity_of(world, cmd.patient, Patient)
  local epidemic = patient and patient.hospital and patient.hospital.epidemic
  if not epidemic or not epidemic.coverup_selected or epidemic.timer.closed or
      not patient.infected or patient.marked_for_vaccination then
    return false, "cannot vaccinate"
  end
  epidemic:markForVaccination(patient)
  return true
end

--! Language-independent identity of a staff profile in the hiring pool.
--! (Names are translated strings and may differ between peers.)
function MultiplayerSession.staffProfileKey(profile)
  return string.format("%d/%.6f", profile.wage, profile.skill)
end

--! Hire a member of staff from the shared pool: {category, index, key, x, y}.
--! `index` is the position the issuing player saw; if the pool changed since
--! (someone else hired), the first profile with the same key is used.
function handlers.hire(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  local pool = world.available_staff[cmd.category] or {}
  local key = MultiplayerSession.staffProfileKey
  local index
  if pool[cmd.index] and key(pool[cmd.index]) == cmd.key then
    index = cmd.index
  else
    for i, profile in ipairs(pool) do
      if key(profile) == cmd.key then index = i break end
    end
  end
  if not index then return false, "no longer available" end
  if not hospital:isInHospital(cmd.x, cmd.y) or not world.map.th:getCellFlags(cmd.x, cmd.y).passable then
    return false, "invalid position"
  end
  local profile = table.remove(pool, index)
  local entity = world:newEntity(profile.humanoid_class, 2, 2)
  entity:setProfile(profile)
  entity:setTile(cmd.x, cmd.y)
  hospital:addStaff(entity)
  entity:setHospital(hospital)
  local room = entity:getRoom()
  if room then
    room:onHumanoidEnter(entity)
  else
    entity:onPlaceInCorridor()
  end
  local window = world.ui and world.ui:getWindow(UIStaffManagement)
  if window then window:updateStaffList() end
  return true
end
