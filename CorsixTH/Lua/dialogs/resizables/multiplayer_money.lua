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

--! Multiplayer co-op: ask another player for money (from the bank manager).
--! The amount is set on a bar ($500 to $50,000); the request is the ask_money
--! command, and the other player pays or declines it in a fax.
class "UIMultiplayerAskMoney" (UIResizable)

---@type UIMultiplayerAskMoney
local UIMultiplayerAskMoney = _G["UIMultiplayerAskMoney"]

local WIDTH = 420
local BAR_X, BAR_W, BAR_Y = 20, 260, 40

function UIMultiplayerAskMoney:UIMultiplayerAskMoney(ui, target)
  local S = _S.multiplayer_window
  local height = 40 + 34 + 34 + 30 + 45
  self:UIResizable(ui, WIDTH, height, Colours.PanelDefault)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.3)
  self.default_button_sound = "selectx.wav"
  self.world = ui.app.world
  self.hospital = ui.hospital
  self.target = target or self:_nextTarget(nil)
  self.amount = 5000

  local title = self.target and S.ask_caption:format(self.target.name) or S.trade_alone
  self:addBevelPanel(20, 10, WIDTH - 40, 20, Colours.Title):setLabel(title).lowered = true
  if not self.target then
    self:addBevelPanel(WIDTH - 140, height - 45, 120, 30, Colours.PanelDefault):setLabel(S.trade_close)
        :makeButton(0, 0, 120, 30, nil, self.close)
    return
  end
  self.bar = self:addBevelPanel(BAR_X, BAR_Y, BAR_W, 28, Colours.Caption)
  self.bar.lowered = true
  self.amount_panel = self:addBevelPanel(BAR_X + BAR_W + 10, BAR_Y, WIDTH - 40 - BAR_W - 10, 28, Colours.Caption)
  self.amount_panel.lowered = true
  local y = BAR_Y + 34
  self:addBevelPanel(BAR_X, y, 125, 26, Colours.PanelDefault):setLabel("-$500")
      :makeRepeatButton(0, 0, 125, 26, nil, function(window) window:setAmount(window.amount - 500) end)
  self:addBevelPanel(BAR_X + BAR_W - 125, y, 125, 26, Colours.PanelDefault):setLabel("+$500")
      :makeRepeatButton(0, 0, 125, 26, nil, function(window) window:setAmount(window.amount + 500) end)
  self.status_panel = self:addBevelPanel(20, y + 34, WIDTH - 40, 22, Colours.PanelDefault)
  self.status_panel.lowered = true
  y = height - 45
  self:addBevelPanel(20, y, 120, 30, Colours.PanelDefault):setLabel(S.ask_button)
      :makeButton(0, 0, 120, 30, nil, self.ask)
  if (self.world.mp_coop and self.world.mp_coop.players or 1) > 2 then
    self:addBevelPanel(150, y, 120, 30, Colours.PanelDefault):setLabel(S.trade_next_player)
        :makeButton(0, 0, 120, 30, nil, self.nextPlayer)
  end
  self:addBevelPanel(WIDTH - 140, y, 120, 30, Colours.PanelDefault):setLabel(S.trade_close)
      :makeButton(0, 0, 120, 30, nil, self.close)
  self:setAmount(self.amount)
end

--! The next player hospital after `current` (wrapping), other than ours.
function UIMultiplayerAskMoney:_nextTarget(current)
  local hospitals = self.world.hospitals
  local n = self.world.mp_coop and self.world.mp_coop.players or 1
  local start = current and self.world:getHospitalIndex(current) or 0
  for step = 1, n do
    local h = hospitals[(start + step - 1) % n + 1]
    if h and h ~= self.hospital then return h end
  end
end

function UIMultiplayerAskMoney:setAmount(amount)
  local step = MultiplayerSession.ASK_STEP
  amount = math.floor((amount + step / 2) / step) * step
  self.amount = math.max(MultiplayerSession.ASK_MIN, math.min(MultiplayerSession.ASK_MAX, amount))
  self.amount_panel:setLabel(_S.multiplayer_window.ask_amount:format(self.amount))
end

function UIMultiplayerAskMoney:_onBar(x, y)
  return self.bar and x >= BAR_X and x < BAR_X + BAR_W and y >= BAR_Y and y < BAR_Y + 28
end

function UIMultiplayerAskMoney:_amountAt(x)
  self:setAmount((x - BAR_X) / BAR_W * MultiplayerSession.ASK_MAX)
end

function UIMultiplayerAskMoney:onMouseDown(button, x, y)
  local s = TheApp.gfx:getUIScale()
  if button == "left" and self:_onBar(x / s, y / s) then
    self.dragging_amount = true
    self:_amountAt(x / s)
    return true
  end
  return UIResizable.onMouseDown(self, button, x, y)
end

function UIMultiplayerAskMoney:onMouseMove(x, y, dx, dy)
  if self.dragging_amount then
    self:_amountAt(x / TheApp.gfx:getUIScale())
    return true
  end
  return UIResizable.onMouseMove(self, x, y, dx, dy)
end

function UIMultiplayerAskMoney:onMouseUp(button, x, y)
  if self.dragging_amount then
    self.dragging_amount = false
    return true
  end
  return UIResizable.onMouseUp(self, button, x, y)
end

function UIMultiplayerAskMoney:draw(canvas, x_, y_)
  UIResizable.draw(self, canvas, x_, y_)
  MultiplayerSession.drawTitleTabs(canvas, self, x_, y_, self.target)
  if not self.bar then return end
  local s = TheApp.gfx:getUIScale()
  local x, y = self.x * s + x_, self.y * s + y_
  local filled = math.floor((BAR_W - 8) * self.amount / MultiplayerSession.ASK_MAX)
  canvas:drawRect(canvas:mapRGB(246, 200, 64), x + (BAR_X + 4) * s, y + (BAR_Y + 8) * s, filled * s, 12 * s)
  canvas:drawRect(canvas:mapRGB(246, 238, 255), x + (BAR_X + 2 + filled) * s, y + (BAR_Y + 4) * s,
      6 * s, 20 * s)
end

--! Send the request: a command, so every peer creates it at the same step.
function UIMultiplayerAskMoney:ask()
  local session = TheApp.mp_session
  if not session or not self.target then return end
  session:issue({kind = "ask_money", to = self.world:getHospitalIndex(self.target), amount = self.amount})
  self.status_panel:setLabel(_S.multiplayer_window.ask_asked)
end

function UIMultiplayerAskMoney:nextPlayer()
  local ui = self.ui
  local target = self:_nextTarget(self.target)
  self:close()
  ui:addWindow(UIMultiplayerAskMoney(ui, target))
end

--! Open the window (bank manager): co-op only.
function UIMultiplayerAskMoney.open(ui)
  if not (TheApp.mp_session and ui.app.world and ui.app.world.mp_coop) then return end
  local window = ui:getWindow(UIMultiplayerAskMoney)
  if window then window:close() end
  ui:addWindow(UIMultiplayerAskMoney(ui))
end
