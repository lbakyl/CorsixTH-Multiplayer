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

--! Client side of the multiplayer relay and lobby server (mp_server/).
--!
--! Keeps the connection, the room list and the state of the room we are in,
--! and starts the game when the server says so: same seed, level and
--! gameplay settings for everybody, then a MultiplayerSession that talks
--! through the same connection. Protocol: docs/multiplayer/protocol.md.
--!
--! The lobby is stored on the App (TheApp.mp_lobby), never in a save game.

class "MultiplayerLobby"

---@type MultiplayerLobby
local MultiplayerLobby = _G["MultiplayerLobby"]

MultiplayerLobby.PROTOCOL = 1
MultiplayerLobby.DEFAULT_PORT = 47800

-- Game speeds from slowest to fastest (World tick_rates); the server allows
-- speeds up to the room's max_speed.
MultiplayerLobby.SPEEDS = {"Slowest", "Slower", "Normal", "Max speed", "And then some more"}

--! The speed to ask the server for: "Pause", or `speed` capped at `max_speed`.
function MultiplayerLobby.clampSpeed(speed, max_speed)
  if speed == "Pause" then return speed end
  local rank, max_rank = nil, nil
  for i, s in ipairs(MultiplayerLobby.SPEEDS) do
    if s == speed then rank = i end
    if s == max_speed then max_rank = i end
  end
  if not rank then return max_speed or "Normal" end
  if max_rank and rank > max_rank then return max_speed end
  return speed
end

local function encode_value(v)
  if v == true then v = 1 elseif v == false then v = 0 end
  return (tostring(v):gsub("[%%%s=]", function(c) return string.format("%%%02X", c:byte()) end))
end

local function decode_value(v)
  return (v:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

--! Build one protocol line: verb plus fields in sorted key order.
function MultiplayerLobby.encode(verb, fields)
  local keys = {}
  for k in pairs(fields or {}) do keys[#keys + 1] = k end
  table.sort(keys)
  local parts = {verb}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. "=" .. encode_value(fields[k])
  end
  return table.concat(parts, " ")
end

--! Split a protocol line into its verb and fields (values stay strings).
function MultiplayerLobby.decode(line)
  local verb, rest = line:match("^(%S+) ?(.*)$")
  if not verb then return nil end
  local fields = {}
  for k, v in rest:gmatch("([%w_]+)=(%S*)") do
    fields[k] = decode_value(v)
  end
  return verb, fields
end

--! Split "host:port" (port optional).
function MultiplayerLobby.parseAddress(address)
  address = (address or ""):match("^%s*(.-)%s*$")
  local host, port = address:match("^%[(.+)%]:(%d+)$")
  if not host then host, port = address:match("^([^:]+):(%d+)$") end
  if not host then host = address end
  port = tonumber(port) or MultiplayerLobby.DEFAULT_PORT
  if host == "" then return nil end
  return host, port
end

--! Identity of this game build: version, savegame version, Lua runtime and a
--! checksum of all Lua game code (line endings ignored, so a Windows and a
--! Linux install of the same code match). Players must have the same build,
--! or their simulations would drift apart.
function MultiplayerLobby.buildId(app)
  app = app or TheApp
  if MultiplayerLobby.cached_build then return MultiplayerLobby.cached_build end
  local lfs = require("lfs")
  local TH = require("TH")
  local root = app:getFullPath({"Lua"}, true)
  local files = {}
  local function walk(dir, rel)
    for name in lfs.dir(dir) do
      if name ~= "." and name ~= ".." then
        local path = dir .. name
        local mode = lfs.attributes(path, "mode")
        if mode == "directory" then
          walk(path .. package.config:sub(1, 1), rel .. name .. "/")
        elseif name:match("%.lua$") then
          files[#files + 1] = {rel .. name, path}
        end
      end
    end
  end
  walk(root, "")
  table.sort(files, function(a, b) return a[1] < b[1] end)
  local parts = {}
  for _, f in ipairs(files) do
    local fh = io.open(f[2], "rb")
    if fh then
      parts[#parts + 1] = f[1] .. "\0" .. fh:read("*a"):gsub("\r", "")
      fh:close()
    end
  end
  local runtime = rawget(_G, "jit") and "luajit" or _VERSION:gsub("Lua ", "lua")
  -- The language matters too: random staff names are picked from its lists,
  -- whose lengths decide how much randomness is used.
  local language = tostring(app.config.language or "?"):gsub("%W", ""):lower()
  local build = string.format("%s-sv%d-%s-mp%d-%s-%08x", app:getReleaseString(),
      app.savegame_version, runtime, MultiplayerLobby.PROTOCOL, language,
      TH.CRC32File(table.concat(parts, "\0")))
  MultiplayerLobby.cached_build = build
  return build
end

--!param params (table) Fields:
--!  transport (table)    object with :send(line), :receive() -> line or nil, :close()
--!  name      (string)   player name
--!  build     (string)   build id (default MultiplayerLobby.buildId())
--!  address   (string)   "host:port", for display
--!  log       (function) optional message logger
function MultiplayerLobby:MultiplayerLobby(params)
  self.transport = params.transport
  self.name = params.name
  self.build = params.build or MultiplayerLobby.buildId()
  self.address = params.address or ""
  self.log = params.log or function() end
  self.state = "connecting" -- connecting | connected | in_room | in_game | closed
  self.rooms = {}           -- from the last LIST
  self.rooms_pending = {}
  self.room = nil           -- JOINED fields
  self.players = {}         -- peer -> PLAYER fields, current room
  self.players_pending = {}
  self.summary = nil        -- LOBBY fields
  self.ready = false
  self.error = nil          -- last ERROR {code, text}
  self.chat = {}
  self.version = 0          -- incremented whenever something visible changes
  self.listeners = {}
  self.transport:send(MultiplayerLobby.encode("HELLO",
      {proto = MultiplayerLobby.PROTOCOL, build = self.build, name = self.name}))
end

--! Connect to a server. Blocks for at most `timeout` seconds.
--!return lobby, or nil and an error message
function MultiplayerLobby.connect(address, name, timeout)
  corsixth.require("mp_transport")
  if not MultiplayerTransport.available() then
    return nil, "LuaSocket is not available in this build"
  end
  local host, port = MultiplayerLobby.parseAddress(address)
  if not host then return nil, "No server address" end
  local transport, err = MultiplayerTransport.join(host, port, timeout or 5)
  if not transport then return nil, tostring(err) end
  return MultiplayerLobby({transport = transport, name = name,
      address = host .. ":" .. port, log = print})
end

--! Register function(lobby, event, fields) called on every change.
function MultiplayerLobby:addListener(fn)
  self.listeners[#self.listeners + 1] = fn
end

function MultiplayerLobby:_changed(event, fields)
  self.version = self.version + 1
  for _, fn in ipairs(self.listeners) do fn(self, event, fields) end
end

function MultiplayerLobby:send(verb, fields)
  self.transport:send(MultiplayerLobby.encode(verb, fields))
end

--! Read and handle everything that has arrived. Before the game starts the
--! lobby reads the connection itself; during the game the session does and
--! hands the server's messages to handleLine().
function MultiplayerLobby:poll()
  if self.state == "in_game" or self.state == "closed" then return end
  while true do
    local line = self.transport:receive()
    if not line then break end
    self:handleLine(line)
    if self.state == "in_game" then break end -- the session reads from now on
  end
  if self.transport.closed and self.state ~= "closed" then
    self.state = "closed"
    self.error = self.error or {code = "closed", text = "Connection to the server lost"}
    self:_changed("closed")
  end
end

function MultiplayerLobby:handleLine(line)
  local verb, f = MultiplayerLobby.decode(line)
  if not verb then return end
  local handler = self["_on" .. verb]
  if handler then
    handler(self, f)
  else
    self.log("multiplayer: ignoring " .. verb)
  end
end

-- Requests ------------------------------------------------------------------

function MultiplayerLobby:refreshRooms() self:send("LIST") end

--!param opts (table) room, password, max, mode, level, difficulty, speed_control
function MultiplayerLobby:createRoom(opts)
  self.error = nil
  self:send("CREATE", opts)
end

function MultiplayerLobby:joinRoom(room, password)
  self.error = nil
  self:send("JOIN", {room = room, password = password or ""})
end

function MultiplayerLobby:setReady(ready)
  self.ready = ready
  self:send("READY", {ready = ready})
end

function MultiplayerLobby:startGame() self.error = nil; self:send("START") end
function MultiplayerLobby:sendChat(text) self:send("CHAT", {text = text}) end

function MultiplayerLobby:leaveRoom()
  self:send("LEAVE")
  self.room, self.players, self.summary, self.ready = nil, {}, nil, false
  self.state = "connected"
  self:_changed("left_room")
  self:refreshRooms()
end

function MultiplayerLobby:isOwner()
  return self.room ~= nil and self.room.owner == "1"
end

--! Close the connection (and end a running multiplayer game's session).
function MultiplayerLobby:disconnect()
  if self.state ~= "closed" then
    pcall(function() self:send("QUIT") end)
    self.transport:close()
  end
  self.state = "closed"
  self:_endSession()
  if TheApp and TheApp.mp_lobby == self then TheApp.mp_lobby = nil end
end

-- Server messages -------------------------------------------------------------

function MultiplayerLobby:_onWELCOME(f)
  self.state = "connected"
  self.player_id = tonumber(f.id)
  self.motd = f.motd
  self:_changed("connected", f)
  self:refreshRooms()
end

function MultiplayerLobby:_onERROR(f)
  self.error = f
  self.log("multiplayer server: " .. tostring(f.code) .. ": " .. tostring(f.text))
  if self.state == "connecting" then
    self.state = "closed"
    self.transport:close()
  end
  self:_changed("error", f)
end

function MultiplayerLobby:_onPING(f) self:send("PONG", {id = f.id}) end
function MultiplayerLobby:_onPONG() end

function MultiplayerLobby:_onROOM(f)
  self.rooms_pending[#self.rooms_pending + 1] = f
end

function MultiplayerLobby:_onROOMS_END()
  self.rooms, self.rooms_pending = self.rooms_pending, {}
  self:_changed("rooms")
end

function MultiplayerLobby:_onJOINED(f)
  self.room = f
  self.state = "in_room"
  self.players, self.players_pending = {}, {}
  self.ready = false
  self:_changed("joined", f)
end

function MultiplayerLobby:_onOWNER()
  if self.room then self.room.owner = "1" end
  self:_changed("owner")
end

function MultiplayerLobby:_onPLAYER(f)
  self.players_pending[tonumber(f.peer)] = f
end

function MultiplayerLobby:_onLOBBY(f)
  self.players, self.players_pending = self.players_pending, {}
  self.summary = f
  self:_changed("lobby", f)
end

function MultiplayerLobby:_onCHAT(f)
  self.chat[#self.chat + 1] = f
  if #self.chat > 20 then table.remove(self.chat, 1) end
  local session = TheApp and TheApp.mp_session
  if session and session.lobby == self then
    session.notify((f.name or "?") .. ": " .. (f.text or ""))
  end
  self:_changed("chat", f)
end

function MultiplayerLobby:_onSTART(f)
  self.start_params = f
  self.state = "in_game"
  self:_changed("start", f)
  local ok, err = pcall(self._beginGame, self, f)
  if not ok then
    self.log("multiplayer: could not start the game: " .. tostring(err))
    self.error = {code = "start_failed", text = tostring(err)}
    self:disconnect()
    self:_changed("error", self.error)
  end
end

function MultiplayerLobby:_onSPEED(f)
  local world = TheApp and TheApp.world
  if world and TheApp.mp_session and TheApp.mp_session.lobby == self then
    world:applySharedSpeed(f.speed)
    if f.peer ~= tostring(self.start_params and self.start_params.peer) then
      local what = f.speed == "Pause" and "paused the game" or ("set the speed to " .. f.speed)
      TheApp.mp_session.notify((f.name or "A player") .. " " .. what .. ".")
    end
  end
end

function MultiplayerLobby:_onLEFT(f)
  local session = TheApp and TheApp.mp_session
  if session and session.lobby == self then
    session:removePeer(tonumber(f.peer))
    session.notify((f.name or "A player") .. " has left the game.")
  end
end

function MultiplayerLobby:_onSHOW(f)
  local session = TheApp and TheApp.mp_session
  if not (session and session.lobby == self) then return end
  if f.kind == "blueprint" then
    session:showRemoteBlueprint(tonumber(f.peer), {room = f.room, x = tonumber(f.x) or 0,
        y = tonumber(f.y) or 0, w = tonumber(f.w) or 0, h = tonumber(f.h) or 0})
  end
end

function MultiplayerLobby:_onDESYNC(f)
  local session = TheApp and TheApp.mp_session
  if session and session.lobby == self then
    session:serverDesync(tonumber(f.step))
  end
end

-- Starting and ending the game ------------------------------------------------

--! The original multiplayer level for a co-op room: LEVEL.L<players><n>
--! with NET<players><n>.SAM, n = room level 1..5 -> 0..4.
function MultiplayerLobby.coopLevelId(players, level)
  players = math.max(2, math.min(4, players))
  return string.format("net%d%d", players, ((tonumber(level) or 1) - 1) % 5)
end

--! Load the agreed level and attach a lockstep session to it.
function MultiplayerLobby:_beginGame(f)
  local app = TheApp
  local peers = {}
  for p in (f.peers or ""):gmatch("%d+") do peers[#peers + 1] = tonumber(p) end
  -- Gameplay settings come from the server so every peer simulates the
  -- same rules (handover README, lesson 4). Restored when the game ends.
  self.saved_config = {
    grant_wage_increase = app.config.grant_wage_increase,
    free_build_mode = app.config.free_build_mode,
  }
  app.config.grant_wage_increase = f.grant_wage_increase == "1"
  app.config.free_build_mode = f.free_build_mode == "1"

  local coop = f.mode == "coop"
  local my_index = 1
  if coop then
    -- One hospital per player, in peer order; this machine runs its own.
    local names = {}
    for i, p in ipairs(peers) do
      local player = self.players[p]
      names[i] = (player and player.name or ("Player " .. p)):upper()
      if p == tonumber(f.peer) then my_index = i end
    end
    app.mp_coop = {players = #peers, local_index = my_index, names = names}
  end

  math.randomseed(tonumber(f.seed))
  local level = tonumber(f.level) or 1
  local level_id = coop and MultiplayerLobby.coopLevelId(#peers, level) or level
  local loaded = app:loadLevel(level_id, f.difficulty or "full", nil, nil, nil, nil,
      _S.errors.load_level_prefix, nil)
  app.mp_coop = nil
  if not loaded or not app.world then
    error("level " .. tostring(level_id) .. " could not be loaded")
  end
  local world = app.world
  local lobby = self
  local session = MultiplayerSession({
    world = world,
    peer_id = tonumber(f.peer),
    peers = peers,
    transport = self.transport,
    delay = tonumber(f.delay) or 2,
    log = function(msg) lobby.log("multiplayer: " .. msg) end,
    notify = function(msg)
      if world.ui and world.ui.adviser then
        world.ui.adviser:say({text = msg, priority = 10})
      end
    end,
    control = function(line) lobby:handleLine(line) end,
    send_cosmetic = function(fields) lobby:send("SHOW", fields) end,
    request_speed = function(speed)
      lobby:send("SPEED", {speed = MultiplayerLobby.clampSpeed(speed, f.max_speed)})
    end,
  })
  session.lobby = self
  session.max_speed = f.max_speed
  session.hospital_index = my_index
  app.mp_session = session
  if coop and world.ui and world.ui.menu_bar then
    local ui = world.ui
    world.ui.menu_bar:addMenu(_S.multiplayer_window.menu_caption, UIMenu()
      :appendItem(_S.multiplayer_window.menu_trade, function()
        ui:addWindow(UIMultiplayerTrade(ui))
      end))
  end
  world:applySharedSpeed(f.speed or "Normal")
  self.log(string.format("multiplayer: playing as %s of %s, seed %s, delay %s, max speed %s",
      f.peer, f.peers, f.seed, f.delay, tostring(f.max_speed)))
end

--! Called when the game world goes away (level lost, back to the main menu).
function MultiplayerLobby:_endSession()
  local app = TheApp
  if app and app.mp_session and app.mp_session.lobby == self then
    app.mp_session = nil
  end
  if self.saved_config and app then
    for k, v in pairs(self.saved_config) do app.config[k] = v end
    self.saved_config = nil
  end
end

function MultiplayerLobby:worldExited()
  if self.state == "in_game" then
    self:_endSession()
    self:disconnect()
  end
end
