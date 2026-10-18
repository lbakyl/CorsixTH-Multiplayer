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
function builder.find_free_rect(world, cx, cy, w, h, max_radius)
  for r = 0, max_radius or 30 do
    for dy = -r, r do
      for dx = -r, r do
        if math.max(math.abs(dx), math.abs(dy)) == r then
          local x, y = cx + dx, cy + dy
          if rect_is_free(world, x, y, w, h) then return x, y end
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
      assert(builder.build_room(world, spec[1], x, y, spec[2], spec[3]), "building " .. spec[1])
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
  -- Same search order on both peers, but only this peer clicks.
  local x, y = builder.find_free_rect(world, desk_x, desk_y, 1, 1, 40)
  place:setBlueprintCell(x, y)
  place.object_cell_x, place.object_cell_y = x, y
  place:onMouseUp("left", 100000, 100000) -- a click outside the window
  log(string.format("UI: bought %s, clicked %d,%d (balance unchanged locally: %s)",
      object_id, x, y, tostring(world.hospitals[1].balance == balance_before)))
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
--! the first valid door clockwise from the top-left, optionally one window
--! in the middle of the top wall, then confirm. In multiplayer the confirm
--! sends the build_room command; nothing is built locally yet.
--!param at (table) optional {x, y}: exact top-left corner instead of a search
function builder.ui_room(world, cx, cy, room_id, w, h, with_window, log, at)
  local ui = world.ui
  local room_type = assert(TheApp.rooms[room_id], "unknown room " .. room_id)
  local x, y
  if at then x, y = at[1], at[2] else x, y = builder.find_free_rect(world, cx, cy, w, h, 40) end
  assert(x, "no space for " .. room_id)
  local dlg = UIEditRoom(ui, room_type)
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
    dlg:setWindowBlueprint(x + math.floor(w / 2), y, "north")
    dlg:placeWindowBlueprint()
  end
  dlg:confirm()
  log(string.format("UI: drew %s at %d,%d size %dx%d%s (editor %s)", room_id, x, y, w, h,
      with_window and " with a window" or "", dlg.phase))
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

return builder
