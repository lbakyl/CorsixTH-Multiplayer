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
  self.seq = self.seq + 1
  cmd.step = self.step + self.delay
  cmd.peer = self.peer_id
  cmd.seq = self.seq
  self.pending[#self.pending + 1] = cmd
  self.transport:send(MultiplayerSession.encodeCommand(cmd))
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
      ok, why = handler(self.world, cmd)
    else
      ok, why = false, "unknown command " .. tostring(cmd.kind)
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

--! Default fingerprint: an ordered projection of gameplay state (not a save).
function MultiplayerSession.defaultFingerprint(world)
  local TH = require("TH")
  local hospital = world.hospitals[1]
  local parts = {}
  for _, e in ipairs(world.entities) do
    parts[#parts + 1] = (e.humanoid_class or (e.object_type and e.object_type.id) or "?")
        .. "@" .. tostring(e.tile_x) .. "," .. tostring(e.tile_y)
  end
  return string.format("%s bal=%s visitors=%s entities=%d cured=%s staff=%d ecrc=%08x rng=%08x",
      world.game_date:tostring(), tostring(hospital.balance), tostring(hospital.num_visitors or 0),
      #world.entities, tostring(hospital.num_cured or 0), #hospital.staff,
      TH.CRC32File(table.concat(parts, ";")), TH.CRC32File(math.randomdump()))
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
