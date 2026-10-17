-- In-game multiplayer probe. Run through the CorsixTH executable with
-- --interpreter=<this file>. Unlike sync_probe.lua, the lockstep here is done
-- by the game itself (MultiplayerSession + World:onTick); this script only
-- ticks the game and performs player actions through the real UI windows.
--
-- Environment:
--   CORSIXTH_SOURCE   checkout root (required)
--   MP_MODE           host | client | solo (no session: normal single
--                     player, to check the same UI actions still work)
--   MP_HOST, MP_PORT  TCP endpoint                    (default 127.0.0.1:47900)
--   MP_SEED           shared random seed              (default 12345)
--   MP_SCENARIO       light | busy                    (default busy)
--   MP_STEPS          game hours to play              (default 3000)
--   MP_UI_SCRIPT      player actions through the UI, ";"-separated
--                     "hour:action[:arg]" with actions
--                       buy:<object>   corridor shop -> confirm -> click map
--                       hire:<class>   hire window -> Hire -> click map
--                       pickup         right-click an object (refused in MP)
--                       cheat          change money locally only (must desync)
--                       pause:<ticks>  pause this peer's game for <ticks> ticks
--                       speedup:<ticks> use "Speed Up" (8 hours per tick) for <ticks>
--   MP_DRAW_EVERY     draw a frame every N ticks (0 = never)
--   MP_LUA_CPATH, MP_LUA_PATH  where to find LuaSocket
local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local mode = assert(os.getenv("MP_MODE"), "Missing MP_MODE")
local seed = tonumber(os.getenv("MP_SEED") or "12345")
local scenario = os.getenv("MP_SCENARIO") or "busy"
local target = tonumber(os.getenv("MP_STEPS") or "3000")
local draw_every = tonumber(os.getenv("MP_DRAW_EVERY") or "0")
local peer_id = mode == "host" and 1 or 2
local solo = mode == "solo"

local function log(msg)
  io.stdout:write("[" .. mode .. "] " .. msg .. "\n")
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

-- Shared setup, identical on both peers, done before the session starts.
local function setup(world)
  local hospital = world.hospitals[1]
  local cx, cy = world.map.th:getCameraTile(1)
  local desk_x, desk_y = builder.find_free_rect(world, cx, cy, 1, 3, 25)
  builder.place_object(world, "reception_desk", desk_x, desk_y, "north")
  builder.hire(world, "Receptionist", desk_x + 2, desk_y + 2)
  if scenario == "busy" then
    for _, spec in ipairs({{"gp", 5, 5}, {"pharmacy", 4, 4}, {"general_diag", 5, 5},
        {"staff_room", 5, 5}, {"toilets", 4, 4}}) do
      local x, y = builder.find_free_rect(world, desk_x, desk_y, spec[2], spec[3], 40)
      assert(builder.build_room(world, spec[1], x, y, spec[2], spec[3]), "building " .. spec[1])
    end
    for i, class in ipairs({"Doctor", "Doctor", "Doctor", "Nurse", "Nurse", "Handyman", "Handyman"}) do
      builder.hire(world, class, desk_x + i, desk_y + 3)
    end
  end
  hospital:open()
  return desk_x, desk_y
end

-- Simulated mouse click at a map tile, in window-relative coordinates.
local function click_tile(ui, window, button, tx, ty)
  local sx, sy = ui:WorldToScreen(tx + 0.5, ty + 0.5)
  return window:onMouseUp(button, sx - window.x, sy - window.y)
end

local function ui_buy(world, desk_x, desk_y, object_id)
  local ui = world.ui
  local shop = UIFurnishCorridor(ui)
  ui:addWindow(shop)
  local found
  for _, o in ipairs(shop.objects) do
    if o.object.id == object_id then o.qty = o.qty + 1 found = true end
  end
  assert(found, "shop does not sell " .. object_id)
  local balance_before = world.hospitals[1].balance
  shop:confirm() -- opens UIPlaceObjects
  local place = ui:getWindow(UIPlaceObjects)
  assert(place, "no placement window")
  -- Same search order on both peers, but only this peer clicks.
  local x, y = builder.find_free_rect(world, desk_x, desk_y, 1, 1, 40)
  place:setBlueprintCell(x, y)
  place.object_cell_x, place.object_cell_y = x, y
  place:onMouseUp("left", 100000, 100000) -- a click outside the window
  log(string.format("UI: bought %s, clicked %d,%d (balance unchanged locally: %s)",
      object_id, x, y, tostring(world.hospitals[1].balance == balance_before)))
  if ui:getWindow(UIPlaceObjects) then ui:getWindow(UIPlaceObjects):close() end
end

local function ui_hire(world, desk_x, desk_y, class)
  local ui = world.ui
  local dlg = UIHireStaff(ui)
  ui:addWindow(dlg)
  dlg:setCategory(class)
  local pool = world.available_staff[class]
  assert(pool and #pool > 0, "nobody to hire in " .. class)
  local name = tostring(pool[dlg.current_index]:getFullName()):gsub("^.*:", "")
  dlg.mouse_up_x, dlg.mouse_up_y = 0, 0 -- where the click happened
  dlg:hire() -- opens UIPlaceStaff
  local place = ui:getWindow(UIPlaceStaff)
  assert(place, "no staff placement window")
  place.tile_x, place.tile_y = desk_x + 1, desk_y + 4
  place.onMouseMove = function() end -- keep the tile we set (no real cursor)
  place:onMouseUp("left", 0, 0)
  log(string.format("UI: hired %s %s at %d,%d (pool size still %d)", class, name,
      desk_x + 1, desk_y + 4, #pool))
  if ui:getWindow(UIHireStaff) then ui:getWindow(UIHireStaff):close() end
end

local function ui_pickup(world)
  for _, e in ipairs(world.entities) do
    if e.object_type and e.object_type.id == "bench" then
      local before = e.picked_up
      e:onClick(world.ui, "right")
      log("UI: right-clicked a bench to pick it up; picked up: " .. tostring(e.picked_up and not before))
      return
    end
  end
  log("UI: no bench to pick up")
end

local function run()
  assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
  assert(TheApp.good_install_folder, "Game data was not accepted")
  corsixth.require("mp_transport")
  assert(MultiplayerTransport.available(), "LuaSocket not found (set MP_LUA_CPATH)")
  local host = os.getenv("MP_HOST") or "127.0.0.1"
  local port = tonumber(os.getenv("MP_PORT") or "47900")
  local transport
  if not solo then
    transport = assert(mode == "host" and MultiplayerTransport.host(host, port, 30)
        or MultiplayerTransport.join(host, port, 30))
    log("connected")
  end

  local socket = require("socket")
  math.randomseed(seed)
  TheApp:_loadLevel(1, "full", nil, "LEVEL.L1")
  local world = TheApp.world
  local desk_x, desk_y = setup(world)
  world:setSpeed("And then some more")

  local session
  if solo then
    -- Stand-in so the loop below can count hours the same way.
    session = {step = 0, stats = {issued = 0, applied = 0, rejected = 0, stalls = 0},
        peer_step = {}, poll = function() end}
  else
    session = MultiplayerSession({world = world, peer_id = peer_id, peers = {1, 2},
        transport = transport, log = log,
        clock = function() return socket.gettime() * 1000 end,
        notify = function(msg)
          log("NOTICE to player: " .. msg)
          world.ui.adviser:say({text = msg, priority = 10})
        end})
    TheApp.mp_session = session
  end
  log("session started, " .. #world.hospitals[1].staff .. " staff")

  local done = {}
  local ticks = 0
  local last_progress = socket.gettime()
  local last_date = world.game_date:tostring()
  local resume_at, max_peer_gap, paused_ticks = nil, 0, 0
  while session.step < target and not session.desync do
    local before = session.step
    TheApp:onTick()
    if resume_at and ticks >= resume_at then
      world:setSpeed("And then some more")
      resume_at = nil
      log("UI: resumed at step " .. session.step)
    end
    if world:isCurrentSpeed("Pause") then paused_ticks = paused_ticks + 1 end
    for _, s in pairs(session.peer_step or {}) do
      max_peer_gap = math.max(max_peer_gap, math.abs(session.step - s))
    end
    if solo and world.game_date:tostring() ~= last_date then
      last_date = world.game_date:tostring()
      session.step = session.step + 1
    end
    ticks = ticks + 1
    if TheApp.world ~= world then log("LEVEL ENDED at step " .. session.step) break end
    if draw_every > 0 and ticks % draw_every == 0 then TheApp:drawFrame() end
    -- Close the annual report like a player would, at the same step on both.
    local report = TheApp.ui:getWindow(UIAnnualReport)
    if report then report:close() end
    for i, entry in ipairs(ui_script) do
      if not done[i] and session.step >= entry.hour then
        done[i] = true
        if entry.action == "buy" then ui_buy(world, desk_x, desk_y, entry.arg)
        elseif entry.action == "hire" then ui_hire(world, desk_x, desk_y, entry.arg)
        elseif entry.action == "pickup" then ui_pickup(world)
        elseif entry.action == "pause" or entry.action == "speedup" then
          world:setSpeed(entry.action == "pause" and "Pause" or "Speed Up")
          resume_at = ticks + tonumber(entry.arg)
          log(string.format("UI: %s for %s ticks at step %d", entry.action, entry.arg, session.step))
        elseif entry.action == "cheat" then
          world.hospitals[1].balance = world.hospitals[1].balance + 1
          log("UI: changed money locally only (cheat)")
        else error("unknown UI action " .. entry.action) end
      end
    end
    if session.step == before then
      socket.sleep(0.001) -- waiting for the peer
      if transport and transport.closed then log("PEER DISCONNECTED at step " .. session.step) break end
      if socket.gettime() - last_progress > 20 then
        log("PEER NOT RESPONDING for 20 s at step " .. session.step)
        break
      end
    else
      last_progress = socket.gettime()
    end
  end
  -- Let the last reports arrive so the final steps are compared too.
  local deadline = socket.gettime() + 10
  while socket.gettime() < deadline and not session.desync do
    session:poll()
    local behind = false
    for _, s in pairs(session.peer_step) do if s < session.step then behind = true end end
    if not behind then break end
    socket.sleep(0.01)
  end
  log("final " .. MultiplayerSession.defaultFingerprint(world))
  log(string.format("steps=%d ticks=%d issued=%d applied=%d rejected=%d stalls=%d",
      session.step, ticks, session.stats.issued, session.stats.applied,
      session.stats.rejected, session.stats.stalls))
  log(string.format("max step gap to peer=%d, ticks spent paused=%d", max_peer_gap, paused_ticks))
  if solo then
    log("RESULT: SOLO through step " .. session.step)
  else
    log(session.desync and ("RESULT: DESYNC at step " .. session.desync.step)
        or ("RESULT: IN SYNC through step " .. session.step))
    transport:close()
  end
  TheApp.mp_session = nil
  log("PROBE: DONE")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  io.stderr:flush()
  os.exit(1)
end
os.exit(0)
