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

-- Do multiplayer texts fit where they are drawn? Run through the CorsixTH
-- executable with --interpreter=<this file> and a config file whose language
-- is the one to check: every text in the list below is measured with the
-- panels' label font (the game's own, with the Unicode font for letters it
-- lacks) and compared with the width of the panel it goes in.
--   CORSIXTH_SOURCE  checkout root (required)
-- Prints "FIT <width>/<room> <key>: <text>" or "OVER ..."; exits 1 if any is over.

local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))

local S = _S.multiplayer_window
local mb = function(n) return S.megabytes:format(n) end
-- {key, the text as drawn, the panel's width} (a few pixels less than the
-- panel: the label is drawn inside its bevel). Widths from the dialogs:
-- multiplayer.lua (WIDTH 420, SIDE_W 170), multiplayer_download.lua (400),
-- multiplayer_save.lua (360), multiplayer_levels.lua (600).
local list = {
  {"get_version", S.get_version:format(mb("3.3")), 374},
  {"switch_version", S.switch_version, 374},
  {"version_other", S.version_other, 374},
  {"version_newer_game", S.version_newer_game, 374},
  {"version_caption", S.version_caption, 354},
  {"version_downloading", S.version_downloading:format(mb("1.7"), mb("3.3")), 354},
  {"version_checking", S.version_checking, 354},
  {"version_starting", S.version_starting, 354},
  {"version_failed", S.version_failed:format("timeout"), 354},
  {"version_bad", S.version_bad, 354},
  {"version_cancel", S.version_cancel, 134},
  {"version_close", S.version_close, 134},
  {"save_caption", S.save_caption, 314},
  {"save_button", S.save_button, 149},
  {"room_map", S.room_map, 64},
  {"room_map_caption", S.room_map_caption, 554},
  {"assistants_caption", S.assistants_caption, 154},
  {"add_assistant_short", S.add_assistant_short, 154},
  {"assistant_starting", S.assistant_starting, 154},
  -- A place's menu is at most as wide as the place's line.
  {"add_assistant", S.add_assistant, 374},
  {"add_assistant_for", S.add_assistant_for:format("MATROFTT"), 374},
  {"remove_assistant", S.remove_assistant, 374},
  -- The connect view's server buttons (two to a row; EU2 alone on the
  -- second row has the whole row) and Discord button.
  {"server_eu1", S.server_eu1, 113},
  {"server_us1", S.server_us1, 113},
  {"server_eu2", S.server_eu2, 241},
  {"discord", S.discord, 126},
  -- The main menu's last row: Discord (56 wide) and Exit (96).
  {"main_menu.discord", _S.main_menu.discord, 52},
  {"main_menu.exit", _S.main_menu.exit, 92},
}

local font = TheApp.gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil, {ttf_shadow = true, apply_ui_scale = true})
local over = 0
for _, item in ipairs(list) do
  -- (The font takes the localised string itself; tostring() would add the
  -- proxy's "<LocalisedString> Current value:" for the print only.)
  local key, room = item[1], item[3]
  local w = font:sizeOf(item[2])
  local text = tostring(item[2]):gsub("^<LocalisedString> Current value:", "")
  if w > room then over = over + 1 end
  io.stdout:write(string.format("%s %3d/%3d %s: %s\n", w > room and "OVER" or "FIT ", w, room, key, text))
end
io.stdout:write(string.format("TEXT FIT: %d of %d over\n", over, #list))
io.stdout:flush()
os.exit(over == 0 and 0 or 1)
