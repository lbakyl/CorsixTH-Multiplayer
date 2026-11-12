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

---@class MultiplayerSession
---@operator call: MultiplayerSession
local MultiplayerSession = _G["MultiplayerSession"] ---@type MultiplayerSession

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
--!             made by the player become a set_speed command (see
--!             MultiplayerSession:requestSpeed) instead of being applied
--!             locally; it is called with the speed (for the server's records)
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
  -- Milliseconds. (SDL is a module, not a global: rawget(_G, "SDL") was
  -- always nil, the clock always 0, and the waiting notice never came.)
  self.clock = params.clock or MultiplayerSession.defaultClock()
  self.wait_started = nil -- clock time when the current stall began
  self.wait_notified = false
  self.control = params.control
  self.request_speed = params.request_speed
  self.send_cosmetic = params.send_cosmetic
  self.peer_name = params.peer_name
  self.send_diagnostics = params.send_diagnostics
  self.observer = params.observer
  MultiplayerSession.traceRandomDraws(true) -- (until MultiplayerLobby:_endSession)
  self.held = false         -- stopped by the server while it repairs a desync
  self.load_data = nil      -- {step, data}: the shared save to load (see App:onTick)
  self.save_at = nil        -- the referee sends its save once at this step
  self.local_save = nil     -- {at, kind}: every player saves the game at this step
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
  if self.held then
    -- The games are being repaired; this step may not exist afterwards.
    self.notify("Please wait; the games are being put back in sync.")
    return cmd
  end
  self.seq = self.seq + 1
  -- The hospital the action is for: this player's (multiplayer co-op).
  if cmd.hospital == nil then cmd.hospital = self.hospital_index or 1 end
  -- For a step no peer has run yet: after a repair of only this game (the
  -- others agreed and went on) it runs again steps the others have run. (In
  -- play no peer is that far ahead: the step is this one plus the delay.)
  local furthest = self.step
  for _, step in pairs(self.peer_step) do furthest = math.max(furthest, step) end
  cmd.step = math.max(self.step + self.delay, furthest + 1)
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
    -- Lines after a shared save are for the game loaded from it.
    if self.load_data then break end
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
  self:takeOverRooms(self.world, peer)
  self:_markPlayerAway(peer)
  -- The outline they were drawing goes with them.
  if self.remote_blueprints and self.remote_blueprints[peer] then self:showRemoteBlueprint(peer, nil) end
end

--! A player left: rooms they were furnishing or editing would stay closed.
--! The remaining player with the lowest number hands them over with a
--! command (room_takeover), so every peer does it at the same step.
function MultiplayerSession:takeOverRooms(world, peer)
  if self.observer or not world or not world.rooms then return end
  local lowest
  for _, p in ipairs(self.peers) do
    if p ~= 0 and (not lowest or p < lowest) then lowest = p end
  end
  if lowest ~= self.peer_id then return end
  local ids = {}
  for id, entry in pairs(world.mp_furnishing or {}) do
    if entry.peer == peer then ids[#ids + 1] = id end
  end
  for id, room in pairs(world.rooms) do
    if room.mp_edit and room.mp_edit.peer == peer then ids[#ids + 1] = id end
  end
  table.sort(ids)
  for _, id in ipairs(ids) do self:issue({kind = "room_takeover", room = id, left = peer}) end
end

--! Co-op (or a race of two teams): a player left. Their hospital stops
--! counting for the team's goals until they rejoin (World:checkIfGameWon),
--! else the others could never win. The remaining player with the lowest
--! number sends it as a command, so every peer marks it at the same step.
function MultiplayerSession:_markPlayerAway(peer)
  local world = self.world
  if self.observer or not (world and world.mp_coop) then return end
  if world.mp_coop.competitive and not world.mp_coop.teams then return end
  local lowest
  for _, p in ipairs(self.peers) do
    if p ~= 0 and (not lowest or p < lowest) then lowest = p end
  end
  if lowest ~= self.peer_id then return end
  local seats = self.lobby and self.lobby.peer_hospital
  local index = seats and seats[peer]
  if not index then return end
  -- A hospital run by a team (mode teamshared) is away only once all its
  -- players are.
  for _, p in ipairs(self.peers) do
    if p ~= peer and p ~= 0 and seats[p] == index then return end
  end
  self:issue({kind = "player_away", seat = index, away = 1})
end

--! The relay server found differing fingerprints at `step`.
function MultiplayerSession:serverDesync(step)
  self:_reportDesync(step, "fingerprints differ (server)")
end

--! A speed or pause change by the player. Returns true if it was sent to the
--! server instead of being applied here (it comes back for everybody).
--!param confirmed (boolean) the player said yes to the vote already
--! (MultiplayerSession:_confirmVote).
function MultiplayerSession:requestSpeed(speed, confirmed)
  if not self.request_speed then return false end
  if self.observer then return true end
  -- Only the room owner, if the room says so (checked here: the owner can
  -- change during a game, which the command handlers do not know).
  if self.speed_control == "owner" and self.lobby and not self.lobby:isOwner() then
    self.notify("Only the room owner changes the speed.")
    return true
  end
  if speed ~= "Pause" then speed = MultiplayerLobby.clampSpeed(speed, self.max_speed) end
  -- Commands: every peer changes speed at the same step (the lockstep
  -- steps depend on the speed below Normal, see World:_mpTick). Pausing and
  -- unpausing take effect at once; a new speed is put to the vote (unless
  -- only the owner sets it, or nobody else plays).
  local world = self.world
  local current = world and world.mp_speed or "Normal"
  local voters = self:voterCount()
  if speed == "Pause" or self.speed_control == "owner" or voters <= 1 then
    if speed ~= current then self:issue({kind = "set_speed", speed = speed}) end
    return true
  end
  if current == "Pause" then
    -- Unpause at the speed from before the pause; a different one is voted on.
    local resume = world.mp_resume_speed or "Normal"
    self:issue({kind = "set_speed", speed = resume})
    if speed == resume then return true end
  elseif speed == current then
    return true
  end
  if world.mp_vote then
    self.notify(_S.multiplayer_window.vote_open)
    return true
  end
  if not confirmed and self:_confirmVote(speed) then return true end
  self:issue({kind = "speed_vote", speed = speed, voters = voters})
  return true
end

--! Asks this player before a speed vote starts: the number keys started
--! votes at a slip of the finger (Argus, eu2 2026-11-07). True when the box
--! is up (its OK asks again, confirmed); false without a game screen.
function MultiplayerSession:_confirmVote(speed)
  local ui = TheApp and TheApp.ui
  local UIConfirmDialog = _G["UIConfirmDialog"]
  if not (ui and ui.addWindow and ui.getWindow and UIConfirmDialog) then return false end
  -- (Another number key while the box is up: the newest speed is asked.)
  local open = ui:getWindow(UIConfirmDialog)
  if open and open.mp_speed_vote then open:close() end
  local box = UIConfirmDialog(ui, false, _S.multiplayer_window.vote_confirm:format(speed),
    --[[persistable:mp_speed_vote_confirm]] function()
      local session = TheApp.mp_session
      if session then session:requestSpeed(speed, true) end
    end)
  box.mp_speed_vote = true
  ui:addWindow(box)
  return true
end

--! How many players vote on a new speed: the people playing. The referee
--! does not play, and bots do not vote (they would agree to anything, and
--! with a bot one player could outvote another). Alone with bots, a player
--! sets the speed at once.
function MultiplayerSession:voterCount()
  local players = self.lobby and self.lobby.players or {}
  local n = 0
  for _, p in ipairs(self.peers or {}) do
    local player = players[p]
    if p ~= 0 and not (player and player.bot == "1") then n = n + 1 end
  end
  return n
end

-- The game's start: its first step waits until the loading picture has been
-- up this long on this computer (MultiplayerLobby.drawLoading), so every
-- player sees it while the game connects; the others wait for the last one.
-- Not for the referee, which shows nothing. 0: no pause (tests, bots).
MultiplayerSession.START_PAUSE_MS = 1500

--! Is every other peer far enough along for us to run the next step?
function MultiplayerSession:canStep()
  self:poll()
  if self.held or self.load_data or (self.save_at and self.step >= self.save_at) or
      (self.local_save and self.step >= self.local_save.at) then
    return false
  end
  local lobby = rawget(_G, "MultiplayerLobby")
  if self.step == 0 and not self.observer and lobby and lobby.inStartPause(rawget(_G, "TheApp")) then return false end
  local needed = self.step + 1 - self.delay + 1
  local waiting_for
  for p, step in pairs(self.peer_step) do
    if step < needed and (not waiting_for or p < waiting_for) then waiting_for = p end
  end
  if waiting_for then
    self.stats.stalls = self.stats.stalls + 1
    -- Picture only: after a moment the screen turns blue like a pause, and
    -- the player is told whom the game waits for (and why, if that player
    -- has a message open that pauses their game, see showBusy).
    local now = self.clock()
    if not self.wait_started then
      self.wait_started = now
    else
      if not self.wait_tinted and now - self.wait_started > 700 then
        self.wait_tinted = true
        self.log(string.format("waiting for peer %d at step %d: the screen turns blue", waiting_for, self.step))
        local video = rawget(_G, "TheApp") and TheApp.video
        if video then video:setBlueFilterActive(true) end
      end
      if not self.wait_notified and now - self.wait_started > 1500 then
        self.wait_notified = true
        self.notify(self:waitingText(waiting_for))
      end
    end
    return false
  end
  self.wait_started = nil
  self.wait_notified = false
  if self.wait_tinted then
    self.wait_tinted = false
    if self.world and self.world.updateScreenBlueFilter then self.world:updateScreenBlueFilter() end
  end
  return true
end

-- What the open pause window of another player is, in words.
local busy_words = {
  UIFax = "a fax", UIStaffRise = "a pay rise request", UIAnnualReport = "the annual report",
  UIConfirmDialog = "a question",
}

--! "Waiting for <name>..." (with the reason if that player has a window
--! open that pauses their game).
function MultiplayerSession:waitingText(peer)
  local name = self.peer_name and self.peer_name(peer) or nil
  local who = name and ("Waiting for " .. name) or "Waiting for the other player"
  local busy = self.busy and self.busy[peer]
  if busy then return who .. ": " .. (busy_words[busy] or "a message") .. " is open." end
  return who .. "..."
end

--! This player's game opened (what = window class) or closed (nil) a window
--! that pauses it (fax, pay rise, ...): the others are told why they wait.
function MultiplayerSession:showBusy(what)
  if what == self.busy_shown then return end
  self.busy_shown = what
  if self.send_cosmetic then self.send_cosmetic({kind = "busy", what = what or ""}) end
end

--! Start again from `step` in `world`, freshly loaded from the save every peer
--! loaded (desync repair). Commands for later steps come again from the server.
--!param peers (list) optional; the players from now on (a player rejoined)
function MultiplayerSession:restartAt(world, step, peers)
  self.world = world
  self.last_fp = nil
  self.vote_shown = nil -- the loaded screen has no vote fax yet
  if peers then
    self.peers = peers
    self.peer_step = {}
    for _, p in ipairs(peers) do
      if p ~= self.peer_id then self.peer_step[p] = step end
    end
  end
  self.step = step
  self.pending = {}
  self:_resumeRetries(world, step)
  self.vaccinate_pending = nil
  self.own_fps, self.peer_fps = {}, {}
  self.desync = nil
  self.desync_notice_at = nil
  self.remote_blueprints = {}
  for p in pairs(self.peer_step) do self.peer_step[p] = step end
  self.wait_started, self.wait_notified = nil, false
  self.restarts = (self.restarts or 0) + 1
end

--! Save the game on this machine once the step being run is complete (the
--! same step on every peer: from a save_game command or the monthly
--! autosave, both in the simulation). Written between ticks, see
--! MultiplayerLobby:serviceSaves.
--!param kind (string) "save" or "autosave"
function MultiplayerSession:requestLocalSave(kind)
  if self.observer or self.local_save then return end
  self.local_save = {at = self.step + 1, kind = kind}
end

--! File > Save in a multiplayer game: every player's game saves at the same
--! game hour, so any of them can continue it later from the lobby.
function MultiplayerSession.saveTogether()
  local session = TheApp and TheApp.mp_session
  if not session then return false end
  session:issue({kind = "save_game"})
  session.notify(_S.multiplayer_window.saving_note)
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
--! After loading a game (a desync repair, a rejoin, a continued game):
--! commands that were waiting to be tried again (a room waiting for people
--! to leave its area) are kept in the game (world.mp_retries, beforeStep),
--! so they go on; the tiles people were asked to leave (avoidTile, set only
--! by such a room) are freed first and marked again by the room's next try.
--! Before, a reload forgot the waiting room: its player's editor waited for
--! good and nobody could build there again (Argus, eu2).
function MultiplayerSession:_resumeRetries(world, step)
  local th = world and world.map and world.map.th
  if not th then return end
  local w, h = th:size()
  local flags = {}
  for ty = 1, h do
    for tx = 1, w do
      th:getCellFlags(tx, ty, flags)
      if flags.avoidTile then th:setCellFlags(tx, ty, {avoidTile = false}) end
    end
  end
  local keys = {}
  for key in pairs(world.mp_retries or {}) do keys[#keys + 1] = key end
  table.sort(keys)
  for _, key in ipairs(keys) do
    local cmd = world.mp_retries[key]
    cmd.step = step + MultiplayerSession.RETRY_STEPS
    cmd.retry_at_hour = nil
    self.pending[#self.pending + 1] = cmd
  end
end

MultiplayerSession.RETRY_STEPS = 4
MultiplayerSession.MAX_RETRIES = 12
--! A room waiting for people to walk out of its area waits longer (single
--! player waits until they have left): 150 tries, 600 steps, 12 days.
MultiplayerSession.MAX_CLEAR_RETRIES = 150

--! Apply every command scheduled for the step about to run, in the shared order.
function MultiplayerSession:beforeStep()
  local n = self.step + 1
  local due, keep = {}, {}
  for _, cmd in ipairs(self.pending) do
    if cmd.step == n then due[#due + 1] = cmd else keep[#keep + 1] = cmd end
  end
  self.pending = keep
  self.applied_this_step = false -- a command ran (see afterStep)
  table.sort(due, command_order)
  local hours_done = self.world and self.world.mp_hours
  for _, cmd in ipairs(due) do
    local handler = self.handlers[cmd.kind]
    local ok, why
    if cmd.retry_at_hour and hours_done and hours_done < cmd.retry_at_hour then
      -- A retry waits RETRY_STEPS game hours, not steps: below Normal a step
      -- is a fraction of an hour, and people need hours to walk away.
      cmd.step = n + 1
      self.pending[#self.pending + 1] = cmd
      ok, why = nil, "waiting"
    elseif handler then
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
    local retry_key = cmd.peer and cmd.seq and (cmd.peer .. ":" .. cmd.seq)
    if not ok and why == "retry" then
      -- Try again a few steps later, at the same step on every peer.
      cmd.retries = (cmd.retries or 0) + 1
      if cmd.retries <= (cmd.max_retries or MultiplayerSession.MAX_RETRIES) then
        cmd.step = n + MultiplayerSession.RETRY_STEPS
        cmd.retry_at_hour = hours_done and hours_done + MultiplayerSession.RETRY_STEPS
        self.pending[#self.pending + 1] = cmd
        why = "retry " .. cmd.retries .. " at step " .. cmd.step
        -- (Kept in the game too, so a reload goes on with it: _resumeRetries.)
        if self.world and retry_key then
          self.world.mp_retries = self.world.mp_retries or {}
          self.world.mp_retries[retry_key] = cmd
        end
      else
        why = "gave up"
        local giveup = self.handlers[cmd.kind .. "_giveup"]
        if giveup then giveup(self.world, cmd) end
      end
    end
    if why ~= "waiting" and not tostring(why):find("^retry ") and retry_key and
        self.world and self.world.mp_retries then
      self.world.mp_retries[retry_key] = nil
    end
    if why == "waiting" then -- luacheck: ignore 542
      -- (still waiting for its retry; nothing to count or log)
    elseif ok then
      self.stats.applied = self.stats.applied + 1
      local sound = MultiplayerSession.success_sounds[cmd.kind]
      local ui = self.world and self.world.ui
      if sound and cmd.peer == self.peer_id and ui and not cmd.no_sound then ui:playSound(sound) end
    else
      self.stats.rejected = self.stats.rejected + 1
      if cmd.peer == self.peer_id and not tostring(why):find("^retry ") then
        self:_tellRejected(cmd, why)
      end
    end
    if why ~= "waiting" and cmd.kind == "mark_vaccinate" and cmd.peer == self.peer_id and
        self.vaccinate_pending then
      self.vaccinate_pending[tostring(cmd.patient)] = nil
    end
    if why ~= "waiting" then
      self.applied_this_step = true
      self.log(string.format("step %d: peer %d #%d %s -> %s%s", n, cmd.peer, cmd.seq,
          tostring(cmd.kind), ok and "ok" or ("rejected: " .. tostring(why)),
          cmd.resolved and (" (" .. cmd.resolved .. ")") or ""))
    end
  end
  self:tickVote()
  self:tickAuction()
  self:tickHold()
  self:_dropStaleOutline()
end

--! This player's reserved outline (blue floor and walls) stays only while
--! their room command is on its way or waiting for a retry. Once none is
--! left (built, refused, given up, or lost in a repair), it goes.
function MultiplayerSession:_dropStaleOutline()
  local own = self.remote_blueprints and self.remote_blueprints[self.peer_id]
  if not own then return end
  for _, cmd in ipairs(self.pending) do
    if cmd.peer == self.peer_id and (cmd.kind == "build_room" or cmd.kind == "room_rebuild") then return end
  end
  self:showRemoteBlueprint(self.peer_id, nil)
  self.log("removed this player's outline: no room command for it any more")
end

--! Sounds for this player's own actions that only count once every peer has
--! done them (the click itself could still be turned down).
MultiplayerSession.success_sounds = {buy_plot = "cashreg.wav", sell_plot = "cashreg.wav"}

--! What the player is told when one of their own actions is turned down
--! (by command kind, then by reason); the reason is shown otherwise.
MultiplayerSession.rejection_texts = {
  hire = {["no longer available"] = "Your team mate hired that candidate first. Here are the others.",
          ["invalid position"] = "Could not place the new member of staff there."},
  place_object = {["tile not free"] = "Could not place the object there: the spot was taken.",
                  ["someone is in the way"] = "Could not place the object there: someone was in the way.",
                  ["gave up"] = "Could not place the object there: someone stayed in the way."},
  move_object = {["tile not free"] = "Could not move the object there: the spot was taken.",
                 ["someone is in the way"] = "Could not move the object there: someone was in the way."},
  build_room = {["gave up"] = "The room could not be built: people did not leave the area."},
  room_object = {["tile not free"] = "The object does not fit there.",
                 ["someone is in the way"] = "Could not place the object there: someone was in the way.",
                 ["it would block the room"] = "Not there: it would block the way to another object."},
  room_finish = {["objects missing"] = "The room still needs some of its objects."},
  offer_staff = {["already offered"] = "That member of staff has already been offered."},
  offer_patient = {["already offered"] = "That patient has already been referred.",
                   ["the patient is in a room"] = "The patient is in a room now. Try again when they come out.",
                   ["the patient is leaving"] = "The patient is leaving.",
                   ["emergency patients stay"] = "Emergency patients cannot be referred.",
                   ["infected patients stay"] = "Infected patients cannot be referred."},
  offer_research = {["nothing to share"] = "They have all of that research by now: nothing was offered.",
                    ["a rival pays at least $1,000"] = "A rival pays at least $1,000 for research."},
  buy_plot = {["another player's side"] = "That land is on another player's side of the map.",
              ["cannot buy this plot"] = "That land cannot be bought now.",
              ["an auction is on"] = "Wait until the auction is over.",
              ["not enough money"] = "You cannot afford that land."},
  give_reputation = {["reputation too low"] = "Your reputation is too low to give any away.",
                     ["their reputation is full"] = "Their reputation cannot go any higher.",
                     ["monthly limit"] = "You have given as much reputation as you may this month."},
  sell_plot = {["not your plot"] = "That plot is not yours.",
               ["starting plot"] = "Your starting plot cannot be sold.",
               ["plot not empty"] = "You can only sell this plot when it is emptied of any items.",
               ["people on the plot"] = "You can only sell this plot when nobody is on it. Try again in a moment.",
               ["joins your land"] = "You cannot sell this plot: the rest of your land is joined to your hospital through it.",
               ["an auction is on"] = "Wait until the auction is over."},
  offer_plot = {["not your plot"] = "That plot is not yours.",
                ["starting plot"] = "Your starting plot cannot be handed over.",
                ["plot not empty"] = "You can only hand over this plot when it is emptied of any items.",
                ["people on the plot"] = "You can only hand over this plot when nobody is on it. Try again in a moment.",
                ["joins your land"] = "You cannot hand over this plot: the rest of your land is joined to your hospital through it.",
                ["already offered"] = "That plot has already been offered.",
                ["an auction is on"] = "Wait until the auction is over.",
                ["invalid price"] = "That price is not allowed."},
  auction_bid = {["outbid"] = "Somebody bid first. Try again.",
                 ["not enough money"] = "You cannot afford that bid.",
                 ["the auction is over"] = "The auction is over."},
  move_staff = {["invalid position"] = "They cannot be placed there.",
                ["cannot move them now"] = "That member of staff cannot be moved now."},
  room_edit = {["room cannot be edited now"] = "That room cannot be edited now.",
               ["room is already being edited"] = "That room is already being edited.",
               ["another player's work"] = "Another player is building or editing that room."},
  room_buy = {["cannot buy that"] = "That object is not available for this room."},
  room_rebuild = {["gave up"] = "The room could not be built there: people did not leave the area.",
                  ["invalid room outline"] = "The room does not fit there.",
                  ["room would block part of the hospital"] = "The room would block part of the hospital.",
                  ["invalid door position"] = "The door cannot go there.",
                  ["door not accepted"] = "The door cannot go there."},
}

--! Multiplayer co-op: a window about another player's patient, staff or
--! machine is for looking only. Its buttons (but the ones in `keep` and
--! Close) then only say so. The commands are refused anyway (handlers check
--! the owner); this saves the player a click that would do nothing.
function MultiplayerSession.viewOnly(window, hospital, keep)
  local world = TheApp and TheApp.world
  if not (TheApp.mp_session and world and world.mp_coop) then return end
  if not hospital or hospital == window.ui.hospital then return end
  local allowed = {[window.close] = true}
  for _, f in ipairs(keep or {}) do allowed[f] = true end
  for _, button in ipairs(window.buttons) do
    if button.on_click and not allowed[button.on_click] then
      button.on_click = MultiplayerSession.refuseOthers
    end
  end
  window.mp_view_only = true
end

function MultiplayerSession.refuseOthers(window)
  local ui = window.ui
  ui:playSound("wrong2.wav")
  if ui.adviser then
    ui.adviser:say({text = "That belongs to another player's hospital.", priority = 10})
  end
end

--! Tell this player that one of their actions could not be done. Every peer
--! turns it down alike; only the player who asked sees the notice.
function MultiplayerSession:_tellRejected(cmd, why)
  if cmd.kind == "place_object" then self:_returnObject(cmd) end
  if cmd.kind == "hire" and why == "no longer available" then self:_reopenHire(cmd.category) end
  local ui = self.world and self.world.ui
  if ui and MultiplayerSession.success_sounds[cmd.kind] then ui:playSound("wrong2.wav") end
  local texts = MultiplayerSession.rejection_texts[cmd.kind]
  local text = texts and texts[why]
  if not text and (why == "not ours" or why == "not our staff" or why == "not our patient" or
      why == "not our patient or room") then
    text = "That belongs to another player's hospital."
  end
  if not text and why == "not on your team" then
    text = "Only your team mates can trade with you."
  end
  if not text and (why == "not enough money" or why == "loan limit") then
    text = "Not enough money for that."
  end
  if not text and cmd.kind == "sabotage" then
    text = _S.multiplayer_window.sabotage_refused:format(tostring(why))
  end
  if not text and cmd.kind == "build_room" then
    text = "The room could not be built: " .. tostring(why) .. "."
  end
  self.notify(text or ("That could not be done (" .. tostring(why) .. ")."))
end

--! Somebody else hired the person this player was placing: the hire window
--! again, on the same kind of staff, to pick another.
function MultiplayerSession:_reopenHire(category)
  local ui = self.world and self.world.ui
  if not ui or not self.world:staffPool()[category] then return end
  local window = ui:getWindow(UIHireStaff)
  if not window then
    window = UIHireStaff(ui)
    ui:addWindow(window)
  end
  window:setCategory(category)
end

--! An object this player clicked down was not placed: back into their list
--! of objects to place (it left the list at the click; nothing was paid).
function MultiplayerSession:_returnObject(cmd)
  local ui = self.world and self.world.ui
  local object = TheApp.objects[cmd.object]
  if not ui or not object then return end
  local entry = {{object = object, qty = 1}}
  for _, window in ipairs(ui.windows or {}) do
    if class.type(window) == "UIPlaceObjects" then -- (not a room editor)
      window:addObjects(entry, false)
      return
    end
  end
  ui:addWindow(UIPlaceObjects(ui, entry, false))
end

--! Record and send this peer's fingerprint for the step just completed.
--!param unchanged (bool) optional; nothing happened in this step (no game
--!  hour, no command), so the fingerprint is the previous one
function MultiplayerSession:afterStep(unchanged)
  self.step = self.step + 1
  local n = self.step
  if self.hidden_staff then self:_keepUsedObjectsShown() end
  local fp = unchanged and self.last_fp or self.fingerprint(self.world)
  self.last_fp = fp
  -- What each person was doing at the last few steps: a desync is noticed a
  -- step or two late, and its report then shows the very step it happened.
  self.details = self.details or {}
  if self.world and self.world.entities then
    self.details[n] = unchanged and self.details[n - 1] or MultiplayerSession.stepDetail(self.world)
  end
  self.details[n - MultiplayerSession.DETAIL_STEPS] = nil
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
  -- A server with a referee repairs it at once (HOLD, then the referee's
  -- game): the player hears about it only afterwards, from the adviser
  -- (MultiplayerLobby:_onRESUME). Without a repair the games stay different:
  -- the player is told so, hard to miss, a moment later (checkDesyncNotice).
  self.desync_notice_at = self.clock() + MultiplayerSession.DESYNC_NOTICE_MS
  if own then self.log("  local: " .. own) end
  if other then self.log("  peer:  " .. tostring(other)) end
  -- For finding the cause: this game's state goes to the server's log, with
  -- what everybody was doing at the desync step itself (the same step in
  -- every player's report, so the reports can be compared line by line).
  if self.send_diagnostics and self.world then
    local ok, text = pcall(MultiplayerSession.diagnostics, self.world)
    if ok then
      local detail = self.details and self.details[step]
      if detail then
        text = text .. string.format("; AT STEP %d: %s", step, table.concat(detail, "; "))
      end
      self.send_diagnostics(self.step, text)
    end
  end
end

-- Steps of stepDetail kept for a desync report.
MultiplayerSession.DETAIL_STEPS = 8

--! What every person is doing (their current action and its target tile)
--! and every hospital's last money transactions: for desync reports, as a
--! list of short strings in the same order in every game.
function MultiplayerSession.stepDetail(world)
  local out = {}
  for i, h in ipairs(world.hospitals or {}) do
    local tx = {}
    for k = 1, math.min(5, #(h.transactions or {})) do
      local t = h.transactions[k]
      tx[#tx + 1] = string.format("%s%s %s", t.spend and "-" or "+", tostring(t.spend or t.receive),
          tostring(t.desc))
    end
    out[#out + 1] = string.format("h%d bal=%s tx[%s]", i, tostring(h.balance), table.concat(tx, " | "))
    -- What its research aims at (a drug or machine picked differently on
    -- some computers shows only much later, in a price).
    local policy = h.research and h.research.research_policy
    if policy then
      local aims = {}
      for _, area in ipairs({"cure", "diagnosis", "drugs", "improvements", "specialisation"}) do
        local cur = policy[area] and policy[area].current
        local name = cur
        if type(cur) == "table" then name = cur.id or (cur.disease and cur.disease.id) or "-" end -- (never an address)
        aims[#aims + 1] = area .. "=" .. tostring(name)
      end
      out[#out + 1] = string.format("h%d research %s", i, table.concat(aims, " "))
    end
  end
  for _, e in ipairs(world.entities) do
    if e.humanoid_class then
      local a = e.action_queue and e.action_queue[1]
      local target = ""
      if a and a.x and a.y then target = string.format(">%s,%s", tostring(a.x), tostring(a.y)) end
      out[#out + 1] = string.format("%s:%s@%s,%s %s%s", tostring(e.mp_id), e.humanoid_class,
          tostring(e.tile_x), tostring(e.tile_y), a and tostring(a.name) or "-", target)
    end
  end
  return out
end

-- How long a desync waits for the server's repair before the player is told
-- that the games stay different.
MultiplayerSession.DESYNC_NOTICE_MS = 3000

--! Between game ticks: a desync the server has not started to repair within
--! DESYNC_NOTICE_MS will not be repaired. Tell the player, hard to miss: from
--! now on every player plays a different game.
function MultiplayerSession:checkDesyncNotice()
  if not self.desync_notice_at or self.held or self.clock() < self.desync_notice_at then return end
  self.desync_notice_at = nil
  local step = self.desync and self.desync.step or self.step
  self.notify(string.format("Multiplayer games are out of sync (step %d). Please restart the game.", step))
  local ui = TheApp and TheApp.world and TheApp.ui
  if ui and self.world and not self.observer then
    pcall(function()
      self.world:setSpeed("Pause")
      ui:addWindow(UIInformation(ui, {
        "The players' games are no longer the same (out of sync since game hour " .. step .. ").",
        "Whatever happens from now on is different for every player.",
        "Please all leave the game, then the host continues it from the last save:",
        "Multiplayer, create a room with Continue (the monthly autosave or your last File > Save).",
      }))
    end)
  end
end

--! An entity's tick failed (World:_advanceHours): it was set aside in every
--! game alike. Tell the server, and the player once.
function MultiplayerSession:reportEntityError(entity, trace)
  local what = tostring(entity.humanoid_class or (entity.object_type and entity.object_type.id) or "entity")
  -- The room they are in (or at the door of), to see what went wrong there.
  local world = self.world
  local room = world and entity.tile_x and world.getRoom and world:getRoom(entity.tile_x, entity.tile_y)
  if room then trace = tostring(trace) .. "\n" .. MultiplayerSession.roomLayout(room) end
  if self:reportError("tick of " .. what .. " #" .. tostring(entity.mp_id), trace) then
    self.notify("After a game error a " .. what .. " stopped working. Save and continue the game " ..
        "(File > Save, then Continue in the lobby) to have them work again.")
  end
end

--! A Lua error in this game: note it in the console log and the server's
--! (once per message), so that a game that stops can be explained.
--! Returns true the first time a message is seen.
--!param where (string) What was running, e.g. "timer handler".
--!param trace (string) The error and its stack trace.
function MultiplayerSession:reportError(where, trace)
  trace = tostring(trace)
  local first = trace:match("[^\n]*")
  self.reported_errors = self.reported_errors or {}
  if self.reported_errors[first] then return end
  self.reported_errors[first] = true
  local text = string.format("ERROR at step %d in the %s: %s", self.step, where, trace)
  self.log(text)
  if self.send_diagnostics then self.send_diagnostics(self.step, text) end
  return true
end

--! The real time in milliseconds: SDL's ticks in the game, LuaSocket's time
--! elsewhere (the server's referee loads the game too), else always 0.
function MultiplayerSession.defaultClock()
  local ok, sdl = pcall(require, "sdl")
  if ok and type(sdl) == "table" and sdl.getTicks then return sdl.getTicks end
  local ok2, socket = pcall(require, "socket")
  if ok2 and type(socket) == "table" and socket.gettime then
    return function() return math.floor(socket.gettime() * 1000) end
  end
  return function() return 0 end
end

--! Called every tick (App:onTick). If this game has not run a step for 15
--! seconds and it is not a pause everybody chose, tell the server why (it
--! logs the note): a player's game that stops for no visible reason can
--! then be explained from the server log. Once per stop.
--! Called every tick (App:onTick), acting about once a second. Clicks on the
--! map are off while a placement window or room editor is open; a player
--! reported them staying off with none open (after placing objects and
--! saving; opening and closing a room editor brought them back). Until the
--! cause is found: log the UI state to the game log whenever it is unusual,
--! and give the map its clicks back when no such window is open.
function MultiplayerSession:checkMapClicks(world)
  self.map_click_ticks = (self.map_click_ticks or 0) + 1
  if self.map_click_ticks % 50 ~= 0 or self.observer then return end
  local ui = world and world.ui
  if not ui or ui.do_world_hit_test == nil then return end
  local placing, names = false, {}
  for _, window in ipairs(ui.windows or {}) do
    local name = class.type(window) or "?"
    if class.is(window, UIPlaceObjects) then
      placing = true
      if not window.visible then name = name .. "(hidden)" end
    end
    names[#names + 1] = name
  end
  local hit, edit = ui.do_world_hit_test, ui.edit_room
  local unusual = hit ~= true or (edit and edit ~= true)
  if unusual then
    local text = string.format("hit test %s, edit_room %s, windows %s",
        hit == true and "on" or hit == false and "off" or "one room",
        type(edit) == "table" and (class.type(edit) or "table") or tostring(edit),
        table.concat(names, ","))
    if text ~= self.map_click_state then
      self.map_click_state = text
      print(string.format("Multiplayer UI at step %d: %s", self.step, text))
    end
  else
    self.map_click_state = nil
  end
  if not placing and hit ~= true and not (edit and class.is(edit, Room)) then
    print(string.format("Multiplayer UI at step %d: map clicks were off with no placement window open; " ..
        "turned back on", self.step))
    if type(edit) == "table" and not class.is(edit, Room) then ui.edit_room = false end
    ui:setWorldHitTest(true)
  end
end

function MultiplayerSession:checkStall(world)
  local now = self.clock()
  if self.step ~= self.stall_step then
    self.stall_step, self.stall_since, self.stall_reported = self.step, now, false
    return
  end
  if self.observer or self.stall_reported or not self.send_diagnostics or not world or not self.stall_since then return end
  if now - self.stall_since < 15000 then return end
  if world:isCurrentSpeed("Pause") and world:isGameUserPaused() and not world:isMustPauseActive() then
    return -- paused on purpose (shared pause)
  end
  self.stall_reported = true
  local windows = {}
  for _, window in ipairs(world.ui and world.ui.windows or {}) do
    windows[#windows + 1] = (class.type(window) or "?") .. (window:mustPause() and "(pauses)" or "")
  end
  local waiting = {}
  for p, s in pairs(self.peer_step) do waiting[#waiting + 1] = p .. ":" .. s end
  table.sort(waiting)
  local text = string.format("STALL at step %d for %ds: speed %s, hours/tick %s, must pause %s, " ..
      "user paused %s, held %s, loading %s, save at %s, local save %s, peers %s, windows %s",
      self.step, math.floor((now - self.stall_since) / 1000), tostring(world:getCurrentSpeed()),
      tostring(world.hours_per_tick), tostring(world:isMustPauseActive()), tostring(world:isGameUserPaused()),
      tostring(self.held), tostring(self.load_data ~= nil), tostring(self.save_at),
      tostring(self.local_save and self.local_save.at), table.concat(waiting, ","), table.concat(windows, ","))
  self.log(text)
  self.send_diagnostics(self.step, text)
end

--! A room's layout for an error report: where it is, its door, state, the
--! objects in it (and whether usable) and the people in it.
function MultiplayerSession.roomLayout(room)
  local world = room.world
  local parts = {string.format("room #%d %s at %d,%d size %dx%d; door %s,%s; active %s, crashed %s, built %s",
      room.id, room.room_info.id, room.x, room.y, room.width, room.height,
      tostring(room.door and room.door.tile_x), tostring(room.door and room.door.tile_y),
      tostring(room.is_active), tostring(room.crashed), tostring(room.built))}
  local objects, people = {}, {}
  for _, e in ipairs(world.entities) do
    if e.tile_x and world:getRoom(e.tile_x, e.tile_y) == room then
      if e.object_type then
        objects[#objects + 1] = string.format("%s#%s@%d,%d %s%s%s", e.object_type.id, tostring(e.mp_id),
            e.tile_x, e.tile_y, tostring(e.direction), e.picked_up and " picked up" or "",
            e.user and " in use" or "")
      elseif e.humanoid_class then
        local action = e.getCurrentAction and e:getCurrentAction()
        people[#people + 1] = string.format("%s#%s@%d,%d %s", e.humanoid_class, tostring(e.mp_id),
            e.tile_x, e.tile_y, tostring(action and action.name))
      end
    end
  end
  parts[#parts + 1] = "objects: " .. table.concat(objects, ", ")
  parts[#parts + 1] = "people: " .. table.concat(people, ", ")
  return table.concat(parts, "; ")
end

--! A description of the game state for comparing two games after a desync:
--! date, money, rooms, and every entity (id, kind, tile) in entity order.
-- The random draws journal. A desync in which only the random numbers differ
-- (one game drew a number the others did not) shows nothing in the state.
-- While a multiplayer game runs, every math.random call notes where it came
-- from (the last DRAWS of them); a desync's diagnostics carry that list, and
-- the games' lists side by side in the server log show the extra draw.
local DRAWS = 2000
local draws = {step = {}, src = {}, line = {}, n = 0}
local real_random

--! Start (on = true) or stop noting where random numbers are drawn.
function MultiplayerSession.traceRandomDraws(on)
  if on and not real_random then
    real_random = math.random
    draws.n = 0
    local getinfo = debug.getinfo
    -- (rawset: luacheck keeps the standard library read-only.)
    rawset(math, "random", function(...)
      local n = draws.n + 1
      draws.n = n
      local i = (n - 1) % DRAWS + 1
      local info = getinfo(2, "Sl")
      local session = TheApp and TheApp.mp_session
      draws.step[i] = session and session.step or -1
      draws.src[i] = info and info.short_src or "?"
      draws.line[i] = info and info.currentline or 0
      return real_random(...)
    end)
  elseif not on and real_random then
    rawset(math, "random", real_random)
    real_random = nil
  end
end

--! The journal, oldest first: "step file:line" (xN for repeats in a row).
function MultiplayerSession.randomDraws()
  local n = draws.n
  local first = math.max(1, n - DRAWS + 1)
  local out, last, count = {}, nil, 0
  local function flush()
    if last then out[#out + 1] = count > 1 and (last .. " x" .. count) or last end
  end
  for k = first, n do
    local i = (k - 1) % DRAWS + 1
    local entry = string.format("%d %s:%d", draws.step[i], tostring(draws.src[i]):match("[^/\\]*$"), draws.line[i])
    if entry == last then
      count = count + 1
    else
      flush()
      last, count = entry, 1
    end
  end
  flush()
  return string.format("%d draws, the last %d: %s", n, n - first + 1, table.concat(out, ", "))
end

function MultiplayerSession.diagnostics(world)
  local parts = {"date " .. world.game_date:tostring()}
  for i, h in ipairs(world.hospitals) do
    parts[#parts + 1] = string.format("h%d bal=%s staff=%d patients=%d", i, tostring(h.balance),
        #h.staff, #h.patients)
  end
  local rooms = {}
  for id, room in pairs(world.rooms) do
    rooms[#rooms + 1] = string.format("room %05d %s@%d,%d %s", id, room.room_info.id, room.x, room.y,
        room.built and "built" or "unfinished")
  end
  table.sort(rooms) -- (pairs order is not the same in two games)
  for _, r in ipairs(rooms) do parts[#parts + 1] = r end
  for _, e in ipairs(world.entities) do
    local kind = e.humanoid_class or (e.object_type and e.object_type.id) or "entity"
    -- (A person: what they are doing, and where a walk goes; a desync of one
    -- person a tile off says more with it.)
    local doing = ""
    local action = e.action_queue and e.action_queue[1]
    if action then
      doing = " " .. tostring(action.name)
      if action.name == "walk" and action.x then doing = doing .. ">" .. action.x .. "," .. action.y end
    end
    parts[#parts + 1] = string.format("%s:%s@%s,%s%s", tostring(e.mp_id), kind,
        tostring(e.tile_x), tostring(e.tile_y), doing)
  end
  parts[#parts + 1] = "map rows " .. MultiplayerSession.mapRows(world)
  parts[#parts + 1] = "random " .. MultiplayerSession.randomDraws()
  return table.concat(parts, "; ")
end

-- The tile flags a map row's checksum covers (the ones the game decides by:
-- walking, building, rat holes, litter, rooms).
local ROW_FLAGS = {"passable", "buildable", "hospital", "room", "travelNorth", "travelEast",
    "travelSouth", "travelWest", "buildableNorth", "buildableEast", "buildableSouth", "buildableWest",
    "avoidTile", "doNotIdle", "tallWest", "tallNorth", "doorWest", "doorNorth"}

--! A checksum of every map row's tile flags, walls and room ids ("y:crc",
--! comma-separated). The fingerprint does not cover the map; a desync in
--! which one game's tiles differ (a corridor tile seen as free in one game
--! only) shows here as the rows that differ.
function MultiplayerSession.mapRows(world)
  local th = world.map and world.map.th
  if not th then return "" end
  local TH = require("TH")
  local w, h = th:size()
  local flags, rows = {}, {}
  for y = 1, h do
    local cells = {}
    for x = 1, w do
      th:getCellFlags(x, y, flags)
      local bits = {}
      for i, name in ipairs(ROW_FLAGS) do bits[i] = flags[name] and "1" or "0" end
      local _, nw, ww = th:getCell(x, y)
      cells[x] = table.concat(bits) .. ":" .. tostring(flags.roomId or 0) .. ":" ..
          tostring(nw % 256 ~= 0) .. tostring(ww % 256 ~= 0) .. ":" .. tostring(flags.thob or 0)
    end
    rows[y] = string.format("%d:%08x", y, TH.CRC32File(table.concat(cells, ";")))
  end
  return table.concat(rows, ",")
end

--------------------------------------------------------------------------------
-- Player colours on the map (co-op): a small bar in the player's colour under
-- each of their patients and staff, and the patients in shirts of it
-- (dressPatient). The bars are only drawn on this screen, never part of the
-- game. MultiplayerSession.markers: "all", "others" or "off" (the bars).
--------------------------------------------------------------------------------

MultiplayerSession.markers = "others" -- (a new sight: own people plain at first)

-- The parts of big objects last drawn in a user's shirt colour
-- (setFloorMarkers): back to their own when the use is over.
local split_dressed = setmetatable({}, {__mode = "k"})

-- Each hospital's colour, by hospital index: its patients wear it (the
-- original game's four shirt colours, layer 1 of a patient's animation:
-- 0 mustard, 2 white, 4 lavender, 6 salmon), its staff have a bar of it at
-- their feet, and its player's chat lines a darker version of it
-- (UIMultiplayerChat.colourOf). Colours 5 to 8 (green, blue, teal, black:
-- a game for more than 4 hospitals) wear the shirts of colours 2 to 4
-- redrawn in their own colour (setupShirtColours; green the salmon shirt).
-- (8 was pink, but the game's palette has no pink or magenta shades that
-- are not close to the salmon shirt: Argus, 2026-11-10.)
MultiplayerSession.CLOTHES = {0, 6, 4, 2, 6, 6, 4, 2}
local MARKER_COLOURS = {{232, 186, 52}, {236, 130, 118}, {160, 146, 232}, {236, 236, 236},
    {100, 200, 80}, {70, 120, 235}, {60, 200, 200}, {50, 50, 50}}
-- The colour a shirt is redrawn in, where not the marker colour: black's
-- is the white shirt darkened, its light grey (lum, 188) to a dark grey and
-- every other shade in proportion (so the folds still show).
local SHIRT_COLOURS = {[8] = {96, 96, 96, lum = 188}}

--! The colour (1-8) of a hospital: the one its players picked in the room
--! (world.mp_coop.colours), else its index (a game from before colours).
function MultiplayerSession.hospitalColour(world, hospital)
  local index = world:getHospitalIndex(hospital)
  if not index then return nil end
  local colours = world.mp_coop and world.mp_coop.colours
  return (colours and colours[index]) or (index - 1) % #MARKER_COLOURS + 1
end

--! The marker colour of a hospital ({r, g, b}).
function MultiplayerSession.markerColour(world, hospital)
  local colour = MultiplayerSession.hospitalColour(world, hospital)
  return colour and MARKER_COLOURS[colour]
end

--! A colour's {r, g, b} (1-8: the lobby's colour buttons).
function MultiplayerSession.colourRGB(colour)
  return MARKER_COLOURS[(colour - 1) % #MARKER_COLOURS + 1]
end

--! Show `hospital`'s starting place on this screen (its map camera tile, as
--! at the start of the game): only the view moves, nothing in the game.
--!param ui (GameUI)
function MultiplayerSession.lookAtHospital(ui, hospital)
  local map = ui.app.map
  local cx, cy = map.th:getCameraTile(hospital:getPlayerIndex())
  ui:scrollMapTo(map:WorldToScreen(cx, cy))
end

--! The next hospital to look at after `index` (the game's hospitals in
--! turn, this player's own among them), or nil with only one.
function MultiplayerSession.nextHospital(world, index)
  local n = world.mp_coop and world.mp_coop.players or 1
  if n < 2 then return nil end
  return (index or 0) % n + 1
end

--! A tab in a hospital's colour (a game with a hospital each), so a window
--! shows whose it is: at (wx, wy), w x h, in the window's own coordinates.
--! Nothing in other games.
function MultiplayerSession.drawColourTab(canvas, window, x_, y_, hospital, wx, wy, w, h)
  local world = TheApp.world
  local c = hospital and world and world.mp_coop and MultiplayerSession.markerColour(world, hospital)
  if not c then return end
  local s = TheApp.gfx:getUIScale()
  local x, y = window.x * s + x_ + wx * s, window.y * s + y_ + wy * s
  canvas:drawRect(canvas:mapRGB(48, 32, 64), x, y, w * s, h * s)
  canvas:drawRect(canvas:mapRGB(c[1], c[2], c[3]), x + s, y + s, (w - 2) * s, (h - 2) * s)
end

--! Colour tabs on both sides of a window's title (at 20, 10, 20 high).
function MultiplayerSession.drawTitleTabs(canvas, window, x_, y_, hospital)
  MultiplayerSession.drawColourTab(canvas, window, x_, y_, hospital, 6, 10, 10, 20)
  MultiplayerSession.drawColourTab(canvas, window, x_, y_, hospital, window.width - 16, 10, 10, 20)
end

local icons -- (mp_icons.lua, loaded when first drawn)
local icon_colours = setmetatable({}, {__mode = "k"}) -- canvas -> name -> mapped colours

--! Draw one of the multiplayer icons (MATROFTT's pixel art, mp_icons.lua)
--! with its top left corner at ix, iy, at UI scale s.
--!param name (string) the icon, e.g. "fax_money" or "transferstuff_pressed"
function MultiplayerSession.drawIcon(canvas, name, ix, iy, s)
  icons = icons or corsixth.require("mp_icons")
  local icon = icons[name]
  if not icon then return end
  local mapped = icon_colours[canvas]
  if not mapped then
    mapped = {}
    icon_colours[canvas] = mapped
  end
  local colours = mapped[name]
  if not colours then
    colours = {}
    local c = icon.colours
    for i = 1, #c, 3 do colours[#colours + 1] = canvas:mapRGB(c[i], c[i + 1], c[i + 2]) end
    mapped[name] = colours
  end
  local runs = icon.runs
  for i = 1, #runs, 4 do
    canvas:drawRect(colours[runs[i]], ix + runs[i + 1] * s, iy + runs[i + 2] * s, runs[i + 3] * s, s)
  end
end

--! Multiplayer with a hospital each: dress a patient in their hospital's
--! colour (the shirt; only what is drawn changes, alike on every machine).
--! Patients without the shirt colours (the King, the invisible) stay as
--! they are.
function MultiplayerSession.dressPatient(patient)
  local world = patient.world
  if not (world and world.mp_coop and world.mp_coop.players > 1 and patient.hospital) then return end
  local class = patient.humanoid_class
  if class == "Elvis Patient" or class == "Invisible Patient" then return end
  local colour = MultiplayerSession.hospitalColour(world, patient.hospital)
  if not colour then return end
  patient:setLayer(1, MultiplayerSession.CLOTHES[colour])
end

--! Shirts of colours 5 to 8: the game has four shirt colours (CLOTHES), so a
--! patient of colour 6 wears colour 2's shirt drawn through a palette map
--! that turns it blue (7 teal, 8 black): every sprite of that clothes
--! variant gets the map (TH.anims:setLayerAltPalette, slot 3), and those
--! patients are drawn with DrawFlags.AltPalette3 (setFloorMarkers, on this
--! screen only). Colour 5 (green) wears colour 2's shirt too, with its map
--! in slot 2 (DrawFlags.AltPalette2). (Not slot 1, DrawFlags.AltPalette:
--! an object's sprites get their grey ghost there once somebody places
--! one, and a patient drawn with it inside a toilet turned its blue cabin
--! grey.) Each entry keeps its brightness in the new colour, the nearest
--! the game's palette has, but a coloured entry no brighter than the colour
--! itself (one even shade of the jacket); near black stays (the outlines).
--! Black's shirt is darker throughout (SHIRT_COLOURS).
--! Only the shirt sprites get a map: skin and hair keep their colours.
--! (Green used to turn the mustard shades of the body sprites green, colour
--! 1's shirt; blonde hair has the same shades and turned green too: Argus,
--! 2026-11-07.)
--!return true if the maps are set
local shirt_colours_set = setmetatable({}, {__mode = "k"}) -- anims -> done (true/false)
function MultiplayerSession.setupShirtColours(app, anims)
  if not anims or not anims.setLayerAltPalette then return false end
  if shirt_colours_set[anims] ~= nil then return shirt_colours_set[anims] end
  local ok, data = pcall(app.readDataFile, app, "Data", "MPalette.dat")
  if not ok or type(data) ~= "string" or #data ~= 768 then
    shirt_colours_set[anims] = false
    return false
  end
  local pal = {}
  for i = 0, 255 do
    local r, g, b = data:byte(i * 3 + 1, i * 3 + 3)
    pal[i] = {r * 4, g * 4, b * 4}
  end
  local function lum(c) return 0.3 * c[1] + 0.59 * c[2] + 0.11 * c[3] end
  local function nearest(r, g, b)
    local best, best_d
    for i = 0, 254 do
      local c = pal[i]
      local d = (c[1] - r) ^ 2 + (c[2] - g) ^ 2 + (c[3] - b) ^ 2
      if not best_d or d < best_d then best, best_d = i, d end
    end
    return best
  end
  for colour = 5, 8 do
    local target = SHIRT_COLOURS[colour] or MARKER_COLOURS[colour]
    local t_lum = target.lum or lum(target)
    local bytes = {}
    for i = 0, 255 do
      local src = pal[i]
      local l = lum(src)
      local to = i
      if i < 255 and l >= 24 then
        local k = l / t_lum
        -- The shirt's own (coloured) shades are no lighter than the colour
        -- itself: blue is dark, and the lighter ones came out a pale cyan
        -- blue, in patches over the jacket (Argus, 2026-11-10). Greys (the
        -- T-shirt under the jacket) keep their lighter shade.
        if target.lum or math.max(src[1], src[2], src[3]) - math.min(src[1], src[2], src[3]) >= 16 then
          k = math.min(k, 1)
        end
        to = nearest(math.min(255, target[1] * k), math.min(255, target[2] * k), math.min(255, target[3] * k))
      end
      bytes[i + 1] = string.char(to)
    end
    local slot = colour == 5 and 2 or 3
    local n = anims:setLayerAltPalette(1, MultiplayerSession.CLOTHES[colour], table.concat(bytes), 0, slot)
    print(string.format("multiplayer: shirts of colour %d: %d sprites recoloured", colour, n))
  end
  -- The map is kept per sprite, and a few sprites of the shirts are also
  -- drawn for heads (layer 0): a whole face, bits of skin, the shower
  -- curtain. Every patient drawn with that slot got them in a shirt's
  -- colour: a grey face under a blue or teal shirt from black's map (Argus,
  -- 2026-11-11). Heads keep their own colours.
  local same = {}
  for i = 0, 255 do same[i + 1] = string.char(i) end
  same = table.concat(same)
  for id = 0, 23 do
    anims:setLayerAltPalette(0, id, same, 0, 2)
    anims:setLayerAltPalette(0, id, same, 0, 3)
  end
  shirt_colours_set[anims] = true
  return true
end

--! A patient drawn outside the map (the queue window, UIQueue:drawPatient,
--! on its own animation): in their hospital's shirt colour 5 to 8 too, as
--! on the map (Argus, 2026-11-12: the queue showed the shirt they are drawn
--! from, white for black). Only this screen's picture changes.
function MultiplayerSession.dressDrawing(th, patient)
  local world = patient.world
  if not (world and world.mp_coop and patient.hospital and th.setPartialFlag) then return end
  if patient.humanoid_class == "Elvis Patient" or patient.humanoid_class == "Invisible Patient" then return end
  local r = MultiplayerSession.hospitalColour(world, patient.hospital) or 1
  if r <= 4 or not MultiplayerSession.setupShirtColours(TheApp, world.anims) then return end
  th:setPartialFlag(DrawFlags.AltPalette3, r > 5)
  th:setPartialFlag(DrawFlags.AltPalette2, r == 5)
end

--! Before the map is drawn (GameUI:draw): give every person the bar of
--! their hospital's colour (or none), drawn by the engine just before them,
--! so that whoever stands in front covers it (TH.animation:setFloorMarker).
--! Returns false if this game's engine cannot (then drawMarkers after the map).
function MultiplayerSession.setFloorMarkers(ui)
  local world = ui.app.world
  local first = world and world.entities and world.entities[1]
  if not (first and first.th and first.th.setFloorMarker) then return false end
  local mode = MultiplayerSession.markers
  local on = mode ~= "off" and TheApp.mp_session and world.mp_coop and world.mp_coop.players > 1
  local cache = {}
  -- (Shirts of colours 5 to 8: setupShirtColours.)
  -- (Any hospital of colour 5 to 8, in a game of any size: colours are
  -- picked in the room.)
  local shirts = false
  if world.mp_coop then
    for _, h in ipairs(world.hospitals) do
      if (MultiplayerSession.hospitalColour(world, h) or 1) > 4 then shirts = true end
    end
  end
  shirts = shirts and MultiplayerSession.setupShirtColours(ui.app, world.anims)
  local recolour = {}
  -- A patient's shirt colour: 5 to 8, or nil (drawn as they are).
  local function shirt_of(patient)
    if not (patient.hospital and class.is(patient, Patient)) then return nil end
    if patient.humanoid_class == "Elvis Patient" or patient.humanoid_class == "Invisible Patient" then return nil end
    local r = recolour[patient.hospital]
    if r == nil then
      r = MultiplayerSession.hospitalColour(world, patient.hospital) or 1
      recolour[patient.hospital] = r
    end
    return r > 4 and r or nil
  end
  local function dress(th, r)
    th:setPartialFlag(DrawFlags.AltPalette3, r ~= nil and r > 5)
    th:setPartialFlag(DrawFlags.AltPalette2, r == 5)
  end
  local split_now = {}
  for _, e in ipairs(world.entities) do
    if shirts and e.th and e.humanoid_class then
      -- Whose shirt this one draws: a patient their own; a member of staff
      -- the patient they treat together in one animation (multi_use_object:
      -- the staff's animation draws both, with the patient's layers); and
      -- the other parts of a big object in use (split_anims) the user's.
      local r
      if class.is(e, Patient) then
        r = shirt_of(e)
      elseif class.is(e, Staff) then
        local action = e:getCurrentAction()
        local with = action and action.name == "multi_use_object" and action.use_with
        r = with and shirt_of(with) or nil
      end
      dress(e.th, r)
      local object = e.user_of
      if r and object and object.split_anims then
        for i = 2, #object.split_anims do
          local th = object.split_anims[i]
          dress(th, r)
          split_now[th] = true
        end
      end
    end
    if e.humanoid_class and e.th then
      local hospital = on and e.hospital
      local c
      if hospital and not (mode == "others" and hospital == ui.hospital) and
          (class.is(e, Patient) or class.is(e, Staff)) then
        c = cache[hospital]
        if c == nil then
          c = MultiplayerSession.markerColour(world, hospital) or false
          cache[hospital] = c
        end
      end
      if c then e.th:setFloorMarker(c[1], c[2], c[3], 0xE0) else e.th:setFloorMarker() end
    end
  end
  for th in pairs(split_dressed) do
    if not split_now[th] then
      dress(th, nil)
      split_dressed[th] = nil
    end
  end
  for th in pairs(split_now) do split_dressed[th] = true end
  return true
end

--! Draw the markers over the map (GameUI:draw, after the map; for an engine
--! without setFloorMarker).
--!param dx, dy the map's screen offset; zoom the map's zoom
function MultiplayerSession.drawMarkers(ui, canvas, dx, dy, zoom)
  local mode = MultiplayerSession.markers
  local world = ui.app.world
  if mode == "off" or not (TheApp.mp_session and world and world.mp_coop and world.mp_coop.players > 1) then
    return
  end
  local map = ui.app.map
  local scr_w, scr_h = canvas:getRenderSize()
  local cache = {}
  for _, e in ipairs(world.entities) do
    local hospital = e.humanoid_class and e.tile_x and e.hospital
    if hospital and not (mode == "others" and hospital == ui.hospital) and
        (class.is(e, Patient) or class.is(e, Staff)) then
      local colour = cache[hospital]
      if colour == nil then
        local c = MultiplayerSession.markerColour(world, hospital)
        colour = c and canvas:mapRGB(c[1], c[2], c[3]) or false
        cache[hospital] = colour
      end
      if colour then
        -- (A tile's screen position is its top corner; people stand 16 lower.)
        local x, y = map:WorldToScreen(e.tile_x, e.tile_y)
        local px, py = e.th:getPosition()
        x, y = math.floor((x + px - dx) * zoom), math.floor((y + py + 17 - dy) * zoom)
        local w, h = math.max(10, math.floor(18 * zoom)), math.max(3, math.floor(4 * zoom))
        if x > -w and y > -h and x < scr_w + w and y < scr_h + h then
          -- A flat oval of the player's colour with a dark rim, at the feet.
          local dark = canvas:mapRGB(20, 20, 20)
          local left = x - math.floor(w / 2)
          canvas:drawRect(dark, left, y - 1, w, h + 2)
          canvas:drawRect(dark, left - 1, y, w + 2, h)
          canvas:drawRect(colour, left + 1, y, w - 2, h)
          canvas:drawRect(colour, left, y + 1, w, h - 2)
        end
      end
    end
  end
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

--! Take a reserved outline's wall pictures (the room editor's wall, door and
--! window animations, by x and y) off the map.
local function remove_walls(walls)
  for _, column in pairs(walls) do
    if column.setTile then
      column:setTile(nil)
    else
      for _, anim in pairs(column) do anim:setTile(nil) end
    end
  end
end

--! Show (or with w = 0, remove) another player's room outline as a blue
--! floor on this player's map. This player's own outline may also bring the
--! editor's walls (rect.walls), shown until it is removed, and the editor
--! waiting for the room (rect.editor), closed then.
function MultiplayerSession:showRemoteBlueprint(peer, rect)
  local old = self.remote_blueprints[peer]
  if old then
    paint_rect(self.world, old, 0)
    if old.walls then remove_walls(old.walls) end
    if old.editor and old.editor.phase == "mp_waiting" then old.editor:close() end
  end
  self.remote_blueprints[peer] = nil
  if rect and (rect.w or 0) > 0 and (rect.h or 0) > 0 then
    self.remote_blueprints[peer] = {x = rect.x, y = rect.y, w = rect.w, h = rect.h, room = rect.room,
        walls = rect.walls, editor = rect.editor}
    paint_rect(self.world, rect, BLUE_FLOOR)
    if peer ~= self.peer_id then
      self.log(string.format("showing reserved area of player %d: %s at %d,%d size %dx%d",
          peer, tostring(rect.room), rect.x, rect.y, rect.w, rect.h))
    end
  end
  -- Overlapping outlines were partly cleared; paint the others again.
  for _, other in pairs(self.remote_blueprints) do paint_rect(self.world, other, BLUE_FLOOR) end
end

--! Run fn() with the outlines of showRemoteBlueprint off the map: they are
--! no part of the game, and a save would keep them there for good. The blue
--! floors come back afterwards; the own outline's walls and waiting editor
--! do not.
function MultiplayerSession:withoutBlueprints(fn)
  for _, rect in pairs(self.remote_blueprints) do
    paint_rect(self.world, rect, 0)
    if rect.walls then
      remove_walls(rect.walls)
      rect.walls = nil
    end
    if rect.editor and rect.editor.phase == "mp_waiting" then rect.editor:close() end
    rect.editor = nil
  end
  local ok, err = pcall(fn)
  for _, rect in pairs(self.remote_blueprints) do paint_rect(self.world, rect, BLUE_FLOOR) end
  if not ok then error(err, 0) end
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

local function tile_free_for_object(world, hospital, x, y, tile, room)
  local th = world.map.th
  if not hospital:isInHospital(x, y) or world:getRoom(x, y) ~= room then return false end
  local flags = th:getCellFlags(x, y)
  if tile.only_passable then return flags.passable end
  return flags.buildable and flags.passable and not world:getObject(x, y)
end

--! Could `object_type` be placed at x, y facing `orientation` for `hospital`?
--! The object editor's own check (a hidden editor, gone again at once): it
--! knows what the simple tile test does not, such as a radiator against a
--! wall or an object put into a room.
local function placement_allowed(world, hospital, object_type, x, y, orientation)
  local ui = world.ui
  if not ui then return false end
  local config = TheApp.config
  local saved_hospital, saved_blocking = ui.hospital, config.blocking_off_areas
  -- (Creating a placement window turns off clicks on the map, until it is
  -- closed by UIPlaceObjects.close, which this check does not use: every
  -- corridor object placed by anybody left this player unable to click
  -- anybody on the map.)
  local saved_hit_test = ui.do_world_hit_test
  ui.hospital, config.blocking_off_areas = hospital, 2 -- (the default rule on every peer)
  UIPlaceObjects.mp_checking = true
  local ok, result = pcall(function()
    local dlg = UIPlaceObjects(ui, {{object = object_type, qty = 1}})
    UIPlaceObjects.mp_checking = nil
    dlg:setOrientation(orientation)
    dlg:setBlueprintCell(x, y)
    local good = dlg.object_blueprint_good
    dlg:clearBlueprint()
    Window.close(dlg) -- (not UIPlaceObjects.close: it refunds an object not placed)
    return good
  end)
  UIPlaceObjects.mp_checking = nil
  ui.hospital, config.blocking_off_areas = saved_hospital, saved_blocking
  ui.do_world_hit_test = saved_hit_test
  if not ok then error(result, 0) end
  return result
end

--! Buy and place a new corridor object: {object, x, y, orientation}. It may
--! go into a room (a radiator or a plant), as in single player.
function handlers.place_object(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  local object_type = world.object_types[cmd.object]
  local orientation = object_type and object_type.orientations[cmd.orientation]
  if not orientation then return false, "unknown object or orientation" end
  for _, t in ipairs(orientation.footprint) do
    if not world:isOnMap(cmd.x + t[1], cmd.y + t[2]) or
        not hospital:isInHospital(cmd.x + t[1], cmd.y + t[2]) then
      return false, "tile not free"
    end
  end
  if not placement_allowed(world, hospital, object_type, cmd.x, cmd.y, cmd.orientation) then
    return false, "tile not free"
  end
  if world:anyHumanoidObscuringArea(cmd.x, cmd.y) then
    -- Somebody walks there: ask them to step aside (once each) and try again
    -- a few steps later, on every peer alike.
    cmd.asked = cmd.asked or {}
    for _, e in ipairs(world.entities) do
      if class.is(e, Humanoid) and e.tile_x == cmd.x and e.tile_y == cmd.y and e.mp_id and
          not cmd.asked[e.mp_id] then
        cmd.asked[e.mp_id] = true
        e:leaveArea()
      end
    end
    return false, "retry"
  end
  local cost = hospital:getObjectBuildCost(cmd.object)
  local msg = _S.transactions.buy_object .. ": " .. object_type.name
  hospital:spendMoney(cost, msg, cost)
  world:prepareFootprintTilesForBuild(orientation.footprint, cmd.x, cmd.y)
  local obj = world:newObject(cmd.object, cmd.x, cmd.y, cmd.orientation)
  local room = world:getRoom(cmd.x, cmd.y)
  if room then room.objects[obj] = true end
  if cmd.object == "reception_desk" then
    hospital:buildReceptionDesksCache()
  end
  return true
end

--! May `hospital`'s players take corridor objects (a plant, a radiator) out
--! of `room`, or put them in, without the room editor, as in single player
--! (Argus, 2026-11-07)? Its own working room, not while somebody edits or
--! furnishes it.
function MultiplayerSession.roomOpenForObjects(world, room, hospital)
  return room.hospital == hospital and room.is_active and not room.crashed and not room.mp_edit and
      not (world.mp_furnishing and world.mp_furnishing[room.id])
end

--! A corridor object of `hospital` that a player may pick up, or nil: in a
--! corridor, or in one of its rooms (MultiplayerSession.roomOpenForObjects).
local function movable_object(world, hospital, id)
  local obj = world:getEntityById(tonumber(id))
  if not obj or not class.is(obj, Object) or not obj.tile_x or
      not obj.object_type.corridor_object or not hospital:isInHospital(obj.tile_x, obj.tile_y) then
    return nil
  end
  local room = obj:getRoom()
  if room and not MultiplayerSession.roomOpenForObjects(world, room, hospital) then return nil end
  return obj
end

--! What picking an object up does to the game (Object:onClick in single
--! player): its users stop, and a plant's or machine's handyman task goes.
local function pick_up(obj)
  if obj.object_type.class == "Plant" or obj.object_type.class == "Machine" then
    local task_type = obj.object_type.class == "Machine" and "repairing" or "watering"
    local index = obj.hospital and obj.hospital:getIndexOfTask(obj.tile_x, obj.tile_y, task_type) or -1
    if index ~= -1 then obj.hospital:removeHandymanTask(index, task_type) end
  end
  obj:onPickUp()
end

--! Put an object (off the map) down at x, y facing `direction`, like
--! UIPlaceObjects:placeObject does with a picked-up object.
local function put_down(world, obj, x, y, direction)
  if direction ~= obj.direction then obj:initOrientation(direction) end
  world:prepareFootprintTilesForBuild(obj.footprint, x, y)
  obj:setTile(x, y)
  world:objectPlaced(obj)
  if obj.slave then world:objectPlaced(obj.slave) end
  if obj:isMachine() then obj:placed(nil) end
end

--! Move a corridor object (picked up and put down): {object, x, y, orientation}.
--! Out of a room or into one too (MultiplayerSession.roomOpenForObjects).
function handlers.move_object(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  local obj = hospital and movable_object(world, hospital, cmd.object)
  if not obj then return false, "cannot move that" end
  local orientation = obj.object_type.orientations[cmd.orientation]
  if not orientation then return false, "unknown orientation" end
  local old_x, old_y, old_direction = obj.tile_x, obj.tile_y, obj.direction
  if world:anyHumanoidObscuringArea(cmd.x, cmd.y) then return false, "someone is in the way" end
  -- Into a room, as in single player (UIPlaceObjects:placeObject): one of
  -- this hospital's open rooms whose kind takes the object (a plant into a
  -- ward), not while it is being edited or furnished.
  local room = world:getRoom(cmd.x, cmd.y)
  if room then
    local allowed = world:willObjectsFootprintTileBeWithinItsAllowedRoomIfLocatedAt(cmd.x, cmd.y, obj.object_type)
    if not MultiplayerSession.roomOpenForObjects(world, room, hospital) or not allowed.within_room then
      return false, "tile not free"
    end
  end
  local old_room = obj:getRoom()
  pick_up(obj)
  obj:setTile(nil)
  obj:rebuildPassableCellFlags()
  local free = true
  for _, t in ipairs(orientation.footprint) do
    if not tile_free_for_object(world, hospital, cmd.x + t[1], cmd.y + t[2], t, room) then free = false end
  end
  if not free then
    put_down(world, obj, old_x, old_y, old_direction)
    return false, "tile not free"
  end
  put_down(world, obj, cmd.x, cmd.y, cmd.orientation)
  if old_room and old_room ~= room then old_room.objects[obj] = nil end
  if room then room.objects[obj] = true end
  if obj.object_type.id == "reception_desk" then hospital:buildReceptionDesksCache() end
  return true
end

--! Sell a corridor object (picked up, then sold): {object}.
function handlers.sell_object(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  local obj = hospital and movable_object(world, hospital, cmd.object)
  if not obj then return false, "cannot sell that" end
  local cost = hospital:getObjectBuildCost(obj.object_type.id)
  hospital:receiveMoney(cost, _S.transactions.sell_object .. ": " .. obj.object_type.name, cost)
  pick_up(obj)
  local desk = obj.object_type.id == "reception_desk"
  world:destroyEntity(obj)
  if desk then hospital:buildReceptionDesksCache() end
  return true
end

--! Save the game on every player's machine (File > Save): {}.
function handlers.save_game(world, cmd) -- luacheck: ignore 212
  local session = TheApp and TheApp.mp_session
  if session then session:requestLocalSave("save") end
  return true
end

--! The shared speed or pause: {speed}. Applied at the same step on every
--! peer, since below Normal the speed decides how many steps an hour takes.
local function known_speed(speed)
  for _, s in ipairs(MultiplayerLobby.SPEEDS) do
    if s == speed then return true end
  end
  return false
end

--! Set the shared speed (or pause) on this peer, in the simulation.
local function apply_speed(world, speed)
  if speed == "Pause" and world.mp_speed ~= "Pause" then
    world.mp_resume_speed = world.mp_speed -- unpausing goes back to it
  end
  world.mp_speed = speed
  -- The menus and the screen show it (a local window that pauses the game,
  -- like the annual report, does not stop the shared game).
  world:applySharedSpeed(speed)
end

function handlers.set_speed(world, cmd)
  local session = TheApp.mp_session
  local speed = cmd.speed
  if speed ~= "Pause" and not known_speed(speed) then return false, "unknown speed" end
  if speed ~= "Pause" then speed = MultiplayerLobby.clampSpeed(speed, session and session.max_speed) end
  apply_speed(world, speed)
  if session and cmd.peer ~= session.peer_id then
    local name = session.peer_name and session.peer_name(cmd.peer) or "A player"
    session.notify(name .. " " .. (speed == "Pause" and "paused the game." or ("set the speed to " .. speed .. ".")))
  end
  return true
end

--------------------------------------------------------------------------------
-- Speed votes. Pausing and unpausing take effect at once (set_speed); a new
-- speed needs more than half of the players to agree, the asker included.
-- The vote (world.mp_vote) is game state, the same on every peer; the others
-- get a fax for it that does not pause the game, only on their own screens
-- (it is not one of the shared messages). A vote nobody decides lapses after
-- VOTE_SECONDS of play, counted in steps on every peer alike.
--------------------------------------------------------------------------------

MultiplayerSession.VOTE_SECONDS = 30
local VOTE_FRAMES = math.ceil(MultiplayerSession.VOTE_SECONDS * 1000 / 18) -- world ticks

local function count_keys(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

local function peer_label(session, peer)
  return session and session.peer_name and session.peer_name(peer) or "A player"
end

--! Take this player's speed vote fax off the screen (all of them: after a
--! load or a repair there may be a stale one).
local function remove_vote_faxes(world)
  local panel = world and world.ui and world.ui.bottom_panel
  if not panel then return end
  for _, icon in ipairs(panel:allMessageIcons()) do
    if icon.mp_vote then icon:removeMessage() end
  end
end

--! Show this player the fax for the open vote if they may still answer it
--! (or answer it at once: a scripted player, session.auto_agree "yes" or
--! "no"; a bot, session.abstains, does not vote). Runs when the vote opens
--! or ends, and again whenever the screen may have lost the fax (a load or a
--! repair).
function MultiplayerSession:syncVote(world)
  local vote = world and world.mp_vote
  local key = vote and vote.id or false
  if self.vote_shown == key then return end
  self.vote_shown = key
  remove_vote_faxes(world)
  if not vote or self.observer or self.abstains or vote.yes[self.peer_id] or vote.no[self.peer_id] then
    return
  end
  if self.auto_agree then
    self:issue({kind = "speed_vote_answer", vote = vote.id, agree = self.auto_agree == "no" and 0 or 1})
    return
  end
  local panel = world.ui and world.ui.bottom_panel
  if not panel then return end
  local S = _S.multiplayer_window
  local message = {
    {text = S.vote_request:format(peer_label(self, vote.peer))},
    {text = S.vote_request_speed:format(vote.speed)},
    choices = {
      {text = S.vote_agree, choice = "mp_vote_agree"},
      {text = S.vote_decline, choice = "mp_vote_decline"},
    },
  }
  local icon = panel:addLocalMessage("mp_vote", message)
  icon.mp_vote = vote.id
end

--! The player answered the speed vote fax (UIFax:buttonChoice).
function MultiplayerSession:answerVote(icon, agree)
  self:issue({kind = "speed_vote_answer", vote = icon.mp_vote, agree = agree and 1 or 0})
  icon:removeMessage()
end

--! The open vote ended: "agreed", "declined" (by peer `by`) or "lapsed".
local function end_vote(world, outcome, by)
  local vote = world.mp_vote
  world.mp_vote = nil
  local session = TheApp.mp_session
  local S = _S.multiplayer_window
  local text
  if outcome == "agreed" then
    if world.mp_speed == "Pause" then
      world.mp_resume_speed = vote.speed
      text = S.vote_passed_paused:format(vote.speed)
    else
      apply_speed(world, vote.speed)
      text = S.vote_passed:format(vote.speed)
    end
  elseif outcome == "declined" then
    text = S.vote_declined:format(peer_label(session, by), vote.speed)
  else
    text = S.vote_lapsed
  end
  if session then
    session.log(string.format("speed vote %d for %s: %s", vote.id, vote.speed, outcome))
    session.notify(text)
    session:syncVote(world)
  end
end

--! Count the open vote's play time (after every step's commands, on every
--! peer); it lapses after VOTE_SECONDS.
function MultiplayerSession:tickVote()
  local world = self.world
  local vote = world and world.mp_vote
  if vote then
    local frames = world._mpStepFrames and world:_mpStepFrames(world.mp_speed or "Normal") or 3
    vote.frames = vote.frames + frames
    if vote.frames >= VOTE_FRAMES then
      end_vote(world, "lapsed")
      self.applied_this_step = true
    end
  end
  self:syncVote(world)
end

--! Ask the others for a new speed: {speed, voters (the asker's count of
--! players)}.
function handlers.speed_vote(world, cmd)
  local session = TheApp.mp_session
  if not known_speed(cmd.speed) then return false, "unknown speed" end
  if world.mp_vote then return false, "a vote is open" end
  local voters = math.max(1, math.floor(tonumber(cmd.voters) or 1))
  world.mp_vote_seq = (world.mp_vote_seq or 0) + 1
  world.mp_vote = {
    id = world.mp_vote_seq,
    speed = MultiplayerLobby.clampSpeed(cmd.speed, session and session.max_speed),
    peer = cmd.peer,
    voters = voters,
    need = math.floor(voters / 2) + 1, -- more than half
    yes = {[cmd.peer] = true},
    no = {},
    frames = 0,
  }
  if world.mp_vote.need <= 1 then
    end_vote(world, "agreed")
    return true
  end
  if session then
    if cmd.peer == session.peer_id then
      session.notify(_S.multiplayer_window.vote_asked:format(world.mp_vote.speed))
    end
    session:syncVote(world)
  end
  return true
end

--! A player's answer to the open speed vote: {vote, agree (1 or 0)}.
function handlers.speed_vote_answer(world, cmd)
  local vote = world.mp_vote
  if not vote or vote.id ~= tonumber(cmd.vote) then return false, "the vote is over" end
  if vote.yes[cmd.peer] or vote.no[cmd.peer] then return false, "already answered" end
  if tonumber(cmd.agree) == 1 then vote.yes[cmd.peer] = true else vote.no[cmd.peer] = true end
  if count_keys(vote.yes) >= vote.need then
    end_vote(world, "agreed")
  elseif vote.voters - count_keys(vote.no) < vote.need then
    end_vote(world, "declined", cmd.peer)
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
    -- The fanfare of the opening (as UIWatch:onCountdownEnd), for its player.
    if world.ui.hospital == hospital then world.ui:playSound("fanfare.wav") end
  end
  return true
end

--! A race: the blue floor of a rival's room being furnished is not shown
--! here (its walls are up for everybody; what goes in is its player's). A
--! team mate's is.
local function hide_rivals_floor(world, cmd)
  local session = TheApp.mp_session
  if session and cmd.peer ~= session.peer_id and
      world:mpRivals(world.hospitals[cmd.hospital or 1], world:getUIHospital()) then
    paint_rect(world, cmd, 0)
  end
end

--! Build a room the player drew: {room, x, y, w, h, door_x, door_y,
--! door_wall, windows, furnish}. If people stand in the area they are asked
--! to walk out and the command is retried a few steps later (on every peer
--! alike). With furnish=1 the room waits for its furniture (room_object,
--! room_finish); otherwise the required objects are placed automatically.
function handlers.build_room(world, cmd)
  local builder = corsixth.require("mp_room_builder")
  local hospital = world.hospitals[cmd.hospital or 1]
  if not hospital then return false, "no such hospital" end
  local room, why, dlg = builder.build(world, hospital, cmd)
  if why == "people in the area" then
    builder.clearArea(world, cmd.x, cmd.y, cmd.w, cmd.h, cmd)
    cmd.max_retries = MultiplayerSession.MAX_CLEAR_RETRIES
    return false, "retry" -- the reserved outline stays visible meanwhile
  end
  local session = TheApp.mp_session
  if session then session:showRemoteBlueprint(cmd.peer, nil) end
  if not room then
    builder.releaseArea(world, cmd.x, cmd.y, cmd.w, cmd.h)
    return false, why
  end
  if dlg then
    local entry = {dlg = dlg, peer = cmd.peer, hospital = cmd.hospital or 1,
        x = cmd.x, y = cmd.y, w = cmd.w, h = cmd.h, placed = {}}
    world.mp_furnishing = world.mp_furnishing or {}
    world.mp_furnishing[room.id] = entry
    -- The player who drew it now places the furniture; if they are in the
    -- middle of drawing another room, it is placed automatically instead.
    if session and cmd.peer == session.peer_id and not session.observer and
        not builder.show(world, entry) then
      session:issue({kind = "room_finish", room = room.id, auto = 1})
    end
    hide_rivals_floor(world, cmd)
  end
  return true
end

--! The room being furnished by hand that a command names, if it is the
--! sender's (only they place its furniture).
local function furnishing(world, cmd)
  local entry = world.mp_furnishing and world.mp_furnishing[tonumber(cmd.room)]
  if entry and entry.peer == cmd.peer then return entry end
end

--! Put one object into a room being furnished: {room, object, x, y, orientation}.
function handlers.room_object(world, cmd)
  local entry = furnishing(world, cmd)
  if not entry then return false, "room is not being furnished" end
  return corsixth.require("mp_room_builder").placeObject(world, entry, cmd)
end

--! Finish a room being furnished: {room, auto (1: place what is missing)}.
function handlers.room_finish(world, cmd)
  local entry = furnishing(world, cmd)
  if not entry then return false, "room is not being furnished" end
  local builder = corsixth.require("mp_room_builder")
  local room, why = builder.finish(world, entry, tonumber(cmd.auto) == 1)
  if not room then
    -- Its player's editor closed when they confirmed: open it again, or the
    -- room would stay half built with no way back into it.
    builder.showAgain(world, entry)
    return false, why
  end
  builder.hide(world, entry)
  builder.releaseUI(world.ui, entry.dlg)
  world.mp_furnishing[tonumber(cmd.room)] = nil
  return true
end

--! Remove a room being furnished (cancelled): {room}.
function handlers.room_abort(world, cmd)
  local entry = furnishing(world, cmd)
  if not entry then return false, "room is not being furnished" end
  local builder = corsixth.require("mp_room_builder")
  builder.hide(world, entry)
  local ok, why = builder.abort(world, entry)
  builder.releaseUI(world.ui, entry.dlg)
  world.mp_furnishing[tonumber(cmd.room)] = nil
  return ok, why
end

--! Edit a built room: {room}. The room closes, everybody inside leaves, and
--! once it is empty (Room:enterEditMode) its editor opens on every peer and
--! its player edits it like a room being furnished.
function handlers.room_edit(world, cmd)
  local room = world.rooms[tonumber(cmd.room)]
  local hospital = world.hospitals[cmd.hospital or 1]
  if not room or not hospital then return false, "no such room" end
  if room.hospital ~= hospital then return false, "not ours" end
  local entry = world.mp_furnishing and world.mp_furnishing[room.id]
  if room.mp_edit or entry then
    if (entry and entry.peer or room.mp_edit.peer) ~= cmd.peer then return false, "another player's work" end
    return false, "room is already being edited"
  end
  if not room.built or room.crashed or not room.is_active then return false, "room cannot be edited now" end
  room.mp_edit = {peer = cmd.peer}
  room:tryToEdit() -- opens the editor at once if nobody is inside
  return true
end

--! Pick up an object of a room being furnished or edited: {room, object}.
function handlers.room_pickup(world, cmd)
  local entry = furnishing(world, cmd)
  if not entry then return false, "room is not being furnished" end
  local obj = world:getEntityById(tonumber(cmd.object))
  if not obj or not class.is(obj, Object) then return false, "not in this room" end
  return corsixth.require("mp_room_builder").pickUp(world, entry, obj)
end

--! Buy objects for, or sell unplaced objects from, a room being furnished
--! or edited: {room, buy = "id:qty,...", sell = "id:qty,..."}.
function handlers.room_buy(world, cmd)
  local entry = furnishing(world, cmd)
  if not entry then return false, "room is not being furnished" end
  local builder = corsixth.require("mp_room_builder")
  return builder.buy(world, entry, builder.decodeCounts(cmd.buy), builder.decodeCounts(cmd.sell))
end

--! Take the walls of a room being furnished or edited down, to draw it again
--! elsewhere or in another size (or to remove it): {room}.
function handlers.room_unbuild(world, cmd)
  local entry = furnishing(world, cmd)
  if not entry then return false, "room is not being furnished" end
  local builder = corsixth.require("mp_room_builder")
  local ok, why = builder.unbuild(world, entry)
  if ok then builder.startRedraw(world, entry) else builder.showAgain(world, entry) end
  return ok, why
end

--! Build a room whose walls are down again: {room, x, y, w, h, door_x,
--! door_y, door_wall, windows}. People in the way are asked to leave and
--! the command is retried, as for build_room.
function handlers.room_rebuild(world, cmd)
  local entry = furnishing(world, cmd)
  if not entry then return false, "room is not being furnished" end
  local builder = corsixth.require("mp_room_builder")
  local ok, why = builder.rebuild(world, entry, cmd)
  if why == "people in the area" then
    builder.clearArea(world, cmd.x, cmd.y, cmd.w, cmd.h, cmd)
    cmd.max_retries = MultiplayerSession.MAX_CLEAR_RETRIES
    return false, "retry"
  end
  local session = TheApp.mp_session
  if session then session:showRemoteBlueprint(cmd.peer, nil) end
  builder.releaseArea(world, cmd.x, cmd.y, cmd.w, cmd.h)
  if ok then
    builder.showAgain(world, entry)
    hide_rivals_floor(world, cmd)
  else
    builder.startRedraw(world, entry, cmd)
  end
  return ok, why
end

function handlers.room_rebuild_giveup(world, cmd)
  local builder = corsixth.require("mp_room_builder")
  builder.releaseArea(world, cmd.x, cmd.y, cmd.w, cmd.h)
  local session = TheApp.mp_session
  if session then session:showRemoteBlueprint(cmd.peer, nil) end
  local entry = furnishing(world, cmd)
  if entry then builder.startRedraw(world, entry, cmd) end
  return false, "not a player command"
end

--! Remove a room whose walls are down (half its cost back if it was paid
--! for): {room}.
function handlers.room_delete(world, cmd)
  local entry = furnishing(world, cmd)
  if not entry then return false, "room is not being furnished" end
  local builder = corsixth.require("mp_room_builder")
  builder.hide(world, entry)
  local ok, why = builder.delete(world, entry)
  builder.releaseUI(world.ui, entry.dlg)
  if ok then
    world.mp_furnishing[tonumber(cmd.room)] = nil
  else
    builder.startRedraw(world, entry)
  end
  return ok, why
end

--! A room of a player who left: {room, left}. A room being furnished or
--! edited is finished (what is missing placed automatically; removed if that
--! fails or its walls are down); a room still emptying for an edit opens
--! again.
function handlers.room_takeover(world, cmd)
  local id = tonumber(cmd.room)
  local left = tonumber(cmd.left)
  local builder = corsixth.require("mp_room_builder")
  local entry = world.mp_furnishing and world.mp_furnishing[id]
  if entry then
    if entry.peer ~= left then return false, "not that player's room" end
    builder.hide(world, entry)
    local done
    if not entry.unbuilt then done = builder.finish(world, entry, true) end
    if not done then
      if entry.unbuilt then builder.delete(world, entry) else builder.abort(world, entry) end
    end
    builder.releaseUI(world.ui, entry.dlg)
    world.mp_furnishing[id] = nil
    return true
  end
  local room = world.rooms[id]
  if room and room.mp_edit and room.mp_edit.peer == left then
    room.mp_edit = nil
    if not room.is_active then world:markRoomAsBuilt(room) end
    return true
  end
  return false, "nothing to take over"
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
  if icon.hospital and not icon.everyone and icon.hospital ~= world.hospitals[cmd.hospital or 1] then
    return false, "not ours"
  end
  local choices = icon.message and icon.message.choices
  if not choices or not choices[cmd.choice] then return false, "no such choice" end
  if choices[cmd.choice].enabled == false or choices[cmd.choice].choice == "disabled" then
    return false, "choice not available"
  end
  -- For the command log (desync hunting): which message, which answer.
  cmd.resolved = tostring(icon.type) .. ": " .. tostring(choices[cmd.choice].choice)
  local queued = icon.parent == nil
  icon:removeMessage(cmd.choice)
  if queued then panel:forgetQueuedIcon(icon) end
  -- A win fax the game stood still for: answered (MultiplayerSession.startHold).
  local hold = world.mp_hold
  if hold then
    for i = #hold.msgs, 1, -1 do
      if hold.msgs[i] == tonumber(cmd.msg) then table.remove(hold.msgs, i) end
    end
    if #hold.msgs == 0 and hold.kind == "win" then hold.waiting = {} end
  end
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
  -- (Money only between allies: a rival in a race is not sent or asked for
  -- any (Jan, 2026-11-12). Research and staff may be sold to a rival.)
  if not world:mpMayTrade(from, to) or world:mpRivals(from, to) then return false, "not on your team" end
  if amount <= 0 then return false, "nothing to send" end
  if from.balance < amount then return false, "not enough money" end
  from:spendMoney(amount, _S.multiplayer_window.money_sent:format(to.name))
  to:receiveMoney(amount, _S.multiplayer_window.money_received:format(from.name))
  MultiplayerSession.tellPlayer(world, to,
      _S.multiplayer_window.money_received_note:format(from.name, amount))
  return true
end

-- Vouching for an ally: reputation points move from one hospital to another
-- (the giver loses what the receiver gains), so a player who trails behind
-- can be lifted by the others. The giver keeps REP_FLOOR points (the game
-- warns below 200 and is lost below 100), gives at most REP_MAX_GIVE points
-- at a time and REP_MONTH_LIMIT in a game month, so that the points cannot be
-- passed back and forth for ever. The receiver stops at the game's top.
MultiplayerSession.REP_MAX_GIVE = 100
MultiplayerSession.REP_FLOOR = 200
MultiplayerSession.REP_MONTH_LIMIT = 200

--! How many reputation points `from` may still give in this game month.
function MultiplayerSession.reputationLeft(world, from)
  local given = from.mp_rep_given
  local used = given and given.month == world:date():monthOfGame() and given.points or 0
  return math.max(0, MultiplayerSession.REP_MONTH_LIMIT - used)
end

--! How many points `from` can give `to` now (0 to REP_MAX_GIVE), and why not
--! more: "reputation too low" (the giver's floor), "their reputation is
--! full" (the receiver's top) or "monthly limit".
function MultiplayerSession.reputationRoom(world, from, to)
  local keep = math.floor(from.reputation or 0) - MultiplayerSession.REP_FLOOR
  local top = math.floor((to.reputation_max or 1000) - (to.reputation or 0))
  local left = MultiplayerSession.reputationLeft(world, from)
  local room = math.min(MultiplayerSession.REP_MAX_GIVE, keep, top, left)
  if room >= 1 then return room end
  if keep < 1 then return 0, "reputation too low" end
  if top < 1 then return 0, "their reputation is full" end
  return 0, "monthly limit"
end

--! Give reputation points to an ally: {hospital (giver), to, amount} (1 to
--! REP_MAX_GIVE; less if the floor, the limit or the top stops it).
function handlers.give_reputation(world, cmd)
  local S = _S.multiplayer_window
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  if not from or not to or from == to then return false, "no such hospital" end
  if not world:mpMayTrade(from, to) or world:mpRivals(from, to) then return false, "not on your team" end
  local amount = math.floor(tonumber(cmd.amount) or 0)
  if amount < 1 or amount > MultiplayerSession.REP_MAX_GIVE then return false, "invalid amount" end
  local room, why = MultiplayerSession.reputationRoom(world, from, to)
  if room < 1 then return false, why end
  amount = math.min(amount, room)
  local month = world:date():monthOfGame()
  local given = from.mp_rep_given
  local used = given and given.month == month and given.points or 0
  from:unconditionalChangeReputation(-amount)
  to:unconditionalChangeReputation(amount)
  from.mp_rep_given = {month = month, points = used + amount}
  cmd.resolved = amount .. " points"
  MultiplayerSession.tellPlayer(world, from, S.rep_given_note:format(to.name, amount))
  MultiplayerSession.tellPlayer(world, to, S.rep_received_note:format(from.name, amount))
  return true
end

--! Staff member `index` of a hospital, if their profile still has `key`.
--! The member of staff a command names: by entity id (cmd.staff), else by
--! position and key (wage and skill; a skill grows while training, so the
--! key alone can miss someone in the training room).
local function find_staff(world, hospital, cmd)
  local by_id = cmd.staff and world:getEntityById(tonumber(cmd.staff))
  if by_id then
    -- (An evil handyman, competitive, is not theirs to give away.)
    if class.is(by_id, Staff) and by_id.hospital == hospital and not by_id.fired and
        not by_id.mp_saboteur then
      return by_id
    end
    return nil
  end
  local index, key = cmd.index, cmd.key
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

MultiplayerSession.arrivalTile = arrival_tile

--! Send a staff member to another player's hospital: {hospital (sender), to,
--! index, key}. They walk over to the new one and start work there. No hiring fee
--! and no severance pay.
function handlers.send_staff(world, cmd)
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  if not from or not to or from == to then return false, "no such hospital" end
  if not world:mpMayTrade(from, to) or world:mpRivals(from, to) then return false, "not on your team" end
  local staff = find_staff(world, from, cmd)
  if not staff then return false, "no such staff member" end
  return MultiplayerSession.transferStaff(world, from, to, staff)
end

--! Move a member of staff from one player's hospital to another's: they walk
--! over and start work there on arrival.
--!return true, or false and a reason
function MultiplayerSession.transferStaff(world, from, to, staff)
  local x, y = arrival_tile(world, to)
  if not x then return false, "no room at the other hospital" end

  -- Leave the old hospital (like being fired, but without the sack): the
  -- same person walks over to the other hospital and starts work there on
  -- arrival (World:_tickCoopTransfers). On the way they belong to neither.
  local staff_window = world.ui and world.ui:getWindow(UIStaff)
  if staff_window and staff_window.staff == staff then staff_window:close() end
  staff:removeQueuedStaffMessage()
  staff:unregisterCallbacks()
  staff.dealing_with_patient = nil
  staff:setMood("idea3", "deactivate")
  staff:setMood("reflexion", "deactivate")
  from:removeStaff(staff)
  staff.mp_in_transit = {to = world:getHospitalIndex(to), x = x, y = y}
  staff:setDynamicInfoText(_S.multiplayer_window.staff_on_the_way:format(to.name))
  -- A brisk walk: the way between two hospitals is long (normal speed
  -- again on arrival, Staff:onPlaceInCorridor).
  staff.speed, staff.slow_animation = "transit", false
  -- (Busy with something that must happen first, an operation say, they
  -- finish it before they set off: World:_tickCoopTransfers waits for this
  -- walk.)
  local walk = WalkAction(x, y):setMustHappen(true)
  staff.mp_transfer_walk = walk
  staff:setNextAction(walk)
  staff:queueAction(IdleAction())
  world.mp_transfers = world.mp_transfers or {}
  world.mp_transfers[#world.mp_transfers + 1] = staff

  local window = world.ui and world.ui:getWindow(UIStaffManagement)
  if window then window:updateStaffList() end
  MultiplayerSession.tellPlayer(world, to,
      _S.multiplayer_window.staff_received_note:format(from.name, "") .. staff.profile:getFullName())
  return true
end

--! Show a short adviser message, only to the player running `hospital`.
--!param longer (number) [optional] how many times as long as usual the
--! adviser talks (UIAdviser:say)
function MultiplayerSession.tellPlayer(world, hospital, text, longer)
  local ui = world.ui
  if ui and ui.adviser and ui.hospital == hospital then
    ui.adviser:say({text = text, priority = 10, longer = longer})
  end
end

--! Tell every player except the one of `hospital` (nil: everybody).
function MultiplayerSession.tellOthers(world, hospital, text)
  local ui = world.ui
  if ui and ui.adviser and ui.hospital ~= hospital then
    ui.adviser:say({text = text, priority = 10})
  end
end

--! Is this game ending for everybody: finishing already, or "Back to the
--! lobby" (a fax answer) received and still to be applied? Another player's
--! game can get there first and leave, and its "left" must not be announced.
function MultiplayerSession:isEnding()
  if self.finish_request then return true end
  local panel = self.world and self.world.ui and self.world.ui.bottom_panel
  for _, cmd in ipairs(self.pending) do
    if cmd.kind == "fax_choice" and panel and panel.findMessageIcon then
      local icon = panel:findMessageIcon(tonumber(cmd.msg))
      local choices = icon and type(icon.message) == "table" and icon.message.choices
      local chosen = choices and choices[tonumber(cmd.choice)]
      if chosen and chosen.choice == "return_to_main_menu" then return true end
    end
  end
  return false
end

--! End the multiplayer game for this player (every peer asks for it at the
--! same step: a fax answer or the level lost). It ends between steps (see
--! World:onTick), never in the middle of one; the player goes back to the
--! main menu with `message` and into the lobby of the same server.
--!param message (table) lines for the main menu
--!param movie (string) [optional] "win" or "lose": the video to play first
--!param letter (table) [optional] the words for the letter the win video
--! ends with (MultiplayerSession.winLetter)
function MultiplayerSession:finish(message, movie, letter)
  self.finish_request = self.finish_request or {message = message, movie = movie, letter = letter}
end

--! The words for the letter the win video ends with (Jan: it stayed blank):
--! "Dear <hospital>" (unless the fax `message` starts with it: a line marked
--! `greeting`) and the paragraphs of the win fax, without its last one when
--! it has been `answered` (the question its buttons answer).
--!return (table) the paragraphs, or nil
function MultiplayerSession.winLetter(message, hospital, answered)
  if type(message) ~= "table" then return nil end
  local letter = {}
  if hospital and not (message[1] and message[1].greeting) then
    letter[1] = _S.letter.dear_player:format(hospital.name)
  end
  for i = 1, #message - (answered and 1 or 0) do
    if message[i].text then letter[#letter + 1] = message[i].text end
  end
  return letter
end

--! The message (its table of lines) of fax number `mp_id`, shown or queued.
local function fax_message(panel, mp_id)
  if not (panel and mp_id) then return nil end
  for _, info in ipairs(panel.message_queue or {}) do
    if info.mp_id == mp_id then return info.message end
  end
  local icon = panel.findMessageIcon and panel:findMessageIcon(mp_id)
  return icon and icon.message
end

function MultiplayerSession:finishGame()
  local request = self.finish_request
  self.finish_request = nil
  TheApp.mp_starting = nil
  local back_to_lobby = self.lobby and not self.lobby.is_referee
  local app = TheApp
  app:loadMainMenu(request.message)
  local function reconnect()
    if back_to_lobby and app.ui then
      local menu = app.ui:getWindow(UIMainMenu)
      if menu and menu.buttonMultiplayer then
        menu:buttonMultiplayer()
        local lobby_window = app.ui:getWindow(UIMultiplayer)
        if lobby_window then lobby_window:buttonConnect() end
      end
    end
  end
  -- The win or lose video, as in single player; back to the lobby after it
  -- (a server hangs up on a connection that says nothing for 15 seconds).
  local movies = back_to_lobby and app.moviePlayer
  if movies and request.movie == "win" then
    movies:playWinLevelMovie(reconnect, request.letter)
  elseif movies and request.movie == "lose" then
    movies:playLoseMovie(reconnect)
  else
    reconnect()
  end
end

--! Once per frame (App:onTick): a video a game step asked for on this
--! player's screen (a race won: World:_mpPlaceFax), played outside the step.
function MultiplayerSession:checkPendingMovie(app)
  local movie = self.pending_movie
  if not movie then return end
  self.pending_movie = nil
  local fax = self.pending_movie_fax
  self.pending_movie_fax = nil
  -- The fax that goes with it, once the video is over (at once without one),
  -- unless it was answered on the video's letter.
  local answered = false
  local function open_fax()
    local panel = app.ui and app.ui.bottom_panel
    if not answered and fax and panel and panel.openMessageById then panel:openMessageById(fax) end
  end
  if movie == "win" and app.moviePlayer then
    self.win_movie_shown = true
    -- The fax's words on the letter the video ends with, and its cross and
    -- tick to answer it there, as in the original game (Jan): the question
    -- becomes a yes or no one, the tick its first choice (back to the
    -- lobby), the cross the second (watch). The stop movie key skips to the
    -- fax.
    local ui = app.ui
    local message = ui and fax_message(ui.bottom_panel, fax)
    local letter = ui and MultiplayerSession.winLetter(message, ui.hospital)
    local choose
    if letter and type(message.choices) == "table" and #message.choices == 2 then
      letter[#letter] = _S.multiplayer_window.race_won_question
      choose = function(choice)
        answered = true
        self:issue({kind = "fax_choice", msg = fax, choice = choice})
      end
    end
    app.moviePlayer:playWinLevelMovie(open_fax, letter, choose)
  else
    open_fax()
  end
end

--------------------------------------------------------------------------------
-- Co-op offers: a member of staff or a patient offered to another player's
-- hospital. The offer is a message (type "mp_offer", the purple icon) that
-- exists on every peer and is shown only to the receiving player; answering
-- it is a fax_choice command (1 = accept, 2 = decline), and it declines
-- itself after MultiplayerSession.OFFER_DAYS game days (the message
-- timeout runs in game hours on every peer, UIBottomPanel:onWorldTick).
-- While it is open, the person stays where they are and cannot be offered
-- again (entity.mp_offer = the message number).
--------------------------------------------------------------------------------

-- Like the VIP fax: 20 game days (its default is yes; an offer's is no).
MultiplayerSession.OFFER_DAYS = 20

-- A member of staff may be offered for a price, in steps of $500.
MultiplayerSession.STAFF_MAX_PRICE = 10000
MultiplayerSession.STAFF_PRICE_STEP = 500

local function display_name(entity)
  local S = _S.multiplayer_window
  if entity.profile then return entity.profile:getFullName() end
  if class.is(entity, Patient) then
    if entity.diagnosed and entity.disease then return S.offer_patient_known:format(entity.disease.name) end
    return S.offer_patient_unknown
  end
  return "?"
end

--! Create an offer of `entity` (staff or patient) from one hospital to
--! another, for `price` (optional, staff only).
local function create_offer(world, kind, from, to, entity, price)
  local S = _S.multiplayer_window
  local panel = world.ui and world.ui.bottom_panel
  if not panel then return false, "no message panel" end
  local name = display_name(entity)
  price = price or 0
  local message = {
    {text = (kind == "staff" and S.offer_staff_line or S.offer_patient_line):format(from.name)},
    {text = name},
    choices = {
      {text = price > 0 and S.offer_accept_price:format(price) or S.offer_accept, choice = "mp_offer_accept"},
      {text = S.offer_decline, choice = "mp_offer_decline"},
    },
    mp_offer = {kind = kind, from = world:getHospitalIndex(from), to = world:getHospitalIndex(to),
        entity = entity.mp_id, name = name, price = price > 0 and price or nil},
  }
  -- (The price straight after who offers it, before the details, on a line
  -- of its own.)
  if price > 0 then
    table.insert(message, 2, {text = " "})
    table.insert(message, 3, {text = S.offer_price_line:format(price)})
    table.insert(message, 4, {text = " "})
  end
  panel:queueMessage("mp_offer", message, nil, Date.hoursPerDay() * MultiplayerSession.OFFER_DAYS, 2, nil, to)
  entity.mp_offer = world.next_message_id
  MultiplayerSession.tellPlayer(world, from, price > 0 and S.offer_sent_price_note:format(name, to.name, price)
      or S.offer_sent_note:format(name, to.name))
  return true
end

--! Offer a member of staff to another player: {to, staff (entity id), index,
--! key, price (optional)}. They join that hospital only if its player accepts (and
--! pays the price; MultiplayerSession.resolveOffer).
function handlers.offer_staff(world, cmd)
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  if not from or not to or from == to then return false, "no such hospital" end
  if not world:mpMayTrade(from, to) then return false, "not on your team" end
  local price = math.floor(tonumber(cmd.price) or 0)
  if price < 0 or price > MultiplayerSession.STAFF_MAX_PRICE then return false, "invalid price" end
  local staff = find_staff(world, from, cmd)
  if not staff or staff.mp_in_transit then return false, "no such staff member" end
  if staff.mp_offer then return false, "already offered" end
  return create_offer(world, "staff", from, to, staff, price)
end

--! Can this patient be referred to another hospital? (They must be free to
--! leave: not in a room, not leaving, not an infected patient. Emergency
--! patients may go: they keep counting for their own hospital's emergency,
--! Hospital:emergencyOf.)
local function referable(patient)
  if patient.going_home or patient.going_to_die or patient.dead or patient.mp_in_transit then
    return false, "the patient is leaving"
  end
  if patient.infected then return false, "infected patients stay" end
  if patient:getRoom() then return false, "the patient is in a room" end
  return true
end
MultiplayerSession.referable = referable

--! Refer a patient to another player: {to, patient}. They go there only if
--! its player accepts.
function handlers.offer_patient(world, cmd)
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  if not from or not to or from == to then return false, "no such hospital" end
  if not world:mpMayTrade(from, to) then return false, "not on your team" end
  local patient = world:getEntityById(tonumber(cmd.patient))
  if not patient or not class.is(patient, Patient) or patient.hospital ~= from then
    return false, "no such patient"
  end
  if patient.mp_offer then return false, "already offered" end
  local ok, why = referable(patient)
  if not ok then return false, why end
  return create_offer(world, "patient", from, to, patient)
end

--! Move a referred patient to another hospital: they walk over and are that
--! hospital's patient on arrival (World:_tickCoopTransfers).
--!return true, or false and a reason
function MultiplayerSession.transferPatient(world, from, to, patient)
  local ok, why = referable(patient)
  if not ok then return false, why end
  local x, y = arrival_tile(world, to)
  if not x then return false, "no room at the other hospital" end
  local window = world.ui and world.ui:getWindow(UIPatient)
  if window and window.patient == patient then window:close() end
  -- Leave this hospital like going home, without the counts: no message,
  -- no queue, no vaccination call, not this hospital's patient any more.
  patient:unregisterCallbacks()
  patient:setMood("patient_wait", "deactivate")
  patient.waiting = nil
  world.dispatcher:dropFromQueue(patient)
  from:removePatient(patient)
  from:updatePercentages()
  patient.mp_in_transit = {to = world:getHospitalIndex(to), from = world:getHospitalIndex(from), x = x, y = y}
  patient:setDynamicInfoText(_S.multiplayer_window.patient_on_the_way:format(to.name))
  patient.speed = "transit" -- a long way (normal again on arrival)
  patient:setNextAction(WalkAction(x, y):setMustHappen(true))
  patient:queueAction(IdleAction())
  world.mp_transfers = world.mp_transfers or {}
  world.mp_transfers[#world.mp_transfers + 1] = patient
  return true
end

-- A referral that ends in a cure is good for both hospitals (Jan,
-- 2026-11-12): the one that referred the patient gains REFERRAL_REPUTATION
-- (sending them home would have cost it 3), the one that cured them
-- REFERRAL_EXTRA on top of the usual point for a cure. Nothing more if the
-- patient dies there or is sent home.
MultiplayerSession.REFERRAL_REPUTATION = 3
MultiplayerSession.REFERRAL_EXTRA = 1

--! A referred patient was cured at `hospital` (Hospital:updateCuredCounts):
--! the reputation for the referral, on every peer at the same step.
function MultiplayerSession.referralCured(world, hospital, patient)
  local by = world.hospitals[patient.mp_referred_by or 0]
  patient.mp_referred_by = nil
  if not by or by == hospital then return end
  local S = _S.multiplayer_window
  by:changeReputation(nil, nil, MultiplayerSession.REFERRAL_REPUTATION)
  hospital:changeReputation(nil, nil, MultiplayerSession.REFERRAL_EXTRA)
  MultiplayerSession.tellPlayer(world, by, S.referral_cured_note:format(hospital.name,
      MultiplayerSession.REFERRAL_REPUTATION))
  MultiplayerSession.tellPlayer(world, hospital, S.referral_cured_here_note:format(by.name,
      MultiplayerSession.REFERRAL_EXTRA))
  local session = world.app and world.app.mp_session
  if session then
    session.log(string.format("referred patient #%s cured at hospital %d: +%d for hospital %d",
        tostring(patient.mp_id), world:getHospitalIndex(hospital), MultiplayerSession.REFERRAL_REPUTATION,
        world:getHospitalIndex(by)))
  end
end

--------------------------------------------------------------------------------
-- Co-op research sharing: one hospital offers knowledge it has and another
-- lacks (equipment discoveries, drug improvements, machine improvements),
-- for free or for a price ($0 to $20,000). The offer is a message of type
-- "mp_research" (an icon with a flask), answered in the fax window like the
-- other offers; on acceptance the receiver pays and gets whatever of it they
-- still lack then. The sender keeps their research: knowledge is copied.
--------------------------------------------------------------------------------

MultiplayerSession.RESEARCH_MAX_PRICE = 20000
-- Research is sold to a rival for at least this much, and a member of staff
-- is offered to one for this much unless the player changes it (Jan,
-- 2026-11-12: free to an ally, $1,000 to start with to an opponent).
MultiplayerSession.RIVAL_MIN_PRICE = 1000

--! The text of a game string (names are translatable string objects).
local function plain(text)
  if type(text) ~= "userdata" then return tostring(text) end
  return (require("TH").stringProxy._unwrap(text))
end
MultiplayerSession.RESEARCH_PRICE_STEP = 500

--! Item keys: "e:<object id>" equipment discovery, "d:<disease id>" drug
--! improvement, "m:<object id>" machine improvement.
local function research_item(from, to, key)
  local kind, id = tostring(key):match("^(%a):([%w_]+)$")
  local S = _S.multiplayer_window
  if kind == "e" or kind == "m" then
    local object = TheApp.objects[id]
    local have = object and from.research.research_progress[object]
    local lack = object and to.research.research_progress[object]
    if not (have and lack and object.thob) then return nil end
    if kind == "e" and have.discovered and not lack.discovered then
      return {key = key, kind = kind, object = object, name = plain(object.name)}
    end
    if kind == "m" and object.default_strength and have.discovered and
        ((have.strength_imp or 0) > (lack.strength_imp or 0) or (have.cost_imp or 0) > (lack.cost_imp or 0)) then
      return {key = key, kind = kind, object = object, name = S.research_item_machine:format(plain(object.name))}
    end
  elseif kind == "d" then
    local have, lack = from.disease_casebook[id], to.disease_casebook[id]
    if have and lack and have.drug and (have.cure_effectiveness > lack.cure_effectiveness or
        have.drug_cost < lack.drug_cost) then
      return {key = key, kind = kind, disease = id, name = S.research_item_drug:format(plain(have.disease.name))}
    end
  end
  return nil
end

--! Everything `from` could share with `to` now, in a fixed order.
function MultiplayerSession.shareableResearch(from, to)
  local keys = {}
  for _, object in ipairs(TheApp.objects) do
    if object.thob then
      keys[#keys + 1] = "e:" .. object.id
      keys[#keys + 1] = "m:" .. object.id
    end
  end
  local diseases = {}
  for id in pairs(from.disease_casebook) do diseases[#diseases + 1] = id end
  table.sort(diseases)
  for _, id in ipairs(diseases) do keys[#keys + 1] = "d:" .. id end
  local items = {}
  for _, key in ipairs(keys) do
    local item = research_item(from, to, key)
    if item then items[#items + 1] = item end
  end
  return items
end

--! The items of a ";"-separated key list that `from` can still give `to`.
local function research_items_of(from, to, keys)
  local items, seen = {}, {}
  for key in tostring(keys or ""):gmatch("[^;]+") do
    if not seen[key] then
      seen[key] = true
      local item = research_item(from, to, key)
      if item then items[#items + 1] = item end
    end
  end
  return items
end

--! Give `to` one item of `from`'s research.
local function apply_research(world, from, to, item)
  local research = to.research
  if item.kind == "e" then
    research:discoverObject(item.object)
  elseif item.kind == "m" then
    local have, lack = from.research.research_progress[item.object], research.research_progress[item.object]
    if (have.strength_imp or 0) > (lack.strength_imp or 0) then
      lack.start_strength = math.max(lack.start_strength or 0, have.start_strength or 0)
      lack.strength_imp = have.strength_imp
    end
    if (have.cost_imp or 0) > (lack.cost_imp or 0) and have.cost and lack.cost then
      local decrease = lack.cost - have.cost
      lack.cost, lack.cost_imp = have.cost, have.cost_imp
      -- Rooms needing this machine get cheaper by as much, as in improveMachine.
      for _, room in ipairs(world.available_rooms) do
        local no = room.objects_needed[item.object.id]
        local progress = research.research_progress[room]
        if no and progress and progress.build_cost then
          progress.build_cost = progress.build_cost - decrease * no
        end
      end
    end
    if research.research_policy.improvements.current == item.object then
      research:nextResearch("improvements")
    end
  elseif item.kind == "d" then
    local have, lack = from.disease_casebook[item.disease], to.disease_casebook[item.disease]
    lack.cure_effectiveness = math.max(lack.cure_effectiveness, have.cure_effectiveness)
    lack.drug_cost = math.min(lack.drug_cost, have.drug_cost)
    if research.research_policy.drugs.current == lack then research:nextResearch("drugs") end
  end
end
MultiplayerSession.applyResearchItem = apply_research -- (espionage, mp_sabotage.lua)

--! A short list of item names for a fax ("A, B and 3 more").
local function research_names(items)
  local names = {}
  for i, item in ipairs(items) do
    if i > 6 then
      names[#names + 1] = plain(_S.multiplayer_window.research_and_more:format(#items - 6))
      break
    end
    names[#names + 1] = plain(item.name)
  end
  return table.concat(names, ", ")
end

--! Offer research to another player: {to, items (";"-separated keys), price}.
function handlers.offer_research(world, cmd)
  local S = _S.multiplayer_window
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  if not from or not to or from == to then return false, "no such hospital" end
  if not world:mpMayTrade(from, to) then return false, "not on your team" end
  if world.mp_coop and world.mp_coop.sharing_off then return false, "research sharing is off in this game" end
  local price = math.floor(tonumber(cmd.price) or -1)
  if price < 0 or price > MultiplayerSession.RESEARCH_MAX_PRICE then return false, "invalid price" end
  if price < MultiplayerSession.RIVAL_MIN_PRICE and world:mpRivals(from, to) then
    return false, "a rival pays at least $1,000"
  end
  local items = research_items_of(from, to, cmd.items)
  if #items == 0 then return false, "nothing to share" end
  local panel = world.ui and world.ui.bottom_panel
  if not panel then return false, "no message panel" end
  local keys = {}
  for i, item in ipairs(items) do keys[i] = item.key end
  local names = research_names(items)
  local message = {
    {text = S.research_offer_line:format(from.name)},
    -- (The price before the list of what is offered, which can be long, on
    -- a line of its own.)
    {text = " "},
    {text = price > 0 and S.research_price_line:format(price) or S.research_free_line},
    {text = " "},
    {text = names},
    choices = {
      {text = price > 0 and S.research_accept_price:format(price) or S.research_accept, choice = "mp_offer_accept"},
      {text = S.research_decline, choice = "mp_offer_decline"},
    },
    mp_offer = {kind = "research", from = world:getHospitalIndex(from), to = world:getHospitalIndex(to),
        items = table.concat(keys, ";"), price = price, name = names},
  }
  panel:queueMessage("mp_research", message, nil, Date.hoursPerDay() * MultiplayerSession.OFFER_DAYS, 2, nil, to)
  MultiplayerSession.tellPlayer(world, from, S.research_sent_note:format(to.name))
  return true
end

--------------------------------------------------------------------------------
-- Co-op money requests: one player asks another for money (bank manager,
-- "Ask a player"). The request is a message of type "mp_money" (a coin
-- icon) answered in the fax window like the offers; paying is up to the
-- player asked, and checked again when they answer.
--------------------------------------------------------------------------------

MultiplayerSession.ASK_MIN, MultiplayerSession.ASK_MAX, MultiplayerSession.ASK_STEP = 500, 50000, 500

--! Ask another player for money: {to, amount}.
function handlers.ask_money(world, cmd)
  local S = _S.multiplayer_window
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  if not from or not to or from == to then return false, "no such hospital" end
  if not world:mpMayTrade(from, to) or world:mpRivals(from, to) then return false, "not on your team" end
  local amount = math.floor(tonumber(cmd.amount) or 0)
  if amount < MultiplayerSession.ASK_MIN or amount > MultiplayerSession.ASK_MAX then
    return false, "invalid amount"
  end
  local panel = world.ui and world.ui.bottom_panel
  if not panel then return false, "no message panel" end
  local message = {
    {text = S.ask_line:format(from.name, amount)},
    {text = S.ask_balance_line:format(math.floor(from.balance))},
    choices = {
      {text = S.ask_pay:format(amount), choice = "mp_offer_accept"},
      {text = S.ask_decline, choice = "mp_offer_decline"},
    },
    mp_offer = {kind = "money", from = world:getHospitalIndex(from), to = world:getHospitalIndex(to),
        amount = amount, name = "$" .. amount},
  }
  panel:queueMessage("mp_money", message, nil, Date.hoursPerDay() * MultiplayerSession.OFFER_DAYS, 2, nil, to)
  MultiplayerSession.tellPlayer(world, from, S.ask_sent_note:format(amount, to.name))
  return true
end

--! A money request was answered: on "pay", the money moves if it is there.
local function resolve_money(world, offer, from, to, accept)
  local S = _S.multiplayer_window
  local amount = offer.amount or 0
  local outcome
  if not accept then
    outcome = "declined"
    MultiplayerSession.tellPlayer(world, from, S.ask_declined_note:format(to.name, amount))
  elseif to.balance < amount then
    outcome = "no money"
    MultiplayerSession.tellPlayer(world, to, S.ask_no_money_note:format(amount))
    MultiplayerSession.tellPlayer(world, from, S.ask_no_money_asker_note:format(to.name))
  else
    outcome = "paid $" .. amount
    to:spendMoney(amount, S.money_sent:format(from.name))
    from:receiveMoney(amount, S.money_received:format(to.name))
    MultiplayerSession.tellPlayer(world, from, S.money_received_note:format(to.name, amount))
  end
  local session = world.app.mp_session
  if session then
    session.log(string.format("money request of hospital %d to hospital %d: %s", offer.from, offer.to, outcome))
  end
end

--! A research offer was answered: on acceptance the receiver pays and gets
--! what it still lacks of it.
local function resolve_research(world, offer, from, to, accept)
  local S = _S.multiplayer_window
  if not accept then
    MultiplayerSession.tellPlayer(world, from, S.research_declined_note:format(to.name))
    return
  end
  local items = research_items_of(from, to, offer.items)
  local price = offer.price or 0
  local outcome
  if #items == 0 then
    outcome = "known"
    MultiplayerSession.tellPlayer(world, to, S.research_known_note)
    MultiplayerSession.tellPlayer(world, from, S.research_known_sender_note:format(to.name))
  elseif price > 0 and to.balance < price then
    outcome = "no money"
    MultiplayerSession.tellPlayer(world, to, S.research_no_money_note:format(price))
    MultiplayerSession.tellPlayer(world, from, S.research_no_money_sender_note:format(to.name))
  else
    if price > 0 then
      to:spendMoney(price, S.research_bought_transaction:format(from.name))
      from:receiveMoney(price, S.research_sold_transaction:format(to.name))
    end
    for _, item in ipairs(items) do apply_research(world, from, to, item) end
    outcome = #items .. " items for $" .. price
    MultiplayerSession.tellPlayer(world, to, S.research_received_note:format(research_names(items)))
    MultiplayerSession.tellPlayer(world, from, S.research_accepted_note:format(to.name, price))
  end
  local session = world.app.mp_session
  if session then
    session.log(string.format("research offer to hospital %d accepted: %s", offer.to, outcome))
  end
end

--! An offer was answered (or timed out): on every peer, at the same step.
--!param offer (table) the message's mp_offer
function MultiplayerSession.resolveOffer(world, offer, accept)
  local S = _S.multiplayer_window
  local from, to = world.hospitals[offer.from], world.hospitals[offer.to]
  if offer.kind == "research" then
    if from and to then resolve_research(world, offer, from, to, accept) end
    return
  end
  if offer.kind == "money" then
    if from and to then resolve_money(world, offer, from, to, accept) end
    return
  end
  if offer.kind == "plot" then
    if from and to then MultiplayerSession.resolvePlotOffer(world, offer, from, to, accept) end
    return
  end
  local entity = world:getEntityById(offer.entity)
  if entity and entity.mp_offer then entity.mp_offer = nil end
  if not (from and to) then return end
  if not accept then
    MultiplayerSession.tellPlayer(world, from, S.offer_declined_note:format(to.name, offer.name))
    return
  end
  local price = offer.price or 0
  local session = world.app.mp_session
  if price > 0 and to.balance < price then
    MultiplayerSession.tellPlayer(world, to, S.offer_no_money_note:format(price, offer.name))
    MultiplayerSession.tellPlayer(world, from, S.offer_no_money_sender_note:format(to.name, offer.name))
    if session then
      session.log(string.format("offer of %s #%s to hospital %d accepted: no money", offer.kind,
          tostring(offer.entity), offer.to))
    end
    return
  end
  local ok, why = false, "gone"
  if entity and offer.kind == "staff" and class.is(entity, Staff) and entity.hospital == from and
      not entity.fired and not entity.mp_in_transit then
    ok, why = MultiplayerSession.transferStaff(world, from, to, entity)
    if ok and price > 0 then
      to:spendMoney(price, S.staff_bought_transaction:format(from.name))
      from:receiveMoney(price, S.staff_sold_transaction:format(to.name))
    end
  elseif entity and offer.kind == "patient" and class.is(entity, Patient) and entity.hospital == from then
    ok, why = MultiplayerSession.transferPatient(world, from, to, entity)
  end
  if session then
    session.log(string.format("offer of %s #%s to hospital %d accepted: %s", offer.kind,
        tostring(offer.entity), offer.to, ok and ("on the way" .. (price > 0 and (", paid $" .. price) or ""))
        or tostring(why)))
  end
  if ok then
    MultiplayerSession.tellPlayer(world, from, price > 0 and
        S.offer_accepted_price_note:format(to.name, offer.name, price) or
        S.offer_accepted_note:format(to.name, offer.name))
  else
    MultiplayerSession.tellPlayer(world, from, S.offer_gone_note:format(offer.name))
    MultiplayerSession.tellPlayer(world, to, S.offer_gone_note:format(offer.name))
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
--! The most `hospital` may owe the bank (a third of its value and $10000;
--! nothing in free build mode).
function MultiplayerSession.maxLoan(world, hospital)
  if world.free_build_mode then return 0 end
  return math.floor((hospital.value or 0) * 0.33 / 5000) * 5000 + 10000
end

function handlers.loan(world, cmd)
  local hospital = hospital_of(world, cmd)
  local amount = math.floor(tonumber(cmd.amount) or 0)
  if not hospital or amount == 0 then return false, "nothing to do" end
  if amount > 0 then
    if hospital.loan + amount > MultiplayerSession.maxLoan(world, hospital) then return false, "loan limit" end
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

--! Co-op: whose side of the map a plot is on (hospital index): the player
--! whose own land is nearest (centre to centre), the lower index on a tie.
--! Worked out once, from the land owned the first time it is asked (the
--! start of the game), and kept in the world (saved).
--!param peek (table) optional; only look (a screen's question): work it out
--! without keeping it in the world (only the game decides when that is),
--! but in peek.plot_sides, for the screen's next question
function MultiplayerSession.plotSide(world, plot, peek)
  local side = world.mp_plot_side or (peek and peek.plot_sides)
  if not side then
    local th = world.map.th
    local w, h = th:size()
    local plots, own = {}, {}
    local function add(t, k, x, y)
      local c = t[k] or {0, 0, 0}
      c[1], c[2], c[3] = c[1] + x, c[2] + y, c[3] + 1
      t[k] = c
    end
    for y = 1, h do
      for x = 1, w do
        local p = th:getCellFlags(x, y).parcelId
        if p and p ~= 0 then
          add(plots, p, x, y)
          local owner = th:getPlotOwner(p)
          if owner ~= 0 then add(own, owner, x, y) end
        end
      end
    end
    side = {}
    for p, c in pairs(plots) do
      local px, py = c[1] / c[3], c[2] / c[3]
      local best, best_d
      for player = 1, #world.hospitals do
        local o = own[player]
        if o then
          local dx, dy = o[1] / o[3] - px, o[2] / o[3] - py
          local d = dx * dx + dy * dy
          if not best or d < best_d then best, best_d = player, d end
        end
      end
      side[p] = best
    end
    if peek then peek.plot_sides = side else world.mp_plot_side = side end
  end
  return side[plot]
end

--! A player is away (left) or back (rejoined): {seat (hospital index), away (1/0)}.
function handlers.player_away(world, cmd)
  local hospital = world.hospitals[tonumber(cmd.seat) or 0]
  if not hospital or not world.mp_coop then return false, "no such hospital" end
  local away = tonumber(cmd.away) == 1
  if (hospital.mp_player_away or false) == away then return false, "no change" end
  hospital.mp_player_away = away or nil
  local S = _S.multiplayer_window
  if world.mp_coop.players > 1 and (not world.mp_coop.competitive or world.mp_coop.teams) then
    MultiplayerSession.tellOthers(world, hospital,
        (away and S.player_away_note or S.player_back_note):format(hospital.name))
  end
  return true
end

--! Buy a plot of land: {plot}. A plot that borders another hospital's land
--! (or any plot, when the room's owner chose that) goes to auction (see
--! below).
function handlers.buy_plot(world, cmd)
  local hospital = hospital_of(world, cmd)
  if not hospital then return false, "no such hospital" end
  if world.mp_auction then return false, "an auction is on" end
  local plot = tonumber(cmd.plot)
  local bidders = plot and MultiplayerSession.auctionBidders(world, plot, hospital)
  if bidders and #bidders > 1 then
    local price = world.map:getParcelPrice(plot)
    if price > hospital.balance then return false, "not enough money" end
    local auction = MultiplayerSession.startAuction(world, plot, bidders, price)
    cmd.resolved, cmd.no_sound = "auction " .. auction.id, true
    return true
  end
  -- (A plot on another player's side that nobody else may bid for now, its
  -- player away or unable to buy it, is simply bought: before, it was
  -- refused for good, St. Scavengers' plot 16 in a game with an empty seat.)
  local ui = world.ui
  -- purchasePlot gives cost advice through the UI; only to that player.
  local adviser = ui and ui.adviser
  if ui and ui.hospital ~= hospital then ui.adviser = nil end
  local ok = hospital:purchasePlot(tonumber(cmd.plot))
  if ui then ui.adviser = adviser end
  return ok, not ok and "cannot buy this plot" or nil
end

--------------------------------------------------------------------------------
-- Land auctions. A plot on another player's side of the map (plotSide), or
-- one that borders another hospital's land, is not simply bought: it is
-- auctioned among the one who asked, the player whose side it is on and the
-- hospitals whose land borders it (those of them that may buy it). A plot
-- on the asker's own side that no other hospital borders is bought straight
-- away. The room's owner may choose instead that every plot goes to
-- auction among all the hospitals that may buy it (world.mp_coop.
-- auctions_all), or none (auctions_off: whoever asks first buys it).
-- The game stands still during the auction (no game hours,
-- World:_mpHoursForStep); every player sees it (UIMultiplayerAuction).
-- The auction (world.mp_auction) is game state, the same on every peer. It
-- opens at the plot's price, the one who asked leading. Each bid is one step
-- up (auction.step). It is sold when nobody bids for AUCTION_SECONDS (the
-- first bid may take AUCTION_OPEN_SECONDS), or when all the others dropped
-- out. Time is counted in steps on every peer alike, like a speed vote.
-- Bots bid in the game (bots_bid): no command, no waiting. Each bids up to
-- what the plot is worth to it (botPlotWorth): more, the fuller its land.
-- (A bot sharing a person's hospital bids by command while they are away:
-- scripts/multiplayer/bot.lua, Bot:bidAtAuction.)
--------------------------------------------------------------------------------

MultiplayerSession.AUCTION_SECONDS = 6 -- (the original game's gavel takes 5-6 s)
MultiplayerSession.AUCTION_OPEN_SECONDS = 10
local function auction_frames(seconds) return math.ceil(seconds * 1000 / 18) end -- world ticks
-- A bot bids up to this much of the price: the first with plenty of room,
-- the second with its land full (MultiplayerSession.landNeed), at least the
-- third for land it asked for; and keeps this much money (a bot whose land
-- is nearly full, BOT_BORROW_FILL, may borrow for the rest: it takes the loan
-- when it wins, end_auction). On top, each bot
-- wants each plot a little differently (up to BOT_AUCTION_APPETITE more,
-- botAppetite), so that several bots bid against each other: with one
-- worth for all, the first bid (a tenth over the price) was already as far
-- as any other bot would go.
local BOT_AUCTION_LOW, BOT_AUCTION_HIGH, BOT_AUCTION_OWN = 1.3, 2.5, 1.6
local BOT_AUCTION_APPETITE = 0.45
MultiplayerSession.BOT_AUCTION_RESERVE = 5000
-- How full a bot's land is (landFill) when it starts looking for a plot to
-- buy, and when it is willing to borrow for one (at an auction too).
MultiplayerSession.BOT_LAND_FILL = 0.70
MultiplayerSession.BOT_BORROW_FILL = 0.60

--! How full `hospital`'s land is: the share of its indoor floor that rooms
--! take, 0 to 1 (1 with no indoor floor). (Game state only: the same on
--! every peer.)
function MultiplayerSession.landFill(world, hospital)
  local th = world.map.th
  local player = hospital:getPlayerIndex()
  local w, h = th:size()
  local flags = {}
  local inside, rooms = 0, 0
  for y = 1, h do
    for x = 1, w do
      th:getCellFlags(x, y, flags)
      if flags.hospital and flags.owner == player then
        inside = inside + 1
        if (flags.roomId or 0) ~= 0 then rooms = rooms + 1 end
      end
    end
  end
  if inside == 0 then return 1 end
  return rooms / inside
end

--! How badly `hospital` needs more land: 0 (plenty of room) to 1 (full).
--! From the share of its indoor floor that rooms take: up to 45% is
--! plenty, 75% or more is full. (Game state only: the same on every peer.)
function MultiplayerSession.landNeed(world, hospital, fill)
  fill = fill or MultiplayerSession.landFill(world, hospital)
  return math.max(0, math.min(1, (fill - 0.45) / 0.3))
end

--! What bot hospital `i` may spend on a plot beyond its money, keeping its
--! reserve: what it can still borrow, if its land is nearly full
--! (BOT_BORROW_FILL), else nothing. With the fill: borrow, fill.
function MultiplayerSession.botCanBorrow(world, i, fill)
  local hospital = world.hospitals[i]
  fill = fill or MultiplayerSession.landFill(world, hospital)
  if fill < MultiplayerSession.BOT_BORROW_FILL then return 0, fill end
  return math.max(0, MultiplayerSession.maxLoan(world, hospital) - (hospital.loan or 0)), fill
end

--! How much bot hospital `i` wants the auction's plot beyond its need:
--! 0 to 1, from the auction and the hospital only (the same on every peer,
--! no random numbers drawn).
function MultiplayerSession.botAppetite(auction, i)
  return ((auction.id * 7919 + auction.plot * 131 + i * 104729) % 1000) / 999
end

--! The most a bot running hospital `i` would pay for the auction's plot,
--! how badly it needs land (landNeed) and how full its land is (landFill).
function MultiplayerSession.botPlotWorth(world, i, auction)
  local fill = MultiplayerSession.landFill(world, world.hospitals[i])
  local need = MultiplayerSession.landNeed(world, world.hospitals[i], fill)
  local factor = BOT_AUCTION_LOW + (BOT_AUCTION_HIGH - BOT_AUCTION_LOW) * need +
      BOT_AUCTION_APPETITE * MultiplayerSession.botAppetite(auction, i)
  if i == auction.by then factor = math.max(factor, BOT_AUCTION_OWN) end
  return math.floor(auction.price * factor), need, fill
end

-- Which plots touch which (along a tile edge), from the map: the same on
-- every peer, so worked out once per map (not saved).
local plots_touching_cache = setmetatable({}, {__mode = "k"})

--! The plots that touch `plot` (a set).
function MultiplayerSession.plotsTouching(world, plot)
  local th = world.map.th
  local touch = plots_touching_cache[th]
  if not touch then
    touch = {}
    local function link(a, b)
      if a ~= b and a ~= 0 and b ~= 0 then
        touch[a] = touch[a] or {}
        touch[a][b] = true
        touch[b] = touch[b] or {}
        touch[b][a] = true
      end
    end
    local w, h = th:size()
    local flags, above = {}, {}
    for y = 1, h do
      local left
      for x = 1, w do
        local p = th:getCellFlags(x, y, flags).parcelId or 0
        if left then link(left, p) end
        if above[x] then link(above[x], p) end
        above[x], left = p, p
      end
    end
    plots_touching_cache[th] = touch
  end
  return touch[plot] or {}
end

--! Who would bid for `plot` if `hospital` asked to buy it: hospital indices,
--! the asker first, then (by index) every other hospital in the game that
--! may buy it and whose side it is on or whose land borders it (with every
--! plot auctioned: every other hospital that may buy it). Nil: no
--! auction for that plot (one that cannot be bought, a single-player game,
--! free build mode).
--!param peek (table) optional; a screen's question (see plotSide)
--! At most this many bidders (the auction room's picture has four bars): in
--! a game of more hospitals, the one that asks and the others whose
--! hospitals (their starting camera tiles) are nearest the plot.
MultiplayerSession.AUCTION_MAX_BIDDERS = 4

-- Each plot's middle {x, y}, per map (the plots never change).
local plot_middles = setmetatable({}, {__mode = "k"})

local function plotMiddle(th, plot)
  local middles = plot_middles[th]
  if not middles then
    local sums = {}
    local w, h = th:size()
    for y = 1, h do
      for x = 1, w do
        local p = th:getCellFlags(x, y).parcelId
        if p and p ~= 0 then
          local c = sums[p] or {0, 0, 0}
          c[1], c[2], c[3] = c[1] + x, c[2] + y, c[3] + 1
          sums[p] = c
        end
      end
    end
    middles = {}
    for p, c in pairs(sums) do middles[p] = {c[1] / c[3], c[2] / c[3]} end
    plot_middles[th] = middles
  end
  return middles[plot]
end

function MultiplayerSession.auctionBidders(world, plot, hospital, peek)
  local th = world.map.th
  if not world.mp_coop or world.free_build_mode or plot < 1 or plot > th:getPlotCount() or
      not th:isParcelPurchasable(plot, hospital:getPlayerIndex()) then
    return nil
  end
  local me = world:getHospitalIndex(hospital)
  local list = {me}
  -- (The room's owner turned auctions off: whoever asks first buys it.)
  if world.mp_coop.auctions_off then return list end
  local touching = MultiplayerSession.plotsTouching(world, plot)
  local side = MultiplayerSession.plotSide(world, plot, peek)
  for i, other in ipairs(world.hospitals) do
    local player = other:getPlayerIndex()
    if i ~= me and not other.mp_player_away and th:isParcelPurchasable(plot, player) then
      local near = i == side or world.mp_coop.auctions_all
      if not near then
        for q in pairs(touching) do
          if th:getPlotOwner(q) == player then
            near = true
            break
          end
        end
      end
      if near then list[#list + 1] = i end
    end
  end
  local most = MultiplayerSession.AUCTION_MAX_BIDDERS
  local middle = #list > most and plotMiddle(th, plot)
  if middle then
    local function distance(i)
      local cx, cy = th:getCameraTile(world.hospitals[i]:getPlayerIndex())
      return (cx - middle[1]) ^ 2 + (cy - middle[2]) ^ 2
    end
    local others = {}
    for k = 2, #list do others[k - 1] = list[k] end
    table.sort(others, function(a, b)
      local da, db = distance(a), distance(b)
      if da ~= db then return da < db end
      return a < b
    end)
    list = {me}
    for k = 1, most - 1 do list[k + 1] = others[k] end
  end
  return list
end

local function auction_log(text)
  local session = TheApp.mp_session
  if session then session.log(text) end
end

--! `index` bids `amount` (checked by the caller).
local function place_bid(auction, index, amount)
  auction.bid, auction.leader = amount, index
  auction.bids[index] = amount
  auction.frames, auction.limit = 0, auction_frames(MultiplayerSession.AUCTION_SECONDS)
  auction_log(string.format("auction %d: hospital %d bids $%d", auction.id, index, amount))
end

--! Bots' bids: a bot outbid bids again while the next bid is within what
--! the plot is worth to it (worked out once an auction, kept in it) and it
--! keeps its reserve; otherwise it drops out.
local function bots_bid(world, auction)
  local bots = world.mp_coop.bot_hospitals or {}
  local again = true
  while again do
    again = false
    for _, i in ipairs(auction.bidders) do
      if bots[i] and auction.leader ~= i and not auction.out[i] then
        auction.worth = auction.worth or {}
        auction.borrow = auction.borrow or {}
        if not auction.worth[i] then
          local worth, _, fill = MultiplayerSession.botPlotWorth(world, i, auction)
          auction.worth[i] = worth
          auction.borrow[i] = MultiplayerSession.botCanBorrow(world, i, fill)
          auction_log(string.format("auction %d: plot worth $%d to bot hospital %d (land %d%% full, may borrow $%d)",
              auction.id, worth, i, math.floor(fill * 100 + 0.5), auction.borrow[i]))
        end
        local amount = auction.bid + auction.step
        if amount <= auction.worth[i] and world.hospitals[i].balance + (auction.borrow[i] or 0) -
            amount >= MultiplayerSession.BOT_AUCTION_RESERVE then
          place_bid(auction, i, amount)
          again = true
        else
          auction.out[i] = true
        end
      end
    end
  end
end

--! Has everybody but the leader dropped out?
local function auction_decided(auction)
  for _, i in ipairs(auction.bidders) do
    if i ~= auction.leader and not auction.out[i] then return false end
  end
  return true
end

--! The auction ends: the leader buys the plot for the bid (if they still
--! may and can pay).
local function end_auction(world)
  local auction = world.mp_auction
  world.mp_auction = nil
  local winner = world.hospitals[auction.leader]
  local S = _S.multiplayer_window
  local ui = world.ui
  -- A bot that bid with borrowed money borrows it now (in steps of $5000,
  -- keeping its reserve, as far as the bank lets it).
  local borrowed = MultiplayerSession.botBorrow(world, auction.leader, winner, auction.bid)
  if borrowed > 0 then
    auction_log(string.format("auction %d: bot hospital %d borrows $%d", auction.id, auction.leader, borrowed))
  end
  -- (purchasePlot gives cost advice through the UI; only to that player.)
  local adviser = ui and ui.adviser
  if ui and ui.hospital ~= winner then ui.adviser = nil end
  local ok = winner and winner:purchasePlot(auction.plot, auction.bid)
  if ui then ui.adviser = adviser end
  -- (Kept for the auction screen's last moment: who got it.)
  auction.sold, auction.name = ok or false, winner and winner.name
  world.mp_auction_last = auction
  auction_log(string.format("auction %d: plot %d %s", auction.id, auction.plot,
      ok and string.format("sold to hospital %d for $%d", auction.leader, auction.bid) or "not sold"))
  local session = TheApp.mp_session
  if session then
    session.notify(ok and S.auction_sold:format(auction.plot, winner.name, auction.bid) or
        S.auction_not_sold:format(auction.plot))
  end
  if ok and ui and ui.hospital == winner then ui:playSound("cashreg.wav") end
end

--! Open an auction for `plot` (MultiplayerSession.auctionBidders: the
--! asker first). Returns it; if nobody bids against the asker it is sold at
--! once (world.mp_auction is nil again).
function MultiplayerSession.startAuction(world, plot, bidders, price)
  world.mp_auction_seq = (world.mp_auction_seq or 0) + 1
  local step = math.max(100, math.floor(price / 1000 + 0.5) * 100) -- 10%, in hundreds
  local auction = {id = world.mp_auction_seq, plot = plot, price = price, step = step,
      by = bidders[1], bidders = bidders, bids = {}, out = {}, frames = 0,
      limit = auction_frames(MultiplayerSession.AUCTION_OPEN_SECONDS)}
  world.mp_auction = auction
  place_bid(auction, bidders[1], price)
  auction.limit = auction_frames(MultiplayerSession.AUCTION_OPEN_SECONDS)
  auction_log(string.format("auction %d: plot %d for $%d, bidders %s", auction.id, plot, price,
      table.concat(bidders, ",")))
  local asker = world.hospitals[bidders[1]]
  local session = TheApp.mp_session
  if session then session.notify(_S.multiplayer_window.auction_started:format(asker.name, plot)) end
  bots_bid(world, auction)
  if auction_decided(auction) then end_auction(world) end
  return auction
end

--! A bid: {auction, amount} (the current bid and one step: two players
--! bidding at once, the second is turned down).
function handlers.auction_bid(world, cmd)
  local auction = world.mp_auction
  local hospital = hospital_of(world, cmd)
  if not auction or auction.id ~= tonumber(cmd.auction) or not hospital then return false, "the auction is over" end
  local index = world:getHospitalIndex(hospital)
  local bidder = false
  for _, i in ipairs(auction.bidders) do bidder = bidder or i == index end
  if not bidder or auction.out[index] then return false, "not a bidder" end
  if auction.leader == index then return false, "already leading" end
  local amount = tonumber(cmd.amount)
  if amount ~= auction.bid + auction.step then return false, "outbid" end
  if amount > hospital.balance then return false, "not enough money" end
  place_bid(auction, index, amount)
  bots_bid(world, auction)
  if auction_decided(auction) then end_auction(world) end
  return true
end

--! Drop out of the auction: {auction}.
function handlers.auction_pass(world, cmd)
  local auction = world.mp_auction
  local hospital = hospital_of(world, cmd)
  if not auction or auction.id ~= tonumber(cmd.auction) or not hospital then return false, "the auction is over" end
  local index = world:getHospitalIndex(hospital)
  if auction.leader == index or auction.out[index] then return false, "cannot drop out" end
  auction.out[index] = true
  auction_log(string.format("auction %d: hospital %d drops out", auction.id, index))
  if auction_decided(auction) then end_auction(world) end
  return true
end

--! Count the auction's time (after every step's commands, on every peer).
--! A bidder whose player left drops out.
function MultiplayerSession:tickAuction()
  local world = self.world
  local auction = world and world.mp_auction
  if auction then
    for _, i in ipairs(auction.bidders) do
      local hospital = world.hospitals[i]
      if i ~= auction.leader and hospital and hospital.mp_player_away then auction.out[i] = true end
    end
    auction.frames = auction.frames + world:_mpStepFrames(world.mp_speed or "Normal")
    if auction.frames >= auction.limit or auction_decided(auction) then
      end_auction(world)
      self.applied_this_step = true
    end
  end
  self:syncAuction(world)
end

--! Show the auction window while there is an auction (again after a load
--! or a repair), unless this player closed it (then a box to wait in, with
--! the way back); close it after.
function MultiplayerSession:syncAuction(world)
  local ui = world and world.ui
  local class_ = rawget(_G, "UIMultiplayerAuction")
  if self.observer or self.abstains or not ui or not class_ then return end -- (not for bots)
  local auction = world.mp_auction
  local window = ui:getWindow(class_)
  if window and auction and window.auction_id ~= auction.id then
    window:close()
    window = nil
  end
  if auction and not window and self.auction_closed ~= auction.id then
    ui:addWindow(class_(ui))
  elseif window and not auction then
    window:finish() -- the gavel, then it closes
  end
  -- Closed by this player: "Auction in progress, please wait..." and the way
  -- back, until it is over.
  local wait_class = rawget(_G, "UIMultiplayerAuctionWait")
  local waiting = wait_class and ui:getWindow(wait_class)
  if auction and not ui:getWindow(class_) and self.auction_closed == auction.id then
    if not waiting then ui:addWindow(wait_class(ui)) end
  elseif waiting then
    waiting:close()
  end
end

--------------------------------------------------------------------------------
-- Selling a plot back to the bank. A player may undo a purchase at any time,
-- except for their starting plot, once the plot is empty: no room (not one
-- being built either), no object (the walls are the rooms' walls), nobody on
-- it or about to walk over it (people are not moved: the sale is refused
-- until they have gone). Litter and rat holes do not count; they go with the
-- plot. The bank pays back PLOT_SELL_PERCENT of what the plot cost (an
-- auction's price, not the list price; a plot bought before this was kept
-- track of counts at the list price). The plot belongs to nobody then, and
-- can be bought (or auctioned) again. A plot is also refused when the rest
-- of the player's land hangs together with their hospital through it.
--------------------------------------------------------------------------------

MultiplayerSession.PLOT_SELL_PERCENT = 80

-- Each plot's tiles, flat {x1, y1, x2, y2, ...}, per map (the plots never change).
local plot_tile_lists = setmetatable({}, {__mode = "k"})

--! The tiles of a plot, flat {x1, y1, x2, y2, ...}, in map order.
function MultiplayerSession.plotTiles(th, plot)
  local lists = plot_tile_lists[th]
  if not lists then
    lists = {}
    local w, h = th:size()
    local flags = {}
    for y = 1, h do
      for x = 1, w do
        local p = th:getCellFlags(x, y, flags).parcelId
        if p and p ~= 0 then
          local list = lists[p]
          if not list then
            list = {}
            lists[p] = list
          end
          list[#list + 1] = x
          list[#list + 1] = y
        end
      end
    end
    plot_tile_lists[th] = lists
  end
  return lists[plot] or {}
end

--! The tile in the top right corner of a plot (the one furthest that way),
--! for the town map's buttons.
function MultiplayerSession.plotCorner(th, plot)
  local tiles = MultiplayerSession.plotTiles(th, plot)
  local bx, by, best
  for i = 1, #tiles, 2 do
    local score = tiles[i] - tiles[i + 1]
    if not best or score > best then bx, by, best = tiles[i], tiles[i + 1], score end
  end
  return bx, by
end

--! What `plot` cost its owner (kept when it was bought; the list price for
--! land bought before that was kept).
function MultiplayerSession.plotPaid(world, plot)
  local paid = world.mp_plot_paid and world.mp_plot_paid[plot]
  if paid then return paid end
  if world.free_build_mode then return 0 end
  return world.map:getParcelPrice(plot)
end

--! What the bank pays back for `plot`.
function MultiplayerSession.plotRefund(world, plot)
  return math.floor(MultiplayerSession.plotPaid(world, plot) * MultiplayerSession.PLOT_SELL_PERCENT / 100)
end

--! Is `plot` one of the starting plots (every player starts with one)?
function MultiplayerSession.isStartingPlot(world, plot)
  return plot <= world.map.th:getPlayerCount()
end

--! Is there a person on `plot`, or one whose walk crosses it?
local function person_on_plot(world, plot)
  local th = world.map.th
  local flags = {}
  for _, entity in ipairs(world.entities) do
    local queue = entity.action_queue
    if queue and entity.tile_x and entity.tile_y then
      if th:getCellFlags(entity.tile_x, entity.tile_y, flags).parcelId == plot then return true end
      local action = queue[1]
      local path_x = action and action.name == "walk" and action.path_x
      local path_y = action and action.path_y
      if path_x and path_y then
        for i = action.path_index or 1, #path_x do
          if th:getCellFlags(path_x[i], path_y[i], flags).parcelId == plot then return true end
        end
      end
    end
  end
  return false
end

--! Why `plot` is not empty: "plot not empty" (a room, or an object other than
--! litter and rat holes), "people on the plot", or nil when it is empty.
function MultiplayerSession.plotNotEmpty(world, plot)
  local th = world.map.th
  local tiles = MultiplayerSession.plotTiles(th, plot)
  local flags = {}
  for i = 1, #tiles, 2 do
    local x, y = tiles[i], tiles[i + 1]
    if (th:getCellFlags(x, y, flags).roomId or 0) ~= 0 then return "plot not empty" end
    for _, object in ipairs(world:getObjects(x, y) or {}) do
      local id = object.object_type.id
      -- (Litter that cannot be cleaned up stays an object in the way. What
      -- the map put on the plot, the doors of an entrance, belongs to the
      -- land: release_plot takes it along.)
      if id ~= "rathole" and not object.object_type.supports_creation_for_map and
          not (id == "litter" and object:isCleanable()) then
        return "plot not empty"
      end
    end
  end
  -- A room still being built has no room number on its tiles yet.
  for _, room in pairs(world.rooms) do
    for ry = room.y, room.y + room.height - 1 do
      for rx = room.x, room.x + room.width - 1 do
        if th:getCellFlags(rx, ry, flags).parcelId == plot then return "plot not empty" end
      end
    end
  end
  if person_on_plot(world, plot) then return "people on the plot" end
  return nil
end

--! Would the rest of `hospital`'s land still hang together with its
--! starting plot without `plot` (plots joined along an edge)? Land that is
--! cut off from the starting plot already does not count.
local function land_stays_whole(world, hospital, plot)
  local th = world.map.th
  local player = hospital:getPlayerIndex()
  local owned = {}
  for p = 1, th:getPlotCount() do
    if th:getPlotOwner(p) == player then owned[p] = true end
  end
  if not owned[player] then return true end -- (no starting plot to measure from)
  -- How many of the plots reach the starting plot, without `skip`.
  local function reached(skip)
    local seen, queue, n = {[player] = true}, {player}, 1
    local count, next_index = 1, 1
    while next_index <= n do
      local current = queue[next_index]
      next_index = next_index + 1
      for q in pairs(MultiplayerSession.plotsTouching(world, current)) do
        if owned[q] and q ~= skip and not seen[q] then
          seen[q] = true
          count = count + 1
          n = n + 1
          queue[n] = q
        end
      end
    end
    return count, seen
  end
  local before, seen = reached(nil)
  if seen[plot] then before = before - 1 end
  return reached(plot) >= before
end

--! Why `hospital` may not sell or hand over `plot` now, or nil when it may.
--! The reasons: "no such plot", "not your plot", "starting plot", "an auction
--! is on", "plot not empty", "people on the plot", "joins your land".
--!param answering (bool) optional; an offer being answered (an auction going
--! on does not matter then: it would only void the offer)
function MultiplayerSession.plotRefusal(world, hospital, plot, answering)
  local th = world.map.th
  if not plot or plot < 1 or plot > th:getPlotCount() then return "no such plot" end
  if th:getPlotOwner(plot) ~= hospital:getPlayerIndex() then return "not your plot" end
  if MultiplayerSession.isStartingPlot(world, plot) then return "starting plot" end
  if world.mp_auction and not answering then return "an auction is on" end
  local why = MultiplayerSession.plotNotEmpty(world, plot)
  if why then return why end
  if not land_stays_whole(world, hospital, plot) then return "joins your land" end
  return nil
end

--! Take `plot` off `hospital`'s hands: its litter, rat holes and the doors
--! the map gave it (made again for whoever buys or gets the plot next, as
--! when it was first bought: World:setPlotOwner), the handymen who looked
--! after it look after all the land, and the plot belongs to `new_owner`
--! (0: nobody) with the rooms next to it walled in again.
local function release_plot(world, hospital, plot, new_owner)
  local th = world.map.th
  local tiles = MultiplayerSession.plotTiles(th, plot)
  local flags = {}
  for i = 1, #tiles, 2 do
    local litter = {}
    for _, object in ipairs(world:getObjects(tiles[i], tiles[i + 1]) or {}) do
      if object.object_type.id == "litter" then litter[#litter + 1] = object end
    end
    for _, object in ipairs(litter) do object:remove() end
  end
  local doors = {}
  for i = 1, #tiles, 2 do
    for _, object in ipairs(world:getObjects(tiles[i], tiles[i + 1]) or {}) do
      if object.object_type.supports_creation_for_map then doors[#doors + 1] = object end
    end
  end
  world.delayed_map_objects = world.delayed_map_objects or {}
  for _, door in ipairs(doors) do
    -- (As the map file gives them: even numbers face north, odd ones west.)
    world.delayed_map_objects[{door.object_type.id, door.tile_x, door.tile_y, door.direction == "north" and 0 or 1,
        "map object"}] = plot
  end
  for _, door in ipairs(doors) do world:destroyEntity(door) end
  local holes = {}
  for _, hole in ipairs(hospital.ratholes) do
    if th:getCellFlags(hole.x, hole.y, flags).parcelId == plot then holes[#holes + 1] = hole end
  end
  for _, hole in ipairs(holes) do hospital:removeRathole(hole) end
  for i, owned in ipairs(hospital.ownedPlots) do
    if owned == plot then
      table.remove(hospital.ownedPlots, i)
      break
    end
  end
  for _, member in ipairs(hospital.staff) do
    if member.parcelNr == plot then member.parcelNr = 0 end
  end
  world:setPlotOwner(plot, new_owner)
  -- The plot's border tiles and the tiles across it: the engine puts a fence
  -- over the wall of a room that stands next to land of another owner.
  local width, height = th:size()
  local border, seen = {}, {}
  local function add(x, y)
    local key = y * (width + 2) + x
    if not seen[key] then
      seen[key] = true
      border[#border + 1] = {x, y}
    end
  end
  for i = 1, #tiles, 2 do
    local x, y = tiles[i], tiles[i + 1]
    for _, d in ipairs({{-1, 0}, {1, 0}, {0, -1}, {0, 1}}) do
      local nx, ny = x + d[1], y + d[2]
      if nx >= 1 and ny >= 1 and nx <= width and ny <= height and
          th:getCellFlags(nx, ny, flags).parcelId ~= plot then
        add(x, y)
        add(nx, ny)
      end
    end
  end
  world.map:_wallInRooms(border, true)
  th:updatePathfinding()
  if world.ui and world.ui.applyTransparency then world.ui:applyTransparency() end
end

--! Sell a plot back to the bank: {plot}.
function handlers.sell_plot(world, cmd)
  local S = _S.multiplayer_window
  local hospital = hospital_of(world, cmd)
  if not hospital then return false, "no such hospital" end
  local plot = math.floor(tonumber(cmd.plot) or 0)
  local why = MultiplayerSession.plotRefusal(world, hospital, plot)
  if why then return false, why end
  local paid = MultiplayerSession.plotPaid(world, plot)
  local refund = MultiplayerSession.plotRefund(world, plot)
  release_plot(world, hospital, plot, 0)
  if world.mp_plot_paid then world.mp_plot_paid[plot] = nil end
  hospital:receiveMoney(refund, S.plot_sold_transaction:format(plot), paid)
  cmd.resolved = "plot " .. plot .. " for $" .. refund
  MultiplayerSession.tellPlayer(world, hospital, S.plot_sold_note:format(plot, refund))
  if world.mp_coop and world.mp_coop.players > 1 then
    MultiplayerSession.tellOthers(world, hospital, S.plot_sold_others_note:format(hospital.name, plot))
  end
  return true
end

--------------------------------------------------------------------------------
-- Handing a plot to an ally. The owner offers an empty plot (the same rules
-- as for selling it back, and not the starting plot) for a price of $0 to
-- PLOT_MAX_PRICE; the other player gets a fax and accepts or declines it
-- (an offer left alone lapses after OFFER_DAYS: declined). Both games check
-- it again when it is answered: the plot must still be the giver's, empty,
-- and the receiver must be able to pay (a bot takes a loan for it). The plot
-- need not touch the receiver's land: a plot anywhere may be bought (also at
-- an auction), so it may be handed over too (Jan, 2026-11-08; it used to
-- have to touch). The plot keeps its original price: selling it back to the
-- bank pays 80 percent of that, to whoever owns it.
--------------------------------------------------------------------------------

MultiplayerSession.PLOT_MAX_PRICE = 50000
MultiplayerSession.PLOT_PRICE_STEP = 500

--! Why `hospital` may not take `plot`, or nil. Any plot may be handed over,
--! as any may be bought (the giver's side is checked by plotRefusal).
function MultiplayerSession.plotHandoverRefusal(world, hospital, plot)
  if not (hospital and world.map and plot) then return "no such hospital" end
  return nil
end

--! Is a fax offering `plot` still waiting for an answer?
local function plot_offer_pending(world, plot)
  local id = world.mp_plot_offers and world.mp_plot_offers[plot]
  local panel = world.ui and world.ui.bottom_panel
  return id ~= nil and panel ~= nil and panel:findMessageIcon(id) ~= nil
end

--! Offer a plot to an ally: {to, plot, price (0 to PLOT_MAX_PRICE)}.
function handlers.offer_plot(world, cmd)
  local S = _S.multiplayer_window
  local from, to = world.hospitals[cmd.hospital or 1], world.hospitals[cmd.to or 0]
  if not from or not to or from == to then return false, "no such hospital" end
  if not world:mpMayTrade(from, to) or world:mpRivals(from, to) then return false, "not on your team" end
  local price = math.floor(tonumber(cmd.price) or 0)
  if price < 0 or price > MultiplayerSession.PLOT_MAX_PRICE then return false, "invalid price" end
  local plot = math.floor(tonumber(cmd.plot) or 0)
  local why = MultiplayerSession.plotRefusal(world, from, plot)
  if not why then why = MultiplayerSession.plotHandoverRefusal(world, to, plot) end
  if not why and plot_offer_pending(world, plot) then why = "already offered" end
  if why then return false, why end
  local panel = world.ui and world.ui.bottom_panel
  if not panel then return false, "no message panel" end
  local tiles = math.floor(#MultiplayerSession.plotTiles(world.map.th, plot) / 2)
  local message = {
    {text = S.plot_offer_line:format(from.name, plot, tiles)},
    {text = price > 0 and S.plot_offer_price_line:format(price) or S.plot_offer_free_line},
    choices = {
      {text = price > 0 and S.offer_accept_price:format(price) or S.offer_accept, choice = "mp_offer_accept"},
      {text = S.offer_decline, choice = "mp_offer_decline"},
    },
    mp_offer = {kind = "plot", from = world:getHospitalIndex(from), to = world:getHospitalIndex(to),
        plot = plot, price = price > 0 and price or nil, name = "plot " .. plot},
  }
  panel:queueMessage("mp_money", message, nil, Date.hoursPerDay() * MultiplayerSession.OFFER_DAYS, 2, nil, to)
  world.mp_plot_offers = world.mp_plot_offers or {}
  world.mp_plot_offers[plot] = world.next_message_id
  MultiplayerSession.tellPlayer(world, from, price > 0 and S.plot_offer_sent_price_note:format(plot, to.name, price)
      or S.plot_offer_sent_note:format(plot, to.name))
  cmd.resolved = "plot " .. plot .. " for $" .. price
  return true
end

--! A plot offer was answered (or lapsed): on acceptance the plot, and the
--! price if there is one, change hands if all is as it was offered.
function MultiplayerSession.resolvePlotOffer(world, offer, from, to, accept)
  local S = _S.multiplayer_window
  local plot, price = offer.plot, offer.price or 0
  if world.mp_plot_offers then world.mp_plot_offers[plot] = nil end
  local session = world.app.mp_session
  local function log(outcome)
    if session then
      session.log(string.format("offer of plot %s to hospital %d: %s", tostring(plot), offer.to, outcome))
    end
  end
  if not accept then
    log("declined")
    MultiplayerSession.tellPlayer(world, from, S.plot_offer_declined_note:format(to.name, plot))
    return
  end
  local why = MultiplayerSession.plotRefusal(world, from, plot, true)
  if not why then why = MultiplayerSession.plotHandoverRefusal(world, to, plot) end
  if why then
    log("void: " .. why)
    MultiplayerSession.tellPlayer(world, from, S.plot_offer_gone_note:format(plot))
    MultiplayerSession.tellPlayer(world, to, S.plot_offer_gone_note:format(plot))
    return
  end
  -- (A bot borrows what it lacks, as it does at an auction.)
  if price > 0 and to.balance < price then
    MultiplayerSession.botBorrow(world, offer.to, to, price)
  end
  if price > 0 and to.balance < price then
    log("no money")
    MultiplayerSession.tellPlayer(world, to, S.plot_offer_no_money_note:format(price, plot))
    MultiplayerSession.tellPlayer(world, from, S.plot_offer_no_money_sender_note:format(to.name, plot))
    return
  end
  local paid = MultiplayerSession.plotPaid(world, plot)
  release_plot(world, from, plot, to:getPlayerIndex())
  table.insert(to.ownedPlots, plot)
  if not world.free_build_mode then
    -- The plot's worth moves with it.
    from.value = from.value - paid
    to.value = to.value + paid
  end
  if price > 0 then
    to:spendMoney(price, S.plot_bought_transaction:format(from.name, plot))
    from:receiveMoney(price, S.plot_given_transaction:format(to.name, plot))
  end
  log(price > 0 and ("handed over for $" .. price) or "handed over")
  MultiplayerSession.tellPlayer(world, to, S.plot_received_note:format(plot, from.name))
  MultiplayerSession.tellPlayer(world, from, price > 0 and S.plot_offer_accepted_price_note:format(to.name, plot, price)
      or S.plot_offer_accepted_note:format(to.name, plot))
end

--! A bot hospital that must pay `cost` and would be left with less than its
--! reserve borrows the difference (in steps of $5000, as far as the bank
--! lets it). Returns the amount borrowed (0: none). The same on every peer.
function MultiplayerSession.botBorrow(world, index, hospital, cost)
  local bots = world.mp_coop and world.mp_coop.bot_hospitals or {}
  local reserve = MultiplayerSession.BOT_AUCTION_RESERVE
  if not (hospital and bots[index]) or hospital.balance - cost >= reserve then return 0 end
  local short = cost + reserve - hospital.balance
  local room = MultiplayerSession.maxLoan(world, hospital) - hospital.loan
  local amount = math.min(math.ceil(short / 5000) * 5000, math.floor(room / 5000) * 5000)
  if amount <= 0 then return 0 end
  hospital.loan = hospital.loan + amount
  hospital:receiveMoney(amount, _S.transactions.bank_loan)
  return amount
end

--------------------------------------------------------------------------------
-- Holds: the game stands still for everybody (no game hours, as during an
-- auction) while the people read the annual report, or until a win fax is
-- answered. Every peer keeps stepping (World:_mpHoursForStep gives 0 hours),
-- so nobody falls behind. A hold waits for every hospital a person plays
-- (one of its players is enough), not for bots or players who left, and
-- ends after HOLD_SECONDS at the latest.
--------------------------------------------------------------------------------

MultiplayerSession.HOLD_SECONDS = {year = 180, win = 300}

--! Start (or widen) a hold. kind "year" (it ends when each waiting
--! hospital's player closed the report: hold_done) or "win" (it ends when
--! the fax message msg_id is answered: a fax_choice command, so at the same
--! step everywhere); only: just that hospital's player.
function MultiplayerSession.startHold(world, kind, msg_id, only)
  local count = world.mp_coop and world.mp_coop.players or 1
  local bots = world.mp_coop and world.mp_coop.bot_hospitals or {}
  local hold = world.mp_hold
  if not hold then
    world.mp_hold_count = (world.mp_hold_count or 0) + 1
    hold = {id = world.mp_hold_count, kind = kind, waiting = {}, msgs = {}, frames = 0,
        limit = auction_frames(MultiplayerSession.HOLD_SECONDS[kind] or 180)}
  elseif kind == "win" then
    hold.kind = "win" -- (a win fax at the year end: the longer wait, its text)
    hold.limit = math.max(hold.limit, auction_frames(MultiplayerSession.HOLD_SECONDS.win))
  end
  for i = 1, count do
    local h = world.hospitals[i]
    if h and not h.mp_player_away and not bots[i] and (not only or only == i) then hold.waiting[i] = true end
  end
  if msg_id then hold.msgs[#hold.msgs + 1] = msg_id end
  if next(hold.waiting) then world.mp_hold = hold end
  return world.mp_hold
end

--! Seconds until the hold ends by itself (HOLD_SECONDS), counted from the
--! shared step count, so the same on every screen. (A world tick is 18 ms;
--! the time stands still while the game waits for a slow connection.)
function MultiplayerSession.holdSecondsLeft(hold)
  if not (hold and hold.limit and hold.frames) then return 0 end
  return math.max(0, math.ceil((hold.limit - hold.frames) * 18 / 1000))
end

--! This player closed their annual report: {hold}.
function handlers.hold_done(world, cmd)
  local hold, hospital = world.mp_hold, hospital_of(world, cmd)
  if not hold or hold.id ~= tonumber(cmd.hold) or not hospital then return false, "nothing to wait for" end
  hold.waiting[world:getHospitalIndex(hospital)] = nil
  return true
end

--! Count the hold's time and see whether it is over (after every step's
--! commands, on every peer).
function MultiplayerSession:tickHold()
  local world = self.world
  local hold = world and world.mp_hold
  if hold then
    -- (Nobody to wait for in a hospital whose player is away, or that only
    -- bots play now: a hold saved before a game was continued with bots in
    -- people's places waited for them, Jan on eu2.)
    local bots = world.mp_coop and world.mp_coop.bot_hospitals or {}
    for i in pairs(hold.waiting) do
      local h = world.hospitals[i]
      if not h or h.mp_player_away or bots[i] then hold.waiting[i] = nil end
    end
    -- (A win fax: over once it is answered, handlers.fax_choice; not from
    -- the message bar, which is each player's own screen.)
    hold.frames = hold.frames + world:_mpStepFrames(world.mp_speed or "Normal")
    if not next(hold.waiting) or hold.frames >= hold.limit then
      world.mp_hold = nil
      self.applied_this_step = true
      self.log(string.format("hold %d (%s) over", hold.id, hold.kind))
    end
  end
  self:syncHold(world)
end

--! While a hold waits for others (this player's report is closed, or the
--! fax is not theirs): a box saying for whom; closed when it is over.
function MultiplayerSession:syncHold(world)
  local ui = world and world.ui
  local class_ = rawget(_G, "UIMultiplayerHoldWait")
  if self.observer or self.abstains or not ui or not class_ then return end -- (not for bots)
  local hold = world.mp_hold
  -- (Not for oneself only: this player's "done" is on its way.)
  if hold then
    local others = false
    for i in pairs(hold.waiting) do
      if world.hospitals[i] ~= ui.hospital or self.hold_done_sent ~= hold.id then others = true end
    end
    if not others then hold = nil end
  end
  local box = ui:getWindow(class_)
  local report_class, fax_class = rawget(_G, "UIAnnualReport"), rawget(_G, "UIFax")
  local reading = hold and ((report_class and ui:getWindow(report_class)) or (fax_class and ui:getWindow(fax_class)))
  if hold and not reading then
    if not box then ui:addWindow(class_(ui)) end
  elseif box then
    box:close()
  end
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
--! Does `entity` belong to the hospital of the player who sent `cmd`? In
--! co-op every player acts on their own hospital's patients, staff,
--! machines and queues only (they can look at the others').
local function ours(world, cmd, entity)
  if entity.mp_in_transit then return false end -- on the way to another hospital
  local hospital = hospital_of(world, cmd)
  if entity.hospital then return entity.hospital == hospital end
  if entity.tile_x then return hospital:isInHospital(entity.tile_x, entity.tile_y) end
  return false
end

local function entity_of(world, id, klass)
  local entity = world:getEntityById(tonumber(id))
  if entity and (not klass or class.is(entity, klass)) then return entity end
end
MultiplayerSession.entityOf = entity_of

--! Picture only (this machine): hide a member of staff this player picked
--! up, until move_staff runs or the move is cancelled. Nothing in the game
--! reads whether a person is visible; saves show them (lobby _writeLocalSave).
--! Somebody using an object (a doctor at a desk) is drawn together with it,
--! and the object itself is hidden meanwhile: it is shown on its own while
--! they are hidden, else it would vanish with them (Argus).
function MultiplayerSession:hideLocally(staff)
  self.hidden_staff = self.hidden_staff or {}
  if staff.th and not self.hidden_staff[staff] then
    local used = staff.user_of
    used = used and used.th and used or nil
    self.hidden_staff[staff] = {object = used}
    staff.th:makeInvisible()
    if used then used.th:makeVisible() end
  end
end

--! After every step: a hidden member of staff goes on in the shared game,
--! and what they do may show them again (keep them hidden), or move them to
--! another object, or hide the one they use (keep it shown).
function MultiplayerSession:_keepUsedObjectsShown()
  for staff, entry in pairs(self.hidden_staff or {}) do
    if staff.th then staff.th:makeInvisible() end
    local used = staff.user_of
    used = used and used.th and used or nil
    if type(entry) == "table" then entry.object = used end
    if used then used.th:makeVisible() end
  end
end

--! The object a hidden member of staff is still using (shown on its own).
local function shown_object(staff, entry)
  local object = type(entry) == "table" and entry.object
  if object and staff.user_of == object then return object end
end

function MultiplayerSession:showLocally(staff)
  local entry = self.hidden_staff and self.hidden_staff[staff]
  if entry then
    self.hidden_staff[staff] = nil
    if staff.th then staff.th:makeVisible() end
    -- Still at it: the object is drawn with them again.
    local object = shown_object(staff, entry)
    if object then object.th:makeInvisible() end
  end
end

--! Run fn with every locally hidden member of staff shown (for a save).
function MultiplayerSession:withHiddenShown(fn, ...)
  local hidden = {}
  for staff, entry in pairs(self.hidden_staff or {}) do
    hidden[#hidden + 1] = staff
    staff.th:makeVisible()
    local object = shown_object(staff, entry)
    if object then object.th:makeInvisible() end
  end
  local results = {pcall(fn, ...)}
  for _, staff in ipairs(hidden) do
    staff.th:makeInvisible()
    local object = shown_object(staff, self.hidden_staff[staff])
    if object then object.th:makeVisible() end
  end
  if not results[1] then error(results[2], 0) end
  return (table.unpack or unpack)(results, 2)
end

--! Pick up a member of staff and put them down elsewhere: {staff, x, y}.
--! The tile must be one single player's placement window accepts.
function handlers.move_staff(world, cmd)
  local staff = entity_of(world, cmd.staff, Staff)
  -- The player who moves them hid them on their screen; whatever happens
  -- now, the game decides where they are seen (the pick up shows them).
  local session = TheApp and TheApp.mp_session
  if staff and session then session:showLocally(staff) end
  if not staff or not ours(world, cmd, staff) then return false, "not our staff" end
  if staff.fired or staff.pickup or not staff.tile_x or staff.mp_saboteur then
    return false, "cannot move them now"
  end
  local x, y = tonumber(cmd.x), tonumber(cmd.y)
  local check = {world = world, tile_x = x, tile_y = y, ui = {hospital = staff.hospital},
      profile = staff.profile, allow_in_rooms = not staff.profile:isType("Receptionist")}
  if not x or not UIPlaceStaff._isValidStaffPlacement(check) then return false, "invalid position" end
  staff.pickup = true
  local action = PickupAction(world.ui)
  action.mp_place = {x, y}
  staff:setNextAction(action, true)
  return true
end

--! Which plot a handyman looks after: {staff, parcel} (0 = all).
function handlers.handyman_parcel(world, cmd)
  local staff = entity_of(world, cmd.staff, Handyman)
  if staff and not ours(world, cmd, staff) then return false, "not ours" end
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
  if staff and not ours(world, cmd, staff) then return false, "not ours" end
  if not staff or staff.fired or not staff:getAttribute(cmd.attr) then return false, "no such handyman" end
  UIStaff.raiseHandymanPriority(staff, cmd.attr)
  return true
end

--! Longest queue for a room door or reception desk: {owner, size} (0..30).
function handlers.queue_size(world, cmd)
  local owner = entity_of(world, cmd.owner)
  if owner and not ours(world, cmd, owner) then return false, "not ours" end
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
  if patient and not ours(world, cmd, patient) then return false, "not ours" end
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
  if patient and not ours(world, cmd, patient) then return false, "not ours" end
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
  if patient and not ours(world, cmd, patient) then return false, "not ours" end
  if not patient or patient.going_home then return false, "no such patient" end
  patient:setNextAction(SeekReceptionAction())
  return true
end

--! Pay a member of staff a bonus: {staff}.
function handlers.staff_bonus(world, cmd)
  local staff = entity_of(world, cmd.staff, Staff)
  if staff and not ours(world, cmd, staff) then return false, "not ours" end
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
  if staff and not ours(world, cmd, staff) then return false, "not ours" end
  if not staff or staff.fired then return false, "no such staff member" end
  if not staff:increaseWage(math.floor(staff.profile.wage * 0.1)) then return false, "no raise" end
  return true
end

--! Fire a member of staff (staff window, staff management): {staff}.
function handlers.fire_staff(world, cmd)
  local staff = entity_of(world, cmd.staff, Staff)
  if not staff or staff.fired then return false, "no such staff member" end
  if staff.hospital ~= hospital_of(world, cmd) or staff.mp_in_transit then return false, "not our staff" end
  if staff.mp_saboteur then
    -- Competitive: a rival's evil handyman, thrown out (no severance).
    return MultiplayerSession.sabotage.throwOut(world, staff, staff.hospital)
  end
  staff:fire()
  return true
end

--! Answer a pay rise request (pay rise window): {staff, accept (1 or 0), amount}.
--! Like the end of Staff:checkIfWaitedTooLongForRaise, but chosen by the player.
function handlers.pay_rise(world, cmd)
  local staff = entity_of(world, cmd.staff, Staff)
  if not staff or staff.fired or not staff.quitting_in then return false, "no pay rise asked" end
  if staff.hospital ~= hospital_of(world, cmd) then return false, "not our staff" end
  local amount = math.floor(tonumber(cmd.amount) or 0)
  local accept = tonumber(cmd.accept) == 1
  if accept and amount <= 0 then return false, "bad amount" end
  staff.quitting_in = nil
  staff.hospital:removeMessage(staff)
  staff.message_callback = nil
  -- The window may be open on another peer too (it is that peer's view).
  for _, w in ipairs(world.ui:getWindows(UIStaffRise)) do
    if w.staff == staff then w:close() end
  end
  if accept then
    staff.mp_headhunted = nil
    staff:increaseWage(amount)
  elseif staff.mp_headhunted then
    -- Competitive: poached by a rival's headhunter (no severance).
    MultiplayerSession.sabotage.poached(staff)
  else
    staff:fire()
  end
  return true
end

--! Move a patient in a queue (queue window): {owner (door or desk), patient,
--! to ("front", "back" or the slot it was dropped on, from 0)}.
function handlers.queue_move(world, cmd)
  local owner = entity_of(world, cmd.owner)
  local humanoid = entity_of(world, cmd.patient)
  local queue = owner and owner.queue
  if not queue or not humanoid then return false, "no such queue or patient" end
  if humanoid.hospital ~= hospital_of(world, cmd) then return false, "not our patient" end
  local index
  for i = 1, queue:reportedSize() do
    if queue:reportedHumanoid(i) == humanoid then index = i break end
  end
  if not index then return false, "not in this queue any more" end
  local to = cmd.to
  if to ~= "front" and to ~= "back" then
    to = math.floor(tonumber(to) or -1)
    if to < 0 then return false, "bad position" end
    to = math.min(to, queue:reportedSize() - 1)
  end
  queue:movePatient(index, to)
  return true
end

--! Send a patient to another room of the same kind (dragged from the queue
--! window onto the room): {patient, room (room id)}.
function handlers.queue_redirect(world, cmd)
  local humanoid = entity_of(world, cmd.patient)
  local room = world.rooms[math.floor(tonumber(cmd.room) or -1)]
  if not humanoid or not room or humanoid.going_home then return false, "no such patient or room" end
  if humanoid.hospital ~= hospital_of(world, cmd) or room.hospital ~= humanoid.hospital then
    return false, "not our patient or room"
  end
  if not UIQueue.canSendToRoom(humanoid, room) then return false, "not that room" end
  UIQueue.sendToRoom(humanoid, room)
  return true
end

--! Ask a handyman to repair a machine now: {machine}.
function handlers.call_handyman(world, cmd)
  local machine = entity_of(world, cmd.machine, Machine)
  if machine and not ours(world, cmd, machine) then return false, "not ours" end
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
  if machine and not ours(world, cmd, machine) then return false, "not ours" end
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
  -- Co-op: rats in another player's hospital are theirs to shoot.
  if not ours(world, cmd, rat) then return false, "not ours" end
  -- Level 7 pays a bounty for a rat sent by a rival (a dirty trick).
  local bounty = world.map.level_config.mp_rat_bounty
  if bounty and rat.mp_attack_rat and rat.hospital then
    rat.hospital:receiveMoney(bounty, _S.multiplayer_window.level7_rat_bounty)
  end
  rat:shoot()
  return true
end

--! Clear away a room destroyed by an exploding machine (the single player
--! "remove destroyed rooms" option, always there in multiplayer): {room,
--! rebuild}. With rebuild=1 the player who asked then gets the room editor
--! for the same kind of room, its outline where the old one was.
function handlers.remove_crashed_room(world, cmd)
  local room = world.rooms[tonumber(cmd.room)]
  if not room or not room.crashed then return false, "no such room" end
  local hospital = hospital_of(world, cmd)
  if room.hospital ~= hospital then return false, "not ours" end
  -- repair=1: no clearing fee; the room is built again where it was (same
  -- door and windows) by a build_room command, at the price of a new one.
  local repair
  if tonumber(cmd.repair) == 1 then
    repair = corsixth.require("mp_room_builder").repairCommand(world, room)
    if not repair then return false, "cannot repair this room" end
    local progress = hospital.research.research_progress[room.room_info]
    if not world.free_build_mode and hospital.balance < progress.build_cost then
      return false, "not enough money"
    end
  end
  local cost = repair and 0 or room:calculateRemovalCost()
  -- Soot can only be removed with the option on (Litter:remove); it must
  -- not depend on each player's own setting.
  local config = TheApp.config
  local saved = config.remove_destroyed_rooms
  config.remove_destroyed_rooms = true
  local ok, err = pcall(UIEditRoom.removeRoom, UIEditRoom, false, room, world)
  config.remove_destroyed_rooms = saved
  if not ok then error(err, 0) end
  world:resetSideObjects()
  world.rooms[room.id] = nil
  if cost ~= 0 then hospital:spendMoney(cost, _S.transactions.remove_room) end
  local session = TheApp.mp_session
  if repair then
    if session and cmd.peer == session.peer_id and not session.observer then
      repair.hospital = world:getHospitalIndex(hospital)
      session:issue(repair)
    end
    return true
  end
  local ui = world.ui
  if tonumber(cmd.rebuild) == 1 and session and cmd.peer == session.peer_id and not session.observer
      and ui and not ui:getWindow(UIEditRoom) then
    local fullscreen = ui:getWindow(UIFullscreen)
    if fullscreen then fullscreen:close() end
    local dlg = UIEditRoom(ui, room.room_info)
    ui:addWindow(dlg)
    dlg:setBlueprintRect(room.x, room.y, room.width, room.height)
  end
  return true
end

--! Mark an infected patient for vaccination during an epidemic: {patient}.
function handlers.mark_vaccinate(world, cmd)
  local patient = entity_of(world, cmd.patient, Patient)
  if patient and not ours(world, cmd, patient) then return false, "not ours" end
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

--! Hire a member of staff from the hospital's hiring list (World:staffPool):
--! {category, index, key, x, y}. `index` is the position the issuing player
--! saw; if the list changed since (a player sharing the hospital hired), the
--! first profile with the same key is used.
function handlers.hire(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  local pool = world:staffPool(hospital)[cmd.category] or {}
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
  local reserved = MultiplayerSession.sabotage.hireRefusal(world, hospital, pool[index])
  if reserved then return false, reserved end
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

-- Competitive dirty tricks (handlers.sabotage and the evil handyman).
MultiplayerSession.sabotage = corsixth.require("mp_sabotage")
