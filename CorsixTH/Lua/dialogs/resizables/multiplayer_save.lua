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

--! File > Save in a multiplayer game: the save's name (the level's name to
--! start with), then every player's game saves at the same game hour
--! (MultiplayerSession.saveTogether). The file is named after the name, the
--! player who saved and the game date: "TEAM TOWN Jan y3-m12-d21".
class "UIMultiplayerSave" (UIResizable)

local UIMultiplayerSave = _G["UIMultiplayerSave"] ---@type UIMultiplayerSave

local col = {
  bg = Colours.PanelDefault,
  title = Colours.Title,
  textbox = Colours.Textbox,
}

local W, H = 360, 130
local BUTTON_W = (W - 50) / 2

--!param name (string) the name to start with
function UIMultiplayerSave:UIMultiplayerSave(ui, name)
  local S = _S.multiplayer_window
  self:UIResizable(ui, W, H, col.bg)
  self.resizable = false
  self.on_top = true
  self.esc_closes = true
  self:setDefaultPosition(0.5, 0.4)
  self.default_button_sound = "selectx.wav"
  self:addBevelPanel(20, 10, W - 40, 20, col.title):setLabel(S.save_caption).lowered = true
  self.name_box = self:addBevelPanel(20, 40, W - 40, 25, col.textbox, col.bg, col.bg)
    :setAutoClip(true)
    :makeTextbox(--[[persistable:mp_save_name_confirm]] function() self:buttonSave() end,
        --[[persistable:mp_save_name_abort]] function() self:close() end)
    :allowedInput({"alpha", "numbers", "misc"}):characterLimit(30):setText(name or "")
  self.name_box.panel:setTooltip(_S.tooltip.multiplayer_window.save_name)
  self:addBevelPanel(20, 80, BUTTON_W, 30, col.bg):setLabel(S.save_button)
    :makeButton(0, 0, BUTTON_W, 30, nil, self.buttonSave)
  self:addBevelPanel(30 + BUTTON_W, 80, BUTTON_W, 30, col.bg):setLabel(S.version_cancel)
    :makeButton(0, 0, BUTTON_W, 30, nil, self.close)
  self.name_box:setActive(true)
end

function UIMultiplayerSave:buttonSave()
  local text = self.name_box.text
  if type(text) == "table" then text = table.concat(text, " ") end
  self:close()
  MultiplayerSession.saveTogether(text)
end
