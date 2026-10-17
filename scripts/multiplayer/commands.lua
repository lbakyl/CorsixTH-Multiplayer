-- Experimental lockstep command layer.
--
-- A command is a player action described by plain values, e.g.
--   {kind = "place_object", object = "bench", x = 60, y = 75, orientation = "north"}
-- It is issued by one peer at game hour h, scheduled for hour h + DELAY, sent
-- to the other peer with that hour's fingerprint, and applied by every peer
-- at the start of the scheduled hour in a fixed order. Commands carry exact
-- coordinates chosen by the issuing peer; validity is checked again when the
-- command is applied, against the same state on every peer, so an action that
-- became impossible is rejected identically everywhere.
--
-- Wire format: one line per command, space separated key=value pairs, values
-- percent-encoded:  C hour=52 peer=2 seq=1 kind=place_object object=bench ...

local commands = {}

commands.DELAY = 2 -- game hours between issuing and applying a command

local function encode_value(v)
  return (tostring(v):gsub("[%%%s=]", function(c) return string.format("%%%02X", c:byte()) end))
end

local function decode_value(v)
  v = v:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  return tonumber(v) or v
end

--! Serialize a command to a single line (without trailing newline).
function commands.encode(cmd)
  local keys = {}
  for k in pairs(cmd) do keys[#keys + 1] = k end
  table.sort(keys) -- deterministic text, independent of table order
  local parts = {"C"}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. "=" .. encode_value(cmd[k])
  end
  return table.concat(parts, " ")
end

--! Parse a line produced by commands.encode(), or return nil.
function commands.decode(line)
  if line:sub(1, 2) ~= "C " then return nil end
  local cmd = {}
  for k, v in line:sub(3):gmatch("([%w_]+)=(%S*)") do
    cmd[k] = decode_value(v)
  end
  return cmd
end

--! Order in which commands for the same hour are applied on every peer.
function commands.sort(list)
  table.sort(list, function(a, b)
    if a.hour ~= b.hour then return a.hour < b.hour end
    if a.peer ~= b.peer then return a.peer < b.peer end
    return a.seq < b.seq
  end)
  return list
end

--! Apply one command to the world. Returns true, or false and a reason.
--! Must give the same result on every peer for the same state.
function commands.apply(world, builder, cmd)
  if cmd.kind == "place_object" then
    local object_type = world.object_types[cmd.object]
    if not object_type or not object_type.orientations[cmd.orientation] then
      return false, "unknown object or orientation"
    end
    local x, y = cmd.x, cmd.y
    local hospital = world.hospitals[1]
    local th = world.map.th
    for _, t in ipairs(object_type.orientations[cmd.orientation].footprint) do
      local tx, ty = x + t[1], y + t[2]
      local flags = th:getCellFlags(tx, ty)
      if not hospital:isInHospital(tx, ty) or world:getRoom(tx, ty)
          or not flags.buildable or world:getObject(tx, ty) then
        return false, "tile not free"
      end
    end
    builder.place_object(world, cmd.object, x, y, cmd.orientation)
    return true
  elseif cmd.kind == "build_room" then
    local room, err = builder.build_room(world, cmd.room, cmd.x, cmd.y, cmd.w, cmd.h, nil, true)
    if not room then return false, err end
    return true
  elseif cmd.kind == "hire" then
    builder.hire(world, cmd.class, cmd.x, cmd.y)
    return true
  end
  return false, "unknown command kind " .. tostring(cmd.kind)
end

return commands
