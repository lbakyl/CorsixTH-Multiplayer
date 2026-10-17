-- Helpers that perform player actions through the game's own UI code paths
-- (UIEditRoom, UIPlaceObjects, staff profiles), without mouse input.
-- Diagnostic / experimental: used by sync_probe.lua to build a busier
-- hospital, and as the first "apply a command" implementation.
--
-- Every function is deterministic given the game state: it searches tiles in
-- a fixed order and consumes gameplay randomness only where the game itself
-- would (e.g. staff profile generation).

local builder = {}

local function hospital_of(world) return world.hospitals[1] end

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

return builder
