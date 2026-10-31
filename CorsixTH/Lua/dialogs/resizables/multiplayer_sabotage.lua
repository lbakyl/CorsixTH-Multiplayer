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

--! Multiplayer competitive: buy a dirty trick against a rival's hospital
--! (MULTIPLAYER > DIRTY TRICKS). The first click on a level shows what it
--! does, a second click on it buys it: a lockstep command (`sabotage`, see
--! mp_sabotage.lua); the price is paid when it is done.
class "UIMultiplayerSabotage" (UIResizable)

---@type UIMultiplayerSabotage
local UIMultiplayerSabotage = _G["UIMultiplayerSabotage"]

local col = {
  bg      = Colours.PanelDefault,
  button  = Colours.PanelDefault,
  title   = Colours.Title,
  caption = Colours.Caption,
}

local WIDTH = 420
local ROW = 70
local INFO_H = 66 -- the box saying what the chosen level does

--!param target (Hospital) optional: the rival to play tricks on
function UIMultiplayerSabotage:UIMultiplayerSabotage(ui, target)
  local sabotage = MultiplayerSession.sabotage
  local height = 50 + #sabotage.KINDS * ROW + INFO_H + 95
  self:UIResizable(ui, WIDTH, height, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.2)
  self.default_button_sound = "selectx.wav"
  local S = _S.multiplayer_window
  self.world = ui.app.world
  self.hospital = ui.hospital
  self.target = target or self:_nextTarget(nil)
  self.white_font = ui.app.gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil, { apply_ui_scale = true })
  self.info = S.sabotage_pick

  self.title_panel = self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title)
  self.title_panel.lowered = true
  if not self.target then
    self.title_panel:setLabel(S.sabotage_alone)
    self:addBevelPanel(WIDTH - 130, height - 45, 110, 30, col.button):setLabel(S.sabotage_close)
        :makeButton(0, 0, 110, 30, nil, self.close)
    return
  end
  self.title_panel:setLabel(S.sabotage_caption:format(self.target.name))

  local y = 40
  for _, kind in ipairs(sabotage.KINDS) do
    self:addBevelPanel(20, y, WIDTH - 40, 22, col.caption):setLabel(S["sabotage_" .. kind]).lowered = true
    local prices = sabotage.PRICES[kind]
    local w = math.floor((WIDTH - 40 - 10 * (#prices - 1)) / #prices)
    for level, price in ipairs(prices) do
      self:addBevelPanel(20 + (level - 1) * (w + 10), y + 27, w, 30, col.button)
          :setLabel(S.sabotage_level:format(level, price))
          :makeButton(0, 0, w, 30, nil, function() self:choose(kind, level) end)
          :setTooltip(S.sabotage_levels[kind][level])
    end
    y = y + ROW
  end
  self.info_y = y + 5
  self:addBevelPanel(20, self.info_y, WIDTH - 40, INFO_H, col.caption).lowered = true
  y = y + INFO_H + 10

  self:addBevelPanel(20, y + 5, 180, 30, col.button):setLabel(S.sabotage_next)
      :makeButton(0, 0, 180, 30, nil, self.nextRival)
  self.status_panel = self:addBevelPanel(20, y + 45, WIDTH - 160, 25, col.bg)
  self.status_panel:setLabel("")
  self.status_panel.lowered = true
  self:addBevelPanel(WIDTH - 130, y + 42, 110, 30, col.button):setLabel(S.sabotage_close)
      :makeButton(0, 0, 110, 30, nil, self.close)
end

--! The next rival after `current` (wrapping) that is still in the race.
function UIMultiplayerSabotage:_nextTarget(current)
  local hospitals = self.world.hospitals
  local n = self.world.mp_coop and self.world.mp_coop.players or 1
  local start = current and self.world:getHospitalIndex(current) or 0
  for step = 1, n do
    local h = hospitals[(start + step - 1) % n + 1]
    if h and h ~= self.hospital and not h.mp_place then return h end
  end
end

function UIMultiplayerSabotage:nextRival()
  local target = self:_nextTarget(self.target)
  if target and target ~= self.target then
    local ui = self.ui
    self:close()
    ui:addWindow(UIMultiplayerSabotage(ui, target))
  end
end

function UIMultiplayerSabotage:draw(canvas, x_, y_)
  UIResizable.draw(self, canvas, x_, y_)
  MultiplayerSession.drawTitleTabs(canvas, self, x_, y_, self.target)
  if not self.info_y then return end
  local s = TheApp.gfx:getUIScale()
  local x, y = self.x * s + x_, self.y * s + y_
  self.white_font:drawWrapped(canvas, self.info, x + 28 * s, y + (self.info_y + 6) * s, (WIDTH - 56) * s)
end

--! A level button: the first click says what it does and what it costs,
--! a second click on the same one buys it.
function UIMultiplayerSabotage:choose(kind, level)
  local S = _S.multiplayer_window
  if self.chosen_kind == kind and self.chosen_level == level then
    self.chosen_kind, self.chosen_level = nil, nil
    self.info = S.sabotage_pick
    return self:buy(kind, level)
  end
  self.chosen_kind, self.chosen_level = kind, level
  self.info = S["sabotage_" .. kind] .. " L" .. level .. ": " .. S.sabotage_levels[kind][level]
  self:setStatus(S.sabotage_again:format(level, MultiplayerSession.sabotage.PRICES[kind][level]))
end

function UIMultiplayerSabotage:setStatus(text)
  if self.status_panel then self.status_panel:setLabel(text) end
end

--! Order a trick. The game checks again when the command runs (the same on
--! every computer); this only answers at once when it clearly cannot be done.
function UIMultiplayerSabotage:buy(kind, level)
  local session = TheApp.mp_session
  if not session or not self.target then return end
  local S = _S.multiplayer_window
  local why = MultiplayerSession.sabotage.refusal(self.world, self.hospital, self.target, kind, level)
  if why then
    self.ui:playSound("wrong2.wav")
    self:setStatus(why)
    return
  end
  session:issue({kind = "sabotage", trick = kind, level = level,
      to = self.world:getHospitalIndex(self.target)})
  self:setStatus(S.sabotage_sent)
end
