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
--! use tile of every object in the room (this one included) reachable from
--! the entrance? The room editor's own checks allow layouts in which, for
--! example, the desk walls off the cabinet's use tile; a player would see
--! that and move things, but the automatic placement must avoid it (a doctor
--! looking for the cabinet would find none).
--!param placed (table) list of {footprint, use_x, use_y} already in the room
local function keeps_room_usable(room, rect, placed, object_type, tx, ty, o)
  local orientation = object_type.orientations[o]
  local blocked = {}
  local function key(x, y) return x * 1000 + y end
  local uses = {}
  local candidate = {footprint = {}, use_x = tx + orientation.use_position[1],
      use_y = ty + orientation.use_position[2]}
  for _, t in ipairs(orientation.footprint) do
    if not t.only_passable then candidate.footprint[#candidate.footprint + 1] = {tx + t[1], ty + t[2]} end
  end
  for _, item in ipairs(placed) do
    for _, xy in ipairs(item.footprint) do blocked[key(xy[1], xy[2])] = true end
    uses[#uses + 1] = {item.use_x, item.use_y}
  end
  for _, xy in ipairs(candidate.footprint) do blocked[key(xy[1], xy[2])] = true end
  uses[#uses + 1] = {candidate.use_x, candidate.use_y}

  local ex, ey = room:getEntranceXY(true)
  if blocked[key(ex, ey)] then return false, candidate end
  local function inside(x, y)
    return x >= rect.x and x < rect.x + rect.w and y >= rect.y and y < rect.y + rect.h
  end
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
  for _, u in ipairs(uses) do
    if not seen[key(u[1], u[2])] then return false, candidate end
  end
  return true, candidate
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
    dlg:setWindowBlueprint(win[1], win[2], win[3])
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

--! Show the room editor of a room being furnished to its player (only on
--! that player's machine). False if another room editor is open there.
function builder.show(world, entry)
  local ui = world.ui
  if not ui or (ui.edit_room and ui.edit_room ~= entry.dlg) then return false end
  local dlg = entry.dlg
  dlg.mp_room_id = entry.dlg.room.id
  if not dlg.parent then ui:addWindow(dlg) end
  ui.edit_room = dlg
  ui:setWorldHitTest(dlg.room)
  -- Buying more objects and picking up placed ones are not commands yet.
  if dlg.purchase_button then dlg.purchase_button:enable(false) end
  if dlg.pickup_button then dlg.pickup_button:enable(false) end
  return true
end

--! Take the editor away from its player's screen (not on the other peers,
--! where it never was). The room itself is unchanged.
function builder.hide(world, entry)
  local dlg = entry.dlg
  if dlg.parent then dlg.parent:removeWindow(dlg) end
  builder.releaseUI(world.ui, dlg)
end

--! If the UI still points at this room editor (clicks limited to its room,
--! ui.edit_room set) while the editor is not shown, give the whole map back.
--! A save made in that state would otherwise keep a player from clicking
--! anybody outside that room.
function builder.releaseUI(ui, dlg)
  if not ui or (dlg and dlg.parent) then return end
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
      if not dlg.parent then
        -- Not shown on this machine: no blueprint on the map.
        dlg:clearBlueprint()
        dlg.object_cell_x, dlg.object_cell_y = nil, nil
        return
      end
      -- This player's editor goes on following their mouse from where it was.
      if dlg.objects[dlg.active_index] then
        if orientation then dlg:setOrientation(orientation) end
        if cell_x then dlg:setBlueprintCell(cell_x, cell_y) end
      end
    end
    dlg:setActiveIndex(index)
    dlg:setOrientation(cmd.orientation)
    dlg:setBlueprintCell(cmd.x, cmd.y)
    if not dlg.object_blueprint_good then restore() return false, "tile not free" end
    if world:anyHumanoidObscuringArea(cmd.x, cmd.y) then restore() return false, "someone is in the way" end
    local usable, item = keeps_room_usable(dlg.room, entry, entry.placed, object_type,
        cmd.x, cmd.y, cmd.orientation)
    if not usable then restore() return false, "it would block the room" end
    dlg.object_cell_x, dlg.object_cell_y = cmd.x, cmd.y
    dlg:placeObject()
    entry.placed[#entry.placed + 1] = item
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
      local ok, why = builder.autoFurnish(dlg, dlg.room, entry, entry.placed)
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

return builder
