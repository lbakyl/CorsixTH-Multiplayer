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

--! Multiplayer co-op: hand one of your plots to an ally (opened from the arrow
--! on the plot in the town map). The ally is picked from a list, the price
--! set from $0 (a gift) to $50,000; the offer is the offer_plot command, and
--! the other player accepts or declines it in a fax.
class "UIMultiplayerGivePlot" (UIResizable)

---@class UIMultiplayerGivePlot: UIResizable
---@operator call: UIMultiplayerGivePlot
local UIMultiplayerGivePlot = _G["UIMultiplayerGivePlot"] ---@type UIMultiplayerGivePlot

local col = {
  bg             = Colours.PanelDefault,
  button         = Colours.PanelDefault,
  setting        = Colours.Setting,
  setting_active = Colours.SettingActive,
  title          = Colours.Title,
  caption        = Colours.Caption,
}

local WIDTH = 380

--! The hospitals `hospital` may hand a plot to: its allies.
local function allies_of(world, hospital)
  local list = {}
  local n = world.mp_coop and world.mp_coop.players or 0
  for i = 1, n do
    local other = world.hospitals[i]
    if other and other ~= hospital and world:mpMayTrade(hospital, other) and not world:mpRivals(hospital, other) then
      list[#list + 1] = other
    end
  end
  return list
end

--!param plot (int) the plot to hand over
function UIMultiplayerGivePlot:UIMultiplayerGivePlot(ui, plot)
  local S = _S.multiplayer_window
  local world = ui.app.world
  self.world = world
  self.hospital = ui.hospital
  self.plot = plot
  self.allies = allies_of(world, self.hospital)
  self.target = self.allies[1]
  self.price = 0
  local rows = math.max(1, #self.allies)
  local height = 40 + 26 + rows * 25 + 10 + 34 + 34 + 30 + 45
  self:UIResizable(ui, WIDTH, height, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.25)
  self.default_button_sound = "selectx.wav"

  self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title):setLabel(S.plot_give_caption:format(plot)).lowered = true
  local y = 40
  self:addBevelPanel(20, y, WIDTH - 40, 20, col.caption):setLabel(S.plot_give_to).lowered = true
  y = y + 26
  self.rows = {}
  if #self.allies == 0 then
    self:addBevelPanel(20, y, WIDTH - 40, 23, col.caption):setLabel(S.plot_give_none).lowered = true
  end
  for i, ally in ipairs(self.allies) do
    self.rows[i] = self:addBevelPanel(20, y + (i - 1) * 25, WIDTH - 40, 23, col.setting, nil, nil, nil,
        col.setting_active)
        :setLabel(ally.name)
        :makeToggleButton(0, 0, WIDTH - 40, 23, nil, function(window, state) window:selectAlly(i, state) end)
    self.rows[i]:setToggleState(ally == self.target)
  end
  y = y + rows * 25 + 10
  self.price_panel = self:addBevelPanel(20, y, 100, 28, col.caption)
  self.price_panel.lowered = true
  local steps = {-5000, -500, 500, 5000}
  for i, amount in ipairs(steps) do
    self:addBevelPanel(130 + (i - 1) * 54, y, 50, 28, col.button)
        :setLabel((amount > 0 and "+$" or "-$") .. math.abs(amount))
        :makeRepeatButton(0, 0, 50, 28, nil, function(window) window:setPrice(window.price + amount) end)
  end
  y = y + 34
  self.status_panel = self:addBevelPanel(20, y, WIDTH - 40, 24, col.caption)
  self.status_panel.lowered = true
  self.status_panel:setLabel("")
  y = height - 45
  self:addBevelPanel(20, y, 160, 30, col.button):setLabel(S.plot_give_button)
      :makeButton(0, 0, 160, 30, nil, self.give)
  self:addBevelPanel(WIDTH - 140, y, 120, 30, col.button):setLabel(S.plot_give_cancel)
      :makeButton(0, 0, 120, 30, nil, self.close)
  self:setPrice(0)
end

function UIMultiplayerGivePlot:draw(canvas, x_, y_)
  UIResizable.draw(self, canvas, x_, y_)
  MultiplayerSession.drawTitleTabs(canvas, self, x_, y_, self.target)
end

--! Pick an ally (one at a time).
function UIMultiplayerGivePlot:selectAlly(row, state)
  if state then
    self.target = self.allies[row]
  elseif self.target == self.allies[row] then
    self.target = nil
  end
  for i, button in ipairs(self.rows) do button:setToggleState(self.allies[i] == self.target) end
end

--! Set the price asked, $0 (free) to MultiplayerSession.PLOT_MAX_PRICE.
function UIMultiplayerGivePlot:setPrice(price)
  local step = MultiplayerSession.PLOT_PRICE_STEP
  price = math.floor(price / step + 0.5) * step
  self.price = math.max(0, math.min(MultiplayerSession.PLOT_MAX_PRICE, price))
  local S = _S.multiplayer_window
  self.price_panel:setLabel(self.price > 0 and S.plot_give_price:format(self.price) or S.plot_give_free)
end

function UIMultiplayerGivePlot:setStatus(text)
  self.status_panel:setLabel(text)
end

--! Make the offer (a command; the plot changes hands only if the ally
--! accepts). Turned down here at once when it cannot work.
function UIMultiplayerGivePlot:give()
  local session = TheApp.mp_session
  if not session or not self.target then return end
  local why = MultiplayerSession.plotRefusal(self.world, self.hospital, self.plot) or
      MultiplayerSession.plotHandoverRefusal(self.world, self.target, self.plot)
  if why then
    local texts = MultiplayerSession.rejection_texts.offer_plot
    self:setStatus(texts[why] or why)
    return
  end
  session:issue({kind = "offer_plot", to = self.world:getHospitalIndex(self.target), plot = self.plot,
      price = self.price > 0 and self.price or nil})
  if self.ui.adviser then
    self.ui.adviser:say({text = _S.multiplayer_window.plot_give_offered, priority = 10})
  end
  self:close()
end

--! Open the window for `plot`: a message instead when it cannot be handed
--! over now (it is not empty, ...).
function UIMultiplayerGivePlot.open(ui, plot)
  local world = ui.app.world
  local why = MultiplayerSession.plotRefusal(world, ui.hospital, plot)
  if why then
    local texts = MultiplayerSession.rejection_texts.offer_plot
    ui:addWindow(UIInformation(ui, {texts[why] or ("That plot cannot be handed over now (" .. why .. ").")}))
    return
  end
  local window = ui:getWindow(UIMultiplayerGivePlot)
  if window then window:close() end
  ui:addWindow(UIMultiplayerGivePlot(ui, plot))
end
