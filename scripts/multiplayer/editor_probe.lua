--[[ Usage: corsix-th --interpreter=scripts/multiplayer/editor_probe.lua --config-file=...
(CORSIXTH_SOURCE: the checkout; MP_OUT: a folder for the map it saves)

The map editor with 8 players: opens it on a blank map, picks 8 players in
its menu's way, sets the camera and heliport of player 7 with its Camera,
Heliport and Player buttons, saves the map and loads it again. Prints
"EDITOR OK ..." and exits 0 when the tiles came back, else "EDITOR FAILED". ]]

local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local out = assert(os.getenv("MP_OUT"), "Missing MP_OUT")
assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
assert(TheApp.good_install_folder, "Game data was not accepted")

local function fail(why)
  print("EDITOR FAILED: " .. tostring(why))
  os.exit(1)
end

local ok, err = pcall(function()
  TheApp:mapEdit()
  local editor = assert(TheApp.ui.map_editor, "no map editor")
  local map = TheApp.map
  editor:setPlayerCount(8)
  assert(map:getPlayerCount() == 8, "player count " .. map:getPlayerCount())
  -- Player 7: the Player button six times from player 1.
  for _ = 1, 6 do editor:nextPlayer() end
  assert(editor.editor_player == 7, "player " .. tostring(editor.editor_player))
  editor:pageClicked("camera")
  assert(editor.cursor.state == "camera" and editor.cursor.camera == 7, "camera cursor")
  map:setCameraTile(40, 50, editor.cursor.camera)
  editor:pageClicked("heliport")
  assert(editor.cursor.state == "heliport" and editor.cursor.heliport == 7, "heliport cursor")
  map:setHeliportTile(44, 52, editor.cursor.heliport)
  -- (and player 2's, to see the first four still go where they did)
  map:setCameraTile(10, 12, 2)
  local labels = {}
  for _, pb in ipairs(editor.page_selectbuttons) do
    if pb.name == "camera" or pb.name == "heliport" then
      labels[#labels + 1] = tostring(pb.button.panel_for_sprite.label):gsub("^<LocalisedString> Current value:%s*", "")
    end
  end
  -- Wrap around: player 8, then 1.
  editor:nextPlayer()
  editor:nextPlayer()
  assert(editor.editor_player == 1, "wrapped to " .. tostring(editor.editor_player))
  local file = out .. "/eight.map"
  map:save(file)
  local f = assert(io.open(file, "rb"))
  local data = f:read("*a")
  f:close()
  assert(#data == 163948, "saved " .. #data .. " bytes")
  local th = require("TH").map()
  assert(th:load(data), "the saved map does not load")
  local cx, cy = th:getCameraTile(7)
  local hx, hy = th:getHeliportTile(7)
  local c2x, c2y = th:getCameraTile(2)
  assert(th:getPlayerCount() == 8, "loaded player count " .. th:getPlayerCount())
  assert(cx == 40 and cy == 50, ("camera 7 at %d,%d"):format(cx, cy))
  assert(hx == 44 and hy == 52, ("heliport 7 at %d,%d"):format(hx, hy))
  assert(c2x == 10 and c2y == 12, ("camera 2 at %d,%d"):format(c2x, c2y))
  print(("EDITOR OK: 8 players; camera 7 at %d,%d, heliport 7 at %d,%d, camera 2 at %d,%d; buttons %s"):format(
      cx, cy, hx, hy, c2x, c2y, table.concat(labels, ", ")))
end)
if not ok then fail(err) end
os.exit(0)
