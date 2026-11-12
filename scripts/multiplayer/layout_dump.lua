-- The layout of every hospital in saved games, for the bots to learn from
-- (Jan, 2026-11-12: "down to where each plant and heater is placed"):
--   corsix-th --interpreter=<this file> --config-file=<a config>
-- Environment:
--   CORSIXTH_SOURCE   checkout root
--   MP_LAYOUT_SAVES   the saved games, separated by ";"
--   MP_LAYOUT_OUT     file to write (JSON lines: one line per hospital)
--   MP_LUA_CPATH, MP_LUA_PATH  where the game's Lua libraries are, if not in
--                     the standard paths (a server's referee game: lfs)
-- Each line: the save, its date, the level (name, map size, hospitals), and
-- one hospital: its name and index, whether a bot played it (bot: the
-- room's own bot; standin: a bot playing for a person who left), its plots,
-- every room (kind, corner, size, door and its side, and each object in it:
-- kind, tile, direction and the tiles it stands on) and the objects in its
-- corridors (benches, plants, radiators, machines...). Positions are the
-- map's tiles; scripts/multiplayer/layout_learn.py turns them into each
-- room's layout seen from its door, and into what the bots learn.
local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local saves = assert(os.getenv("MP_LAYOUT_SAVES"), "Missing MP_LAYOUT_SAVES")
local out_path = assert(os.getenv("MP_LAYOUT_OUT"), "Missing MP_LAYOUT_OUT")
if os.getenv("MP_LUA_CPATH") then package.cpath = os.getenv("MP_LUA_CPATH") .. ";" .. package.cpath end
if os.getenv("MP_LUA_PATH") then package.path = os.getenv("MP_LUA_PATH") .. ";" .. package.path end

local function json(v)
  local t = type(v)
  if t == "table" then
    if #v > 0 or next(v) == nil then
      local parts = {}
      for i = 1, #v do parts[i] = json(v[i]) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = json(k) .. ":" .. json(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif t == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"'
  elseif t == "number" then
    return tostring(v)
  elseif t == "boolean" then
    return v and "true" or "false"
  end
  return "null"
end

--! The tiles an object stands on (its footprint without the tiles people
--! only walk on to use it), as {x, y} pairs in a fixed order.
local function solid_tiles(object_type, x, y, direction)
  local orientation = object_type.orientations and object_type.orientations[direction]
  local tiles = {}
  for _, t in ipairs(orientation and orientation.footprint or {}) do
    if not t.only_passable then tiles[#tiles + 1] = {x + t[1], y + t[2]} end
  end
  if #tiles == 0 then tiles[1] = {x, y} end
  table.sort(tiles, function(a, b) return a[2] < b[2] or (a[2] == b[2] and a[1] < b[1]) end)
  return tiles
end

local function object_of(e)
  return {id = e.object_type.id, x = e.tile_x, y = e.tile_y, dir = e.direction,
      tiles = solid_tiles(e.object_type, e.tile_x, e.tile_y, e.direction)}
end

local function dump(world, save, out)
  local th = world.map.th
  local w, h = th:size()
  local flags = {}
  -- Which hospital a tile's plot belongs to (by player index).
  local by_player = {}
  for index, hospital in ipairs(world.hospitals) do by_player[hospital:getPlayerIndex()] = index end
  local function owner_of(x, y)
    local p = th:getCellFlags(x, y, flags).parcelId or 0
    return p ~= 0 and by_player[th:getPlotOwner(p)] or nil, p
  end
  local per = {}
  local coop = world.mp_coop or {}
  local bots, standins = coop.bot_hospitals or {}, coop.standin_hospitals or {}
  local ai = rawget(_G, "AIHospital")
  for index, hospital in ipairs(world.hospitals) do
    per[index] = {save = save, date = world:date():tostring(), map = {w, h}, index = index,
        level = (tostring(world.map.level_name or ""):gsub("^<LocalisedString> Current value:", "")),
        hospitals = #world.hospitals, ai = (ai and class.is(hospital, ai)) and true or false,
        name = tostring(hospital.name), rooms = {}, corridor = {}, plots = {},
        bot = bots[index] and true or false, standin = standins[index] and true or false,
        value = hospital.value, reputation = hospital.reputation, balance = hospital.balance,
        cured = hospital.num_cured, deaths = hospital.num_deaths}
  end
  for p = 1, th:getPlotCount() do
    local index = by_player[th:getPlotOwner(p)]
    if index then per[index].plots[#per[index].plots + 1] = p end
  end
  local in_room = {}
  for _, room in pairs(world.rooms) do
    local index = room.hospital and world:getHospitalIndex(room.hospital) or owner_of(room.x, room.y)
    if index and per[index] then
      local door = room.door
      local r = {kind = room.room_info.id, x = room.x, y = room.y, w = room.width, h = room.height,
          door = door and {x = door.tile_x, y = door.tile_y, dir = door.direction} or nil,
          built = room.is_active and true or false, objects = {}}
      for object in pairs(room.objects or {}) do
        if object.object_type then
          r.objects[#r.objects + 1] = object_of(object)
          in_room[object] = true
        end
      end
      table.sort(r.objects, function(a, b)
        if a.id ~= b.id then return a.id < b.id end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
      end)
      local rooms = per[index].rooms
      rooms[#rooms + 1] = r
    end
  end
  for _, e in ipairs(world.entities) do
    if e.object_type and e.tile_x and not in_room[e] and not world:getRoom(e.tile_x, e.tile_y) then
      local index = owner_of(e.tile_x, e.tile_y)
      if index then
        local corridor = per[index].corridor
        corridor[#corridor + 1] = object_of(e)
      end
    end
  end
  for _, record in ipairs(per) do
    table.sort(record.rooms, function(a, b)
      if a.kind ~= b.kind then return a.kind < b.kind end
      return a.x * 1000 + a.y < b.x * 1000 + b.y
    end)
    out:write(json(record), "\n")
  end
end

local function run()
  assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
  assert(TheApp.good_install_folder, "Game data was not accepted")
  local out = assert(io.open(out_path, "w"))
  for save in saves:gmatch("[^;]+") do
    local ok, err = pcall(function() TheApp:load(save) end)
    if ok and TheApp.world then
      local done, why = pcall(dump, TheApp.world, save, out)
      print((done and "dumped " or "could not dump ") .. save .. (done and "" or (": " .. tostring(why))))
    else
      print("could not load " .. save .. ": " .. tostring(err))
    end
  end
  out:close()
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  io.stderr:flush()
  os.exit(1)
end
os.exit(0)
