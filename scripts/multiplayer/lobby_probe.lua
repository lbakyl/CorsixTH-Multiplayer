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
--   MP_SCENARIO       light | busy | none                (default light; none: no
--                     test setup, to join a game a person hosts)
--   MP_STEPS          game hours to play                 (default 1500)
--   MP_FAST           1: run at the fastest local speed (test only, default 1)
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
local shot_dir = os.getenv("MP_SHOT_DIR")
-- With the server's referee a desync is repaired: keep playing through it.
local expect_repair = os.getenv("MP_EXPECT_REPAIR") == "1"
-- Join a running game again (this name left it earlier).
local rejoin = os.getenv("MP_REJOIN") == "1"

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

local function tick()
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
  w:buttonConnect()
  local lobby = assert(TheApp.mp_lobby, "not connected: " .. tostring(w.status_text))
  log("connected as " .. lobby.build)
  wait_for("room list", function() return lobby.state == "connected" and lobby_window() and lobby_window().view == "rooms" end)

  if role == "host" then
    w = lobby_window()
    w.room_name_box:setText(room)
    w.password_box:setText(password)
    if coop then w:buttonMode() end -- "A hospital each"
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
    wait_for("room " .. room, function()
      for i, r in ipairs(lobby.rooms) do
        if r.room == room then index = i return true end
      end
      lobby:refreshRooms()
      socket.sleep(0.2)
      return false
    end, 30)
    w = lobby_window()
    shot("lobby-rooms")
    w:selectRoom(index, true)
    w.password_box:setText(join_password)
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

local function run()
  assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
  assert(TheApp.good_install_folder, "Game data was not accepted")
  socket = require("socket")

  local lobby = run_lobby()
  if not lobby then log("PROBE: DONE") return end
  local session = assert(TheApp.mp_session, "no session after start")
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
  elseif scenario == "none" then
    -- Playing with a person: their game has no test setup, so neither has this.
    builder.register_handlers()
    if world.mp_coop then builder.hospital = world.ui.hospital end -- this player's own
  else
    -- The same test setup runs on every peer (and on the server's referee).
    desk_x, desk_y = builder.start_game(world, session, scenario, log)
  end
  if fast then world:setSpeed("And then some more") end
  if desk_x then look_at(desk_x, desk_y) end
  shot("game-start")

  local done = {}
  local ticks = 0
  local last_progress = socket.gettime()
  local quit = false
  local speed_seen = {}
  local seen_blueprints = {}
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
    tick()
    ticks = ticks + 1
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
      log(string.format("REPAIRED: loaded the shared save at step %d (repair %d); messages shown: %s; watches: %s",
          session.step, repairs, table.concat(shown, ","), table.concat(watches, ",")))
    end
    if TheApp.world ~= world then log("LEVEL ENDED at step " .. session.step) break end
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
        for name in pairs(object and object.orientations or {}) do facings[#facings + 1] = name end
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
          if icon then
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
          local patient
          for _, p in ipairs(world.ui.hospital.patients) do
            if not patient and MultiplayerSession.referable(p) and not p.mp_offer then patient = p end
          end
          if patient then
            local w = UIPatient(world.ui, patient)
            world.ui:addWindow(w)
            shot("patient-refer")
            log(string.format("UI: referred patient #%d at step %d", patient.mp_id, session.step))
            w:referPatient()
            w:close()
          else
            log("UI: no patient to refer")
          end
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
        elseif a == "notreatfax" then
          session:issue({kind = "probe_notreat"})
        elseif a == "sendstaff" then
          local trade = UIMultiplayerTrade(world.ui)
          world.ui:addWindow(trade)
          local row
          for i, e in ipairs(trade.staff_list) do
            if not row and e.staff.humanoid_class == entry.arg then row = i end
          end
          if row then
            trade:selectStaff(row, true)
            log(string.format("UI: sent %s %s to %s at step %d", entry.arg,
                tostring(trade.staff_list[row].staff.profile:getFullName()), trade.target.name, session.step))
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
            if not icon and i.type == ftype and (not world.mp_coop or i.hospital == world.ui.hospital) then
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
          -- put it down a few tiles away, or sell it (close the window).
          local obj
          for _, e in ipairs(world.entities) do
            if not obj and class.is(e, Object) and e.object_type.id == entry.arg and e.tile_x and
                not e:getRoom() and world.ui.hospital:isInHospital(e.tile_x, e.tile_y) then
              obj = e
            end
          end
          if obj then
            obj:onClick(world.ui, "right")
            local place = world.ui:getWindow(UIPlaceObjects)
            if a == "moveobject" and place then
              local x, y = builder.find_free_rect(world, obj.tile_x + 3, obj.tile_y, 1, 1, 10,
                  function(tx, ty) return not world:anyHumanoidObscuringArea(tx, ty) end)
              place:setBlueprintCell(x, y)
              place.object_cell_x, place.object_cell_y = x, y
              place:onMouseUp("left", 100000, 100000)
              log(string.format("UI: moved %s #%d from %d,%d to %d,%d at step %d", entry.arg, obj.mp_id,
                  obj.tile_x, obj.tile_y, x, y, session.step))
              place = world.ui:getWindow(UIPlaceObjects)
              if place then place:close(true) end -- click refused: put it back
            elseif place then
              log(string.format("UI: sold %s #%d at step %d", entry.arg, obj.mp_id, session.step))
              place:close(false)
            end
          else
            log("UI: no " .. entry.arg .. " to pick up")
          end
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
        elseif a == "inputerror" then
          -- An error in the mouse movement handler, as the game reports it
          -- (App:errorHandler): in multiplayer the handler stays connected.
          local had_handler = TheApp.eventHandlers.motion ~= nil
          TheApp:errorHandler("motion", "probe: an error in the motion handler")
          log(string.format("UI: motion handler after an error at step %d: %s (before %s)", session.step,
              TheApp.eventHandlers.motion ~= nil and "connected" or "disconnected", tostring(had_handler)))
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
                text(r.value)}, "|")
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
        elseif a == "patients" then
          session:issue({kind = "probe_patients", n = tonumber(entry.arg)})
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
        elseif a == "researchboard" then
          -- The research blackboard, with "Share research" next to the total.
          local board = UIResearch(world.ui)
          world.ui:addWindow(board)
          shot("research-board")
          board:close()
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
