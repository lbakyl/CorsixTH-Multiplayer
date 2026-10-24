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

--! Builds a complete room for the multiplayer "build_room" command, the same
--! way on every peer.
--!
--! In multiplayer the player designing a room only draws it (outline, door,
--! windows); nothing is built on their machine yet, so the other players'
--! games stay identical. The command then builds the room everywhere at the
--! same step, through a room editor window that is not added to the UI on
--! the other players' machines (so it does not close the windows they have
--! open).
--!
--! Furniture: either placed automatically, in a fixed order (scripted tests,
--! or `furnish` not set), or by hand: the room then waits, unfinished, with
--! its editor kept in world.mp_furnishing[room id]. Only the player who drew
--! it sees that editor; each object they put down is a room_object command,
--! and room_finish / room_abort end it on every peer.

local builder = {}

-- Local settings that would change what gets built; fixed while building.
local fixed_config = {
  enable_avg_contents = false, -- would add optional objects chosen with pairs()
  blocking_off_areas = 2,      -- default rule for rooms that block corridors
}

--! Encode a window list {{x, y, wall}, ...} as "x,y,wall;..." for a command.
function builder.encodeWindows(windows)
  local parts = {}
  for _, w in ipairs(windows) do
    parts[#parts + 1] = string.format("%d,%d,%s", w[1], w[2], w[3])
  end
  return table.concat(parts, ";")
end

function builder.decodeWindows(text)
  local windows = {}
  for x, y, wall in tostring(text or ""):gmatch("(%-?%d+),(%-?%d+),(%a+)") do
    windows[#windows + 1] = {tonumber(x), tonumber(y), wall}
  end
  return windows
end

--! The windows the player put into a room blueprint, in a fixed order.
--!param dlg (UIEditRoom) editor in the windows phase
function builder.windowsOf(dlg)
  local windows = {}
  for x, column in pairs(dlg.blueprint_wall_anims) do
    if type(column) == "table" and not column.setTile then
      for y, anim in pairs(column) do
        if anim.getTag and anim:getTag() == "window" then
          -- Animation flag bit 1: west-facing wall, otherwise north-facing.
          local wall = (anim:getFlag() % 2 == 1) and "west" or "north"
          windows[#windows + 1] = {x, y, wall}
        end
      end
    end
  end
  table.sort(windows, function(a, b)
    if a[1] ~= b[1] then return a[1] < b[1] end
    if a[2] ~= b[2] then return a[2] < b[2] end
    return a[3] < b[3]
  end)
  return windows
end

--! The floor tile and wall to place a recorded window from, as a player
--! would: a window on the south or east wall is recorded as the north or
--! west wall of the tile outside the room, but placed from the tile inside
--! (the editor's blue marker goes on that tile, which the finished room
--! clears; on the outside tile it stayed on the corridor floor).
--!param win (table) {x, y, wall} from builder.windowsOf
--!return x, y, wall
function builder.windowCell(win, x, y, w, h)
  local wx, wy, wall = win[1], win[2], win[3]
  if wall == "north" and wy == y + h then return wx, wy - 1, "south" end
  if wall == "west" and wx == x + w then return wx - 1, wy, "east" end
  return wx, wy, wall
end

-- Values the room editor paints on the overlay layer (4) in front of a door
-- or window it is placing (see door_floor_blueprint_markers in edit_room.lua).
local OVERLAY_LAYER, FIRST_MARKER, LAST_MARKER = 4, 25, 36

--! Remove door and window markers no room editor is showing (left on the
--! floor by games before builder.windowCell). Only while no editor is open.
function builder.clearStaleMarkers(world)
  local ui = world and world.ui
  local th = world and world.map and world.map.th
  if not (ui and th) then return 0 end
  for _, window in ipairs(ui.windows or {}) do
    if class.is(window, UIEditRoom) then return 0 end
  end
  local cleared = 0
  local mw, mh = th:size()
  for ty = 1, mh do
    for tx = 1, mw do
      local v = th:getCell(tx, ty, OVERLAY_LAYER)
      if v >= FIRST_MARKER and v <= LAST_MARKER then
        th:setCell(tx, ty, OVERLAY_LAYER, 0)
        cleared = cleared + 1
      end
    end
  end
  return cleared
end

--! Humanoids standing in a rectangle (plus nothing else), in entity order.
local function humanoids_in(world, x, y, w, h)
  local found = {}
  for _, e in ipairs(world.entities) do
    if class.is(e, Humanoid) and e.tile_x and e.tile_x >= x and e.tile_x < x + w and
        e.tile_y >= y and e.tile_y < y + h then
      found[#found + 1] = e
    end
  end
  return found
end

--! Ask everybody in the area to walk out, and keep others away meanwhile.
function builder.clearArea(world, x, y, w, h)
  local th = world.map.th
  for tx = x, x + w - 1 do
    for ty = y, y + h - 1 do
      th:setCellFlags(tx, ty, {avoidTile = true})
    end
  end
  for _, humanoid in ipairs(humanoids_in(world, x, y, w, h)) do
    humanoid:leaveArea()
  end
end

function builder.releaseArea(world, x, y, w, h)
  local th = world.map.th
  for tx = x, x + w - 1 do
    for ty = y, y + h - 1 do
      th:setCellFlags(tx, ty, {avoidTile = false})
    end
  end
end

--! Would placing an object of `object_type` at (tx, ty) facing `o` keep the
--! use tile of every object in the room reachable from the entrance, and its
--! own? The room editor's own checks allow layouts in which, for example, the
--! desk walls off the cabinet's use tile; a player would see that and move
--! things, but the automatic placement must avoid it (a doctor looking for
--! the cabinet would find none). A use tile that is already cut off (a room
--! edited after single player play) does not stop other placements.
--!param placed (table) list of {footprint, use_x, use_y} already in the room
local function keeps_room_usable(room, rect, placed, object_type, tx, ty, o)
  local orientation = object_type.orientations[o]
  local function key(x, y) return x * 1000 + y end
  local candidate = {footprint = {}}
  local own = {}
  for _, t in ipairs(orientation.footprint) do
    own[key(tx + t[1], ty + t[2])] = true
    -- (A wall object, such as a radiator, leaves its tile walkable.)
    if not t.only_passable and not t.only_side then
      candidate.footprint[#candidate.footprint + 1] = {tx + t[1], ty + t[2]}
    end
  end
  -- Only an object the room needs must be usable itself (single player lets
  -- a plant stand where nobody can water it); a use tile on the object's own
  -- footprint (a radiator, an extinguisher) never counts.
  local needed = room.room_info.objects_needed and room.room_info.objects_needed[object_type.id]
  if needed and type(orientation.use_position) == "table" and
      not own[key(tx + orientation.use_position[1], ty + orientation.use_position[2])] then
    candidate.use_x = tx + orientation.use_position[1]
    candidate.use_y = ty + orientation.use_position[2]
  end
  local ex, ey = room:getEntranceXY(true)
  local function inside(x, y)
    return x >= rect.x and x < rect.x + rect.w and y >= rect.y and y < rect.y + rect.h
  end
  -- The tiles reachable from the entrance with these items in the room.
  local function reach(items)
    local blocked = {}
    for _, item in ipairs(items) do
      for _, xy in ipairs(item.footprint) do blocked[key(xy[1], xy[2])] = true end
    end
    if blocked[key(ex, ey)] then return {} end
    local seen, queue, head = {[key(ex, ey)] = true}, {{ex, ey}}, 1
    while queue[head] do
      local x, y = queue[head][1], queue[head][2]
      head = head + 1
      for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
        local nx, ny = x + d[1], y + d[2]
        local k = key(nx, ny)
        if inside(nx, ny) and not blocked[k] and not seen[k] then
          seen[k] = true
          queue[#queue + 1] = {nx, ny}
        end
      end
    end
    return seen
  end
  local before = reach(placed)
  local with = {candidate}
  for _, item in ipairs(placed) do with[#with + 1] = item end
  local after = reach(with)
  if candidate.use_x and not after[key(candidate.use_x, candidate.use_y)] then return false, candidate end
  for _, item in ipairs(placed) do
    if item.use_x then
      local k = key(item.use_x, item.use_y)
      if before[k] and not after[k] then return false, candidate end
    end
  end
  return true, candidate
end

--! The objects in a room (not its doors) as {footprint, use_x, use_y}, for
--! keeps_room_usable.
function builder.roomItems(room)
  local items = {}
  for obj in pairs(room.objects) do
    local orientation = obj.tile_x and obj.object_type.orientations and
        obj.object_type.orientations[obj.direction]
    local door = obj == room.door or obj == room.door2 or class.is(obj, Door) or class.is(obj, SwingDoor)
    if orientation and not door then
      local item = {footprint = {}}
      for _, t in ipairs(orientation.footprint) do
        if not t.only_passable and not t.only_side then
          item.footprint[#item.footprint + 1] = {obj.tile_x + t[1], obj.tile_y + t[2]}
        end
      end
      local ux, uy
      local needed = room.room_info.objects_needed and room.room_info.objects_needed[obj.object_type.id]
      if needed and type(orientation.use_position) == "table" then
        ux, uy = obj.tile_x + orientation.use_position[1], obj.tile_y + orientation.use_position[2]
      end
      for _, t in ipairs(orientation.footprint) do
        if obj.tile_x + t[1] == ux and obj.tile_y + t[2] == uy then ux = nil end -- used from its own tile
      end
      item.use_x, item.use_y = ux, ux and uy
      items[#items + 1] = item
    end
  end
  return items
end

local function try_build(world, hospital, cmd)
  local ui = world.ui
  local room_type = TheApp.rooms[cmd.room]
  if not room_type then return nil, "unknown room type" end
  local progress = hospital.research.research_progress[room_type]
  local discovery = hospital.room_discoveries[room_type.id]
  if not progress or not (discovery and discovery.is_discovered) then
    return nil, "room not available"
  end
  if not world.free_build_mode and hospital.balance < progress.build_cost then
    return nil, "not enough money"
  end
  local x, y, w, h = cmd.x, cmd.y, cmd.w, cmd.h
  if #humanoids_in(world, x, y, w, h) > 0 then
    return nil, "people in the area"
  end

  local dlg = UIEditRoom(ui, room_type)
  local function fail(why)
    dlg:close()
    return nil, why
  end

  -- 1. Outline
  dlg:setBlueprintRect(x, y, w, h)
  if not dlg.confirm_button.enabled then return fail("invalid room outline") end
  dlg:confirm(true)
  if dlg.phase ~= "door" then return fail("room would block part of the hospital") end
  -- 2. Door
  dlg:setDoorBlueprint(cmd.door_x, cmd.door_y, cmd.door_wall)
  if not dlg.blueprint_door.valid then return fail("invalid door position") end
  dlg:placeDoorBlueprint()
  if dlg.phase ~= "windows" then return fail("door not accepted") end
  -- 3. Windows (an invalid one is skipped, like a click on a bad wall)
  for _, win in ipairs(builder.decodeWindows(cmd.windows)) do
    dlg:setWindowBlueprint(builder.windowCell(win, x, y, w, h))
    dlg:placeWindowBlueprint()
  end
  -- 4. Area is empty (checked above), so this goes straight to objects.
  dlg:confirm(true)
  if dlg.phase == "clear_area" then return fail("people in the area") end
  if dlg.phase ~= "objects" and dlg.phase ~= "closed" then
    return fail("unexpected phase " .. tostring(dlg.phase))
  end
  local room = dlg.room
  if tonumber(cmd.furnish) == 1 and dlg.phase == "objects" then
    -- Furnished by hand: keep the editor (see builder.placeObject), without
    -- a blueprint on the map until its player's machine shows it.
    dlg:clearBlueprint()
    dlg.object_cell_x, dlg.object_cell_y = nil, nil
    return room, nil, dlg
  end
  local ok, why = builder.autoFurnish(dlg, room, cmd, {})
  if not ok then return nil, why end
  return builder.finishEditor(dlg, room)
end

local orientations = {"north", "east", "south", "west"}

--! 5. Place the objects still to place, in name order, at the first fitting
--! tile and orientation (the room editor dlg is in its objects phase).
--!param rect {x, y, w, h} the room's outline
--!param placed list of {footprint, use_x, use_y} already in the room
function builder.autoFurnish(dlg, room, rect, placed)
  local x, y, w, h = rect.x, rect.y, rect.w, rect.h
  local guard = 0
  while dlg.phase == "objects" and #dlg.objects > 0 and guard < 40 do
    guard = guard + 1
    local first = 1
    for i, o in ipairs(dlg.objects) do
      if o.object.id < dlg.objects[first].object.id then first = i end
    end
    dlg:setActiveIndex(first)
    local done = false
    for ty = y, y + h - 1 do
      for tx = x, x + w - 1 do
        for _, o in ipairs(orientations) do
          -- (Once placed, the object is gone from dlg.objects.)
          local object_type = not done and dlg.objects[dlg.active_index].object
          if object_type and object_type.orientations[o] then
            dlg:setOrientation(o)
            dlg:setBlueprintCell(tx, ty)
            if dlg.object_blueprint_good then
              local usable, item = keeps_room_usable(room, rect, placed, object_type, tx, ty, o)
              if usable then
                dlg:placeObject()
                placed[#placed + 1] = item
                done = true
              end
            end
          end
        end
      end
    end
    if not done then
      dlg:abortRoom()
      return false, "required objects do not fit"
    end
  end
  return true
end

--! 6. Pay and open the room.
function builder.finishEditor(dlg, room)
  if dlg.phase == "objects" then dlg:confirm(true) end
  if dlg.phase ~= "closed" then dlg:close() end
  if not room or not room.built then return nil, "room was not finished" end
  return room
end

--! Run fn(...) with the room editor working for `hospital`: the editor uses
--! ui.hospital for money and research, and local settings that would change
--! the result are fixed. All local UI state is restored afterwards.
local function with_editor(world, hospital, fn, ...)
  local ui = world.ui
  local app = TheApp
  local saved = {
    hospital = ui.hospital,
    edit_room = ui.edit_room,
    hit_test = ui.do_world_hit_test,
    cursor = ui.cursor,
    config = {},
  }
  for k, v in pairs(fixed_config) do
    saved.config[k] = app.config[k]
    app.config[k] = v
  end
  ui.hospital = hospital
  local results = {pcall(fn, ...)}
  ui.hospital = saved.hospital
  ui.edit_room = saved.edit_room
  ui.do_world_hit_test = saved.hit_test
  if saved.cursor then ui:setCursor(saved.cursor) end
  for k, v in pairs(saved.config) do app.config[k] = v end
  if not results[1] then error(results[2], 0) end
  return (table.unpack or unpack)(results, 2, 4)
end

--! Build the room described by a build_room command on `hospital`.
--!return room, or nil and a reason; for a room furnished by hand also the
--!  room editor, still in its objects phase
function builder.build(world, hospital, cmd)
  return with_editor(world, hospital, try_build, world, hospital, cmd)
end

--------------------------------------------------------------------------------
-- Rooms furnished by hand (world.mp_furnishing[room id] = entry, with
-- entry = {dlg, peer, hospital, x, y, w, h, placed}).
--------------------------------------------------------------------------------

--! Is `dlg` one of the UI's open windows? (Window:removeWindow does not
--! clear a window's parent, so that is no answer.)
local function is_shown(ui, dlg)
  for _, window in ipairs(ui and ui.windows or {}) do
    if window == dlg then return true end
  end
  return false
end

--! Show the room editor of a room being furnished to its player (only on
--! that player's machine). False if another room editor is open there.
function builder.show(world, entry)
  local ui = world.ui
  if not ui or (ui.edit_room and ui.edit_room ~= entry.dlg) then return false end
  local dlg = entry.dlg
  dlg.mp_room_id = entry.dlg.room.id
  if not is_shown(ui, dlg) then ui:addWindow(dlg) end
  ui.edit_room = dlg
  ui:setWorldHitTest(dlg.room)
  -- Buying and picking up objects: only while placing them (room_buy,
  -- room_pickup), not while the outline is drawn again.
  local objects = dlg.phase == "objects"
  if dlg.purchase_button then dlg.purchase_button:enable(objects) end
  if dlg.pickup_button then dlg.pickup_button:enable(objects) end
  return true
end

--! Take the editor away from its player's screen (not on the other peers,
--! where it never was). The room itself is unchanged.
function builder.hide(world, entry)
  local dlg = entry.dlg
  if is_shown(world.ui, dlg) then world.ui:removeWindow(dlg) end
  builder.releaseUI(world.ui, dlg)
end

--! If the UI still points at this room editor (clicks limited to its room,
--! ui.edit_room set) while the editor is not shown, give the whole map back.
--! A save made in that state would otherwise keep a player from clicking
--! anybody outside that room.
function builder.releaseUI(ui, dlg)
  if not ui or (dlg and is_shown(ui, dlg)) then return end
  local room = dlg and dlg.room
  if dlg and ui.edit_room == dlg then ui.edit_room = false end
  if ui.do_world_hit_test ~= true and (not dlg or ui.do_world_hit_test == room) then
    ui:setWorldHitTest(true)
  end
end

--! After loading a shared save: an editor the UI points at must be one
--! that is actually open on this machine.
function builder.sanitizeUI(ui)
  if not ui then return end
  local open = false
  for _, window in ipairs(ui.windows or {}) do
    if class.is(window, UIPlaceObjects) then open = true end
  end
  if open then return end
  if ui.edit_room and not class.is(ui.edit_room, Room) then ui.edit_room = false end
  if ui.do_world_hit_test ~= true then ui:setWorldHitTest(true) end
end

--! Put down one object in a room being furnished: {object, x, y, orientation}.
--!return true, or false and a reason
function builder.placeObject(world, entry, cmd)
  local dlg = entry.dlg
  -- (The furnishing player's count of objects sent but not yet placed.)
  if dlg.mp_pending and dlg.mp_pending[cmd.object] then
    dlg.mp_pending[cmd.object] = math.max(0, dlg.mp_pending[cmd.object] - 1)
  end
  return with_editor(world, world.hospitals[entry.hospital], function()
    if dlg.phase ~= "objects" then return false, "room is not being furnished" end
    local index
    for i, o in ipairs(dlg.objects) do
      if o.object.id == cmd.object and o.qty > 0 then index = i break end
    end
    if not index then return false, "no such object to place" end
    local object_type = dlg.objects[index].object
    if not object_type.orientations[cmd.orientation] then return false, "unknown orientation" end
    local cell_x, cell_y, orientation = dlg.object_cell_x, dlg.object_cell_y, dlg.object_orientation
    local function restore()
      if not is_shown(world.ui, dlg) then
        -- Not shown on this machine: no blueprint on the map.
        dlg:clearBlueprint()
        dlg.object_cell_x, dlg.object_cell_y = nil, nil
        return
      end
      -- This player's editor goes on following their mouse from where it was
      -- (picture only: an error here must not change the command's result,
      -- which is the same on every peer). The chosen object may have
      -- changed: keep the facing only if it has one like it.
      pcall(function()
        local entry_now = dlg.objects[dlg.active_index]
        if not entry_now then return end
        if orientation and entry_now.object.orientations[orientation] then
          dlg:setOrientation(orientation)
        else
          local keep = dlg.active_index
          dlg.active_index = 0
          dlg:setActiveIndex(keep)
        end
        if cell_x then dlg:setBlueprintCell(cell_x, cell_y) end
      end)
    end
    dlg:setActiveIndex(index)
    dlg:setOrientation(cmd.orientation)
    dlg:setBlueprintCell(cmd.x, cmd.y)
    if not dlg.object_blueprint_good then restore() return false, "tile not free" end
    if world:anyHumanoidObscuringArea(cmd.x, cmd.y) then restore() return false, "someone is in the way" end
    local usable = keeps_room_usable(dlg.room, dlg.blueprint_rect, builder.roomItems(dlg.room),
        object_type, cmd.x, cmd.y, cmd.orientation)
    if not usable then restore() return false, "it would block the room" end
    dlg.object_cell_x, dlg.object_cell_y = cmd.x, cmd.y
    dlg:placeObject()
    restore()
    return true
  end)
end

--! Finish a room being furnished (pay and open it); `auto` first places the
--! objects still missing, like a room built without furnishing by hand.
--!return room, or nil and a reason
function builder.finish(world, entry, auto)
  local dlg = entry.dlg
  return with_editor(world, world.hospitals[entry.hospital], function()
    if dlg.phase ~= "objects" then return nil, "room is not being furnished" end
    if auto then
      local ok, why = builder.autoFurnish(dlg, dlg.room, dlg.blueprint_rect, builder.roomItems(dlg.room))
      if not ok then return nil, why end
    end
    if not dlg:checkEnableConfirm() then return nil, "objects missing" end
    return builder.finishEditor(dlg, dlg.room)
  end)
end

--! Remove a room being furnished, like cancelling it in single player.
function builder.abort(world, entry)
  local dlg = entry.dlg
  return with_editor(world, world.hospitals[entry.hospital], function()
    if dlg.phase ~= "objects" then return false, "room is not being furnished" end
    dlg.confirm_button:enable(false) -- close() would finish a complete room
    dlg:abortRoom()
    return true
  end)
end

--------------------------------------------------------------------------------
-- Editing rooms. A room being furnished (new) or edited (built before) has an
-- editor on every peer; its player's machine shows it. Every command below
-- runs the single player editor code on that editor, so all peers change the
-- room alike. entry.edit: a built room being edited; entry.unbuilt: its
-- walls are down (moved or resized), its objects wait in the editor's list.
--------------------------------------------------------------------------------

--! Hidden editors draw nothing on the map (a blueprint under this machine's
--! mouse would show another player's editor).
local function quiet(world, dlg)
  if not is_shown(world.ui, dlg) then
    dlg:clearBlueprint()
    dlg.object_cell_x, dlg.object_cell_y = nil, nil
  end
end

--! Show the editor to its player again after a command changed it.
function builder.showAgain(world, entry)
  local session = TheApp.mp_session
  if session and entry.peer == session.peer_id and not session.observer then
    return builder.show(world, entry)
  end
end

--! A room asked to be edited (room.mp_edit = {peer}) is empty now: open its
--! editor on every peer, shown to its player. Called by Room:enterEditMode.
function builder.startEdit(world, room)
  local want = room.mp_edit
  room.mp_edit = nil
  local dlg = with_editor(world, room.hospital, function() return UIEditRoom(world.ui, room) end)
  quiet(world, dlg)
  local entry = {dlg = dlg, peer = want.peer, hospital = world:getHospitalIndex(room.hospital),
      x = room.x, y = room.y, w = room.width, h = room.height, placed = {}, edit = true}
  world.mp_furnishing = world.mp_furnishing or {}
  world.mp_furnishing[room.id] = entry
  local session = TheApp.mp_session
  if session and want.peer == session.peer_id and not session.observer and
      not builder.show(world, entry) then
    -- Busy with another editor: open the room again.
    session:issue({kind = "room_finish", room = room.id, auto = 1})
  end
  return entry
end

--! Pick up an object of the room (it goes back into the editor's list), as
--! a click in single player's pick up mode does.
function builder.pickUp(world, entry, obj)
  local dlg = entry.dlg
  return with_editor(world, world.hospitals[entry.hospital], function()
    if dlg.phase ~= "objects" then return false, "room is not being furnished" end
    local room = dlg.room
    if not room.objects[obj] or obj == room.door or obj == room.door2 then
      return false, "not in this room"
    end
    if obj.object_type.class == "Plant" or obj.object_type.class == "Machine" then
      -- (Object:onClick) The handyman task for it goes too.
      local task = obj.object_type.class == "Plant" and "watering" or "repairing"
      local index = obj.hospital and obj.hospital:getIndexOfTask(obj.tile_x, obj.tile_y, task) or -1
      if index ~= -1 then obj.hospital:removeHandymanTask(index, task) end
    end
    local direction = obj.direction
    obj.picked_up = true
    world:destroyEntity(obj)
    dlg:stopPickupItems()
    dlg:addObjects({{object = obj.object_type, qty = 1, existing_object = obj}}, false)
    dlg:selectObjectType(obj.object_type)
    dlg:checkEnableConfirm()
    dlg:setOrientation(direction)
    obj.orientation_before = direction
    quiet(world, dlg)
    return true
  end)
end

--! Parse "id:qty,id:qty" into {id = qty}.
function builder.decodeCounts(text)
  local counts = {}
  for id, n in tostring(text or ""):gmatch("([%w_]+):(%d+)") do
    counts[id] = (counts[id] or 0) + tonumber(n)
  end
  return counts
end

function builder.encodeCounts(counts)
  local ids = {}
  for id, n in pairs(counts) do if n > 0 then ids[#ids + 1] = id end end
  table.sort(ids)
  local parts = {}
  for _, id in ipairs(ids) do parts[#parts + 1] = id .. ":" .. counts[id] end
  return table.concat(parts, ",")
end

--! Buy more objects for the room, or sell objects not placed yet, as the
--! room editor's purchase window does (UIFurnishCorridor:confirm).
--!param buy, sell ({id = qty})
function builder.buy(world, entry, buy, sell)
  local dlg = entry.dlg
  return with_editor(world, world.hospitals[entry.hospital], function()
    if dlg.phase ~= "objects" then return false, "room is not being furnished" end
    local hospital = world.ui.hospital
    local allowed = {}
    local cfg_objects = world.map.level_config.objects
    for _, id in ipairs(dlg.room.room_info.objects_additional) do
      local object = TheApp.objects[id]
      local progress = hospital.research.research_progress[object]
      if cfg_objects[object.thob].AvailableForLevel == 1 and (not progress or progress.discovered) then
        allowed[id] = true
      end
    end
    local in_list = {}
    for _, o in ipairs(dlg.objects) do in_list[o.object.id] = (in_list[o.object.id] or 0) + o.qty end
    local ids = {}
    for id in pairs(buy) do ids[#ids + 1] = id end
    for id in pairs(sell) do if not buy[id] then ids[#ids + 1] = id end end
    table.sort(ids)
    local cost = 0
    for _, id in ipairs(ids) do
      if (buy[id] or 0) > 0 then
        if not allowed[id] then return false, "cannot buy that" end
        cost = cost + buy[id] * hospital:getObjectBuildCost(id)
      end
      if (sell[id] or 0) > (in_list[id] or 0) then return false, "nothing to sell" end
    end
    if not world.free_build_mode and cost > 0 and hospital.balance < cost then
      return false, "not enough money"
    end
    local to_purchase, to_sell = {}, {}
    for _, id in ipairs(ids) do
      local object = TheApp.objects[id]
      local build_cost = hospital:getObjectBuildCost(id)
      if (buy[id] or 0) > 0 then
        to_purchase[#to_purchase + 1] = {object = object, qty = buy[id]}
        hospital:spendMoney(build_cost * buy[id], _S.transactions.buy_object .. ": " .. object.name,
            build_cost * buy[id])
      end
      if (sell[id] or 0) > 0 then
        to_sell[#to_sell + 1] = {object = object, qty = sell[id]}
        hospital:receiveMoney(build_cost * sell[id], _S.transactions.sell_object .. ": " .. object.name,
            build_cost * sell[id])
      end
    end
    if #to_purchase > 0 then dlg:addObjects(to_purchase, false) end
    if #to_sell > 0 then dlg:removeObjects(to_sell) end
    dlg:checkEnableConfirm()
    quiet(world, dlg)
    return true
  end)
end

--! Walls down to move or resize the room, as cancelling in single player's
--! objects phase does: the objects go into the editor's list, and its player
--! draws the room again (builder.rebuild).
function builder.unbuild(world, entry)
  local dlg = entry.dlg
  return with_editor(world, world.hospitals[entry.hospital], function()
    if dlg.phase ~= "objects" then return false, "room is not being furnished" end
    dlg:stopPickupItems()
    dlg:returnToDoorPhase()
    world:resetSideObjects()
    dlg:returnToWallPhase()
    -- Nothing on the map until the new outline is built; its player's
    -- machine shows the old outline to start from.
    dlg:setBlueprintRect(1, 1, 0, 0)
    entry.unbuilt = true
    return true
  end)
end

--! Its player draws the room again: their editor shows the outline phase,
--! starting from the old outline (or `cmd`'s, after a failed rebuild). Only
--! on that player's machine; the other peers see the reserved outline.
function builder.startRedraw(world, entry, cmd)
  local session = TheApp.mp_session
  if not (session and entry.peer == session.peer_id and not session.observer) then return end
  if not builder.show(world, entry) then return end
  local dlg = entry.dlg
  local r = cmd or entry
  dlg.desc_text = _S.place_objects_window.drag_blueprint
  dlg:setBlueprintRect(r.x, r.y, r.w, r.h)
end

--! Back to the outline phase with nothing drawn (after a failed rebuild).
local function reset_to_walls(dlg)
  local guard = 0
  while dlg.phase ~= "walls" and guard < 6 do
    guard = guard + 1
    dlg:cancel()
  end
  dlg:setBlueprintRect(1, 1, 0, 0)
end

--! Build an unbuilt room again where its player drew it: {x, y, w, h,
--! door_x, door_y, door_wall, windows}. The objects then wait to be placed.
--!return true, or false and a reason ("people in the area": retry)
function builder.rebuild(world, entry, cmd)
  local dlg = entry.dlg
  return with_editor(world, world.hospitals[entry.hospital], function()
    if not entry.unbuilt then return false, "room is not being moved" end
    local x, y, w, h = cmd.x, cmd.y, cmd.w, cmd.h
    reset_to_walls(dlg)
    if #humanoids_in(world, x, y, w, h) > 0 then return false, "people in the area" end
    local function fail(why)
      reset_to_walls(dlg)
      return false, why
    end
    dlg:setBlueprintRect(x, y, w, h)
    if not dlg.confirm_button.enabled then return fail("invalid room outline") end
    dlg:confirm(true)
    if dlg.phase ~= "door" then return fail("room would block part of the hospital") end
    dlg:setDoorBlueprint(cmd.door_x, cmd.door_y, cmd.door_wall)
    if not dlg.blueprint_door.valid then return fail("invalid door position") end
    dlg:placeDoorBlueprint()
    if dlg.phase ~= "windows" then return fail("door not accepted") end
    for _, win in ipairs(builder.decodeWindows(cmd.windows)) do
      dlg:setWindowBlueprint(builder.windowCell(win, x, y, w, h))
      dlg:placeWindowBlueprint()
    end
    dlg:confirm(true)
    if dlg.phase == "clear_area" then return fail("people in the area") end
    if dlg.phase ~= "objects" then return fail("unexpected phase " .. tostring(dlg.phase)) end
    entry.unbuilt = nil
    entry.x, entry.y, entry.w, entry.h = x, y, w, h
    quiet(world, dlg)
    return true
  end)
end

--! Remove a room whose walls are down, as cancelling in single player's
--! outline phase does (half the build cost back if it was paid).
function builder.delete(world, entry)
  local dlg = entry.dlg
  return with_editor(world, world.hospitals[entry.hospital], function()
    if not entry.unbuilt then return false, "room is not being moved" end
    reset_to_walls(dlg)
    dlg:abortRoom()
    return true
  end)
end

return builder
