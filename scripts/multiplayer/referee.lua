-- Headless referee for one multiplayer room (milestone S3). The server
-- (mp_server) starts it when a room's game starts:
--   corsix-th --interpreter=<this file> --config-file=<generated>
-- It connects to the server as the room's referee, plays the same game as
-- the players (same seed, level, settings and commands) without a screen and
-- without ever issuing a command, and reports a fingerprint for every game
-- hour. The players never wait for it. The server compares the players'
-- fingerprints with the referee's; on a desync, or when a player rejoins, the
-- server asks the referee for a save that everybody loads.
--
-- Environment (set by the server):
--   CORSIXTH_SOURCE      checkout root
--   MP_SERVER            server address host:port
--   MP_REFEREE_ROOM      room name
--   MP_REFEREE_TOKEN     token the server gave this referee
--   MP_LUA_CPATH, MP_LUA_PATH  where to find LuaSocket (if not standard)
local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local server = assert(os.getenv("MP_SERVER"), "Missing MP_SERVER")
local room = assert(os.getenv("MP_REFEREE_ROOM"), "Missing MP_REFEREE_ROOM")
local token = assert(os.getenv("MP_REFEREE_TOKEN"), "Missing MP_REFEREE_TOKEN")

if os.getenv("MP_LUA_CPATH") then package.cpath = os.getenv("MP_LUA_CPATH") .. ";" .. package.cpath end
if os.getenv("MP_LUA_PATH") then package.path = os.getenv("MP_LUA_PATH") .. ";" .. package.path end

local function log(msg)
  io.stdout:write("[referee " .. room .. "] " .. msg .. "\n")
  io.stdout:flush()
end

local function run()
  assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
  assert(TheApp.good_install_folder, "Game data was not accepted")
  local socket = require("socket")
  corsixth.require("mp_lobby")

  local lobby, err = MultiplayerLobby.connect(server, "referee", 10,
      {role = "referee", room = room, token = token})
  assert(lobby, "cannot connect: " .. tostring(err))
  lobby.log = log
  log("connected as " .. lobby.build)

  -- Wait for the server's START (the game data and level load here).
  local deadline = socket.gettime() + 30
  while lobby.state ~= "in_game" do
    lobby:poll()
    if lobby.state == "closed" then error("server closed the connection: " ..
        tostring(lobby.error and lobby.error.text)) end
    if socket.gettime() > deadline then error("no START from the server") end
    socket.sleep(0.01)
  end
  log("game started")
  -- Tests only: the probes set up their hospitals the same way on every
  -- peer before the first step; the referee must do it too.
  local probe_spec = os.getenv("MP_REFEREE_PROBE_SCENARIO") -- "room=scenario;..."
  -- (A continued game has no world until its save arrives, and was set up
  -- before it was saved.)
  if probe_spec and TheApp.world then
    local probe_scenario = "light"
    for r, sc in probe_spec:gmatch("([^;=]+)=([^;]+)") do
      if r == room then probe_scenario = sc end
    end
    local builder = assert(loadfile(source_dir .. "/scripts/multiplayer/probe_builder.lua"))()
    if probe_scenario == "none" then
      builder.register_handlers() -- (as lobby_probe.lua does: no setup, test commands only)
    else
      builder.start_game(TheApp.world, TheApp.mp_session, probe_scenario, log)
    end
    log("probe setup: " .. probe_scenario)
  end

  local last_report = socket.gettime()
  while lobby.state == "in_game" and not lobby.transport.closed do
    local session = TheApp.mp_session
    if not session then break end
    -- A continued game: no world until the host's save arrives (the session
    -- is held until then); App:onTick reads the network and loads it.
    if not TheApp.world and not session.held then break end
    -- Always run as fast as the lockstep allows; the players set the pace.
    if TheApp.world and not TheApp.world:isCurrentSpeed("And then some more") and not session.held then
      TheApp.world:setSpeed("And then some more")
    end
    local before = session.step
    TheApp:onTick()
    -- The annual report window would pause this game; close it at once.
    local report = TheApp.world and TheApp.ui:getWindow(UIAnnualReport)
    if report then report:close() end
    if session.step == before then socket.sleep(0.002) end
    if socket.gettime() - last_report > 60 then
      last_report = socket.gettime()
      log("at step " .. session.step)
    end
  end
  log("game over (" .. tostring(lobby.state) .. ")")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  io.stderr:flush()
  os.exit(1)
end
os.exit(0)
