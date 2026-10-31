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

--! Multiplayer co-op: offer research to another player's hospital, free or
--! for a price. Lists what this hospital knows and the other one does not
--! (MultiplayerSession.shareableResearch); the offer is the offer_research
--! command, and the other player accepts or declines it in a fax.
class "UIMultiplayerResearch" (UIResizable)

---@class UIMultiplayerResearch: UIResizable
---@operator call: UIMultiplayerResearch
local UIMultiplayerResearch = _G["UIMultiplayerResearch"] ---@type UIMultiplayerResearch

local col = {
  bg             = Colours.PanelDefault,
  button         = Colours.PanelDefault,
  setting        = Colours.Setting,
  setting_active = Colours.SettingActive,
  title          = Colours.Title,
  caption        = Colours.Caption,
}

local WIDTH = 420
local ROWS = 8
local ROW_H = 23
local BAR_X, BAR_W = 20, 260 -- the price bar, in window coordinates

--!param target (Hospital) optional; the hospital to offer to (default: the next one)
function UIMultiplayerResearch:UIMultiplayerResearch(ui, target)
  local S = _S.multiplayer_window
  local height = 40 + 30 + ROWS * (ROW_H + 2) + 35 + 40 + 40 + 40
  self:UIResizable(ui, WIDTH, height, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.15)
  self.default_button_sound = "selectx.wav"
  self.world = ui.app.world
  self.hospital = ui.hospital
  self.target = target or self:_nextTarget(nil)
  self.selected = {}
  self.page = 1
  self.price = 0

  local title = self.target and S.research_caption:format(self.target.name) or S.trade_alone
  self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title):setLabel(title).lowered = true
  if not self.target then
    self:addBevelPanel(WIDTH - 140, height - 45, 120, 30, col.button):setLabel(S.trade_close)
        :makeButton(0, 0, 120, 30, nil, self.close)
    return
  end
  self.items = MultiplayerSession.shareableResearch(self.hospital, self.target)

  -- The list (one page of ROWS) and its paging.
  self.rows = {}
  for row = 1, ROWS do
    local y = 40 + (row - 1) * (ROW_H + 2)
    local panel = self:addBevelPanel(20, y, WIDTH - 40, ROW_H, col.setting, nil, nil, nil, col.setting_active)
    self.rows[row] = panel:makeToggleButton(0, 0, WIDTH - 40, ROW_H, nil,
        function(window, state) window:toggleRow(row, state) end)
  end
  local y = 40 + ROWS * (ROW_H + 2) + 5
  self.all_button = self:addBevelPanel(20, y, 100, 28, col.setting, nil, nil, nil, col.setting_active)
      :setLabel(S.research_all):makeToggleButton(0, 0, 100, 28, nil, self.toggleAll)
  self.page_panel = self:addBevelPanel(130, y, 140, 28, col.caption)
  self.page_panel.lowered = true
  -- (The game's font has no arrows or slashes: words instead.)
  self:addBevelPanel(280, y, 55, 28, col.button):setLabel(S.research_previous)
      :makeButton(0, 0, 55, 28, nil, function(window) window:turnPage(-1) end)
  self:addBevelPanel(345, y, 55, 28, col.button):setLabel(S.research_next)
      :makeButton(0, 0, 55, 28, nil, function(window) window:turnPage(1) end)

  -- The price: a bar to drag or click, and one step down / up.
  y = y + 38
  self.price_y = y
  self.bar = self:addBevelPanel(BAR_X, y, BAR_W, 28, col.caption)
  self.bar.lowered = true
  self.price_panel = self:addBevelPanel(BAR_X + BAR_W + 10, y, WIDTH - 40 - BAR_W - 10, 28, col.caption)
  self.price_panel.lowered = true
  y = y + 34
  self:addBevelPanel(BAR_X, y, 125, 26, col.button):setLabel("-$500")
      :makeRepeatButton(0, 0, 125, 26, nil, function(window) window:setPrice(window.price - 500) end)
  self:addBevelPanel(BAR_X + BAR_W - 125, y, 125, 26, col.button):setLabel("+$500")
      :makeRepeatButton(0, 0, 125, 26, nil, function(window) window:setPrice(window.price + 500) end)

  -- Offer, next player (with three or four players), close; status line.
  y = height - 75
  self.status_panel = self:addBevelPanel(20, y, WIDTH - 40, 22, col.bg)
  self.status_panel.lowered = true
  y = height - 45
  self:addBevelPanel(20, y, 120, 30, col.button):setLabel(S.research_offer)
      :makeButton(0, 0, 120, 30, nil, self.offer)
  if (self.world.mp_coop and self.world.mp_coop.players or 1) > 2 then
    self:addBevelPanel(150, y, 120, 30, col.button):setLabel(S.trade_next_player)
        :makeButton(0, 0, 120, 30, nil, self.nextPlayer)
  end
  self:addBevelPanel(WIDTH - 140, y, 120, 30, col.button):setLabel(S.trade_close)
      :makeButton(0, 0, 120, 30, nil, self.close)

  self:setPrice(0)
  self:_showPage()
  if #self.items == 0 then self:setStatus(S.research_none) end
end

--! The next player hospital after `current` (wrapping), other than ours.
function UIMultiplayerResearch:_nextTarget(current)
  local hospitals = self.world.hospitals
  local n = self.world.mp_coop and self.world.mp_coop.players or 1
  local start = current and self.world:getHospitalIndex(current) or 0
  for step = 1, n do
    local h = hospitals[(start + step - 1) % n + 1]
    if h and h ~= self.hospital then return h end
  end
end

function UIMultiplayerResearch:setStatus(text)
  if self.status_panel then self.status_panel:setLabel(text or "") end
end

function UIMultiplayerResearch:_pages()
  return math.max(1, math.ceil(#self.items / ROWS))
end

--! Show the items of the current page, selected ones toggled on.
function UIMultiplayerResearch:_showPage()
  local first = (self.page - 1) * ROWS
  for row, button in ipairs(self.rows) do
    local item = self.items[first + row]
    button:setLabel(item and item.name or "")
    button:enable(item ~= nil)
    if (item and self.selected[item.key] or false) ~= (button.toggled or false) then button:toggle() end
  end
  self.page_panel:setLabel(_S.multiplayer_window.research_page:format(self.page, self:_pages()))
end

function UIMultiplayerResearch:turnPage(delta)
  self.page = math.min(self:_pages(), math.max(1, self.page + delta))
  self:_showPage()
end

function UIMultiplayerResearch:toggleRow(row, state)
  local item = self.items[(self.page - 1) * ROWS + row]
  if item then self.selected[item.key] = state or nil end
end

function UIMultiplayerResearch:toggleAll(state)
  for _, item in ipairs(self.items) do self.selected[item.key] = state or nil end
  self:_showPage()
end

--! Set the price, in steps of $500 from $0 to $20,000.
function UIMultiplayerResearch:setPrice(price)
  local S = _S.multiplayer_window
  local step = MultiplayerSession.RESEARCH_PRICE_STEP
  price = math.floor((price + step / 2) / step) * step
  self.price = math.max(0, math.min(MultiplayerSession.RESEARCH_MAX_PRICE, price))
  self.price_panel:setLabel(self.price > 0 and S.research_price:format(self.price) or S.research_free)
end

--! Is (x, y), in window coordinates, on the price bar?
function UIMultiplayerResearch:_onBar(x, y)
  return self.price_y and x >= BAR_X and x < BAR_X + BAR_W and y >= self.price_y and y < self.price_y + 28
end

function UIMultiplayerResearch:_priceAt(x)
  self:setPrice((x - BAR_X) / BAR_W * MultiplayerSession.RESEARCH_MAX_PRICE)
end

function UIMultiplayerResearch:onMouseDown(button, x, y)
  local s = TheApp.gfx:getUIScale()
  if button == "left" and self:_onBar(x / s, y / s) then
    self.dragging_price = true
    self:_priceAt(x / s)
    return true
  end
  return UIResizable.onMouseDown(self, button, x, y)
end

function UIMultiplayerResearch:onMouseMove(x, y, dx, dy)
  if self.dragging_price then
    local s = TheApp.gfx:getUIScale()
    self:_priceAt(x / s)
    return true
  end
  return UIResizable.onMouseMove(self, x, y, dx, dy)
end

function UIMultiplayerResearch:onMouseUp(button, x, y)
  if self.dragging_price then
    self.dragging_price = false
    return true
  end
  return UIResizable.onMouseUp(self, button, x, y)
end

function UIMultiplayerResearch:draw(canvas, x_, y_)
  UIResizable.draw(self, canvas, x_, y_)
  MultiplayerSession.drawTitleTabs(canvas, self, x_, y_, self.target)
  if not self.price_y then return end
  -- The filled part of the price bar and its handle.
  local s = TheApp.gfx:getUIScale()
  local x, y = self.x * s + x_, self.y * s + y_
  local filled = math.floor((BAR_W - 8) * self.price / MultiplayerSession.RESEARCH_MAX_PRICE)
  canvas:drawRect(canvas:mapRGB(150, 76, 206), x + (BAR_X + 4) * s, y + (self.price_y + 8) * s,
      filled * s, 12 * s)
  canvas:drawRect(canvas:mapRGB(246, 238, 255), x + (BAR_X + 2 + filled) * s, y + (self.price_y + 4) * s,
      6 * s, 20 * s)
end

--! Send the offer: a command, so every peer creates it at the same step.
function UIMultiplayerResearch:offer()
  local S = _S.multiplayer_window
  local session = TheApp.mp_session
  if not session or not self.target then return end
  local keys = {}
  for _, item in ipairs(self.items) do
    if self.selected[item.key] then keys[#keys + 1] = item.key end
  end
  if #keys == 0 then
    self:setStatus(#self.items == 0 and S.research_none or S.research_none_selected)
    return
  end
  session:issue({kind = "offer_research", to = self.world:getHospitalIndex(self.target),
      items = table.concat(keys, ";"), price = self.price})
  self:setStatus(S.research_offered)
  self.selected = {}
  if self.all_button.toggled then self.all_button:toggle() end
  self:_showPage()
end

function UIMultiplayerResearch:nextPlayer()
  local ui = self.ui
  local target = self:_nextTarget(self.target)
  self:close()
  ui:addWindow(UIMultiplayerResearch(ui, target))
end

--! Open the window (Multiplayer menu or the research blackboard): co-op only.
function UIMultiplayerResearch.open(ui)
  if not (TheApp.mp_session and ui.app.world and ui.app.world.mp_coop) then return end
  local window = ui:getWindow(UIMultiplayerResearch)
  if window then window:close() end
  ui:addWindow(UIMultiplayerResearch(ui))
end
