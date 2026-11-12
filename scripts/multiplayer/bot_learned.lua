-- What the bots learnt from expert players' hospitals, and how a bot uses it
-- (Jan, 2026-11-12: bots should build rooms the way Argus does).
-- scripts/multiplayer/layout_learn.py writes the learned file from saved
-- games; bot.lua loads it (MP_BOT_LEARNED) with this module:
-- - recipes: for each kind of room the size an expert builds and where each
--   object stands, seen from the door (the frame: the door's wall at the
--   top, W tiles wide along it, D deep; the door at column `door`);
-- - plans: for a level, map size, number of hospitals and hospital place an
--   expert played, every room of theirs (kind, corner, size, door, layout)
--   and the objects in their corridors.
-- Plain functions without the game (bot_learned_test.lua runs them).
local L = {}

local DIRS = {"north", "east", "south", "west"}
local DIR_INDEX = {north = 0, east = 1, south = 2, west = 3}
-- Clockwise quarter turns that bring each door wall to the top.
local ROT = {north = 0, west = 1, south = 2, east = 3}
local MIRROR = {east = "west", west = "east"}

--! The learned data in the file at `path` (a Lua table constructor, run
--! with no access to anything), or nil and why.
function L.load(path)
  local f = path and path ~= "" and io.open(path, "r")
  if not f then return nil, "no file" end
  local text = f:read("*a")
  f:close()
  local chunk, err
  -- (rawget: the game's strict mode refuses a global that is not there;
  -- setfenv and loadstring are Lua 5.1's and LuaJIT's.)
  local set_env, load_string = rawget(_G, "setfenv"), rawget(_G, "loadstring")
  if set_env and load_string then
    chunk, err = load_string(text, "=learned")
    if chunk then set_env(chunk, {}) end
  else
    chunk, err = load(text, "=learned", "t", {})
  end
  if not chunk then return nil, err end
  local ok, data = pcall(chunk)
  if not ok then return nil, tostring(data) end
  if type(data) ~= "table" or data.version ~= 1 then return nil, "not version 1" end
  data.recipes, data.plans = data.recipes or {}, data.plans or {}
  return data
end

--! The frame of a room at x, y (w x h tiles) whose door (the game's door
--! object) is at door_x, door_y facing door_dir ("north": in the north or
--! south wall, "west": in the west or east wall).
function L.frame(x, y, w, h, door_x, door_y, door_dir)
  local wall
  if door_dir == "north" then
    wall = door_y == y and "north" or "south"
  else
    wall = door_x == x and "west" or "east"
  end
  local col
  if wall == "north" then col = door_x - x
  elseif wall == "south" then col = w - 1 - (door_x - x)
  elseif wall == "west" then col = h - 1 - (door_y - y)
  else col = door_y - y end
  local W, D = w, h
  if wall == "west" or wall == "east" then W, D = h, w end
  return {x = x, y = y, w = w, h = h, wall = wall, col = col, W = W, D = D}
end

--! The door's column in the frame for a door the room editor would place
--! on `wall` at the room's edge tile tx, ty (UIEditRoom:setDoorBlueprint).
function L.editorCol(x, y, w, h, wall, tx, ty)
  if wall == "north" then return tx - x end
  if wall == "south" then return w - 1 - (tx - x) end
  if wall == "west" then return h - 1 - (ty - y) end
  return ty - y
end

--! The edge tile and wall where the room editor puts a door at column
--! `col` of the frame whose door wall is `wall` (L.editorCol backwards).
function L.editorDoor(x, y, w, h, wall, col)
  if wall == "north" then return x + col, y end
  if wall == "south" then return x + w - 1 - col, y + h - 1 end
  if wall == "west" then return x, y + h - 1 - col end
  return x + w - 1, y + col
end

--! A frame position (column, row) as the map's tile.
function L.toMap(f, c, r)
  if f.wall == "north" then return f.x + c, f.y + r end
  if f.wall == "south" then return f.x + f.w - 1 - c, f.y + f.h - 1 - r end
  if f.wall == "west" then return f.x + r, f.y + f.h - 1 - c end
  return f.x + f.w - 1 - r, f.y + c
end

--! A map tile inside the room as (column, row) in its frame.
function L.toFrame(f, tx, ty)
  local rx, ry = tx - f.x, ty - f.y
  if f.wall == "north" then return rx, ry end
  if f.wall == "south" then return f.w - 1 - rx, f.h - 1 - ry end
  if f.wall == "west" then return f.h - 1 - ry, rx end
  return ry, f.w - 1 - rx
end

--! A direction in the frame as one on the map, and back.
function L.mapDir(f, d)
  local i = DIR_INDEX[d]
  if not i then return d end
  return DIRS[(i - ROT[f.wall]) % 4 + 1]
end

function L.frameDir(f, d)
  local i = DIR_INDEX[d]
  if not i then return d end
  return DIRS[(i + ROT[f.wall]) % 4 + 1]
end

--! A layout's objects as they stand in the room with frame `f`: each
--! {id, dir, tiles} with map directions and tiles; mirrored left to right
--! first if `mirror`.
function L.placements(f, objects, mirror)
  local out = {}
  for _, o in ipairs(objects) do
    local d = o.dir
    if mirror then d = MIRROR[d] or d end
    local tiles = {}
    for _, t in ipairs(o.tiles) do
      local c = mirror and (f.W - 1 - t[1]) or t[1]
      local mx, my = L.toMap(f, c, t[2])
      tiles[#tiles + 1] = {mx, my}
    end
    out[#out + 1] = {id = o.id, dir = L.mapDir(f, d), tiles = tiles}
  end
  return out
end

--! The tiles an object type stands on facing `dir` (its footprint without
--! the tiles people only walk on to use it), as offsets from its tile.
function L.solidFootprint(object_type, dir)
  local orientation = object_type.orientations and object_type.orientations[dir]
  if not orientation then return nil end
  local solid = {}
  for _, t in ipairs(orientation.footprint or {}) do
    if not t.only_passable then solid[#solid + 1] = {t[1], t[2]} end
  end
  if #solid == 0 then solid[1] = {0, 0} end
  return solid
end

--! The tile to put an object of `object_type` facing `dir` on so that it
--! stands on exactly `tiles`, or nil (another shape).
function L.origin(object_type, dir, tiles)
  local solid = L.solidFootprint(object_type, dir)
  if not solid or #solid ~= #tiles then return nil end
  local want = {}
  for _, t in ipairs(tiles) do want[t[2] * 100000 + t[1]] = true end
  for _, s in ipairs(solid) do
    local ox, oy = tiles[1][1] - s[1], tiles[1][2] - s[2]
    local all = true
    for _, s2 in ipairs(solid) do
      if not want[(oy + s2[2]) * 100000 + (ox + s2[1])] then all = false break end
    end
    if all then return ox, oy end
  end
end

--! The layout of `objects` (seen from a door at column `door` in a frame
--! W x D) for a room with frame `f`: the objects and whether to mirror
--! them, or nil when the room's size or door does not suit it.
function L.fit(layout_w, layout_d, door, objects, f)
  if layout_w ~= f.W or layout_d ~= f.D then return nil end
  if door == f.col then return objects, false end
  if door == f.W - 1 - f.col then return objects, true end
end

--! The layouts of a recipe or plan room as candidates for a room: each
--! {w, d, wall, col, objects}; a recipe's own door walls first (its
--! variants, as the experts had them), then its canonical layout (any wall).
function L.layouts(r)
  local out = {}
  for _, v in ipairs(r.variants or {}) do
    out[#out + 1] = {w = r.w, d = r.d, wall = v.wall, col = v.col, objects = v.objects}
  end
  out[#out + 1] = {w = r.w, d = r.d, col = r.door, objects = r.objects}
  return out
end

--! The best of `layouts` for the room with frame `f`: the most objects that
--! can stand on their tiles there (`object_types[id]`, the game's objects:
--! L.origin), the same door wall first. Returns the placements (L.placements)
--! and how many of them can be put, or nil.
function L.best(layouts, f, object_types)
  local best, best_n, best_score
  for _, lay in ipairs(layouts) do
    local objects, mirror = L.fit(lay.w, lay.d, lay.col, lay.objects, f)
    if objects then
      local placed = L.placements(f, objects, mirror)
      local n = 0
      for _, p in ipairs(placed) do
        local ot = object_types[p.id]
        if ot and L.origin(ot, p.dir, p.tiles) then n = n + 1 end
      end
      local score = n + ((lay.wall == f.wall and not mirror) and 0.5 or 0)
      if not best_score or score > best_score then best, best_n, best_score = placed, n, score end
    end
  end
  return best, best_n
end

--! The recipe for a room of kind `id` a bot plans at size `planned`
--! (square), or nil: none, or much bigger than the bot would build (an
--! expert's 11 x 11 research room in a bot's first year).
--!param slack (number) optional: how many tiles bigger may do (default 3)
function L.recipe(data, id, planned, slack)
  local r = data and data.recipes[id]
  if not r then return nil end
  if planned and math.max(r.w, r.d) > planned + (slack or 3) then return nil end
  return r
end

--! The plan for a hospital: the key is the level's name, the map's size,
--! the number of hospitals and this hospital's place among them.
function L.planKey(level, map_w, map_h, hospitals, index)
  -- (A campaign level's name is a localised string.)
  local name = tostring(level):gsub("^<LocalisedString> Current value:", "")
  return string.format("%s/%dx%d/%d/%d", name, map_w, map_h, hospitals, index)
end

function L.plan(data, key)
  return data and data.plans[key]
end

--! The plan's rooms of kind `id` in order, those for which `usable(slot)`
--! says yes.
function L.slots(plan, id, usable)
  local out = {}
  for _, slot in ipairs(plan and plan.rooms or {}) do
    if slot.kind == id and (not usable or usable(slot)) then out[#out + 1] = slot end
  end
  return out
end

--! How many of each object a layout has beyond `needed` (a room type's
--! objects_needed): the extras to buy.
function L.extras(objects, needed)
  local counts = {}
  for _, o in ipairs(objects) do counts[o.id] = (counts[o.id] or 0) + 1 end
  local extras = {}
  for id, n in pairs(counts) do
    local more = n - ((needed and needed[id]) or 0)
    if more > 0 then extras[id] = more end
  end
  return extras
end

return L
