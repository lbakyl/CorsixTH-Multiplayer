-- Run through the CorsixTH executable, not the standalone Lua interpreter.
-- This is a diagnostic harness; it does not change gameplay source files.
local args = {...}
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local output_dir = assert(os.getenv("CORSIXTH_SMOKE_OUTPUT"), "Missing CORSIXTH_SMOKE_OUTPUT")
local unpack_args = table.unpack or unpack

local function run()
  assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
  assert(TheApp.good_install_folder, "Game data was not accepted")
  TheApp:_loadLevel(1, "full", nil, "LEVEL.L1")
  assert(TheApp.world and TheApp.map, "Level did not create a world")
  print("SMOKE: level loaded")

  TheApp.world:setSpeed("Normal")
  local initial_date = TheApp.world.game_date:tostring()
  for _ = 1, 600 do
    TheApp:onTick()
  end
  local saved_date = TheApp.world.game_date:tostring()
  assert(initial_date ~= saved_date, "Game date did not advance")
  print("SMOKE: 600 application callbacks completed; date=" .. saved_date)

  -- Numbers load as they were saved: on Lua 5.3 and later an integer stays
  -- an integer and a float a float (50000 came back as 50000.0, 3.0 as 3,
  -- and a game loaded in a multiplayer repair differed from the others).
  local numbers = {50000, 3.0, -5, 16383, 16384, 0.5, -2.0, 2 ^ 40, 7}
  if math.type then numbers[#numbers + 1] = math.tointeger(2 ^ 40) end
  TheApp.world.smoke_numbers = numbers
  local function shown(list)
    local out = {}
    for i, v in ipairs(list) do out[i] = tostring(v) end
    return table.concat(out, " ")
  end
  local numbers_text = shown(numbers)
  local save_path = output_dir .. "/baseline.sav"
  TheApp:save(save_path)
  local lfs = require("lfs")
  assert((lfs.attributes(save_path, "size") or 0) > 0, "No save produced")
  TheApp:load(save_path)
  assert(TheApp.world and TheApp.map, "Reload did not create a world")
  assert(TheApp.world.game_date:tostring() == saved_date, "Reload changed the date")
  local loaded_text = shown(TheApp.world.smoke_numbers or {})
  assert(loaded_text == numbers_text, "Numbers changed in the save: " .. numbers_text .. " -> " .. loaded_text)
  print("SMOKE: numbers kept in the save: " .. loaded_text)
  for _ = 1, 120 do
    TheApp:onTick()
  end
  assert(TheApp.world.game_date:tostring() ~= saved_date, "Reloaded game did not advance")
  print("SMOKE: save/reload and 120 additional application callbacks completed")

  -- A diagnostic, not a pass/fail condition: upstream rendering consumes the
  -- same MT19937 stream as gameplay, even with no active screen shake.
  local rng_before = math.randomdump()
  TheApp:drawFrame()
  local render_consumed_rng = math.randomdump() ~= rng_before
  print("DIAGNOSTIC: rendering consumed shared RNG=" .. tostring(render_consumed_rng))
  print("SMOKE: PASS")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  io.stderr:flush()
  os.exit(1)
end
io.stdout:flush()
-- Deliberately avoid entering the interactive C++ main loop after the test.
os.exit(0)
