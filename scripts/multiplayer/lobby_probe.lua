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
--                       buy:<object>, hire:<class>      as in ingame_probe.lua
--                       room:<id>:<w>:<h>[:window]      draw a room in the room editor
--                       crowdroom:<id>:<w>:<h>          draw it where somebody stands
--                       vip[:<hospital>]                make a VIP visit fax appear for
--                                                       a hospital (test-only command)
--                       emergency[:<hospital>]          an emergency fax for a hospital
--                                                       (test-only command)
--                       answerfax:<type>:<n>            open the first fax of <type> and
--                                                       click choice <n> in the fax window
--                       openhospital                    click the opening watch's button
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
      log(string.format("REPAIRED: loaded the shared save at step %d (repair %d)", session.step, repairs))
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
        elseif a == "vip" then
          session:issue({kind = "probe_vip", target = tonumber(entry.arg) or 1})
          log("UI: asked for a VIP fax at step " .. session.step)
        elseif a == "answerfax" then
          local ftype, n = entry.arg:match("^(%a+):(%d+)$")
          local icon
          for _, i in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if i.type == ftype then icon = i break end
          end
          if icon then
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
            furnishing = {cancel = a == "cancelroom", pace = furnish_pace,
                not_before = furnish_pace and session.step + furnish_pace}
          end
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
    if h.research and h.heating then
      log(string.format("hospital %d settings: loan %s, heat %s, cure research %s%%", i,
          tostring(h.loan), tostring(h.heating.radiator_heat),
          tostring(h.research.research_policy.cure and h.research.research_policy.cure.frac)))
    end
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
