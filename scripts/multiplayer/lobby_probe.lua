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
--   MP_SCENARIO       light | busy                       (default light)
--   MP_STEPS          game hours to play                 (default 1500)
--   MP_FAST           1: run at the fastest local speed (test only, default 1)
--   MP_UI_SCRIPT      ";"-separated "hour:action[:arg]":
--                       buy:<object>, hire:<class>      as in ingame_probe.lua
--                       room:<id>:<w>:<h>[:window]      draw a room in the room editor
--                       crowdroom:<id>:<w>:<h>          draw it where somebody stands
--                       vip                             make a VIP visit fax appear for
--                                                       everybody (test-only command)
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
--   MP_DRAW_EVERY     draw a frame every N ticks (0 = never)
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
local target = tonumber(os.getenv("MP_STEPS") or "1500")
local fast = (os.getenv("MP_FAST") or "1") == "1"
local draw_every = tonumber(os.getenv("MP_DRAW_EVERY") or "0")
local coop = os.getenv("MP_COOP") == "1"

local function log(msg)
  io.stdout:write("[" .. name .. "] " .. msg .. "\n")
  io.stdout:flush()
end

if os.getenv("MP_LUA_CPATH") then package.cpath = os.getenv("MP_LUA_CPATH") .. ";" .. package.cpath end
if os.getenv("MP_LUA_PATH") then package.path = os.getenv("MP_LUA_PATH") .. ";" .. package.path end

local builder = assert(loadfile(source_dir .. "/scripts/multiplayer/probe_builder.lua"))()

local ui_script = {}
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

local function run_lobby()
  local menu = assert(TheApp.ui:getWindow(UIMainMenu), "no main menu")
  menu:buttonMultiplayer()
  local w = assert(lobby_window(), "no multiplayer window")
  w.address_box:setText(server)
  w.name_box:setText(name)
  w:buttonConnect()
  local lobby = assert(TheApp.mp_lobby, "not connected: " .. tostring(w.status_text))
  log("connected as " .. lobby.build)
  wait_for("room list", function() return lobby.state == "connected" and lobby_window() and lobby_window().view == "rooms" end)

  if role == "host" then
    w = lobby_window()
    w.room_name_box:setText(room)
    w.password_box:setText(password)
    if coop then w:buttonMode() end -- "A hospital each"
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
    w:selectRoom(index, true)
    w.password_box:setText(join_password)
    w:buttonJoin()
    wait_for("joining", function() return lobby.state == "in_room" or lobby.error ~= nil end)
    if lobby.state ~= "in_room" then
      log("JOIN REFUSED: " .. tostring(lobby.error.code))
      return nil
    end
    log("joined room " .. room .. " as player " .. lobby.room.peer)
    wait_for("ready button", function() return lobby_window() and lobby_window().view == "room" end)
    lobby_window():buttonReady(true)
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

  -- Test-only command, registered on every peer: a VIP asks to visit.
  MultiplayerSession.default_handlers.probe_vip = function(w)
    w.hospitals[1]:createVip()
    return true
  end

  -- Same setup on every peer before the first step, so it stays in sync.
  -- It changes the shared world directly, like a command handler does.
  session.applying = true
  local desk_x, desk_y
  if world.mp_coop then
    -- Each player's hospital gets the same start, in hospital order.
    for i = 1, world.mp_coop.players do
      builder.hospital = world.hospitals[i]
      local x, y = builder.setup_scenario(world, scenario, true)
      if world.hospitals[i] == world.ui.hospital then desk_x, desk_y = x, y end
    end
    builder.hospital = world.ui.hospital -- the UI actions below are this player's
    log(string.format("co-op: %d hospitals, playing %s (hospital %d)", world.mp_coop.players,
        world.ui.hospital.name, world:getHospitalIndex(world.ui.hospital)))
  else
    desk_x, desk_y = builder.setup_scenario(world, scenario)
  end
  session.applying = false
  if fast then world:setSpeed("And then some more") end

  local done = {}
  local ticks = 0
  local last_progress = socket.gettime()
  local quit = false
  local speed_seen = {}
  local seen_blueprints = {}
  local presses = {} -- {wait = ticks, paused = only count while paused}
  local last_speed = world:getCurrentSpeed()
  while session.step < target and not session.desync and not quit do
    local before = session.step
    tick()
    ticks = ticks + 1
    if TheApp.world ~= world then log("LEVEL ENDED at step " .. session.step) break end
    for peer, r in pairs(session.remote_blueprints) do
      local key = string.format("%d:%s:%d,%d", peer, tostring(r.room), r.x, r.y)
      if peer ~= session.peer_id and not seen_blueprints[key] then
        seen_blueprints[key] = true
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
    for i, entry in ipairs(ui_script) do
      if not done[i] and session.step >= entry.hour then
        done[i] = true
        local a = entry.action
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
        elseif a == "vip" then
          session:issue({kind = "probe_vip"})
          log("UI: asked for a VIP fax at step " .. session.step)
        elseif a == "answerfax" then
          local ftype, n = entry.arg:match("^(%a+):(%d+)$")
          local icon
          for _, i in ipairs(world.ui.bottom_panel:allMessageIcons()) do
            if i.type == ftype then icon = i break end
          end
          if icon then
            if not icon.fax then icon:openMessage() end
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
        elseif a == "cheat" then
          world.hospitals[1].balance = world.hospitals[1].balance + 1
          log("UI: changed money locally only (cheat)")
        else error("unknown UI action " .. a) end
      end
    end
    if session.step == before then
      socket.sleep(0.001)
      if lobby.transport.closed then log("SERVER CONNECTION LOST at step " .. session.step) break end
      local limit = world:isCurrentSpeed("Pause") and 30 or 20
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
