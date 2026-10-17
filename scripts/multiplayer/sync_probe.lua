-- Determinism / sync probe. Run through the CorsixTH executable with
-- --interpreter=<this file>. Diagnostic only: it does not change gameplay code.
--
-- Environment:
--   CORSIXTH_SOURCE   checkout root (required)
--   MP_MODE           solo | host | client          (default solo)
--   MP_SEED           integer seed for math.random   (default 12345)
--   MP_CALLBACKS      App:onTick calls to run        (default 3000)
--   MP_DRAW_EVERY     call drawFrame every N ticks; 0 = never (default 0)
--   MP_OUT            file to write one fingerprint line per game hour
--   MP_HOST, MP_PORT  TCP endpoint for host/client  (default 127.0.0.1:47800)
--   MP_LUA_CPATH      extra package.cpath entries (for luasocket)
--   MP_LUA_PATH       extra package.path entries
local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local mode = os.getenv("MP_MODE") or "solo"
local seed = tonumber(os.getenv("MP_SEED") or "12345")
local callbacks = tonumber(os.getenv("MP_CALLBACKS") or "3000")
local draw_every = tonumber(os.getenv("MP_DRAW_EVERY") or "0")
local out_path = os.getenv("MP_OUT")

local function log(msg)
  io.stdout:write("[" .. mode .. "] " .. msg .. "\n")
  io.stdout:flush()
end

-- Ordered, explicit gameplay projection. Deliberately not the save file.
local function fingerprint(world)
  local hospital = world.hospitals[1]
  local parts = {
    world.game_date:tostring(),
    tostring(hospital.balance),
    tostring(hospital.num_visitors or 0),
    tostring(#world.entities),
  }
  for _, e in ipairs(world.entities) do
    parts[#parts + 1] = (e.humanoid_class or (e.object_type and e.object_type.id) or "?")
        .. "@" .. tostring(e.tile_x) .. "," .. tostring(e.tile_y)
  end
  local TH = require("TH")
  local entities_crc = TH.CRC32File(table.concat(parts, ";", 5))
  local rng_crc = TH.CRC32File(math.randomdump())
  return string.format("%s bal=%s visitors=%s entities=%s ecrc=%08x rng=%08x",
      parts[1], parts[2], parts[3], parts[4], entities_crc, rng_crc)
end


-- Scripted, identical-on-every-peer setup: one reception desk, one
-- receptionist, hospital opened. Stands in for player commands for now.
local function setup_hospital(world)
  local hospital = world.hospitals[1]
  local th = world.map.th
  local cx, cy = th:getCameraTile(1)
  local fp = world.object_types.reception_desk.orientations.north.footprint
  local function ok_tile(x, y)
    if not hospital:isInHospital(x, y) or world:getRoom(x, y) then return false end
    local flags = th:getCellFlags(x, y)
    return flags.buildable and flags.passable
  end
  local desk_x, desk_y
  for r = 0, 25 do
    for dx = -r, r do
      for dy = -r, r do
        local x, y = cx + dx, cy + dy
        local good = true
        for _, t in ipairs(fp) do
          for nx = -1, 1 do
            for ny = -1, 1 do
              if not ok_tile(x + t[1] + nx, y + t[2] + ny) then good = false end
            end
          end
        end
        if good then desk_x, desk_y = x, y break end
      end
      if desk_x then break end
    end
    if desk_x then break end
  end
  assert(desk_x, "No free tile for a reception desk")
  world:prepareFootprintTilesForBuild(fp, desk_x, desk_y)
  world:newObject("reception_desk", desk_x, desk_y, "north")
  hospital:spendMoney(hospital:getObjectBuildCost("reception_desk"), "probe desk")

  local profile = StaffProfile(world, "Receptionist", _S.staff_class["receptionist"])
  profile:init(0.5)
  local staff = world:newEntity(profile.humanoid_class, 2, 2)
  staff:setProfile(profile)
  staff:setTile(desk_x + 2, desk_y + 2)
  -- Receptionists need their hospital before onPlaceInCorridor().
  hospital.staff[#hospital.staff + 1] = staff
  staff:setHospital(hospital)
  staff:onPlaceInCorridor()
  hospital:open()
  return desk_x, desk_y
end

local conn
local function connect()
  local extra_cpath = os.getenv("MP_LUA_CPATH")
  if extra_cpath then package.cpath = extra_cpath .. ";" .. package.cpath end
  local extra_path = os.getenv("MP_LUA_PATH")
  if extra_path then package.path = extra_path .. ";" .. package.path end
  local socket = require("socket")
  local host = os.getenv("MP_HOST") or "127.0.0.1"
  local port = tonumber(os.getenv("MP_PORT") or "47800")
  if mode == "host" then
    local server = assert(socket.bind(host, port))
    server:settimeout(30)
    log("listening on " .. host .. ":" .. port)
    conn = assert(server:accept(), "No client connected within 30 s")
    server:close()
  else
    local deadline = socket.gettime() + 30
    repeat
      conn = socket.connect(host, port)
      if not conn then socket.sleep(0.2) end
    until conn or socket.gettime() > deadline
    assert(conn, "Could not reach host")
  end
  conn:settimeout(30)
  conn:setoption("tcp-nodelay", true)
  log("connected")
end

-- Lockstep barrier: both peers send their fingerprint for hour N and wait
-- for the other side's before simulating further.
local function exchange(hour, fp)
  assert(conn:send(string.format("H %d %s\n", hour, fp)))
  local line, err = conn:receive("*l")
  assert(line, "Peer closed or timed out: " .. tostring(err))
  local peer_hour, peer_fp = line:match("^H (%d+) (.*)$")
  assert(tonumber(peer_hour) == hour, "Hour mismatch: " .. line)
  return peer_fp
end

local function run()
  assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
  assert(TheApp.good_install_folder, "Game data was not accepted")
  if mode ~= "solo" then connect() end

  -- Replace the clock-based seed from App:init before anything else runs.
  math.randomseed(seed)
  TheApp:_loadLevel(1, "full", nil, "LEVEL.L1")
  assert(TheApp.world, "Level did not load")
  local world = TheApp.world
  local desk_x, desk_y = setup_hospital(world)
  log("reception desk at " .. desk_x .. "," .. desk_y)
  world:setSpeed("And then some more")

  local out = out_path and assert(io.open(out_path, "w"))
  local last_date = world.game_date:tostring()
  local hour, first_mismatch, compared = 0, nil, 0
  for i = 1, callbacks do
    TheApp:onTick()
    if draw_every > 0 and i % draw_every == 0 then TheApp:drawFrame() end
    local date = world.game_date:tostring()
    if date ~= last_date then
      last_date = date
      hour = hour + 1
      local fp = fingerprint(world)
      if out then out:write(hour, " ", fp, "\n") end
      if conn then
        local peer_fp = exchange(hour, fp)
        compared = compared + 1
        if peer_fp ~= fp and not first_mismatch then
          first_mismatch = hour
          log("DESYNC at game hour " .. hour)
          log("  local: " .. fp)
          log("  peer:  " .. peer_fp)
        end
      end
    end
  end
  if out then out:close() end
  log("final " .. fingerprint(world))
  log(string.format("hours=%d compared=%d", hour, compared))
  if conn then
    conn:close()
    log(first_mismatch and ("RESULT: DESYNC first at hour " .. first_mismatch)
        or "RESULT: IN SYNC for all compared hours")
  end
  log("PROBE: DONE")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  io.stderr:flush()
  os.exit(1)
end
os.exit(0)
