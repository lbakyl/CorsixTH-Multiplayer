-- Checks of bot_learned.lua without the game: a room seen from its door and
-- back, for each wall the door can be in, mirrored, and an object's tile
-- found from the tiles it stands on.
-- Usage: lua scripts/multiplayer/bot_learned_test.lua scripts/multiplayer/bot_learned.lua
-- (any Lua 5.1 to 5.5 or LuaJIT).
local L = assert(loadfile(arg[1]))()

local function eq(a, b, what)
  if a ~= b then
    print("FAIL", what, tostring(a), tostring(b))
    os.exit(1)
  end
end

-- A room 5 wide, 4 high at 10,20; its door in each wall. The game's door
-- object: north wall at (x, 20) facing north, south wall at (x, 24), west
-- wall at (10, y) facing west, east wall at (15, y).
local doors = {
  north = {12, 20, "north"}, south = {13, 24, "north"},
  west = {10, 22, "west"}, east = {15, 21, "west"},
}
for wall, d in pairs(doors) do
  local f = L.frame(10, 20, 5, 4, d[1], d[2], d[3])
  eq(f.wall, wall, "wall " .. wall)
  eq(f.W, (wall == "north" or wall == "south") and 5 or 4, "frame width " .. wall)
  -- Every tile there and back.
  for ty = 20, 23 do
    for tx = 10, 14 do
      local c, r = L.toFrame(f, tx, ty)
      assert(c >= 0 and c < f.W and r >= 0 and r < f.D, "inside the frame " .. wall)
      local mx, my = L.toMap(f, c, r)
      eq(mx * 1000 + my, tx * 1000 + ty, "tile back " .. wall)
    end
  end
  -- The door's wall is the frame's top row, its tile there at the door's column.
  local edge = {north = {d[1], 20}, south = {d[1], 23}, west = {10, d[2]}, east = {14, d[2]}}
  local c, r = L.toFrame(f, edge[wall][1], edge[wall][2])
  eq(r, 0, "door row " .. wall)
  eq(c, f.col, "door column " .. wall)
  -- The room editor's door tile for that column, and back.
  local ex, ey = L.editorDoor(10, 20, 5, 4, wall, f.col)
  eq(L.editorCol(10, 20, 5, 4, wall, ex, ey), f.col, "editor column " .. wall)
  eq(ex * 1000 + ey, edge[wall][1] * 1000 + edge[wall][2], "editor tile " .. wall)
  -- Directions turn with the room: the one towards the door is north.
  eq(L.frameDir(f, wall), "north", "towards the door " .. wall)
  for _, dir in ipairs({"north", "east", "south", "west"}) do
    eq(L.mapDir(f, L.frameDir(f, dir)), dir, "direction back " .. wall .. " " .. dir)
  end
end

-- A two-tile object (a bed: its tile and the one east of it facing east,
-- north of it facing north...), as the game's footprints say.
local bed = {orientations = {
  east = {footprint = {{0, 0}, {1, 0}, {0, 1, only_passable = true}}},
  west = {footprint = {{0, 0}, {-1, 0}, {0, 1, only_passable = true}}},
  north = {footprint = {{0, 0}, {0, -1}, {1, 0, only_passable = true}}},
  south = {footprint = {{0, 0}, {0, 1}, {1, 0, only_passable = true}}},
}}
local x, y = L.origin(bed, "east", {{4, 7}, {5, 7}})
eq(x * 100 + y, 407, "bed east")
x, y = L.origin(bed, "west", {{4, 7}, {5, 7}})
eq(x * 100 + y, 507, "bed west")
eq(L.origin(bed, "east", {{4, 7}, {4, 8}}), nil, "bed east does not stand north-south")

-- A layout learnt from a room with its door in the east wall, used in a
-- room of the same size with the door in the south wall: each object keeps
-- its place seen from the door; mirrored when the door is at the other end.
local learnt = L.frame(10, 20, 4, 5, 14, 21, "west") -- door in the east wall, column 1
eq(learnt.W * 10 + learnt.D, 54, "learnt frame")
local objects = {{id = "bed", dir = L.frameDir(learnt, "west"), tiles = {}}}
for _, t in ipairs({{12, 22}, {13, 22}}) do
  local c, r = L.toFrame(learnt, t[1], t[2])
  objects[1].tiles[#objects[1].tiles + 1] = {c, r}
end
local room = L.frame(30, 40, 5, 4, 31, 44, "north") -- door in the south wall
local layout, mirror = L.fit(learnt.W, learnt.D, learnt.col, objects, room)
assert(layout, "fits")
local placed = L.placements(room, layout, mirror)
local ox = L.origin(bed, placed[1].dir, placed[1].tiles)
assert(ox, "the bed stands on two tiles side by side: " .. placed[1].dir)
-- Same distance from the door wall (2 rows in) both times.
local _, r1 = L.toFrame(room, placed[1].tiles[1][1], placed[1].tiles[1][2])
eq(r1, 1, "row from the door")
-- A room 4 deep, not 5: no fit.
eq(L.fit(learnt.W, learnt.D, learnt.col, objects, L.frame(30, 40, 4, 4, 31, 44, "north")), nil, "other size")

-- Of a recipe's layouts the one for the room's own door wall first: there
-- every object stands on its tiles as the expert's did.
local recipe = {w = learnt.W, d = learnt.D, door = learnt.col, objects = objects,
    variants = {{wall = "east", col = learnt.col, objects = objects}}}
local lays = L.layouts(recipe)
eq(#lays, 2, "a variant and the canonical layout")
local same = L.frame(50, 60, 4, 5, 54, 61, "west") -- like the expert's: door in the east wall, column 1
local best, n = L.best(lays, same, {bed = bed})
eq(n, 1, "the bed fits")
local bx, by = L.origin(bed, best[1].dir, best[1].tiles)
eq(bx * 1000 + by, 53062, "the bed where the expert's stood, moved with the room")
eq(L.best(lays, L.frame(30, 40, 4, 4, 31, 44, "north"), {bed = bed}), nil, "no layout for another size")

-- The extras a layout has beyond what the room needs.
local extras = L.extras({{id = "desk"}, {id = "radiator"}, {id = "radiator"}, {id = "cabinet"}},
    {desk = 1, cabinet = 1})
eq(extras.radiator, 2, "two radiators")
eq(extras.desk, nil, "no extra desk")

-- Too big a recipe for what the bot builds.
local data = {recipes = {research = {w = 11, d = 11}, gp = {w = 4, d = 4}}, plans = {}}
eq(L.recipe(data, "research", 6), nil, "11 x 11 is too big for 6")
eq(L.recipe(data, "research", 8).w, 11, "a research-heavy bot's 8 + 3")
eq(L.recipe(data, "gp", 4).w, 4, "gp")
eq(L.planKey("CROSSROADS", 192, 192, 6, 6), "CROSSROADS/192x192/6/6", "plan key")
-- Corridor spots by a door (layout_learn.py near_spots): a bench beside
-- the door along the room's wall (row -1, a column to the right, facing
-- north in the frame) and one across the corridor facing the room.
local habits = {door_spots = {bench = {{dc = 1, row = -1, dir = "north", seen = 16},
  {dc = 0, row = -3, dir = "south", seen = 10}, {dc = 0, row = -1, dir = "north", seen = 9}}},
  desk_spots = {bench = {{dx = 0, dy = -2, dir = "south", seen = 4}}}}
-- Room 5 x 4 at 10,20, door in the north wall at 12,20 (frame column 2).
local sp = L.doorSpots(habits, "bench", 10, 20, 5, 4, 12, 20, "north")
eq(#sp, 3, "north: the spot and its mirror, the one across; never in front of the door")
eq(sp[1].x .. "," .. sp[1].y .. " " .. sp[1].dir, "13,19 north", "north: beside the door")
eq(sp[2].x .. "," .. sp[2].y .. " " .. sp[2].dir, "11,19 north", "north: mirrored")
eq(sp[3].x .. "," .. sp[3].y .. " " .. sp[3].dir, "12,17 south", "north: across the corridor")
-- The same room with its door in the west wall at 10,22: the corridor west.
sp = L.doorSpots(habits, "bench", 10, 20, 5, 4, 10, 22, "west")
eq(sp[1].x .. "," .. sp[1].y .. " " .. sp[1].dir, "9,21 west", "west: beside the door")
eq(sp[3].x .. "," .. sp[3].y .. " " .. sp[3].dir, "7,22 east", "west: across the corridor, facing the room")
-- In the south wall at 12,23 and the east wall at 14,21.
sp = L.doorSpots(habits, "bench", 10, 20, 5, 4, 12, 23, "north")
eq(sp[3].x .. "," .. sp[3].y .. " " .. sp[3].dir, "12,26 north", "south: across the corridor")
sp = L.doorSpots(habits, "bench", 10, 20, 5, 4, 14, 21, "west")
eq(sp[3].x .. "," .. sp[3].y .. " " .. sp[3].dir, "17,21 west", "east: across the corridor")
eq(#L.doorSpots(habits, "plant", 10, 20, 5, 4, 12, 20, "north"), 0, "nothing learnt for plants")
eq(#L.doorSpots(nil, "bench", 10, 20, 5, 4, 12, 20, "north"), 0, "nothing learnt at all")
-- By a desk at 30,30: facing north, a bench 2 tiles in front facing it; the
-- desk facing east: 2 tiles east, facing west.
local ds = L.deskSpots(habits, "bench", 30, 30, "north")
eq(ds[1].x .. "," .. ds[1].y .. " " .. ds[1].dir, "30,28 south", "desk north")
ds = L.deskSpots(habits, "bench", 30, 30, "east")
eq(ds[1].x .. "," .. ds[1].y .. " " .. ds[1].dir, "32,30 west", "desk east")
print("bot_learned_test: all checks passed")
