-- Helpers that perform player actions through the game's own UI code paths
-- (UIEditRoom, UIPlaceObjects, staff profiles), without mouse input.
-- Diagnostic / experimental: used by sync_probe.lua to build a busier
-- hospital, and as the first "apply a command" implementation.
--
-- Every function is deterministic given the game state: it searches tiles in
-- a fixed order and consumes gameplay randomness only where the game itself
-- would (e.g. staff profile generation).

local builder = {}

-- The hospital the helpers act for (multiplayer co-op probes set it).
builder.hospital = nil
local function hospital_of(world) return builder.hospital or world.hospitals[1] end

--! Is every tile of the rectangle (plus a one-tile margin) free hospital floor?
local function rect_is_free(world, x, y, w, h)
  local hospital = hospital_of(world)
  local th = world.map.th
  local mw, mh = th:size()
  if x - 1 < 1 or y - 1 < 1 or x + w > mw or y + h > mh then return false end
  for tx = x - 1, x + w do
    for ty = y - 1, y + h do
      if not hospital:isInHospital(tx, ty) or world:getRoom(tx, ty) then return false end
      local flags = th:getCellFlags(tx, ty)
      if not (flags.buildable and flags.passable) then return false end
      if world:getObject(tx, ty) then return false end
    end
  end
  return true
end

--! Find the nearest free rectangle to (cx, cy), scanning in a fixed order.
--!param extra (function) optional; x, y -> also acceptable?
function builder.find_free_rect(world, cx, cy, w, h, max_radius, extra)
  for r = 0, max_radius or 30 do
    for dy = -r, r do
      for dx = -r, r do
        if math.max(math.abs(dx), math.abs(dy)) == r then
          local x, y = cx + dx, cy + dy
          if rect_is_free(world, x, y, w, h) and (not extra or extra(x, y)) then return x, y end
        end
      end
    end
  end
end

--! Build a room of the given type at an exact rectangle, the way a player
--! would: outline, door, (no windows), clear area, required objects, confirm.
--!param door (table) optional {x=, y=, wall=} door position; otherwise the
--!  first valid position around the edge (fixed search order) is used.
--!param no_wait (bool) if true, fail instead of ticking the game while
--!  people walk out of the area (used when applying lockstep commands, which
--!  must not advance game time).
--!return room on success, or nil and an error message.
function builder.build_room(world, room_id, x, y, w, h, door, no_wait)
  -- The room editor works for ui.hospital; build for the helpers' hospital
  -- (multiplayer co-op setup builds in every player's hospital).
  local ui = world.ui
  local saved = ui.hospital
  ui.hospital = hospital_of(world)
  local results = {pcall(builder._build_room, world, room_id, x, y, w, h, door, no_wait)}
  ui.hospital = saved
  if not results[1] then error(results[2], 0) end
  return results[2], results[3], results[4]
end

function builder._build_room(world, room_id, x, y, w, h, door, no_wait)
  local ui = world.ui
  local room_type = TheApp.rooms[room_id]
  if not room_type then return nil, "unknown room type " .. room_id end
  if not hospital_of(world).research.research_progress[room_type] then
    return nil, room_id .. " is not available on this level"
  end

  local dlg = UIEditRoom(ui, room_type)
  ui:addWindow(dlg)

  -- 1. Walls
  dlg:setBlueprintRect(x, y, w, h)
  if not dlg.confirm_button.enabled then
    dlg:close()
    return nil, "invalid room outline"
  end
  dlg:confirm(true)
  if dlg.phase ~= "door" then
    dlg:close()
    return nil, "room would block part of the hospital"
  end

  -- 2. Door: given position, or first valid spot clockwise from the top-left.
  local candidates = {}
  if door then
    candidates[1] = door
  else
    -- Corner tiles are skipped: UIEditRoom:_finishRoomFoundation() handles the
    -- top-left corner specially and would not create a door there.
    for tx = x + 1, x + w - 2 do candidates[#candidates + 1] = {x = tx, y = y, wall = "north"} end
    for ty = y + 1, y + h - 2 do candidates[#candidates + 1] = {x = x + w - 1, y = ty, wall = "east"} end
    for tx = x + w - 2, x + 1, -1 do candidates[#candidates + 1] = {x = tx, y = y + h - 1, wall = "south"} end
    for ty = y + h - 2, y + 1, -1 do candidates[#candidates + 1] = {x = x, y = ty, wall = "west"} end
  end
  local placed_door
  for _, c in ipairs(candidates) do
    dlg:setDoorBlueprint(c.x, c.y, c.wall)
    if dlg.blueprint_door.valid then
      placed_door = c
      dlg:placeDoorBlueprint() -- confirms -> windows phase
      break
    end
  end
  if not placed_door then
    dlg:abortRoom()
    return nil, "no valid door position"
  end

  -- 3. Windows: none. 4. Clear area: may need ticks for people to walk out.
  dlg:confirm(true)
  if no_wait and dlg.phase == "clear_area" then
    dlg:abortRoom()
    return nil, "people are standing in the area"
  end
  local guard = 0
  while dlg.phase == "clear_area" and guard < 2000 do
    TheApp:onTick()
    guard = guard + 1
  end
  if dlg.phase ~= "objects" and dlg.phase ~= "closed" then
    return nil, "room area did not clear (phase " .. tostring(dlg.phase) .. ")"
  end

  -- 5. Required objects: try every tile and orientation in a fixed order.
  local orientations = {"north", "east", "south", "west"}
  local attempts = 0
  while dlg.phase == "objects" and #dlg.objects > 0 and attempts < 20 do
    attempts = attempts + 1
    -- UIEditRoom fills dlg.objects with pairs() over a string-keyed table,
    -- whose order varies between processes (Lua string hash seeding). Pick
    -- objects in name order so every peer places them identically.
    local first = 1
    for i, o in ipairs(dlg.objects) do
      if o.object.id < dlg.objects[first].object.id then first = i end
    end
    dlg:setActiveIndex(first)
    local done = false
    for ty = y, y + h - 1 do
      for tx = x, x + w - 1 do
        for _, o in ipairs(orientations) do
          if dlg.objects[dlg.active_index].object.orientations[o] then
            dlg:setOrientation(o)
            dlg:setBlueprintCell(tx, ty)
            if dlg.object_blueprint_good then
              dlg:placeObject()
              done = true
              break
            end
          end
        end
        if done then break end
      end
      if done then break end
    end
    if not done then
      dlg:abortRoom()
      return nil, "could not place " .. dlg.objects[dlg.active_index].object.id
    end
  end

  -- 6. Confirm: pays for the room and marks it built.
  if dlg.phase == "objects" then
    if not dlg.confirm_button.enabled then
      dlg:abortRoom()
      return nil, "required objects missing"
    end
    dlg:confirm(true)
  end
  local room = world:getRoom(x, y)
  if not room or not room.is_active then
    return nil, "room not active after confirm"
  end
  return room, nil, placed_door
end

--! Place a single corridor object (bench, plant, desk...) like UIPlaceObjects.
function builder.place_object(world, object_id, x, y, orientation)
  local object_type = world.object_types[object_id]
  local footprint = object_type.orientations[orientation].footprint
  world:prepareFootprintTilesForBuild(footprint, x, y)
  local obj = world:newObject(object_id, x, y, orientation)
  local hospital = hospital_of(world)
  hospital:spendMoney(hospital:getObjectBuildCost(object_id), "probe: " .. object_id)
  return obj
end

--! Hire a staff member of the given class and place them at (x, y), using the
--! same sequence as Hospital:initStaff() for level-provided staff.
function builder.hire(world, class, x, y, skill)
  local hospital = hospital_of(world)
  -- If the tile is not corridor floor of the hospital (e.g. on a co-op map),
  -- use the nearest one that is, in a fixed search order.
  local th = world.map.th
  local function usable(tx, ty)
    local mw, mh = th:size()
    return tx >= 1 and ty >= 1 and tx <= mw and ty <= mh and hospital:isInHospital(tx, ty) and
        not world:getRoom(tx, ty) and th:getCellFlags(tx, ty).passable
  end
  if not usable(x, y) then
    local found = false
    for r = 1, 20 do
      for dy = -r, r do
        for dx = -r, r do
          if not found and math.max(math.abs(dx), math.abs(dy)) == r and usable(x + dx, y + dy) then
            x, y, found = x + dx, y + dy, true
          end
        end
      end
      if found then break end
    end
  end
  local profile = StaffProfile(world, class, _S.staff_class[class:lower()])
  if class == "Doctor" then
    profile:initDoctor(0, 0, 0, nil, nil, skill or 0.5)
  else
    profile:init(skill or 0.5)
  end
  local staff = world:newEntity(profile.humanoid_class, 2, 2)
  staff:setProfile(profile)
  staff:setTile(x, y)
  hospital.staff[#hospital.staff + 1] = staff
  staff:setHospital(hospital)
  staff:onPlaceInCorridor()
  return staff
end

-- Player actions through the real game windows (used by ingame_probe.lua and
-- lobby_probe.lua).

-- Shared setup, identical on both peers, done before the session starts.
--!param keep_closed (bool) leave the hospital closed (the test opens it)
function builder.setup_scenario(world, scenario, keep_closed)
  local hospital = hospital_of(world)
  local cx, cy = world.map.th:getCameraTile(hospital:getPlayerIndex())
  local desk_x, desk_y = builder.find_free_rect(world, cx, cy, 1, 3, 25)
  builder.place_object(world, "reception_desk", desk_x, desk_y, "north")
  builder.hire(world, "Receptionist", desk_x + 2, desk_y + 2)
  if scenario == "busy" then
    for _, spec in ipairs({{"gp", 5, 5}, {"pharmacy", 4, 4}, {"general_diag", 5, 5},
        {"staff_room", 5, 5}, {"toilets", 4, 4}}) do
      local x, y = builder.find_free_rect(world, desk_x, desk_y, spec[2], spec[3], 40)
      if x or not keep_closed then
        assert(builder.build_room(world, spec[1], x, y, spec[2], spec[3]), "building " .. spec[1])
      else
        -- Co-op maps have smaller plots; leave out a room that does not fit.
        print("probe setup: no space for " .. spec[1] .. " in " .. tostring(hospital.name))
      end
    end
    for i, class in ipairs({"Doctor", "Doctor", "Doctor", "Nurse", "Nurse", "Handyman", "Handyman"}) do
      builder.hire(world, class, desk_x + i, desk_y + 3)
    end
  end
  if not keep_closed then hospital:open() end
  return desk_x, desk_y
end

-- Simulated mouse click at a map tile, in window-relative coordinates.
function builder.click_tile(ui, window, button, tx, ty)
  local sx, sy = ui:WorldToScreen(tx + 0.5, ty + 0.5)
  return window:onMouseUp(button, sx - window.x, sy - window.y)
end

function builder.ui_buy(world, desk_x, desk_y, object_id, log)
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
  -- Same search order on both peers, but only this peer clicks. Nobody may
  -- stand there (the game ignores the click then).
  local x, y = builder.find_free_rect(world, desk_x, desk_y, 1, 1, 40,
      function(tx, ty) return not world:anyHumanoidObscuringArea(tx, ty) end)
  place:setBlueprintCell(x, y)
  place.object_cell_x, place.object_cell_y = x, y
  place:onMouseUp("left", 100000, 100000) -- a click outside the window
  log(string.format("UI: bought %s, clicked %d,%d (balance unchanged locally: %s)%s",
      object_id, x, y, tostring(world.hospitals[1].balance == balance_before),
      ui:getWindow(UIPlaceObjects) and " (click refused)" or ""))
  if ui:getWindow(UIPlaceObjects) then ui:getWindow(UIPlaceObjects):close() end
end

function builder.ui_hire(world, desk_x, desk_y, class, log)
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
  -- Below the desk, or the nearest valid tile around it (fixed search order).
  local tx, ty = desk_x + 1, desk_y + 4
  place.tile_x, place.tile_y = tx, ty
  local r = 0
  while not place:_isValidStaffPlacement() and r < 12 do
    r = r + 1
    local found = false
    for dy = -r, r do
      for dx = -r, r do
        if not found and math.max(math.abs(dx), math.abs(dy)) == r then
          place.tile_x, place.tile_y = desk_x + 1 + dx, desk_y + 4 + dy
          found = place:_isValidStaffPlacement()
        end
      end
    end
  end
  tx, ty = place.tile_x, place.tile_y
  place.onMouseMove = function() end -- keep the tile we set (no real cursor)
  place:onMouseUp("left", 0, 0)
  log(string.format("UI: hired %s %s at %d,%d (pool size still %d)", class, name,
      tx, ty, #pool))
  if ui:getWindow(UIHireStaff) then ui:getWindow(UIHireStaff):close() end
end

--! Draw a room in the room editor like a player: outline next to (cx, cy),
--! the first valid door clockwise from the top-left, optionally a window
--! on each wall, then confirm. In multiplayer the confirm
--! sends the build_room command; nothing is built locally yet.
--!param at (table) optional {x, y}: exact top-left corner instead of a search
--!param by_hand (bool) optional; multiplayer: place the furniture by hand
--!  afterwards (builder.furnish_tick); otherwise it is placed automatically
function builder.ui_room(world, cx, cy, room_id, w, h, with_window, log, at, by_hand)
  local ui = world.ui
  local room_type = assert(TheApp.rooms[room_id], "unknown room " .. room_id)
  local x, y
  if at then x, y = at[1], at[2] else x, y = builder.find_free_rect(world, cx, cy, w, h, 40) end
  if not x then
    log(string.format("UI: no space for %s %dx%d", room_id, w, h))
    return false
  end
  local dlg = UIEditRoom(ui, room_type)
  dlg.mp_auto_furnish = not by_hand
  ui:addWindow(dlg)
  dlg:setBlueprintRect(x, y, w, h)
  dlg:confirm()
  if dlg.phase ~= "door" then
    log("UI: room outline refused at " .. x .. "," .. y)
    dlg:close()
    return
  end
  local candidates = {}
  for tx = x + 1, x + w - 2 do candidates[#candidates + 1] = {x = tx, y = y + h - 1, wall = "south"} end
  for ty = y + 1, y + h - 2 do candidates[#candidates + 1] = {x = x + w - 1, y = ty, wall = "east"} end
  for _, c in ipairs(candidates) do
    dlg:setDoorBlueprint(c.x, c.y, c.wall)
    if dlg.blueprint_door.valid then
      dlg:placeDoorBlueprint()
      break
    end
  end
  if dlg.phase ~= "windows" then
    log("UI: no door position for " .. room_id)
    dlg:close()
    return
  end
  if with_window then
    -- One window on each wall where one fits (not on the door): windows on
    -- the south and east walls once left blue markers on the corridor.
    local walls = {
      north = {}, west = {}, south = {}, east = {},
    }
    for tx = x + 1, x + w - 2 do
      walls.north[#walls.north + 1] = {tx, y}
      walls.south[#walls.south + 1] = {tx, y + h - 1}
    end
    for ty = y + 1, y + h - 2 do
      walls.west[#walls.west + 1] = {x, ty}
      walls.east[#walls.east + 1] = {x + w - 1, ty}
    end
    for _, wall in ipairs({"north", "west", "south", "east"}) do
      for _, c in ipairs(walls[wall]) do
        dlg:setWindowBlueprint(c[1], c[2], wall)
        if dlg.blueprint_window.anim and dlg.blueprint_window.valid then
          dlg:placeWindowBlueprint()
          break
        end
      end
    end
  end
  dlg:confirm()
  log(string.format("UI: drew %s at %d,%d size %dx%d%s (editor %s)", room_id, x, y, w, h,
      with_window and " with a window" or "", dlg.phase))
  return true
end

--! A tile to search from for this player's rooms and objects: the first
--! reception desk of their hospital, or else the free floor tile nearest the
--! middle of the hospital (its corners are often unusable).
function builder.anchor(world)
  local hospital = hospital_of(world)
  local desk = hospital:getReceptionDesks()[1]
  if desk and desk.tile_x then return desk.tile_x, desk.tile_y end
  local map, th = world.map, world.map.th
  local tiles, sx, sy = {}, 0, 0
  for y = 1, map.height do
    for x = 1, map.width do
      if hospital:isInHospital(x, y) then
        tiles[#tiles + 1] = {x, y}
        sx, sy = sx + x, sy + y
      end
    end
  end
  if #tiles == 0 then return nil end
  local cx, cy = sx / #tiles, sy / #tiles
  local best, best_d
  for _, t in ipairs(tiles) do
    local flags = th:getCellFlags(t[1], t[2])
    if flags.buildable and flags.passable and not world:getRoom(t[1], t[2]) then
      local d = (t[1] - cx) ^ 2 + (t[2] - cy) ^ 2
      if not best_d or d < best_d then best, best_d = t, d end
    end
  end
  best = best or tiles[1]
  return best[1], best[2]
end

--! Multiplayer, a room furnished by hand: call once per tick while it runs.
--! Waits for this player's room editor, then puts down one object at a
--! time like a click (each one a room_object command) and waits for it to
--! appear; a refused spot is not tried again. When the room is complete it
--! confirms (room_finish), or with `cancel` it cancels instead (room_abort).
--!return true when done
function builder.furnish_tick(world, state, log)
  local ui = world.ui
  local dlg = ui.edit_room
  -- A person watching: wait state.pace game hours between objects.
  local step = TheApp.mp_session and TheApp.mp_session.step or 0
  if state.not_before and step < state.not_before then return false end
  if not (dlg and dlg.mp_room_id) then
    state.waited = (state.waited or 0) + 1
    if state.started and state.waited > 400 then log("UI: furnishing: editor gone") return true end
    return false
  end
  state.started = true
  state.waited = 0
  if state.cancel then
    -- Cancel: the walls come down (room_unbuild), then cancel once more in
    -- the outline phase to remove the room (room_delete), as in single player.
    local entry = world.mp_furnishing and world.mp_furnishing[dlg.mp_room_id]
    if not state.cancelled then
      log(string.format("UI: cancelled furnishing room #%d", dlg.mp_room_id))
      state.cancelled = dlg.mp_room_id
      dlg:cancel()
      return false
    elseif entry and entry.unbuilt and dlg.phase == "walls" then
      log(string.format("UI: removing room #%d", dlg.mp_room_id))
      dlg:cancel()
      return true
    end
    return false
  end
  if state.pending then
    -- Wait until the object is in the room (or the command was refused).
    local count = 0
    for _, o in ipairs(dlg.objects) do count = count + o.qty end
    if count < state.pending.count then
      log(string.format("UI: furnishing: %s is in the room", state.pending.id))
      state.pending = nil
      if state.pace then state.not_before = step + state.pace return false end
    elseif step > state.pending.by_step then
      state.pending = nil -- refused; that spot was marked as tried
    else
      return false
    end
  end
  if dlg.confirm_button.enabled and not (state.no_confirm and dlg.objects[1]) then
    if state.no_confirm then return true end
    log(string.format("UI: furnished room #%d; confirming", dlg.mp_room_id))
    dlg:confirm()
    return true
  end
  local o = dlg.objects[1]
  if not o then return state.no_confirm == true end
  state.tried = state.tried or {}
  local room = dlg.room
  local rx, ry, rw, rh = room.x, room.y, room.width, room.height
  for ty = ry, ry + rh - 1 do
    for tx = rx, rx + rw - 1 do
      for _, dir in ipairs({"north", "east", "south", "west"}) do
        local key = string.format("%s:%d,%d:%s", o.object.id, tx, ty, dir)
        if o.object.orientations[dir] and not state.tried[key] then
          dlg:setActiveIndex(1)
          dlg:setOrientation(dir)
          dlg:setBlueprintCell(tx, ty)
          if dlg.object_blueprint_good and not world:anyHumanoidObscuringArea(tx, ty) then
            state.tried[key] = true
            local count = 0
            for _, p in ipairs(dlg.objects) do count = count + p.qty end
            -- It runs `delay` game hours from now; a refusal shows as no change.
            local delay = TheApp.mp_session and TheApp.mp_session.delay or 2
            state.pending = {id = o.object.id, count = count, by_step = step + delay + 2}
            log(string.format("UI: furnishing: put %s at %d,%d facing %s", o.object.id, tx, ty, dir))
            dlg:placeObject()
            return false
          end
        end
      end
    end
  end
  log("UI: furnishing: no place left for " .. o.object.id)
  dlg:cancel()
  return true
end

--! Edit one of this player's rooms like a person would (multiplayer): the
--! edit room button and a click on the room, then the steps in state.steps:
--!   pickup:<object>   pick up an object of the room (pick up mode, click)
--!   buy:<object>      buy one more in the purchase window (first allowed if "first")
--!   place             put every object waiting in the list into the room
--!   move:<dx>:<dy>    cancel (walls down), draw the room again shifted
--!   done              confirm (the room opens again)
--!   delete            cancel twice (walls down, then remove the room)
--! Returns true when finished. Logs "UI: edit <step> ok" or "... FAILED".
function builder.edit_tick(world, state, log)
  local ui = world.ui
  local session = TheApp.mp_session
  local step = session.step
  local entry = state.room and world.mp_furnishing and world.mp_furnishing[state.room.id]
  local dlg = entry and entry.dlg
  local shown = dlg and ui.edit_room == dlg
  local function count()
    local n = 0
    for _, o in ipairs(dlg.objects) do n = n + o.qty end
    return n
  end
  local function finish_step(ok, what)
    log(string.format("UI: edit %s %s at step %d", state.current or "?", ok and "ok" or ("FAILED: " .. what), step))
    state.current, state.wait = nil, nil
    state.i = state.i + 1
    if not ok then state.i = #state.steps + 1 end
  end
  if not state.room then
    for _, room in pairs(world.rooms) do
      if room.room_info.id == state.room_type and room.hospital == ui.hospital and room.built and
          room.is_active and (not state.room or room.id < state.room.id) then
        state.room = room
      end
    end
    if not state.room then log("UI: edit: no " .. state.room_type .. " to edit") return true end
    local x, y = state.room.x + 1, state.room.y + 1
    ui:setEditRoom(true)
    local sx, sy = ui:WorldToScreen(x + 0.5, y + 0.5)
    ui:onMouseUp(1, sx, sy)
    log(string.format("UI: edit: clicked %s #%d at %d,%d", state.room_type, state.room.id, x, y))
    state.i, state.since = 1, step
    return false
  end
  if state.i > #state.steps then return true end
  -- Wait for this player's editor (the room empties first).
  if not state.current then
    if not (shown and dlg.phase == "objects") then
      if step - state.since > 300 then
        state.current = state.current or state.steps[state.i]
        finish_step(false, "editor did not open")
      end
      return false
    end
    state.current = state.steps[state.i]
    state.since = step
    local name, a1, a2 = state.current:match("^(%w+):?([%w_%-]*):?([%-%d]*)$")
    state.name, state.a1, state.a2 = name, a1, a2
    if name == "pickup" then
      local obj
      for o in pairs(dlg.room.objects) do
        if o.object_type.id == a1 and o ~= dlg.room.door and (not obj or o.mp_id < obj.mp_id) then obj = o end
      end
      if not obj then finish_step(false, "no " .. a1) return false end
      state.before = count()
      dlg:pickupItems()
      obj:onClick(ui, "left")
    elseif name == "buy" then
      dlg:purchaseItems()
      local shop = ui:getWindow(UIFurnishCorridor)
      if not shop then finish_step(false, "no purchase window") return false end
      local index
      for i, o in ipairs(shop.objects) do
        if not index and (a1 == "first" or o.object.id == a1) then index = i end
      end
      if not index then shop:close() finish_step(false, "nothing to buy") return false end
      state.bought = shop.objects[index].object.id
      state.before = count()
      shop:purchaseItem(index, 1)
      shop:confirm()
    elseif name == "place" then
      state.placing = {no_confirm = true}
    elseif name == "move" then
      state.old = {x = dlg.room.x, y = dlg.room.y, w = dlg.room.width, h = dlg.room.height}
      dlg:cancel()
    elseif name == "done" then
      dlg:confirm()
    elseif name == "delete" then
      state.deleting = 1
      dlg:cancel()
    else
      finish_step(false, "unknown step")
    end
    return false
  end
  local name = state.name
  if step - state.since > 400 then finish_step(false, "timed out") return false end
  if name == "pickup" then
    if shown and count() > state.before then finish_step(true) end
  elseif name == "buy" then
    if shown and count() > state.before then
      log("UI: edit: bought " .. state.bought)
      finish_step(true)
    end
  elseif name == "place" then
    if shown and dlg.phase == "objects" and builder.furnish_tick(world, state.placing, log) then
      finish_step(#dlg.objects == 0, "objects left")
    end
  elseif name == "move" then
    if shown and entry.unbuilt and dlg.phase == "walls" and not state.drawn then
      -- Draw it again a little further (the first offset that works).
      local dx, dy = tonumber(state.a1) or 1, tonumber(state.a2) or 0
      local offsets = {{dx, dy}, {-dx, -dy}, {dy, dx}, {-dy, -dx}, {0, 0}}
      for _, d in ipairs(offsets) do
        if not state.drawn then
          dlg:setBlueprintRect(state.old.x + d[1], state.old.y + d[2], state.old.w, state.old.h)
          if dlg.confirm_button.enabled then
            dlg:confirm()
            if dlg.phase == "door" then
              local r = dlg.blueprint_rect
              for tx = r.x + 1, r.x + r.w - 2 do
                if dlg.phase == "door" then
                  dlg:setDoorBlueprint(tx, r.y + r.h - 1, "south")
                  if dlg.blueprint_door.valid then dlg:placeDoorBlueprint() end
                end
              end
              if dlg.phase == "windows" then
                state.drawn = {x = r.x, y = r.y}
                log(string.format("UI: edit: drew the room again at %d,%d", r.x, r.y))
                dlg:confirm()
              else
                dlg:cancel()
              end
            end
          end
        end
      end
      if not state.drawn then finish_step(false, "no place to move to") end
    elseif shown and state.drawn and not entry.unbuilt and dlg.phase == "objects" then
      log(string.format("UI: edit: room now at %d,%d (was %d,%d)", dlg.room.x, dlg.room.y,
          state.old.x, state.old.y))
      state.drawn = nil
      finish_step(true)
    end
  elseif name == "done" then
    if not entry and state.room.is_active then finish_step(true) end
  elseif name == "delete" then
    if state.deleting == 1 and shown and entry.unbuilt and dlg.phase == "walls" then
      state.deleting = 2
      dlg:cancel() -- a paid room asks first
      local confirm = ui:getWindow(UIConfirmDialog)
      if confirm then confirm:ok() end
    elseif state.deleting == 2 and not world.rooms[state.room.id] then
      finish_step(true)
    end
  end
  return false
end

--! A free w x h rectangle that has a person standing in it right now
--! (to test that building waits for people to walk out). Nil if none.
function builder.rect_with_person(world, w, h)
  local hospital = hospital_of(world)
  local th = world.map.th
  -- Like rect_is_free, but without the one-tile margin.
  local function free(x, y)
    for tx = x, x + w - 1 do
      for ty = y, y + h - 1 do
        if not hospital:isInHospital(tx, ty) or world:getRoom(tx, ty) or world:getObject(tx, ty) then
          return false
        end
        local flags = th:getCellFlags(tx, ty)
        if not (flags.buildable and flags.passable) then return false end
      end
    end
    return true
  end
  for _, e in ipairs(world.entities) do
    if class.is(e, Humanoid) and e.tile_x and not class.is(e, Receptionist) then
      for dx = 0, w - 1 do
        for dy = 0, h - 1 do
          local x, y = e.tile_x - dx, e.tile_y - dy
          if free(x, y) then return x, y end
        end
      end
    end
  end
end

--! Test setup at the start of a multiplayer game, the same on every peer
--! before the first step: test-only commands and the scenario's hospital
--! (each player's, in co-op). Returns this player's desk tile.
--! Test-only commands, registered on every peer.
function builder.register_handlers()
  -- A VIP asks to visit.
  MultiplayerSession.default_handlers.probe_vip = function(w, cmd)
    w.hospitals[cmd.target or 1]:createVip()
    return true
  end
  -- An emergency for hospital `target`.
  MultiplayerSession.default_handlers.probe_emergency = function(w, cmd)
    local err = w.hospitals[cmd.target or 1]:createEmergency()
    return err == nil, err
  end
  -- `n` patients arrive at once next to the reception desk (to make a queue
  -- now; from the map edge they would walk for hundreds of hours).
  MultiplayerSession.default_handlers.probe_patients = function(w, cmd)
    local hospital = w.hospitals[cmd.hospital or 1]
    local desk = hospital:getReceptionDesks()[1]
    if not desk then return false, "no reception desk" end
    local x, y = builder.find_free_rect(w, desk.tile_x, desk.tile_y + 3, 1, 1, 10)
    if not x then return false, "no room next to the desk" end
    for _ = 1, math.min(tonumber(cmd.n) or 1, 20) do
      local patient = w:spawnPatient(hospital)
      if patient then patient:setNextAction(SpawnAction("spawn", {x = x, y = y, direction = "north"})) end
    end
    return true
  end
  -- A member of staff of `class` asks for a pay rise (like Staff:requestRaise,
  -- without the dice).
  MultiplayerSession.default_handlers.probe_raise = function(w, cmd)
    local h = w.hospitals[cmd.hospital or 1]
    for _, s in ipairs(h.staff) do
      if s.humanoid_class == cmd.class and not s.fired and not s.quitting_in then
        h:makeRaiseRequest(math.floor(s.profile.wage * 0.1) + 1, s)
        s.quitting_in = 25 * 30
        s:setMood("pay_rise", "activate")
        return true
      end
    end
    return false, "nobody to ask"
  end
end

function builder.start_game(world, session, scenario, log)
  builder.register_handlers()

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
  return desk_x, desk_y
end

return builder
