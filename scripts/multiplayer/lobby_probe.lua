-- Multiplayer through the relay server (mp_server/), driven like a player:
-- main menu -> Multiplayer -> connect -> create or join a room -> ready ->
-- start, then lockstep play with actions through the real game windows.
-- Run through the CorsixTH executable with --interpreter=<this file>.
--
-- Environment:
--   CORSIXTH_SOURCE   checkout root (required)
--   MP_ROLE           host (creates the room and starts) | join
--   MP_SERVER         server address host:port          (default 127.0.0.1:47800)
--   MP_NAME           player name
--   MP_ROOM, MP_PASSWORD  room to create or join         (default probe / secret)
--   MP_JOIN_PASSWORD  password the joiner types (default MP_PASSWORD)
--   MP_PLAYERS        players the host waits for         (default 2)
--   MP_COOP           1: the host creates a co-op room (a hospital each)
--   MP_ADD_BOTS       the host clicks this many empty places in the room to
--                     add bots (the server must run them)
--   MP_MODE           the room mode the host picks: shared, coop or competitive
--   MP_SCENARIO       light | busy | none                (default light; none: no
--                     test setup, to join a game a person hosts)
--   MP_STEPS          game hours to play                 (default 1500)
--   MP_FAST           1: one lockstep step per tick, whatever the speed (test
--                     only, default 1); 0: steps at the game's own pace
--   MP_REALTIME       1: tick every 18 ms like the real game (default: as fast
--                     as possible)
--   MP_UI_SCRIPT      ";"-separated "hour:action[:arg]":
--                       buy:<object>, hire:<class>      as in ingame_probe.lua; hire:Doctor:surgeon for a skill
--                       room:<id>:<w>:<h>[:window]      draw a room in the room editor
--                       crowdroom:<id>:<w>:<h>          draw it where somebody stands
--                       vip[:<hospital>]                make a VIP visit fax appear for
--                                                       a hospital (test-only command)
--                       emergency[:<hospital>]          an emergency fax for a hospital
--                                                       (test-only command)
--                       answerfax:<type>:<n>            open the first fax of <type> and
--                                                       click choice <n> in the fax window
--                       openhospital                    click the opening watch's button
--                       edge:top|right                  scroll to that edge of the map, screenshot
--                       key:<name>                      press a key (return, escape, ...)
--                       furnishall:<gap>                every room this hospital can build, by hand
--                       openfax:<type>                  open the first fax of a type, leave it open
--                       staffsend                       staff management: send the first doctor
--                       rebuildcrashed                  clear a destroyed room away and build it again
--                       buyinroom:<object>:<room>       buy an object, put it into such a room
--                       researchlists                   log the share list for each other player
--                       buyunder:<object>               buy an object, put it where someone stands
--                       givemoney:<amount>              co-op trade window: send money
--                       sendstaff:<class>               co-op trade window: send the first
--                                                       member of staff of that class
--                       loan                            bank manager: borrow $5,000
--                       priceup                         casebook: raise the first price by 1%
--                       research:<area>                 research window: -1% for an area
--                       heatup                          town map: radiators one step warmer
--                       bonus:<class>, raise:<class>    staff management: bonus or 10% raise
--                                                       for the first member of staff of <class>
--                       sendhome                        patient window: send this hospital's
--                                                       first patient home
--                       pause[:<ticks>]                 press P (shared through the server),
--                                                       optionally <ticks> later; works
--                                                       while the game is paused
--                       unpause[:<ticks>]               P again, <ticks> after the shared
--                                                       pause has arrived here
--                       speed:<name>                    choose a speed in the menu
--                       quit                            close the connection and stop
--                       cheat                           change money locally only (must desync)
--                       furnishroom:<id>:<w>:<h>        draw a room and place its furniture
--                                                       by hand, one object at a time
--                       cancelroom:<id>:<w>:<h>         draw a room, cancel while furnishing
--                       editroom:<id>:<steps>           edit a room (see builder.edit_tick)
--   MP_FURNISH_PACE   game hours between furnishing steps (default 0)
--   MP_CONTINUE       host: create the room continuing a saved multiplayer
--                     game (its label, or "latest"); UI action mpsave saves one
--   MP_UI_COMMANDS    optional file; every line added to it while the game
--                     runs is done at once, as "action[:arg]" (the actions above),
--                     to direct a scripted player during a game with a person
--   MP_DRAW_EVERY     draw a frame every N ticks (0 = never)
--   MP_SHOT_DIR       if set, save screenshots (PNG) of the lobby views and of
--                     moments in the game there, named <player>-<what>.png;
--                     the UI script action shot:<what> takes one more
--   MP_LUA_CPATH, MP_LUA_PATH  where to find LuaSocket
local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local role = assert(os.getenv("MP_ROLE"), "Missing MP_ROLE")
local server = os.getenv("MP_SERVER") or "127.0.0.1:47800"
local name = os.getenv("MP_NAME") or role
local room = os.getenv("MP_ROOM") or "probe"
local password = os.getenv("MP_PASSWORD") or "secret"
local join_password = os.getenv("MP_JOIN_PASSWORD") or password
local want_players = tonumber(os.getenv("MP_PLAYERS") or "2")
local scenario = os.getenv("MP_SCENARIO") or "light"
-- Seconds without progress before giving up (default 20, 30 while paused);
-- longer when playing with a person, who may pause or read a fax.
local stall_limit = tonumber(os.getenv("MP_STALL_LIMIT") or "")
local target = tonumber(os.getenv("MP_STEPS") or "1500")
local fast = (os.getenv("MP_FAST") or "1") == "1"
local draw_every = tonumber(os.getenv("MP_DRAW_EVERY") or "0")
local coop = os.getenv("MP_COOP") == "1"
local room_mode = os.getenv("MP_MODE") or (coop and "coop" or "shared")
local shot_dir = os.getenv("MP_SHOT_DIR")
-- With the server's referee a desync is repaired: keep playing through it.
local expect_repair = os.getenv("MP_EXPECT_REPAIR") == "1"
-- Join a running game again (this name left it earlier).
local rejoin = os.getenv("MP_REJOIN") == "1"
-- MP_AUTO_ROOMS=1: a joining player types the password first and never
-- clicks Refresh; the room list must show the room by itself.
local auto_rooms = os.getenv("MP_AUTO_ROOMS") == "1"

local function log(msg)
  io.stdout:write("[" .. name .. "] " .. msg .. "\n")
  io.stdout:flush()
end

if os.getenv("MP_LUA_CPATH") then package.cpath = os.getenv("MP_LUA_CPATH") .. ";" .. package.cpath end
if os.getenv("MP_LUA_PATH") then package.path = os.getenv("MP_LUA_PATH") .. ";" .. package.path end

local builder = assert(loadfile(source_dir .. "/scripts/multiplayer/probe_builder.lua"))()

local ui_script = {}
local commands_file = os.getenv("MP_UI_COMMANDS")
-- Game hours to wait between the steps of furnishing a room (for a person
-- watching; default none).
local furnish_pace = tonumber(os.getenv("MP_FURNISH_PACE") or "")
-- MP_HOVER=1: while furnishing a room by hand, move the object picture over
-- the room every tick, as a player's mouse does (other objects, facings).
local hover = os.getenv("MP_HOVER") == "1"
local hover_n = 0
local commands_seen = 0
if commands_file then
  -- Only lines added from now on count.
  local f = io.open(commands_file, "r")
  if f then for _ in f:lines() do commands_seen = commands_seen + 1 end f:close() end
end
for entry in (os.getenv("MP_UI_SCRIPT") or ""):gmatch("[^;]+") do
  local hour, action, arg = entry:match("^(%d+):(%w+):?(.*)$")
  ui_script[#ui_script + 1] = {hour = tonumber(hour), action = action, arg = arg}
end

local socket

-- MP_REALTIME=1: tick every 18 ms like the real game (SDL timer), not as
-- fast as possible.
local realtime = os.getenv("MP_REALTIME") == "1"
local next_tick
local function tick()
  if realtime then
    local now = socket.gettime()
    if next_tick and now < next_tick then socket.sleep(next_tick - now) end
    next_tick = math.max(now, next_tick or now) + 0.018
  end
  TheApp:onTick()
end

-- Tick the menus until cond() is true (or fail after `seconds`).
local function wait_for(what, cond, seconds)
  local deadline = socket.gettime() + (seconds or 20)
  while not cond() do
    if socket.gettime() > deadline then error("timed out waiting for " .. what) end
    tick()
    socket.sleep(0.01)
  end
end

local function lobby_window()
  return TheApp.ui:getWindow(UIMultiplayer)
end

local shots_taken = {}
local filming -- see the "film" action
local held_room -- see the "holdroom" action
local held_user -- see the "holduser" action
--! Draw a frame and save it as <shot_dir>/<name>-<what>.png (once per what).
local function shot(what)
  if not shot_dir or shots_taken[what] then return end
  shots_taken[what] = true
  -- In the game, close information popups so the map is visible.
  if TheApp.world then
    for i = #TheApp.ui.windows, 1, -1 do
      local win = TheApp.ui.windows[i]
      if class.is(win, UIInformation) then win:close() end
    end
  end
  TheApp:drawFrame()
  local path = shot_dir .. "/" .. name .. "-" .. what .. ".png"
  local ok, err = TheApp.video:takeScreenshot(path)
  log(ok and ("SHOT " .. path) or ("SHOT FAILED " .. tostring(err)))
end

--! Centre the game view on a map tile.
local function look_at(tx, ty)
  local ui = TheApp.ui
  local x, y = TheApp.map:WorldToScreen(tx, ty)
  ui:scrollMapTo(x, y)
end

local function run_lobby()
  local menu = assert(TheApp.ui:getWindow(UIMainMenu), "no main menu")
  shot("main-menu")
  menu:buttonMultiplayer()
  -- Closing the lobby window brings the main menu back.
  assert(lobby_window(), "no multiplayer window"):close()
  menu = assert(TheApp.ui:getWindow(UIMainMenu), "no main menu after closing the lobby window")
  menu:buttonMultiplayer()
  local w = assert(lobby_window(), "no multiplayer window")
  w.address_box:setText(server)
  w.name_box:setText(name)
  shot("lobby-connect")
  local clicked = socket.gettime()
  w:buttonConnect()
  log(string.format("UI: the connect click took %d ms", math.floor((socket.gettime() - clicked) * 1000)))
  wait_for("the connection", function() return TheApp.mp_lobby or not w.connecting end)
  local lobby = assert(TheApp.mp_lobby, "not connected: " .. tostring(w.status_text))
  log("connected as " .. lobby.build)
  wait_for("room list", function() return lobby.state == "connected" and lobby_window() and lobby_window().view == "rooms" end)

  if role == "host" then
    w = lobby_window()
    w.room_name_box:setText(room)
    w.password_box:setText(password)
    for _ = 1, 3 do -- "A hospital each", "Competitive race"
      if w.new_mode ~= room_mode then w:buttonMode() end
    end
    for _ = 2, tonumber(os.getenv("MP_LEVEL") or 1) do w:buttonLevel() end
    -- Room size: MP_PLAYERS (2 to 4).
    for _ = 1, 3 do
      if (w.new_max or 2) ~= math.max(2, math.min(4, want_players)) then w:buttonMax() end
    end
    if os.getenv("MP_CONTINUE") then
      local save = w:selectContinue(os.getenv("MP_CONTINUE"))
      log("continuing saved game " .. tostring(save and save.label))
    end
    shot("lobby-create")
    w:buttonCreate()
    wait_for("own room", function() return lobby.state == "in_room" end)
    log("created room " .. room)
    -- Bots: click the first empty place, once per bot, as a person would.
    local add_bots = tonumber(os.getenv("MP_ADD_BOTS") or "0")
    for k = 1, add_bots do
      local win = lobby_window()
      local labels = {}
      for i = 1, 4 do labels[i] = (tostring(win.player_panels[i].label or ""):gsub("^<LocalisedString> Current value:%s*", "")) end
      local empty
      for i = 1, tonumber(lobby.room.max) or 2 do
        if not empty and not lobby.players[i] and labels[i]:find("add a bot", 1, true) then empty = i end
      end
      log(string.format("UI: room places before bot %d: %s", k, table.concat(labels, " | ")))
      if not empty then error("no empty place to click for a bot") end
      win:clickPlace(empty)
      wait_for("bot " .. k .. " starting", function()
        local n = 0
        for _ in pairs(lobby.players) do n = n + 1 end
        return n + (tonumber(lobby.summary and lobby.summary.starting) or 0) >= 1 + k
      end, 10)
    end
    if add_bots > 0 then
      wait_for("bots joined", function()
        local bots = 0
        for _, p in pairs(lobby.players) do if p.bot == "1" and p.ready == "1" then bots = bots + 1 end end
        return bots >= add_bots
      end, 60)
      local win, labels = lobby_window(), {}
      for i = 1, 4 do labels[i] = (tostring(win.player_panels[i].label or ""):gsub("^<LocalisedString> Current value:%s*", "")) end
      log("UI: room places with the bots: " .. table.concat(labels, " | "))
    end
    wait_for("players", function()
      local n, ready = 0, true
      for peer, p in pairs(lobby.players) do
        n = n + 1
        if peer ~= 1 and p.ready ~= "1" then ready = false end
      end
      return n >= want_players and ready and lobby.summary ~= nil
    end, 60)
    shot("lobby-room-host")
    log(string.format("lobby: %d players, recommended speed %s, delay %s, one way %s ms",
        want_players, lobby.summary.speed, lobby.summary.delay, lobby.summary.one_way))
    for peer, p in pairs(lobby.players) do log(string.format("  player %d %s rtt %s ms", peer, p.name, p.rtt)) end
    wait_for("game start", function()
      local win = lobby_window()
      if win and win.view == "room" and lobby.state == "in_room" then win:buttonStart() end
      return lobby.state == "in_game"
    end)
  else
    local index
    if auto_rooms then
      lobby_window().password_box:setText(join_password)
      local since = socket.gettime()
      wait_for("room " .. room .. " in the list", function()
        local win = lobby_window()
        for i, r in ipairs(lobby.rooms) do
          if r.room == room and win and (win.rooms_shown or ""):find(room, 1, true) then index = i return true end
        end
        return false
      end, 30)
      log(string.format("UI: the room list showed '%s' without Refresh after %.1f s; password kept: %s", room,
          socket.gettime() - since, tostring(lobby_window().password_box.text == join_password)))
    else
      wait_for("room " .. room, function()
        for i, r in ipairs(lobby.rooms) do
          if r.room == room then index = i return true end
        end
        lobby:refreshRooms()
        socket.sleep(0.2)
        return false
      end, 30)
    end
    w = lobby_window()
    shot("lobby-rooms")
    w:selectRoom(index, true)
    if not auto_rooms then w.password_box:setText(join_password) end
    w:buttonJoin()
    wait_for("joining", function()
      return lobby.state == "in_room" or lobby.state == "in_game" or lobby.error ~= nil
    end)
    if lobby.state ~= "in_room" and lobby.state ~= "in_game" then
      log("JOIN REFUSED: " .. tostring(lobby.error.code))
      return nil
    end
    log("joined room " .. room .. " as player " .. lobby.room.peer)
    if rejoin then
      wait_for("game start", function() return lobby.state == "in_game" end, 30)
      return lobby
    end
    wait_for("ready button", function() return lobby_window() and lobby_window().view == "room" end)
    lobby_window():buttonReady(true)
    wait_for("lobby update", function() return lobby.summary ~= nil end, 10)
    shot("lobby-room-joined")
    wait_for("game start", function() return lobby.state == "in_game" end, 60)
  end
  return lobby
end

local probe_started, game_started
local function run()
  assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
  assert(TheApp.good_install_folder, "Game data was not accepted")
  socket = require("socket")
  probe_started = socket.gettime()

  local lobby = run_lobby()
  if not lobby then log("PROBE: DONE") return end
  local session = assert(TheApp.mp_session, "no session after start")
  game_started = socket.gettime() - probe_started
  -- Chat lines that reach this player go into the log.
  lobby:addListener(function(_, event, f)
    if event == "chat" then
      log(string.format("CHAT IN at step %d: %s%s: %s", TheApp.mp_session and TheApp.mp_session.step or -1,
          tostring(f.name), f.to and " (private)" or "", tostring(f.text)))
      -- The colour of its bar in the chat lines (the sender's).
      local window = TheApp.ui and TheApp.ui:getWindow(UIMultiplayerChat)
      local line = window and window.lines[#window.lines]
      if line and line.colour then
        log(string.format("CHAT COLOUR: %s %s", tostring(f.name), table.concat(line.colour, ",")))
      end
    end
  end)
  -- MP_TRACE_HIT=1: log who turns clicks on the map on or off.
  if os.getenv("MP_TRACE_HIT") == "1" and not GameUI.mp_probe_set_hit then
    GameUI.mp_probe_set_hit = GameUI.setWorldHitTest
    GameUI.setWorldHitTest = function(ui, mode)
      log("HITTEST " .. tostring(mode) .. " at step " .. tostring(TheApp.mp_session and TheApp.mp_session.step)
          .. " " .. debug.traceback("", 2))
      return GameUI.mp_probe_set_hit(ui, mode)
    end
  end
  -- What the adviser tells this player goes into the log too.
  if Audio.playOwnAnnouncement and not Audio.mp_probe_announce then
    Audio.mp_probe_announce = Audio.playOwnAnnouncement
    Audio.playOwnAnnouncement = function(audio, path, ...)
      local handle = Audio.mp_probe_announce(audio, path, ...)
      log(string.format("ANNOUNCED: %s (sound %s, handle %s)", path:match("[^/\\]+$"),
          tostring(audio.own_sounds and audio.own_sounds[path]), tostring(handle)))
      return handle
    end
  end
  if not UIAdviser.mp_probe_say then
    UIAdviser.mp_probe_say = UIAdviser.say
    UIAdviser.say = function(adviser, speech, ...)
      local text = type(speech) == "table" and speech.text or speech
      log("ADVISER: " .. (tostring(text):gsub("^<LocalisedString> Current value:", "")))
      return UIAdviser.mp_probe_say(adviser, speech, ...)
    end
  end
  local world = TheApp.world
  local p = lobby.start_params
  log(string.format("START: peer %s of %s, seed %s, delay %s, max speed %s, speed %s",
      p.peer, p.peers, p.seed, p.delay, p.max_speed, p.speed))

  local desk_x, desk_y
  if rejoin or p.resume == "1" then
    -- The game comes with the shared save everybody loads (rejoining, or a
    -- saved game continued).
    builder.register_handlers()
    wait_for("the shared save", function() return (session.restarts or 0) > 0 end, 60)
    world = TheApp.world
    if world.mp_coop then builder.hospital = world.ui.hospital end
    log(string.format("%s: loaded the shared save at step %d; playing %s (hospital %d): %s",
        rejoin and "REJOINED" or "LOADED", session.step, tostring(world.ui.hospital.name),
        world:getHospitalIndex(world.ui.hospital), MultiplayerSession.defaultFingerprint(world)))
    -- Rejoining: MP_STEPS steps from here (the others' steps went on while
    -- this player was away, also while their game was paused).
    if rejoin then target = session.step + target end
  elseif scenario == "none" then
    -- Playing with a person: their game has no test setup, so neither has this.
    builder.register_handlers()
    if world.mp_coop then builder.hospital = world.ui.hospital end -- this player's own
  else
    -- The same test setup runs on every peer (and on the server's referee).
    desk_x, desk_y = builder.start_game(world, session, scenario, log)
  end
  -- MP_LOG_EVENTS=1: log the level's events as they happen (emergencies,
  -- epidemic patients) and each month's state of every hospital. Logging
  -- only, on this peer: nothing in the game changes.
  if os.getenv("MP_LOG_EVENTS") == "1" then
    local function where(hosp)
      return string.format("%s hospital %d", world.game_date:tostring(), world:getHospitalIndex(hosp))
    end
    local create, add = Hospital.createEmergency, Hospital.addToEpidemic
    Hospital.createEmergency = function(hosp, e, ...)
      local failed = create(hosp, e, ...)
      log(string.format("EVENT: emergency %s: %s x%s %s", where(hosp), e and e.disease.id or "random",
          tostring(e and e.victims), failed or "started"))
      return failed
    end
    Hospital.addToEpidemic = function(hosp, patient, ...)
      log(string.format("EVENT: epidemic patient %s: %s", where(hosp), patient.disease.id))
      return add(hosp, patient, ...)
    end
    local end_month = World.onEndMonth
    World.onEndMonth = function(w, ...)
      local parts = {}
      for h = 1, w.mp_coop.players do
        local hosp = w.hospitals[h]
        local rats = 0
        for _, e in ipairs(w.entities) do
          if class.is(e, Rat) and e.hospital == hosp then rats = rats + 1 end
        end
        parts[#parts + 1] = string.format("%d: rep %d rats %d epidemic %s cured %d died %d", h, hosp.reputation,
            rats, hosp.epidemic and hosp.epidemic.disease.id or "-", hosp.num_cured, hosp.num_deaths)
      end
      log("EVENT: month end " .. w.game_date:tostring() .. "; " .. table.concat(parts, "; "))
      return end_month(w, ...)
    end
  end
  -- Test runs: one lockstep step per tick, whatever the shared speed (a
  -- player's own speed setting does not change a multiplayer game).
  if fast then session.unpaced, session.steps_per_tick = true, 1 end
  -- A scripted player agrees to every speed vote (MP_VOTE=no declines,
  -- MP_VOTE=ask shows the fax, answered by the votefax action).
  local vote_mode = os.getenv("MP_VOTE") or "yes"
  session.auto_agree = vote_mode ~= "ask" and vote_mode or nil
  if desk_x then look_at(desk_x, desk_y) end
  shot("game-start")

  local done = {}
  local ticks = 0
  local last_progress = socket.gettime()
  local quit = false
  local speed_seen = {}
  local seen_blueprints = {}
  local editor_seen = "none"
  local presses = {} -- {wait = ticks, paused = only count while paused}
  local last_speed = world:getCurrentSpeed()
  local repairs = session.restarts or 0
  local waiting_rejoin -- restarts seen when the "waitrejoin" pause began
  local furnishing -- state of a room being furnished by hand (furnishroom)
  local last_transfer_log
  local editing -- state of a room being edited (editroom)
  local holding -- a window that pauses this game, open for some seconds (holdpause)
  local monkey -- random clicks all over the screen, like a small child (monkey)
  while session.step < target and (expect_repair or not session.desync) and not quit do
    local before = session.step
    -- This player's view before the tick (a repair during it must keep it).
    local view_before = world.ui.getScreenOffset and {world.ui:getScreenOffset()} or {}
    tick()
    ticks = ticks + 1
    if waiting_rejoin and session.step > before then
      -- The game steps on while paused (so the unpause can arrive): while
      -- waiting for the rejoin, those steps count neither towards the end
      -- nor for the rest of the UI script.
      local made = session.step - before
      target = target + made
      for k, e in ipairs(ui_script) do
        if not done[k] then e.hour = e.hour + made end
      end
    end
    if (session.restarts or 0) > repairs then
      -- Desync repaired: everybody loaded the referee's game.
      repairs = session.restarts
      world = TheApp.world
      if world.mp_coop then builder.hospital = world.ui.hospital end
      if fast then world:setSpeed("And then some more") end
      -- The message icons on this player's bar (type@hospital).
      local shown = {}
      for _, icon in ipairs(world.ui.bottom_panel and world.ui.bottom_panel.message_windows or {}) do
        shown[#shown + 1] = string.format("%s@%s", tostring(icon.type),
            tostring(icon.hospital and world:getHospitalIndex(icon.hospital)))
      end
      -- And the countdowns (watches) on the screen (type@hospital).
      local watches = {}
      for _, win in ipairs(world.ui.windows or {}) do
        if class.is(win, UIWatch) then
          watches[#watches + 1] = string.format("%s@%s", tostring(win.count_type),
              tostring(win.hospital and world:getHospitalIndex(win.hospital)))
        end
      end
      -- Information popups left open (the referee's level introduction must
      -- not pop up again) and whether the view stayed where it was.
      local popups = 0
      for _, win in ipairs(world.ui.windows or {}) do
        if class.is(win, UIInformation) then popups = popups + 1 end
      end
      local vx, vy = world.ui:getScreenOffset()
      log(string.format("REPAIRED: loaded the shared save at step %d (repair %d); popups %d; view kept %s; messages shown: %s; watches: %s",
          session.step, repairs, popups, tostring(vx == view_before[1] and vy == view_before[2]),
          table.concat(shown, ","), table.concat(watches, ",")))
    end
    if TheApp.world ~= world then log("LEVEL ENDED at step " .. session.step) break end
    -- The room editor on this screen: each change of its phase, and whether
    -- its window is up.
    -- (A new room's editor is a window; a room's being furnished or edited
    -- is ui.edit_room too, also while hidden.)
    local ed_window = world.ui:getWindow(UIEditRoom)
    local ed = ed_window or (class.is(world.ui.edit_room, UIEditRoom) and world.ui.edit_room)
    local ed_now = "none"
    if ed then
      ed_now = tostring(ed.phase) .. (ed_window and " (window up)" or " (no window)")
    end
    if ed_now ~= editor_seen then
      editor_seen = ed_now
      log(string.format("UI: room editor %s at step %d", ed_now, session.step))
    end
    for peer, r in pairs(session.remote_blueprints) do
      local key = string.format("%d:%s:%d,%d", peer, tostring(r.room), r.x, r.y)
      if peer ~= session.peer_id and not seen_blueprints[key] then
        seen_blueprints[key] = true
        look_at(r.x + math.floor(r.w / 2), r.y + math.floor(r.h / 2))
        shot("reserved-outline")
        log(string.format("saw reserved area of player %d: %s at %d,%d size %dx%d (step %d)",
            peer, tostring(r.room), r.x, r.y, r.w, r.h, session.step))
      end
    end
    local now_speed = world:getCurrentSpeed()
    if now_speed ~= last_speed then
      speed_seen[#speed_seen + 1] = now_speed
      log("speed is now " .. tostring(now_speed) .. " at step " .. session.step)
      last_speed = now_speed
      -- Test runs go fast locally again after a shared unpause.
      if fast and now_speed ~= "Pause" and now_speed ~= "And then some more" then
        world:setSpeed("And then some more")
        last_speed = world:getCurrentSpeed()
      end
    end
    if waiting_rejoin and (session.restarts or 0) > waiting_rejoin and not session.held then
      waiting_rejoin = nil
      log("UI: a player rejoined; unpausing at step " .. session.step)
      world:setUserSpeed("Max speed")
    end
    if furnishing and builder.furnish_tick(world, furnishing, log) then furnishing = nil end
    local editor = hover and world.ui.edit_room
    if editor and class.is(editor, UIEditRoom) and editor.phase == "objects" and #editor.objects > 0 then
      local rect = editor.blueprint_rect
      local keep_index, keep_orientation = editor.active_index, editor.object_orientation
      local keep_x, keep_y = editor.object_cell_x, editor.object_cell_y
      for _ = 1, 6 do
        hover_n = hover_n + 1
        local index = hover_n % #editor.objects + 1
        editor:setActiveIndex(index)
        local object = editor.objects[index] and editor.objects[index].object
        local facings = {}
        for facing in pairs(object and object.orientations or {}) do facings[#facings + 1] = facing end
        table.sort(facings)
        if #facings > 0 then editor:setOrientation(facings[hover_n % #facings + 1]) end
        local tx = rect.x + (hover_n * 7) % math.max(1, rect.w)
        local ty = rect.y + (hover_n * 3) % math.max(1, rect.h)
        editor:setBlueprintCell(tx, ty)
      end
      if editor.objects[keep_index] then editor:setActiveIndex(keep_index) end
      if keep_orientation and editor.objects[editor.active_index] and
          editor.objects[editor.active_index].object.orientations[keep_orientation] then
        editor:setOrientation(keep_orientation)
      end
      editor:setBlueprintCell(keep_x, keep_y)
    end
    if os.getenv("MP_DEBUG_TRANSFERS") and session.step % 100 == 0 and session.step ~= last_transfer_log then
      last_transfer_log = session.step
      for _, e in ipairs(world.mp_transfers or {}) do
        local act = e:getCurrentAction()
        local t = e.mp_in_transit
        log(string.format("TRANSFER #%d %s at %s,%s action %s target %s,%s queue %d", e.mp_id, e.humanoid_class,
            tostring(e.tile_x), tostring(e.tile_y), act and act.name or "-", t and t.x or "-", t and t.y or "-",
            #e.action_queue))
      end
    end
    if editing and not furnishing and builder.edit_tick(world, editing, log) then editing = nil end
    if monkey and ticks % 3 == 0 then
      -- Its own random numbers (the game's must not change): a fixed seed.
      monkey.state = (monkey.state * 1103515245 + 12345) % 2147483648
      local r = monkey.state
      local sw, sh = TheApp.video:getRenderSize()
      local sx, sy = r % sw, math.floor(r / sw) % sh
      local button = (math.floor(r / 7) % 4 == 0) and 3 or 1
      local ok, err = pcall(function()
        world.ui:onMouseMove(sx, sy, 0, 0)
        world.ui:onMouseDown(button, sx, sy)
        world.ui:onMouseUp(button, sx, sy)
      end)
      monkey.n = monkey.n + 1
      if not ok then log("UI: monkey click error: " .. tostring(err)) end
      if monkey.n >= monkey.total then
        log(string.format("UI: monkey done after %d clicks at step %d; windows: %s", monkey.n, session.step,
            (function() local t = {} for _, w in ipairs(world.ui.windows) do t[#t + 1] = class.type(w) or "?" end return table.concat(t, ",") end)()))
        monkey = nil
      end
    end
    if holding and socket.gettime() >= holding.until_time then
      log(string.format("UI: closed the question at step %d", session.step))
      holding.win:close()
      holding = nil
    end
    -- In a person's game: once everybody else has left, leave too, so the
    -- room closes instead of running on with nobody watching.
    if scenario == "none" and not quit and #session.peers <= 1 then
      log("UI: the other players left; leaving too at step " .. session.step)
      quit = true
    end
    if draw_every > 0 and ticks % draw_every == 0 then TheApp:drawFrame() end
    local report = TheApp.ui:getWindow(UIAnnualReport)
    if report then report:close() end
    for i = #presses, 1, -1 do
      local press = presses[i]
      -- An unpause only counts down once the shared pause has arrived.
      if not press.paused or world:isCurrentSpeed("Pause") then press.wait = press.wait - 1 end
      if press.wait <= 0 then
        table.remove(presses, i)
        log("UI: pressed P at step " .. session.step .. (world:isCurrentSpeed("Pause") and " (paused)" or ""))
        world:pauseOrUnpause()
      end
    end
    -- Live instructions: new lines in the MP_UI_COMMANDS file, done now.
    if commands_file and ticks % 25 == 0 then
      local f = io.open(commands_file, "r")
      if f then
        local n = 0
        for line in f:lines() do
          n = n + 1
          if n > commands_seen and line:match("%S") then
            local action, arg = line:match("^%s*(%w+):?(.-)%s*$")
            if action then
              ui_script[#ui_script + 1] = {hour = session.step, action = action, arg = arg, live = true}
              log(string.format("UI: live instruction %q at step %d", line, session.step))
            end
          end
        end
        commands_seen = math.max(commands_seen, n)
        f:close()
      end
    end
    -- Joining a person's game: the anchor for room and object searches is
    -- their reception desk (or the first tile of this hospital).
    if not desk_x and #ui_script > 0 then desk_x, desk_y = builder.anchor(world) end
    -- "holduser": while held, the object stays seen; then cancel the move.
    if held_user and session.step % 5 == 0 then
      local st, obj = held_user.staff, held_user.object
      local now = st.user_of
      log(string.format("UI: held %s at step %d: person seen %s, using %s, seen %s", st.humanoid_class,
          session.step, tostring(st.th:isVisible()), now and now.object_type.id or "nothing",
          tostring((now or obj).th:isVisible())))
      if session.step >= held_user.until_step then
        local win = world.ui:getWindow(UIPlaceStaff)
        if win then win:close() end
        log(string.format("UI: put back at step %d: person seen %s, using %s, its object seen %s",
            session.step, tostring(st.th:isVisible()), st.user_of and st.user_of.object_type.id or "nothing",
            st.user_of and tostring(st.user_of.th:isVisible()) or "-"))
        held_user = nil
      end
    end
    -- "holdroom": count, every 20 steps, how much of the held room's floor
    -- is still blue (Argus: parts of a blueprint disappear into the floor).
    if held_room and session.step % 20 == 0 then
      local blue, th = 0, world.map.th
      for ty = held_room.y, held_room.y + held_room.h - 1 do
        for tx = held_room.x, held_room.x + held_room.w - 1 do
          if th:getCell(tx, ty, 4) == 24 then blue = blue + 1 end
        end
      end
      log(string.format("UI: held blueprint blue %d of %d at step %d (editor %s)", blue,
          held_room.w * held_room.h, session.step, tostring(held_room.dlg.phase)))
    end
    -- "film": follow one walking person with the camera and take a
    -- screenshot every step (frames for a clip of the player colours).
    if filming and filming.left > 0 then
      local e = filming.who
      if e and e.tile_x then
        local x, y = TheApp.map:WorldToScreen(e.tile_x, e.tile_y)
        local px, py = e.th:getPosition()
        world.ui:scrollMapTo(x + px, y + py)
      end
      filming.n = filming.n + 1
      shot(string.format("film-%03d", filming.n))
      filming.left = filming.left - 1
    end
    for i, entry in ipairs(ui_script) do
      if not done[i] and session.step >= entry.hour then
        done[i] = true
        local a, live = entry.action, entry.live
        if a == "buy" then builder.ui_buy(world, desk_x, desk_y, entry.arg, log)
        elseif a == "openhospital" then
          local watch
          for _, win in ipairs(world.ui.windows) do
            if class.is(win, UIWatch) and win.count_type == "initial_opening" then watch = win end
          end
          if watch then
            log("UI: clicked the opening watch at step " .. session.step)
            watch:buttonEndCountdown()
          else
            log("UI: no opening watch")
          end
        elseif a == "givemoney" then
          local trade = UIMultiplayerTrade(world.ui)
          world.ui:addWindow(trade)
          shot("trade-window")
          log(string.format("UI: sent $%s to %s at step %d", entry.arg, trade.target.name, session.step))
          trade:sendMoney(tonumber(entry.arg))
          trade:close()
        elseif a == "acceptoffer" or a == "declineoffer" then
          -- Open the purple offer icon and answer it in its window.
          local icon
          for _, candidate in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if not icon and candidate.type == "mp_offer" and candidate.hospital == world.ui.hospital then
              icon = candidate
            end
          end
          if not icon and entry.arg == "wait" and (entry.retries or 0) < 80 and entry.hour < target - 100 then
            -- acceptoffer:wait: look again every 100 hours until it comes.
            entry.retries = (entry.retries or 0) + 1
            entry.hour = entry.hour + 100
            done[i] = nil
          elseif icon then
            if not icon.fax then icon:openMessage() end
            shot("offer-" .. icon.message.mp_offer.kind)
            local w = icon.fax
            log(string.format("UI: %s offer of %s (%s) at step %d", a == "acceptoffer" and "accepted" or
                "declined", (tostring(icon.message.mp_offer.name):gsub("^.*:", "")),
                icon.message.mp_offer.kind, session.step))
            if a == "acceptoffer" then w:accept() else w:decline() end
          else
            log("UI: no offer to answer")
          end
        elseif a == "referpatient" then
          -- Open this hospital's first free patient's window and press Refer.
          -- referpatient:emergency: an emergency patient, waiting until one is
          -- there (every 100 hours).
          local patient
          for _, p in ipairs(world.ui.hospital.patients) do
            if not patient and MultiplayerSession.referable(p) and not p.mp_offer and
                (entry.arg ~= "emergency" or p.is_emergency) then
              patient = p
            end
          end
          if not patient and entry.arg == "emergency" and (entry.retries or 0) < 80 and
              entry.hour < target - 100 then
            entry.retries = (entry.retries or 0) + 1
            entry.hour = entry.hour + 100
            done[i] = nil
          elseif patient then
            local w = UIPatient(world.ui, patient)
            world.ui:addWindow(w)
            shot("patient-refer")
            log(string.format("UI: referred %spatient #%d at step %d", patient.is_emergency and "emergency " or "",
                patient.mp_id, session.step))
            w:referPatient()
            w:close()
          else
            log("UI: no patient to refer")
          end
        elseif a == "watches" then
          -- The countdown watches on this screen, and this hospital's
          -- countdowns in the simulation (emergency, epidemic cover up).
          local shown = {}
          for _, w in ipairs(world.ui.windows) do
            if class.is(w, UIWatch) then
              shown[#shown + 1] = string.format("%s@%d open %d tick %d", w.count_type,
                  world:getHospitalIndex(w.hospital), w.open_timer, w.tick_timer)
            end
          end
          local h = world.ui.hospital
          local e = h.mp_emergency_timer
          local ep = h.epidemic and h.epidemic.timer
          log(string.format("UI: watches at step %d: %s; emergency %s, timer %s; epidemic %s, timer %s", session.step,
              #shown > 0 and table.concat(shown, ", ") or "none", tostring(h.emergency ~= nil),
              e and string.format("open %d tick %d", e.open_timer, e.tick_timer) or "-",
              tostring(h.epidemic ~= nil), ep and ep.open_timer and string.format("open %d", ep.open_timer) or "-"))
        elseif a == "straywatch" then
          -- Test only: an emergency watch on this screen with no emergency
          -- countdown behind it (as the stuck red watch); it must go away.
          world.ui:addWindow(UIWatch(world.ui, "emergency", world.ui.hospital))
          log("UI: opened a stray emergency watch at step " .. session.step)
        elseif a == "rngcheat" then
          -- Test only: draw a random number in this game alone (a desync in
          -- which only the random numbers differ; the draw journal shows it).
          log("UI: drew a random number alone at step " .. session.step .. ": " .. math.random(1, 6))
        elseif a == "crash" then
          session:issue({kind = "probe_crash", room = entry.arg})
        elseif a == "removecrashed" then
          -- With the "remove destroyed rooms" option: click the room with the
          -- edit cursor and confirm.
          local found
          for _, room in pairs(world.rooms) do
            if room.crashed and room.hospital == world.ui.hospital and (not found or room.id < found.id) then
              found = room
            end
          end
          if found then
            TheApp.config.remove_destroyed_rooms = true
            log(string.format("UI: removing crashed room #%d (%s) at step %d", found.id, found.room_info.id, session.step))
            session:issue({kind = "remove_crashed_room", room = found.id})
          else
            log("UI: no crashed room")
          end
        elseif a == "buyunder" then
          builder.ui_buy_under_person(world, entry.arg, log)
        elseif a == "buyinroom" then
          -- Corridor shop: buy an object and put it into a room ("<object>:<room>").
          local object_id, room_id = entry.arg:match("^([%w_]+):([%w_]+)$")
          builder.ui_buy_into_room(world, object_id, room_id, log)
        elseif a == "rebuildcrashed" then
          -- Multiplayer: click a destroyed room with the edit cursor and
          -- confirm "clear it away and build it again" (whatever the remove
          -- option says); then (rebuildfinish) the editor that opens.
          local found
          for _, candidate in pairs(world.rooms) do
            if candidate.crashed and candidate.hospital == world.ui.hospital and
                (not found or candidate.id < found.id) then
              found = candidate
            end
          end
          if found then
            TheApp.config.remove_destroyed_rooms = false
            log(string.format("UI: rebuilding crashed room #%d (%s) at step %d", found.id, found.room_info.id, session.step))
            session:issue({kind = "remove_crashed_room", room = found.id, rebuild = 1,
                hospital = world:getHospitalIndex(world.ui.hospital)})
            ui_script[#ui_script + 1] = {hour = session.step + 20, action = "rebuildfinish",
                arg = string.format("%s:%d:%d:%d:%d", found.room_info.id, found.x, found.y, found.width, found.height)}
          else
            log("UI: no crashed room")
          end
        elseif a == "repaircrashed" then
          -- repaircrashed:<room>: a destroyed room of this type is repaired
          -- (the answer Yes to the first question); repaircheck looks at it
          -- 80 hours later.
          local found
          for _, candidate in pairs(world.rooms) do
            if candidate.crashed and candidate.hospital == world.ui.hospital and
                candidate.room_info.id == entry.arg and (not found or candidate.id < found.id) then
              found = candidate
            end
          end
          if found then
            local rb = corsixth.require("mp_room_builder")
            local shape = rb.repairCommand(world, found)
            local price = world.ui.hospital.research.research_progress[found.room_info].build_cost
            log(string.format("UI: repairing crashed room #%d (%s) at step %d: %d,%d %dx%d door %s,%s,%s windows %s; " ..
                "balance %d, price %d", found.id, found.room_info.id, session.step, found.x, found.y, found.width,
                found.height, tostring(shape and shape.door_x), tostring(shape and shape.door_y),
                tostring(shape and shape.door_wall), tostring(shape and shape.windows),
                math.floor(world.ui.hospital.balance), price))
            session:issue({kind = "remove_crashed_room", room = found.id, repair = 1,
                hospital = world:getHospitalIndex(world.ui.hospital)})
            ui_script[#ui_script + 1] = {hour = session.step + 80, action = "repaircheck",
                arg = string.format("%s:%d:%d", found.room_info.id, found.x, found.y)}
          else
            log("UI: no crashed " .. tostring(entry.arg))
          end
        elseif a == "repaircheck" then
          local id, x, y = entry.arg:match("^([%w_]+):(%d+):(%d+)$")
          local room
          for _, candidate in pairs(world.rooms) do
            if candidate.room_info.id == id and candidate.x == tonumber(x) and candidate.y == tonumber(y) then
              room = candidate
            end
          end
          if room then
            local shape = corsixth.require("mp_room_builder").repairCommand(world, room)
            local objects = 0
            for _ in pairs(room.objects) do objects = objects + 1 end
            log(string.format("UI: repaired room #%d (%s) at %d,%d %dx%d: crashed %s, built %s, door %s,%s,%s " ..
                "windows %s, objects %d; balance %d", room.id, id, room.x, room.y, room.width, room.height,
                tostring(room.crashed or false), tostring(room.is_active or false), tostring(shape and shape.door_x),
                tostring(shape and shape.door_y), tostring(shape and shape.door_wall), tostring(shape and shape.windows),
                objects, math.floor(world.ui.hospital.balance)))
          else
            log("UI: no repaired " .. tostring(id))
          end
        elseif a == "rebuildfinish" then
          -- The editor opened on the old outline: build the room there again.
          local id, x, y, w, h = entry.arg:match("^([%w_]+):(%d+):(%d+):(%d+):(%d+)$")
          x, y, w, h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
          local dlg = world.ui:getWindow(UIEditRoom)
          local rect = dlg and dlg.blueprint_rect
          log(string.format("UI: rebuild editor %s; %s on the old outline: %s", dlg and "opened" or "missing",
              dlg and dlg.room_type.id or "-",
              tostring(rect ~= nil and rect.x == x and rect.y == y and rect.w == w and rect.h == h)))
          if dlg then dlg:close() end
          builder.ui_room(world, desk_x, desk_y, id, w, h, false, log, {x, y})
        elseif a == "epidemic" then
          session:issue({kind = "probe_epidemic"})
        elseif a == "vaccinate" then
          -- Mark every infected patient of this hospital for vaccination, as
          -- clicks in vaccination mode do (retried until the cover up runs).
          local epidemic = world.ui.hospital.epidemic
          if (not epidemic or not epidemic.coverup_selected) and (entry.retries or 0) < 60 then
            entry.retries = (entry.retries or 0) + 1
            entry.hour = entry.hour + 100
            done[i] = nil
          elseif epidemic then
            local n = 0
            for _, p in ipairs(epidemic.infected_patients) do
              if not p.marked_for_vaccination and not p.vaccinated then
                session:issue({kind = "mark_vaccinate", patient = p.mp_id})
                n = n + 1
              end
            end
            log(string.format("UI: marked %d infected patients for vaccination at step %d", n, session.step))
          end
        elseif a == "vaccmode" then
          -- vaccmode[:right|esc|look]: click the epidemic watch's syringe
          -- button (or right-click the map, press Esc, or only look) with real
          -- mouse/key events,
          -- as a person does; log whether vaccination mode is on (retried
          -- until the cover up runs).
          local ui = world.ui
          local watch
          for _, w in ipairs(ui.windows) do
            if class.is(w, UIWatch) and w.count_type == "epidemic" then watch = w end
          end
          local epidemic = ui.hospital.epidemic
          if not watch and (entry.retries or 0) < 60 then
            entry.retries = (entry.retries or 0) + 1
            entry.hour = entry.hour + 100
            done[i] = nil
          elseif watch then
            local sc = TheApp.gfx:getUIScale()
            if entry.arg == "look" then -- luacheck: ignore 542 (only the log line below)
            elseif entry.arg == "right" then
              local sx, sy = math.floor(ui.app.config.width / 2), math.floor(ui.app.config.height / 2)
              ui:onMouseMove(sx, sy, 0, 0)
              ui:onMouseDown(3, sx, sy)
              ui:onMouseUp(3, sx, sy)
            elseif entry.arg == "esc" then
              ui:onKeyDown("Escape", {})
              ui:onKeyUp("Escape", {})
            else
              local bx = math.floor((watch.x + 4 + 13) * sc)
              local by = math.floor((watch.y + 14) * sc)
              ui:onMouseMove(bx, by, 0, 0)
              ui:onMouseDown(1, bx, by)
              ui:onMouseUp(1, bx, by)
            end
            local cursor = "other"
            if ui.cursor == ui.app.gfx:loadMainCursor("epidemic_hover") then cursor = "epidemic_hover"
            elseif ui.cursor == ui.default_cursor then cursor = "default" end
            log(string.format("UI: vaccmode %s at step %d: mode %s (this epidemic %s, watch's %s), cursor %s",
                entry.arg ~= "" and entry.arg or "button", session.step,
                tostring(epidemic and epidemic.vaccination_mode_active),
                tostring(epidemic), tostring(watch.hospital.epidemic), cursor))
          else
            log("UI: vaccmode: no epidemic watch")
          end
        elseif a == "notreatfax" then
          session:issue({kind = "probe_notreat"})
        elseif a == "sendstaff" then
          -- sendstaff:<class>[:<price>], in the trade window.
          local class_name, price = entry.arg:match("^(%a+):?(%d*)$")
          local trade = UIMultiplayerTrade(world.ui)
          world.ui:addWindow(trade)
          local row
          for i, e in ipairs(trade.staff_list) do
            if not row and e.staff.humanoid_class == class_name then row = i end
          end
          if row then
            trade:selectStaff(row, true)
            local step = MultiplayerSession.STAFF_PRICE_STEP
            for _ = 1, math.floor((tonumber(price) or 0) / step) do trade:setPrice(trade.price + step) end
            log(string.format("UI: sent %s %s to %s for $%d at step %d", class_name,
                tostring(trade.staff_list[row].staff.profile:getFullName()), trade.target.name, trade.price,
                session.step))
            trade:sendStaff()
          else
            log("UI: no " .. entry.arg .. " to send")
          end
          trade:close()
        elseif a == "loan" or a == "priceup" or a == "research" or a == "heatup" then
          -- Hospital settings through their real windows.
          local w
          if a == "loan" then w = UIBankManager(world.ui)
          elseif a == "priceup" then w = UICasebook(world.ui)
          elseif a == "research" then w = UIResearch(world.ui)
          else w = UITownMap(world.ui) end
          world.ui:addWindow(w)
          if a == "loan" then w:increaseLoan()
          elseif a == "priceup" then w:increasePay()
          elseif a == "research" then w:adjustResearch(entry.arg, "less")
          else w:increaseHeat() end
          log(string.format("UI: %s%s at step %d", a, entry.arg ~= "" and (" " .. entry.arg) or "", session.step))
          w:close()
        elseif a == "bonus" or a == "raise" then
          local w = UIStaffManagement(world.ui)
          world.ui:addWindow(w)
          w:setCategory(entry.arg)
          if #(w.staff_members[entry.arg] or {}) > 0 then
            w.selected_staff = 1
            log(string.format("UI: %s for %s at step %d", a, entry.arg, session.step))
            if a == "bonus" then w:payBonus() else w:increaseSalary() end
          else
            log("UI: no " .. entry.arg .. " for " .. a)
          end
          w:close()
        elseif a == "sendhome" then
          local patient
          for _, e in ipairs(world.entities) do
            if not patient and class.is(e, Patient) and e.hospital == world.ui.hospital and
                not e.going_home and e.tile_x then
              patient = e
            end
          end
          if patient then
            local w = UIPatient(world.ui, patient)
            world.ui:addWindow(w)
            log(string.format("UI: sent patient #%d home at step %d", patient.mp_id, session.step))
            w:goHome()
          else
            log("UI: no patient to send home")
          end
        elseif a == "emergency" then
          session:issue({kind = "probe_emergency", target = tonumber(entry.arg) or 1})
          log("UI: asked for an emergency at step " .. session.step)
        elseif a == "shot" then
          shot(entry.arg)
        elseif a == "staffwindow" then
          -- Open the staff window of this hospital's first <arg> (a screenshot
          -- shows it), then click its send icon: the trade window opens.
          local member
          for _, st in ipairs(world.ui.hospital.staff) do
            if not member and st.humanoid_class == entry.arg then member = st end
          end
          if member then
            local win = UIStaff(world.ui, member)
            world.ui:addWindow(win)
            shot("staffwindow-" .. entry.arg)
            win:sendToPlayer()
            local trade = world.ui:getWindow(UIMultiplayerTrade)
            log(string.format("UI: staff window of %s at step %d: send icon opens the trade window: %s, selected: %s",
                entry.arg, session.step, tostring(trade ~= nil),
                tostring(trade and trade.selected and trade.selected.staff == member)))
            if trade then trade:close() end
            win:close()
          else
            log("UI: no " .. entry.arg .. " for the staff window")
          end
        elseif a == "lookroom" then
          -- Centre the view on this hospital's newest room.
          local best
          for _, r in pairs(world.rooms) do
            if r.built and r.hospital == world.ui.hospital and (not best or r.id > best.id) then best = r end
          end
          if best then look_at(best.x + math.floor(best.width / 2), best.y + math.floor(best.height / 2)) end
        elseif a == "staffsend" then
          -- Staff management: select the first doctor, press "send to another
          -- player", screenshot the trade window it opens, close both.
          local manage = UIStaffManagement(world.ui)
          world.ui:addWindow(manage)
          manage:selectIndex(1)
          manage:sendToPlayer()
          local trade = world.ui:getWindow(UIMultiplayerTrade)
          shot("staffsend")
          log(string.format("UI: staff management sent %s to the trade window, selected there: %s",
              tostring(manage.staff_members.Doctor[1].profile:getFullName()):gsub("^.*:", ""),
              trade and trade.selected and tostring(trade.selected.staff.profile:getFullName()):gsub("^.*:", "") or "-"))
          if trade then trade:close() end
          manage:close()
        elseif a == "openfax" then
          -- Open the first fax of a type and leave it open (in multiplayer
          -- the game goes on meanwhile; answerfax answers it later).
          local icon
          for _, candidate in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if not icon and candidate.type == entry.arg and
                (not world.mp_coop or candidate.hospital == world.ui.hospital) then
              icon = candidate
            end
          end
          if icon and not icon.fax then icon:openMessage() end
          log(string.format("UI: %s fax %s at step %d (game speed %s)", entry.arg,
              icon and "opened" or "not found", session.step, tostring(world:getCurrentSpeed())))
        elseif a == "vip" then
          session:issue({kind = "probe_vip", target = tonumber(entry.arg) or 1})
          log("UI: asked for a VIP fax at step " .. session.step)
        elseif a == "answerfax" then
          -- answerfax:<type>:<n>[:wait]: with "wait", look again every 100
          -- hours until the fax comes. Only this player's faxes (co-op).
          local ftype, n, wait = entry.arg:match("^(%a+):(%d+):?(%a*)$")
          local icon
          for _, i in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if not icon and i.type == ftype and (not world.mp_coop or i.everyone or i.hospital == world.ui.hospital) then
              icon = i
            end
          end
          if not icon and wait == "wait" and (entry.retries or 0) < 80 and entry.hour < target - 100 then
            entry.retries = (entry.retries or 0) + 1
            entry.hour = entry.hour + 100
            done[i] = nil
          elseif icon then
            if not icon.fax then icon:openMessage() end
            shot("fax-" .. ftype)
            log(string.format("UI: clicked choice %s of %s fax #%s at step %d", n, ftype,
                tostring(icon.mp_id), session.step))
            icon.fax:buttonChoice(tonumber(n))
          else
            log("UI: no " .. ftype .. " fax to answer")
          end
        elseif a == "crowdroom" then
          local id, rw, rh = entry.arg:match("^([%w_]+):(%d+):(%d+)$")
          rw, rh = tonumber(rw), tonumber(rh)
          local rx, ry = builder.rect_with_person(world, rw, rh)
          if rx then
            builder.ui_room(world, desk_x, desk_y, id, rw, rh, false, log, {rx, ry})
          else
            log("UI: nobody standing in a free spot for " .. id)
          end
        elseif a == "room" then
          local id, rw, rh, opt = entry.arg:match("^([%w_]+):(%d+):(%d+):?(%a*)$")
          builder.ui_room(world, desk_x, desk_y, id, tonumber(rw), tonumber(rh), opt == "window", log)
        elseif a == "hire" then builder.ui_hire(world, desk_x, desk_y, entry.arg, log)
        elseif a == "pause" or a == "unpause" then
          presses[#presses + 1] = {wait = tonumber(entry.arg) or 0, paused = a == "unpause"}
        elseif a == "speed" then
          log("UI: chose speed " .. entry.arg .. " at step " .. session.step)
          world:setUserSpeed(entry.arg)
        elseif a == "speedother" then
          -- The slowest speed the room allows that is not the current one
          -- (the room's top speed depends on the connection).
          local pick
          for _, sp in ipairs(MultiplayerLobby.SPEEDS) do
            if not pick and sp ~= world.mp_speed and
                MultiplayerLobby.clampSpeed(sp, session.max_speed) == sp then
              pick = sp
            end
          end
          log("UI: chose speed " .. tostring(pick) .. " at step " .. session.step)
          if pick then world:setUserSpeed(pick) end
        elseif a == "votefax" then
          -- Answer the speed vote fax with choice <arg> (1 agree, 2 decline),
          -- clicked in the fax window; wait for it if it is not there yet.
          local icon
          for _, ic in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if ic.mp_vote then icon = ic end
          end
          if icon then
            local fax = UIFax(world.ui, icon)
            icon.fax = fax
            world.ui:addWindow(fax)
            log(string.format("UI: answered the speed vote fax with %s at step %d", entry.arg, session.step))
            fax:buttonChoice(tonumber(entry.arg) or 1)
          else
            done[i] = false
            entry.hour = session.step + 5
          end
        elseif a == "quit" then
          log("UI: quitting at step " .. session.step)
          quit = true
        elseif (a == "furnishroom" or a == "cancelroom") and furnishing then
          -- One room at a time: wait until the last one is furnished.
          done[i] = false
          entry.hour = session.step + 20
        elseif a == "furnishall" then
          -- Every room this hospital can build, one after the other (most
          -- needed first), each furnished by hand. Argument: steps between.
          local hospital = world.ui.hospital
          local first = {gp = 1, pharmacy = 2, general_diag = 3, ward = 4, psych = 5, staff_room = 6, toilets = 7}
          local ids = {}
          for _, room_type in ipairs(TheApp.rooms) do
            local discovery = hospital.room_discoveries[room_type.id]
            if discovery and discovery.is_discovered and hospital.research.research_progress[room_type] then
              ids[#ids + 1] = room_type
            end
          end
          table.sort(ids, function(r1, r2)
            local f1, f2 = first[r1.id] or 99, first[r2.id] or 99
            if f1 ~= f2 then return f1 < f2 end
            return r1.id < r2.id
          end)
          local gap, names = tonumber(entry.arg) or 100, {}
          for k, room_type in ipairs(ids) do
            local size = math.min(7, math.max(5, (room_type.minimum_size or 4) + 1))
            ui_script[#ui_script + 1] = {hour = session.step + k * gap, action = "furnishroom",
                arg = string.format("%s:%d:%d", room_type.id, size, size)}
            names[#names + 1] = room_type.id
          end
          log(string.format("UI: building every room at step %d: %s", session.step, table.concat(names, ",")))
        elseif a == "furnishroom" or a == "cancelroom" then
          -- Draw a room, then place its furniture by hand (or cancel then).
          local id, rw, rh = entry.arg:match("^([%w_]+):(%d+):(%d+)$")
          rw, rh = tonumber(rw), tonumber(rh)
          -- Smaller if there is no space (a room is at least 4 x 4 here).
          local drawn = false
          while not drawn and rw >= 4 and rh >= 4 do
            -- With a window in the top wall, like a person would build it.
            drawn = builder.ui_room(world, desk_x, desk_y, id, rw, rh, true, log, nil, true)
            if not drawn then rw, rh = rw - 1, rh - 1 end
          end
          if drawn then
            furnishing = {cancel = a == "cancelroom", pace = furnish_pace, clicks = true,
                not_before = furnish_pace and session.step + furnish_pace}
          end
        elseif a == "editroom" then
          -- Edit a room of this player's: editroom:<room>:<step>+<step>...
          local id, steps = entry.arg:match("^([%w_]+):(.+)$")
          local list = {}
          for s in steps:gmatch("[^+]+") do list[#list + 1] = s end
          editing = {room_type = id, steps = list}
        elseif a == "moveobject" or a == "sellobject" then
          -- Pick up a corridor object of this hospital (right click), then
          -- put it down a few tiles away (or <id>:<dx>:<dy> tiles away,
          -- exactly), or sell it (close the window).
          local id, dx, dy = entry.arg:match("^([%w_]+):?(-?%d*):?(-?%d*)$")
          dx, dy = tonumber(dx), tonumber(dy)
          local obj
          for _, e in ipairs(world.entities) do
            if not obj and class.is(e, Object) and e.object_type.id == id and e.tile_x and
                not e:getRoom() and world.ui.hospital:isInHospital(e.tile_x, e.tile_y) then
              obj = e
            end
          end
          if obj then
            obj:onClick(world.ui, "right")
            local place = world.ui:getWindow(UIPlaceObjects)
            if a == "moveobject" and place then
              local x, y
              if dx then
                x, y = obj.tile_x + dx, obj.tile_y + (dy or 0)
              else
                x, y = builder.find_free_rect(world, obj.tile_x + 3, obj.tile_y, 1, 1, 10,
                    function(tx, ty) return not world:anyHumanoidObscuringArea(tx, ty) end)
              end
              place:setBlueprintCell(x, y)
              place.object_cell_x, place.object_cell_y = x, y
              local someone = world:anyHumanoidObscuringArea(x, y)
              local valid = place.object_blueprint_good and not someone
              if dx and place.object_blueprint_good and someone and (entry.retries or 0) < 20 then
                -- Somebody stands on the spot: wait a moment and try again,
                -- as a player would.
                place:close(true)
                entry.retries = (entry.retries or 0) + 1
                done[i] = false
                entry.hour = session.step + 5
              else
                place:onMouseUp("left", 100000, 100000)
                log(string.format("UI: moved %s #%d from %d,%d to %d,%d at step %d (spot valid: %s)", id, obj.mp_id,
                    obj.tile_x, obj.tile_y, x, y, session.step, tostring(valid)))
                place = world.ui:getWindow(UIPlaceObjects)
                if place then
                  log("UI: the placement was refused on the screen; put back")
                  place:close(true) -- click refused: put it back
                end
              end
            elseif place then
              log(string.format("UI: sold %s #%d at step %d", entry.arg, obj.mp_id, session.step))
              place:close(false)
            end
          else
            log("UI: no " .. id .. " to pick up")
          end
        elseif a == "sabotage" then
          -- sabotage:<trick>:<level>:<hospital>: MULTIPLAYER > DIRTY TRICKS
          local trick, level, to = entry.arg:match("^(%a+):(%d+):(%d+)$")
          local win = UIMultiplayerSabotage(world.ui, world.hospitals[tonumber(to)])
          world.ui:addWindow(win)
          -- Two clicks, as a person: the first shows what it does.
          win:choose(trick, tonumber(level))
          shot("sabotage-" .. trick)
          win:choose(trick, tonumber(level))
          log(string.format("UI: dirty trick %s level %s against hospital %s at step %d: %s", trick, level, to,
              session.step, tostring(win.status_panel and win.status_panel.label)))
          win:close()
        elseif a == "kickevil" then
          -- Find a rival's evil handyman in this hospital and press the sack
          -- button of his staff window (then OK). Look again later if none yet.
          local evil
          for _, e in ipairs(world.entities) do
            if not evil and e.mp_saboteur and not e.mp_in_transit and e.hospital == world.ui.hospital then evil = e end
          end
          if not evil and (entry.retries or 0) < 40 and entry.hour < target - 100 then
            entry.retries = (entry.retries or 0) + 1
            entry.hour = entry.hour + 50
            done[i] = nil
          elseif evil then
            local win = UIStaff(world.ui, evil)
            world.ui:addWindow(win)
            win:fireStaff()
            local confirm = world.ui:getWindow(UIConfirmDialog)
            if confirm then confirm:ok() end
            log(string.format("UI: threw out evil handyman #%d at step %d", evil.mp_id, session.step))
            if win.close and world.ui:getWindow(UIStaff) then win:close() end
          else
            log("UI: no evil handyman found")
          end
        elseif a == "shootrat" then
          -- Click the first attack rat in this hospital (shoot_rat command).
          local rat
          for _, e in ipairs(world.entities) do
            if not rat and e.mp_attack_rat and not e.shot and e.hospital == world.ui.hospital then rat = e end
          end
          if rat then
            rat:onClick(world.ui, "left")
            log(string.format("UI: shot rat #%d at step %d (reputation %d)", rat.mp_id, session.step,
                world.ui.hospital.reputation))
          else
            log("UI: no rat to shoot")
          end
        elseif a == "hospitals" then
          -- Every hospital: open or not, balance, its rooms and staff (to
          -- see what a bot built), with the game date.
          local d = world:date()
          local parts = {}
          for h, hosp in ipairs(world.hospitals) do
            local rooms, staff = {}, {}
            for _, r in pairs(world.rooms) do
              if r.hospital == hosp and r.is_active then rooms[#rooms + 1] = r.room_info.id end
            end
            table.sort(rooms)
            for _, s in ipairs(hosp.staff) do staff[s.humanoid_class] = (staff[s.humanoid_class] or 0) + 1 end
            local st = {}
            for k, v in pairs(staff) do st[#st + 1] = k .. "=" .. v end
            table.sort(st)
            local objects = 0
            for _, e in ipairs(world.entities) do
              if e.object_type and e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) and
                  not world:getRoom(e.tile_x, e.tile_y) then
                objects = objects + 1
              end
            end
            parts[#parts + 1] = string.format("[%d %s opened=%s balance=%d rooms=%s staff=%s corridor_objects=%d]", h,
                tostring(hosp.name), tostring(hosp.opened or false), math.floor(hosp.balance),
                table.concat(rooms, ","), table.concat(st, ","), objects)
          end
          log(string.format("UI: hospitals at step %d (%s, month %d): %s", session.step, d:tostring(),
              d:monthOfGame(), table.concat(parts, " ")))
        elseif a == "rivals" then
          -- Competitive: which people and doors the mouse may point at (the
          -- hover test of the game UI): own ones, and not the rivals'.
          local ui, mine = world.ui, world.ui.hospital
          local own, own_hidden, rival, rival_shown, evil = 0, 0, 0, 0, "-"
          for _, e in ipairs(world.entities) do
            if class.is(e, Humanoid) and e.hospital and not e.going_home then
              local hidden = ui:_isRivals(e)
              if e.mp_saboteur and e.hospital == mine then
                evil = tostring(not hidden)
              elseif e.hospital == mine then
                own = own + 1
                if hidden then own_hidden = own_hidden + 1 end
              else
                rival = rival + 1
                if not hidden then rival_shown = rival_shown + 1 end
              end
            end
          end
          local doors, doors_shown = 0, 0
          for _, r in pairs(world.rooms) do
            if r.door and r.hospital ~= mine then
              doors = doors + 1
              if not ui:_isRivals(r.door) then doors_shown = doors_shown + 1 end
            end
          end
          -- Rivals' rooms being furnished: their floor is not blue here.
          local furnished, blue = 0, 0
          for _, f in pairs(world.mp_furnishing or {}) do
            if f.peer ~= session.peer_id then
              furnished = furnished + 1
              for ty = f.y, f.y + f.h - 1 do
                for tx = f.x, f.x + f.w - 1 do
                  if world.map.th:getCell(tx, ty, 4) ~= 0 then blue = blue + 1 end
                end
              end
            end
          end
          log(string.format("UI: rivals at step %d: own hidden %d of %d; rivals shown %d of %d; " ..
              "rival doors shown %d of %d; evil handyman shown %s; rival rooms being furnished %d, " ..
              "blue tiles %d", session.step, own_hidden, own, rival_shown, rival, doors_shown, doors, evil,
              furnished, blue))
        elseif a == "level" then
          -- What the level has: diseases, rooms there at the start, rooms
          -- that come later (research or automatic), and the goals.
          local hosp = world.ui.hospital
          local now, later = {}, {}
          for id, disc in pairs(hosp.room_discoveries) do
            if disc.is_discovered then now[#now + 1] = id else later[#later + 1] = id end
          end
          table.sort(now)
          table.sort(later)
          local goals = {}
          for _, group in pairs(world.endconditions.win_goals) do
            for crit, goal in pairs(group) do goals[#goals + 1] = crit .. "=" .. tostring(goal.win_value) end
          end
          table.sort(goals)
          log(string.format("UI: level at step %d: level %s; diseases %d; balance %d; rooms now: %s; later: %s; goals: %s",
              session.step, tostring(world.map.level_config.mp_level), #world.available_diseases,
              math.floor(hosp.balance), table.concat(now, ","), table.concat(later, ","), table.concat(goals, " ")))
        elseif a == "race" then
          -- Competitive: each hospital's place, and whether the race is over.
          local parts = {}
          for h = 1, (world.mp_coop and world.mp_coop.players or 1) do
            local hosp = world.hospitals[h]
            parts[#parts + 1] = string.format("%d=%s%s", h, tostring(hosp.mp_place or "-"),
                hosp.mp_place_how and ("(" .. hosp.mp_place_how .. ")") or "")
          end
          local staff = {}
          for _, s in ipairs(world.ui.hospital.staff) do staff[#staff + 1] = s.humanoid_class end
          table.sort(staff)
          log(string.format("UI: race at step %d: %s; over: %s; my staff: %s; reputation %d", session.step,
              table.concat(parts, " "), tostring(world.mp_race_over or false), table.concat(staff, ","),
              world.ui.hospital.reputation))
        elseif a == "discover" then
          -- Test command: the room becomes available (as research would).
          session:issue({kind = "probe_discover", room = entry.arg})
        elseif a == "losteditor" or a == "reopen" then
          -- losteditor: this player's room editor closes without a command
          -- (as something else could close it); reopen: the edit room tool
          -- and a click on that room open it again.
          local own_entry
          for _, e in pairs(world.mp_furnishing or {}) do
            if e.peer == session.peer_id then own_entry = e end
          end
          local builder2 = corsixth.require("mp_room_builder")
          if not own_entry then
            log("UI: no room editor of this player")
          elseif a == "losteditor" then
            builder2.hide(world, own_entry)
            log(string.format("UI: the editor of %s#%d closed at step %d", own_entry.dlg.room.room_info.id,
                own_entry.dlg.room.id, session.step))
          else
            local rm = own_entry.dlg.room
            world.ui:setEditRoom(true)
            builder.mouse_click(world.ui, rm.x + 1, rm.y + 1)
            log(string.format("UI: reopened the editor of %s#%d at step %d: shown %s", rm.room_info.id, rm.id,
                session.step, tostring(world.ui.edit_room == own_entry.dlg)))
          end
        elseif a == "openshop" then
          -- The corridor shop window (buying a drinks machine), left open.
          world.ui:addWindow(UIFurnishCorridor(world.ui))
          log(string.format("UI: opened the corridor shop at step %d", session.step))
        elseif a == "holdobject" then
          -- holdobject:<object>:<x>:<y> bought in the corridor shop and held
          -- (not placed) with its preview at that tile, as while choosing a spot.
          local id, hx, hy = entry.arg:match("^([%w_]+):(%d+):(%d+)$")
          local place = UIPlaceObjects(world.ui, {{object = TheApp.objects[id], qty = 1}})
          world.ui:addWindow(place)
          place:setBlueprintCell(tonumber(hx), tonumber(hy))
          log(string.format("UI: holding a %s at %s,%s at step %d", id, hx, hy, session.step))
        elseif a == "monkey" then
          -- monkey:<clicks>:<seed> random left and right clicks anywhere.
          local n, seed = entry.arg:match("^(%d+):?(%d*)$")
          monkey = {total = tonumber(n) or 500, n = 0, state = tonumber(seed) or 1}
          log(string.format("UI: monkey starts (%d clicks, seed %s) at step %d", monkey.total, tostring(seed), session.step))
        elseif a == "holdpause" then
          -- A window that pauses this game (a question, like a fax would),
          -- left open for <arg> seconds: the other players wait.
          local win = UIConfirmDialog(world.ui, true, "Probe: a question", function() end)
          world.ui:addWindow(win)
          holding = {win = win, until_time = socket.gettime() + (tonumber(entry.arg) or 3)}
          log(string.format("UI: opened a question at step %d", session.step))
        elseif a == "freeze" then
          -- This game stops for <arg> seconds (a slow computer): the others wait.
          log(string.format("UI: freezing for %s s at step %d", entry.arg, session.step))
          socket.sleep(tonumber(entry.arg) or 3)
          log(string.format("UI: going on at step %d", session.step))
        elseif a == "inputerror" then
          -- An error in the mouse movement handler, as the game reports it
          -- (App:errorHandler): in multiplayer the handler stays connected.
          local had_handler = TheApp.eventHandlers.motion ~= nil
          TheApp:errorHandler("motion", "probe: an error in the motion handler")
          log(string.format("UI: motion handler after an error at step %d: %s (before %s)", session.step,
              TheApp.eventHandlers.motion ~= nil and "connected" or "disconnected", tostring(had_handler)))
        elseif a == "breakroom" then
          -- The next patient entering the first <arg> room makes its code fail
          -- once, in every game (test command probe_breakroom).
          log(string.format("UI: breaking the next patient's entry into a %s at step %d", entry.arg, session.step))
          session:issue({kind = "probe_breakroom", room = entry.arg})
        elseif a == "breakstaff" then
          -- A broken tick for the first member of staff of a class, in every
          -- game (test command probe_break): the game sets them aside alike.
          log(string.format("UI: breaking the tick of the first %s at step %d", entry.arg, session.step))
          session:issue({kind = "probe_break", class = entry.arg})
        elseif a == "ticks" then
          for _, st in ipairs(world.ui.hospital.staff) do
            if st.humanoid_class == entry.arg then
              log(string.format("UI: %s #%s ticks %s at step %d", entry.arg, tostring(st.mp_id), tostring(st.ticks), session.step))
            end
          end
        elseif a == "roomdump" then
          -- Every room of a type (entry.arg): its objects, and what a member
          -- of staff at the desk would find (findObjectNear, as gp.lua does).
          for _, rm in pairs(world.rooms) do
            if rm.room_info.id == entry.arg then
              local objs = {}
              for o in pairs(rm.objects) do
                objs[#objs + 1] = string.format("%s@%d,%d/%s", o.object_type.id, o.tile_x or -1, o.tile_y or -1,
                    tostring(o.direction))
              end
              table.sort(objs)
              local staff = rm:getStaffMember()
              local found = "-"
              for o in pairs(rm.objects) do
                if o.object_type.id == "cabinet" and staff then
                  local orient = o.object_type.orientations[o.direction]
                  local ux, uy = o.tile_x, o.tile_y
                  for _, t in ipairs(orient.footprint) do
                    if t.only_passable then ux, uy = o.tile_x + t[1], o.tile_y + t[2] end
                  end
                  local d = world:getPathDistance(staff.tile_x, staff.tile_y, ux, uy)
                  log(string.format("UI: cabinet use tile %d,%d, path from the doctor: %s; tiles: %s", ux, uy,
                      tostring(d), (function()
                        local t = {}
                        for yy = rm.y, rm.y + rm.height - 1 do
                          local row = {}
                          for xx = rm.x, rm.x + rm.width - 1 do
                            local f = world.map.th:getCellFlags(xx, yy)
                            row[#row + 1] = (f.passable and "." or "#") .. (f.travelNorth and "" or "^")
                          end
                          t[#t + 1] = table.concat(row, "")
                        end
                        return table.concat(t, " | ")
                      end)()))
                end
              end
              local ex, ey = rm:getEntranceXY(true)
              log(string.format("UI: door %d,%d %s, entrance inside %d,%d", rm.door.tile_x, rm.door.tile_y,
                  tostring(rm.door.direction), ex, ey))
              for o in pairs(rm.objects) do
                local orient = o.object_type.orientations[o.direction]
                if orient and o ~= rm.door then
                  local fp = {}
                  for _, t in ipairs(orient.footprint) do
                    fp[#fp + 1] = string.format("%d,%d%s%s%s", o.tile_x + t[1], o.tile_y + t[2],
                        t.only_passable and "p" or "", t.complete_cell and "c" or "", t.only_side and "s" or "")
                  end
                  local up = orient.use_position
                  local ux, uy = up and type(up) == "table" and o.tile_x + up[1], up and type(up) == "table" and o.tile_y + up[2]
                  log(string.format("UI: %s at %d,%d %s: footprint %s; use %s,%s; path from entrance %s",
                      o.object_type.id, o.tile_x, o.tile_y, o.direction, table.concat(fp, " "), tostring(ux), tostring(uy),
                      ux and tostring(world:getPathDistance(ex, ey, ux, uy)) or "-"))
                end
              end
              if staff then
                local obj, ox, oy = world:findObjectNear(staff, "cabinet")
                found = obj and string.format("cabinet use tile %d,%d", ox, oy) or "NO CABINET FOUND"
              end
              log(string.format("UI: room %s#%d at %d,%d %dx%d built %s active %s: %s; staff %s at %s,%s ticks %s; %s",
                  entry.arg, rm.id, rm.x, rm.y, rm.width, rm.height, tostring(rm.built), tostring(rm.is_active),
                  table.concat(objs, " "), staff and tostring(staff.mp_id) or "-", staff and tostring(staff.tile_x) or "-",
                  staff and tostring(staff.tile_y) or "-", staff and tostring(staff.ticks) or "-", found))
            end
          end
          for _, st in ipairs(world.ui.hospital.staff) do
            if st.ticks == false then
              log(string.format("UI: frozen %s #%s at %d,%d", st.humanoid_class, tostring(st.mp_id), st.tile_x or -1, st.tile_y or -1))
            end
          end
        elseif a == "buyplot" then
          -- Town map: buy the plot this hospital can buy that has the most
          -- objects waiting on it (entrance doors), as a click there does.
          -- buyplot:other tries one on another player's side (refused).
          local th, hospital = world.map.th, world.ui.hospital
          local me = world:getHospitalIndex(hospital)
          local best, best_n
          for plot = 1, th:getPlotCount() do
            local side = world.mp_coop and MultiplayerSession.plotSide(world, plot)
            local wanted = not side or (entry.arg == "other") == (side ~= me)
            if wanted and th:isParcelPurchasable(plot, hospital:getPlayerIndex()) then
              local n = 0
              for _, p2 in pairs(world.delayed_map_objects or {}) do
                if p2 == plot then n = n + 1 end
              end
              if not best or n > best_n then best, best_n = plot, n end
            end
          end
          if best then
            log(string.format("UI: buying plot %d ($%d, %d objects waiting on it) at step %d", best,
                world.map:getParcelPrice(best), best_n, session.step))
            TheApp.mp_session:issue({kind = "buy_plot", plot = best})
          else
            log("UI: no plot to buy")
          end
        elseif a == "holduser" then
          -- Pick up (right-click) a member of staff who is using an object
          -- (a doctor at a desk), log whether they and the object are seen,
          -- and cancel the move <arg> steps later (see "holdcheck").
          local st
          for _, s2 in ipairs(world.ui.hospital.staff) do
            if not st and s2.user_of and s2.tile_x and not s2.fired then st = s2 end
          end
          if not st then
            log("UI: nobody is using an object at step " .. session.step)
          else
            st:onClick(world.ui, "right")
            local obj = st.user_of
            held_user = {staff = st, object = obj, until_step = session.step + (tonumber(entry.arg) or 20)}
            log(string.format("UI: holding %s using %s at step %d: person seen %s, object seen %s",
                st.humanoid_class, obj.object_type.id, session.step, tostring(st.th:isVisible()),
                tostring(obj.th:isVisible())))
          end
        elseif a == "movestaff" or a == "whereis" then
          -- movestaff: right-click the first member of staff of that class,
          -- then click a free tile in one of this hospital's rooms (as a
          -- person does). whereis: log where they are and in which room.
          local st
          for _, s2 in ipairs(world.ui.hospital.staff) do
            if not st and s2.humanoid_class == entry.arg and not s2.fired and s2.tile_x then st = s2 end
          end
          if not st then
            log("UI: no " .. entry.arg .. " to move")
          elseif a == "whereis" then
            local in_room = st:getRoom()
            log(string.format("UI: %s #%s at step %d is at %d,%d in %s, visible %s", entry.arg, tostring(st.mp_id),
                session.step, st.tile_x, st.tile_y, in_room and (in_room.room_info.id .. "#" .. in_room.id) or "the_corridor",
                tostring(st.th:isVisible())))
          else
            builder.mouse_click(world.ui, st.tile_x, st.tile_y, "right")
            local win = world.ui:getWindow(UIPlaceStaff)
            if not win then
              -- (A walking sprite is not always on its tile: click them directly.)
              log("UI: the right click missed the " .. entry.arg .. "; clicking them directly")
              st:onClick(world.ui, "right")
              win = world.ui:getWindow(UIPlaceStaff)
            end
            local dest
            for _, rm in pairs(world.rooms) do
              if not dest and rm.hospital == world.ui.hospital and rm.built and not rm.crashed and
                  rm ~= st:getRoom() then
                for ty = rm.y + 1, rm.y + rm.height - 2 do
                  for tx = rm.x + 1, rm.x + rm.width - 2 do
                    if not dest and win then
                      win.tile_x, win.tile_y = tx, ty
                      if win:_isValidStaffPlacement() and not world:getObject(tx, ty) then
                        dest = {tx, ty, rm}
                      end
                    end
                  end
                end
              end
            end
            if not (win and dest) then
              log("UI: nowhere to move the " .. entry.arg)
              if win then win:close() end
            else
              log(string.format("UI: moving %s #%s from %d,%d to %d,%d in %s#%d (picked up: hidden %s)", entry.arg,
                  tostring(st.mp_id), st.tile_x, st.tile_y, dest[1], dest[2], dest[3].room_info.id, dest[3].id,
                  tostring(not st.th:isVisible())))
              -- A click there in the placement window (as hiring does).
              builder.click_tile(world.ui, win, "left", dest[1], dest[2])
              if world.ui:getWindow(UIPlaceStaff) then log("UI: the placement window did not take the click") end
            end
          end
        elseif a == "players" then
          -- MULTIPLAYER > PLAYERS: open the window and log its rows.
          local win = UIMultiplayerPlayers(world.ui)
          world.ui:addWindow(win)
          local parts = {}
          local function text(v) return (tostring(v):gsub("^<LocalisedString> Current value:", "")) end
          for _, r in ipairs(UIMultiplayerPlayers.rows(lobby, session, world)) do
            parts[#parts + 1] = table.concat({text(r.name), text(r.hospital), text(r.ping), text(r.status),
                text(r.value), text(r.goals)}, "|")
          end
          log(string.format("UI: players at step %d: %s", session.step, table.concat(parts, "; ")))
          if entry.arg == "shot" then shot("players") end
          win:close()
        elseif a == "overlay" then
          -- Blue marks left on the map's overlay layer (4) outside any room
          -- being edited: value, tile, room id there.
          local th = world.map.th
          local mw, mh = th:size()
          local marks = {}
          for y = 1, mh do
            for x = 1, mw do
              local v = th:getCell(x, y, 4)
              if v ~= 0 then
                marks[#marks + 1] = string.format("%d@%d,%d(room %d)", v, x, y, th:getCellFlags(x, y).roomId or 0)
              end
            end
          end
          log(string.format("UI: overlay at step %d: %d marks %s", session.step, #marks,
              table.concat(marks, " ", 1, math.min(#marks, 40))))
        elseif a == "uistate" then
          -- What decides whether clicks on the map reach people and objects.
          local ui = world.ui
          local names = {}
          for _, win in ipairs(ui.windows or {}) do
            names[#names + 1] = (class.type and class.type(win)) or tostring(win.modal_class or "window")
          end
          local hit = ui.do_world_hit_test
          log(string.format("UI: state at step %d: world hit test %s, edit_room %s, %d windows (%s), "
              .. "user actions %s, staff %d", session.step,
              hit == true and "on" or (hit and ("room #" .. tostring(hit.id)) or "off"),
              tostring(ui.edit_room), #(ui.windows or {}), table.concat(names, ","),
              tostring(world.user_actions_allowed), #ui.hospital.staff))
          for _, st in ipairs(ui.hospital.staff) do
            local ok, entity = pcall(function()
              local sx, sy = TheApp.map:WorldToScreen(st.tile_x, st.tile_y)
              return TheApp.map.th:hitTestObjects(math.floor(sx), math.floor(sy) - 10)
            end)
            log(string.format("UI:   %s at %s,%s fired=%s transit=%s hit=%s", st.humanoid_class,
                tostring(st.tile_x), tostring(st.tile_y), tostring(st.fired),
                tostring(st.mp_in_transit ~= nil), ok and tostring(entity and entity.humanoid_class) or "error"))
          end
        elseif a == "clickstaff" then
          -- Left-click every member of staff of this hospital and everybody
          -- walking over from it, like the player would (errors are logged).
          local list = {}
          for _, st in ipairs(world.ui.hospital.staff) do list[#list + 1] = st end
          for _, st in ipairs(world.mp_transfers or {}) do list[#list + 1] = st end
          for _, st in ipairs(list) do
            local ok, err = pcall(st.onClick, st, world.ui, "left")
            log(string.format("UI: clicked %s (transit %s): %s", st.humanoid_class,
                tostring(st.mp_in_transit ~= nil), ok and "ok" or ("ERROR " .. tostring(err))))
            local win = world.ui:getWindow(UIStaff)
            if win then win:close() end
          end
        elseif a == "staleui" then
          -- Leave the UI pointing at a room editor that is not open (as a
          -- player's game once did before saving): clicks limited to one room.
          log("UI: left a stale room editor in the UI at step " .. session.step)
          world.ui.edit_room = {stale = true}
          world.ui:setWorldHitTest({id = -1})
        elseif a == "uierror" then
          -- An error in the screen's own tick (as the announcer once had
          -- without a sound file): this game must carry on and say so.
          log("UI: an error in the screen tick at step " .. session.step)
          local ui = world.ui
          ui.onTick = function() ui.onTick = nil; error("probe: an error in the screen tick") end
        elseif a == "mpsave" then
          -- File > Save: every player's game saves at the same hour.
          log("UI: File > Save at step " .. session.step)
          MultiplayerSession.saveTogether()
        elseif a == "transfers" then
          -- Where the staff on their way to another hospital are.
          for _, st in ipairs(world.mp_transfers or {}) do
            local t = st.mp_in_transit or {}
            local action = st:getCurrentAction()
            log(string.format("UI: transfer of %s at %s,%s doing %s, to %s,%s (step %d)",
                st.humanoid_class, tostring(st.tile_x), tostring(st.tile_y),
                action and action.name or "-", tostring(t.x), tostring(t.y), session.step))
          end
        elseif a == "faxes" then
          -- The messages this game holds (shown or queued), for the log.
          local parts = {}
          for _, icon in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            parts[#parts + 1] = string.format("%s#%s%s%s", tostring(icon.type), tostring(icon.mp_id),
                icon.parent and "" or "(queued)", icon.everyone and "(everyone)" or "")
          end
          log("UI: messages at step " .. session.step .. ": " .. table.concat(parts, " "))
        elseif a == "goals" then
          -- goals:<hospital>:<win|lose|real> (test command on every peer)
          local target, outcome = entry.arg:match("^(%d+):(%a+)$")
          session:issue({kind = "probe_goals", target = tonumber(target),
              outcome = outcome ~= "real" and outcome or nil})
        elseif a == "wincheck" or a == "yearend" then
          session:issue({kind = "probe_" .. a})
        elseif a == "patients" then
          session:issue({kind = "probe_patients", n = tonumber(entry.arg)})
        elseif a == "enterchat" then
          -- Enter while a room is being drawn: the chat opens (the editor
          -- would take Enter as its checkmark otherwise).
          local dlg = UIEditRoom(world.ui, TheApp.rooms.gp)
          world.ui:addWindow(dlg)
          world.ui:onKeyDown("return", {})
          local input = world.ui:getWindow(UIMultiplayerChatInput)
          log(string.format("UI: Enter with a room editor open at step %d: chat %s, editor %s",
              session.step, input and "opened" or "not opened", dlg.phase))
          if input then input:close() end
          dlg:close()
        elseif a == "chat" then
          -- In-game chat with the real keys: Enter, the text, Tab <n> times
          -- (who it is for), Enter. Argument: "<tabs>:<text>".
          local tabs, text = entry.arg:match("^(%d+):(.*)$")
          -- (Enter goes to an open information box first, like the level
          -- briefing: a player closes it before chatting.)
          for i = #world.ui.windows, 1, -1 do
            if class.is(world.ui.windows[i], UIInformation) then world.ui.windows[i]:close() end
          end
          world.ui:onKeyDown("return", {})
          local input = world.ui:getWindow(UIMultiplayerChatInput)
          if input then
            input.box:setText(text)
            for _ = 1, tonumber(tabs) do world.ui:onKeyDown("tab", {}) end
            shot("chat-input")
            log(string.format("UI: chat %q to %s at step %d", text, input.target_panel.label, session.step))
            world.ui:onKeyDown("return", {})
          else
            -- Something else holds Enter (say which), so send the line as the
            -- input would: <tabs> picks the n-th other player.
            local holders = {}
            for _, handler in ipairs(world.ui.key_handlers["return"] or {}) do
              holders[#holders + 1] = class.type(handler.window) or tostring(handler.window)
            end
            local in_game, others = session.lobby, {}
            for _, player in ipairs(in_game and in_game.game_players or {}) do
              if player.peer ~= session.peer_id and player.connected then others[#others + 1] = player end
            end
            local to = others[tonumber(tabs)]
            if in_game then in_game:send("CHAT", {text = text, to = to and to.peer}) end
            log(string.format("UI: no chat input opened (Enter held by %s); sent %q to %s at step %d",
                table.concat(holders, ","), text, to and to.name or "all", session.step))
          end
        elseif a == "iconsample" then
          -- Test only (changes this game's message list, so near the end):
          -- built-in message icons next to the offer icons, for a screenshot.
          local panel, mine = world.ui.bottom_panel, world.ui.hospital
          local function sample(kind, extra)
            local message = {{text = "sample"}, choices = {{text = "ok", choice = "close"}}}
            for k, v in pairs(extra or {}) do message[k] = v end
            panel:queueMessage(kind, message, nil, nil, nil, nil, mine)
          end
          sample("information")
          sample("personality")
          sample("mp_offer", {mp_offer = {kind = "staff", from = 1, to = 2, name = "sample"}})
          sample("mp_research", {mp_offer = {kind = "research", from = 1, to = 2, name = "sample"}})
        elseif a == "learn" then
          session:issue({kind = "probe_learn"})
        elseif a == "askmoney" then
          -- Bank manager, "Ask a player": the amount, Ask.
          local bank = UIBankManager(world.ui)
          world.ui:addWindow(bank)
          shot("bank-manager")
          bank:askForMoney()
          local w = world.ui:getWindow(UIMultiplayerAskMoney)
          if w then
            w:setAmount(tonumber(entry.arg) or 5000)
            shot("ask-window")
            log(string.format("UI: asked for $%d at step %d", w.amount, session.step))
            w:ask()
            w:close()
          else
            log("UI: no ask window")
          end
          bank:close()
        elseif a == "answermoney" then
          local icon
          for _, candidate in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if not icon and candidate.type == "mp_money" then icon = candidate end
          end
          if icon then
            shot("money-icon")
            if not icon.fax then icon:openMessage() end
            shot("money-fax")
            log(string.format("UI: %s the money request at step %d", entry.arg == "pay" and "paid" or
                "declined", session.step))
            icon.fax:buttonChoice(entry.arg == "pay" and 1 or 2)
          else
            log("UI: no money request to answer")
          end
        elseif a == "key" then
          -- Press a key, as a player would (say Enter or Escape while
          -- somebody else furnishes a room).
          world.ui:onKeyDown(entry.arg, {})
          world.ui:onKeyUp(entry.arg, {})
          log(string.format("UI: pressed %s at step %d", entry.arg, session.step))
        elseif a == "holdroom" then
          -- Draw a room up to its windows and leave the editor open there.
          local room_type = TheApp.rooms[entry.arg ~= "" and entry.arg or "psych"]
          local w, h = 5, 5
          local x, y = builder.find_free_rect(world, desk_x, desk_y, w, h, 40)
          local dlg = UIEditRoom(world.ui, room_type)
          world.ui:addWindow(dlg)
          dlg:setBlueprintRect(x, y, w, h)
          dlg:confirm()
          for tx = x + 1, x + w - 2 do
            dlg:setDoorBlueprint(tx, y + h - 1, "south")
            if dlg.blueprint_door.valid then dlg:placeDoorBlueprint() break end
          end
          held_room = {dlg = dlg, x = x, y = y, w = w, h = h}
          -- The mouse rests over the middle of it (where a player's would be).
          look_at(x + 2, y + 2)
          local sw, sh = TheApp.video:getRenderSize()
          world.ui:onMouseMove(math.floor(sw / 2), math.floor(sh / 2), 0, 0)
          log(string.format("UI: holding a %s at %d,%d in the %s phase (step %d)", room_type.id, x, y,
              tostring(dlg.phase), session.step))
        elseif a == "film" then
          -- Follow a walking person (another player's if there is one) for
          -- <arg> steps; see above.
          local who
          for _, e in ipairs(world.entities) do
            local act = e.humanoid_class and e.hospital and e.action_queue and e.action_queue[1]
            if act and act.name == "walk" and (not who or e.hospital ~= world.ui.hospital) then who = e end
          end
          filming = {who = who, left = tonumber(entry.arg) or 40, n = 0}
          log(string.format("UI: filming %s for %d steps (step %d)", who and who.humanoid_class or "nobody",
              filming.left, session.step))
        elseif a == "shotview" then
          -- Centre the view on this player's first member of staff (the
          -- player colour bars, MultiplayerSession.drawMarkers) and take a
          -- screenshot; arg "others"/"off" sets the colour option first.
          if entry.arg ~= "" then MultiplayerSession.markers = entry.arg end
          local someone = world.ui.hospital.staff[1] or world.ui.hospital.patients[1]
          if someone and someone.tile_x then look_at(someone.tile_x, someone.tile_y) end
          log(string.format("UI: view on own staff, colours %s (step %d)", MultiplayerSession.markers,
              session.step))
          shot("view-" .. MultiplayerSession.markers)
        elseif a == "edge" then
          -- Scroll as far as the camera goes towards the top corner of the
          -- map ("top") or the right one ("right"), and take a screenshot.
          local ui = world.ui
          local dx, dy = 0, -100000
          if entry.arg == "right" then dx, dy = 100000, 0 end
          for _ = 1, 50 do ui:scrollMap(dx / 50, dy / 50) end
          log(string.format("UI: camera at the %s edge: offset %d,%d (step %d)", entry.arg,
              ui.screen_offset_x, ui.screen_offset_y, session.step))
          shot("edge-" .. entry.arg)
        elseif a == "screen" then
          -- Open a window by its class name, take a screenshot, close it.
          -- "<class>:<page>" turns to that page first; a list of staff shows
          -- its first member selected.
          local name_, page = entry.arg:match("^([%w_]+):?(%d*)$")
          local window = _G[name_](world.ui)
          world.ui:addWindow(window)
          if page ~= "" and window.turnPage then window:turnPage(tonumber(page) - 1) end
          if window.selectIndex then window:selectIndex(1) end
          shot("screen-" .. name_ .. page)
          window:close()
        elseif a == "progress" then
          -- The Progress Report, looking at hospital <arg> (a click on its
          -- name): which names can be clicked, the selected one's goals.
          local pr_window = UIProgressReport(world.ui)
          world.ui:addWindow(pr_window)
          local enabled = 0
          for _, b in ipairs(pr_window.buttons) do
            if b.enabled and b.panel_for_sprite and b.panel_for_sprite.x == 265 then enabled = enabled + 1 end
          end
          pr_window.selected = tonumber(entry.arg) or pr_window.selected
          local values = {}
          for _, c in ipairs(pr_window.crit_data) do
            values[#values + 1] = c.name .. "=" ..
                math.floor(world.endconditions:getAttribute(world.hospitals[pr_window.selected], c.name))
          end
          log(string.format("UI: progress report at step %d: own %d, names enabled %d, showing %d (%s): %s",
              session.step, pr_window.own, enabled, pr_window.selected, world.hospitals[pr_window.selected].name,
              table.concat(values, " ")))
          shot("progress-" .. pr_window.selected)
          pr_window:close()
        elseif a == "researchboard" then
          -- The research blackboard, with "Share research" next to the total.
          local board = UIResearch(world.ui)
          world.ui:addWindow(board)
          shot("research-board")
          board:close()
        elseif a == "researchlists" then
          -- MULTIPLAYER > SHARE RESEARCH, then "Next player" round all the
          -- players: what the list offers each of them.
          UIMultiplayerResearch.open(world.ui)
          for _ = 1, (world.mp_coop and world.mp_coop.players or 2) - 1 do
            local w = world.ui:getWindow(UIMultiplayerResearch)
            if not w or not w.target then break end
            local keys = {}
            for _, item in ipairs(w.items or {}) do keys[#keys + 1] = item.key end
            log(string.format("UI: research list for %s: %s", tostring(w.target.name),
                #keys > 0 and table.concat(keys, ",") or "nothing"))
            w:nextPlayer()
          end
          local w = world.ui:getWindow(UIMultiplayerResearch)
          if w then w:close() end
        elseif a == "shareresearch" then
          -- MULTIPLAYER > SHARE RESEARCH: everything, at a price, Offer.
          UIMultiplayerResearch.open(world.ui)
          local w = world.ui:getWindow(UIMultiplayerResearch)
          if w and w.items then
            w:toggleAll(true)
            w:setPrice(tonumber(entry.arg) or 0)
            shot("research-window")
            local names = {}
            for _, item in ipairs(w.items) do names[#names + 1] = item.key end
            log(string.format("UI: offered research %s for $%d at step %d", table.concat(names, ","),
                w.price, session.step))
            w:offer()
            w:close()
          else
            log("UI: no research window")
          end
        elseif a == "answerresearch" then
          local icon
          for _, candidate in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if not icon and candidate.type == "mp_research" then icon = candidate end
          end
          if icon then
            shot("research-icon")
            if not icon.fax then icon:openMessage() end
            shot("research-fax")
            log(string.format("UI: %s the research offer at step %d", entry.arg == "accept" and
                "accepted" or "declined", session.step))
            icon.fax:buttonChoice(entry.arg == "accept" and 1 or 2)
          else
            log("UI: no research offer to answer")
          end
        elseif a == "askraise" then
          session:issue({kind = "probe_raise", class = entry.arg})
        elseif a == "answerraise" then
          local icon
          for _, candidate in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if candidate.type == "strike" then icon = candidate break end
          end
          if icon then
            icon:openMessage()
            local w = world.ui:getWindow(UIStaffRise)
            log(string.format("UI: %s the pay rise of %s at step %d", entry.arg == "accept" and
                "accepted" or "declined", w and tostring(w.staff.profile:getFullName()):gsub("^.*:", "") or "?",
                session.step))
            if w and entry.arg == "accept" then w:increaseSalary() elseif w then w:fireStaff() end
          else
            log("UI: no pay rise request to answer")
          end
        elseif a == "fire" then
          local w = UIStaffManagement(world.ui)
          world.ui:addWindow(w)
          w:setCategory(entry.arg)
          if #(w.staff_members[entry.arg] or {}) > 0 then
            w.selected_staff = 1
            w:fire()
            local confirm = world.ui:getWindow(UIConfirmDialog)
            log(string.format("UI: fired %s %s at step %d", entry.arg,
                (tostring(w.staff_members[entry.arg][1].profile:getFullName()):gsub("^.*:", "")), session.step))
            if confirm then confirm:ok() end
          else
            log("UI: nobody to fire in " .. entry.arg)
          end
          w:close()
        elseif a == "queuefront" then
          -- Drag the last patient of a queue of this hospital to its front.
          local queue
          for _, e in ipairs(world.entities) do
            if not queue and e.queue and e.queue:reportedSize() >= 2 then
              local p1 = e.queue:reportedHumanoid(1)
              if p1 and p1.hospital == world.ui.hospital then queue = e.queue end
            end
          end
          if not queue then
            local sizes, patients = {}, 0
            for _, e in ipairs(world.entities) do
              if e.queue then sizes[#sizes + 1] = e.queue:reportedSize() .. "/" .. e.queue:size() end
              if class.is(e, Patient) then patients = patients + 1 end
            end
            log(string.format("UI: queue sizes at step %d: %s (%d patients)", session.step,
                table.concat(sizes, " "), patients))
          end
          if not queue and (entry.retries or 0) < 40 and entry.hour < target - 100 then
            -- Not now; look again a little later.
            entry.retries = (entry.retries or 0) + 1
            entry.hour = entry.hour + 10
            done[i] = nil
          elseif queue then
            local w = UIQueue(world.ui, queue)
            world.ui:addWindow(w)
            local n = queue:reportedSize()
            local patient = queue:reportedHumanoid(n)
            w.dragged = {patient = patient}
            local s = TheApp.gfx:getUIScale()
            log(string.format("UI: dragged patient #%s from place %d to the front at step %d",
                tostring(patient.mp_id), n, session.step))
            w:onMouseUp("left", 190 * s, 60 * s)
            w:close()
          else
            local sizes = {}
            for _, e in ipairs(world.entities) do
              if e.queue then sizes[#sizes + 1] = e.queue:reportedSize() .. "/" .. e.queue:size() end
            end
            log("UI: no queue of two to reorder; queues " .. table.concat(sizes, " "))
          end
        elseif a == "waitrejoin" then
          -- Pause (shared) until a player has rejoined, then play on.
          log("UI: paused for a rejoin at step " .. session.step)
          waiting_rejoin = session.restarts or 0
          world:setUserSpeed("Pause")
        elseif a == "cheat" then
          world.hospitals[1].balance = world.hospitals[1].balance + 1
          log("UI: changed money locally only (cheat)")
        elseif live then log("UI: unknown action " .. a .. " (ignored)") -- a typo must not end a person's game
        else error("unknown UI action " .. a) end
      end
    end
    if session.step == before then
      socket.sleep(0.001)
      if lobby.transport.closed then log("SERVER CONNECTION LOST at step " .. session.step) break end
      local limit = stall_limit or (world:isCurrentSpeed("Pause") and 30 or 20)
      if socket.gettime() - last_progress > limit then
        log(string.format("NO PROGRESS for %d s at step %d (speed %s)", limit, session.step,
            tostring(world:getCurrentSpeed())))
        break
      end
    else
      last_progress = socket.gettime()
    end
  end
  if not quit then
    -- Let the last reports arrive so the final steps are compared too.
    local deadline = socket.gettime() + 10
    while socket.gettime() < deadline and not session.desync do
      session:poll()
      local behind = false
      for _, s in pairs(session.peer_step) do if s < session.step then behind = true end end
      if not behind then break end
      socket.sleep(0.01)
    end
  end
  log("final " .. MultiplayerSession.defaultFingerprint(world))
  log(string.format("wall seconds %.1f for %d steps (game started %.1f s after the probe)",
      socket.gettime() - probe_started - (game_started or 0), session.step, game_started or 0))
  log(string.format("steps=%d ticks=%d issued=%d applied=%d rejected=%d peers=%d",
      session.step, ticks, session.stats.issued, session.stats.applied,
      session.stats.rejected, #session.peers))
  log("speeds seen: " .. table.concat(speed_seen, ","))
  local rooms = {}
  for _, r in pairs(world.rooms) do
    if r.built then rooms[#rooms + 1] = string.format("%s@%d,%d", r.room_info.id, r.x, r.y) end
  end
  table.sort(rooms)
  log("rooms built: " .. table.concat(rooms, " "))
  for i, h in ipairs(world.hospitals) do
    local classes = {}
    for _, s in ipairs(h.staff) do classes[#classes + 1] = s.humanoid_class end
    table.sort(classes)
    log(string.format("hospital %d %s: balance %s, open %s, staff %s", i, h.name, tostring(h.balance),
        tostring(h.opened), table.concat(classes, ",")))
    if h.research then
      -- What it knows (to compare between players): equipment, drugs.
      local known, drugs = {}, {}
      for _, o in ipairs(TheApp.objects) do
        local progress = o.thob and h.research.research_progress[o]
        if progress and progress.discovered and o.research_category then known[#known + 1] = o.id end
      end
      local ids = {}
      for id, entry in pairs(h.disease_casebook) do if entry.drug then ids[#ids + 1] = id end end
      table.sort(ids)
      for _, id in ipairs(ids) do
        drugs[#drugs + 1] = id .. "=" .. h.disease_casebook[id].cure_effectiveness
      end
      log(string.format("hospital %d research: %s; drugs %s", i, table.concat(known, ","),
          table.concat(drugs, ",")))
    end
    if h.research and h.heating then
      log(string.format("hospital %d settings: loan %s, heat %s, cure research %s%%", i,
          tostring(h.loan), tostring(h.heating.radiator_heat),
          tostring(h.research.research_policy.cure and h.research.research_policy.cure.frac)))
    end
  end
  -- Objects bought but not placed yet (the placement window's list).
  for _, window in ipairs(TheApp.ui.windows or {}) do
    if class.type(window) == "UIPlaceObjects" then
      local waiting = {}
      for _, o in ipairs(window.objects) do waiting[#waiting + 1] = o.object.id .. " x" .. o.qty end
      log("objects to place: " .. table.concat(waiting, ", "))
    end
  end
  local chat = TheApp.ui:getWindow(UIMultiplayerChat)
  if chat then
    local seen = {}
    for _, line in ipairs(chat.lines) do seen[#seen + 1] = line.text .. (line.private and " [private]" or "") end
    log("chat seen: " .. table.concat(seen, " | "))
  end
  log(session.desync and ("RESULT: DESYNC at step " .. session.desync.step)
      or ("RESULT: IN SYNC through step " .. session.step))
  lobby:disconnect()
  log("PROBE: DONE")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  io.stderr:flush()
  os.exit(1)
end
os.exit(0)
