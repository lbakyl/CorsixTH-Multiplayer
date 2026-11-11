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

--! Multiplayer co-op: send money or offer a member of staff (free or for a
--! price) to another player's hospital, or vouch for an ally (give
--! reputation). Every action is a lockstep command (give_money, offer_staff,
--! give_reputation).
class "UIMultiplayerTrade" (UIResizable)

---@class UIMultiplayerTrade: UIResizable
---@operator call: UIMultiplayerTrade
local UIMultiplayerTrade = _G["UIMultiplayerTrade"] ---@type UIMultiplayerTrade

local col = {
  bg             = Colours.PanelDefault,
  button         = Colours.PanelDefault,
  setting        = Colours.Setting,
  setting_active = Colours.SettingActive,
  title          = Colours.Title,
  caption        = Colours.Caption,
}

local WIDTH = 380
-- Rows of the staff list: as many as the screen has room for, 4 to 8 (a
-- screen of 1080 lines at double size has 540: Jan's did not show it all).
local MAX_STAFF_ROWS = 8
local MIN_STAFF_ROWS = 4
local AMOUNTS = {1000, 5000, 20000}
-- The room for the reputation rows: a line of text, the points, the button.
local REP_HEIGHT = 94
-- The window but for the staff rows (and the reputation rows).
local FIXED_HEIGHT = 85 + 36 + 34 + 30 + 10 + 30 + 10

--! How many staff rows fit on the screen, with the reputation rows or not.
local function staff_rows(vouch)
  local video = TheApp and TheApp.video
  local gfx = TheApp and TheApp.gfx
  if not (video and gfx and video.getRenderSize) then return MAX_STAFF_ROWS end
  local _, screen_h = video:getRenderSize()
  local free = math.floor(screen_h / gfx:getUIScale()) - 20 - FIXED_HEIGHT - (vouch and REP_HEIGHT or 0)
  return math.max(MIN_STAFF_ROWS, math.min(MAX_STAFF_ROWS, math.floor(free / 25)))
end

--!param target (Hospital) optional: the player to trade with
--!param staff (Staff) optional: this member of staff selected
function UIMultiplayerTrade:UIMultiplayerTrade(ui, target, staff)
  local world = ui.app.world
  self.world = world
  self.hospital = ui.hospital
  self.target = target or self:_nextTarget(nil)
  -- (Reputation only between allies: not between rivals in a race.)
  local vouch = self.target and not world:mpRivals(self.hospital, self.target)
  local rows = staff_rows(vouch)
  self.staff_rows = rows
  local height = FIXED_HEIGHT + rows * 25 + (vouch and REP_HEIGHT or 0)
  self:UIResizable(ui, WIDTH, height, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.2)
  self.default_button_sound = "selectx.wav"
  local S = _S.multiplayer_window
  self.selected = nil
  self.price = 0
  self.reputation = 10

  local title = self.target and S.trade_caption:format(self.target.name) or S.trade_alone
  self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title):setLabel(title).lowered = true
  if not self.target then
    self:addBevelPanel(WIDTH - 140, height - 45, 120, 30, col.button):setLabel(S.trade_close)
        :makeButton(0, 0, 120, 30, nil, self.close)
    return
  end

  -- Money (only to an ally: a rival in a race gets none, Jan 2026-11-12)
  if vouch then
    for i, amount in ipairs(AMOUNTS) do
      local w = math.floor((WIDTH - 40 - 10 * (#AMOUNTS - 1)) / #AMOUNTS)
      self:addBevelPanel(20 + (i - 1) * (w + 10), 40, w, 30, col.button)
          :setLabel(S.trade_send_money:format(amount))
          :makeButton(0, 0, w, 30, nil, function() self:sendMoney(amount) end)
    end
  else
    self:addBevelPanel(20, 40, WIDTH - 40, 30, col.caption):setLabel(S.trade_money_allies_only).lowered = true
  end

  -- Staff of this player's hospital, a page of `rows` at a time
  self.staff_list = {}
  self.page = 1
  for i, member in ipairs(self.hospital.staff) do
    if not member.fired then
      -- Names are localised strings; concatenating keeps them displayable.
      local profession = _S.staff_class[member.humanoid_class:lower()] or member.humanoid_class
      local entry = {staff = member, index = i,
          label = member.profile:getFullName() .. "  (" .. profession .. ", $" .. member.profile.wage .. ")"}
      self.staff_list[#self.staff_list + 1] = entry
      if member == staff then
        self.selected = entry
        self.page = math.ceil(#self.staff_list / rows)
      end
    end
  end
  if #self.staff_list == 0 then
    self:addBevelPanel(20, 85, WIDTH - 40, 25, col.caption):setLabel(S.trade_no_staff).lowered = true
  end
  self.rows = {}
  for row = 1, rows do
    self.rows[row] = self:addBevelPanel(20, 80 + (row - 1) * 25, WIDTH - 40, 23,
        col.setting, nil, nil, nil, col.setting_active)
        :makeToggleButton(0, 0, WIDTH - 40, 23, nil, function(window, state) window:selectStaff(row, state) end)
  end
  local y = 85 + rows * 25
  -- (The game's font has no arrows or slashes: words instead.)
  self.page_panel = self:addBevelPanel(20, y, WIDTH - 180, 28, col.caption)
  self.page_panel.lowered = true
  self:addBevelPanel(WIDTH - 150, y, 60, 28, col.button):setLabel(S.research_previous)
      :makeButton(0, 0, 60, 28, nil, function(window) window:turnPage(-1) end)
  self:addBevelPanel(WIDTH - 80, y, 60, 28, col.button):setLabel(S.research_next)
      :makeButton(0, 0, 60, 28, nil, function(window) window:turnPage(1) end)
  self:_showPage()

  -- The price the other player pays for the member of staff (free by
  -- default; $1,000 to start with for a rival).
  y = y + 36
  self.price_panel = self:addBevelPanel(20, y, WIDTH - 180, 28, col.caption)
  self.price_panel.lowered = true
  local step = MultiplayerSession.STAFF_PRICE_STEP
  self:addBevelPanel(WIDTH - 150, y, 60, 28, col.button):setLabel("-$" .. step)
      :makeRepeatButton(0, 0, 60, 28, nil, function(window) window:setPrice(window.price - step) end)
  self:addBevelPanel(WIDTH - 80, y, 60, 28, col.button):setLabel("+$" .. step)
      :makeRepeatButton(0, 0, 60, 28, nil, function(window) window:setPrice(window.price + step) end)
  self:setPrice(vouch and 0 or MultiplayerSession.RIVAL_MIN_PRICE)

  y = y + 34
  self:addBevelPanel(20, y, 180, 30, col.button):setLabel(S.trade_send_staff)
      :makeButton(0, 0, 180, 30, nil, self.sendStaff)
  self:addBevelPanel(210, y, WIDTH - 230, 30, col.button):setLabel(S.trade_next_player)
      :makeButton(0, 0, WIDTH - 230, 30, nil, self.nextPlayer)
  if vouch then
    -- Vouch for the ally: points of reputation (1 to 100) from this hospital
    -- to theirs. (The title names them; the button says whose points go:
    -- Jan, 2026-11-08: a name in the line ran out of the window.)
    local ry = y + 38
    self:addBevelPanel(20, ry, WIDTH - 40, 20, col.caption):setLabel(S.rep_vouch_caption).lowered = true
    ry = ry + 24
    self.rep_panel = self:addBevelPanel(20, ry, 120, 28, col.caption)
    self.rep_panel.lowered = true
    for i, points in ipairs({-10, -1, 1, 10}) do
      self:addBevelPanel(150 + (i - 1) * 52, ry, 46, 28, col.button)
          :setLabel((points > 0 and "+" or "") .. points)
          :makeRepeatButton(0, 0, 46, 28, nil, function(window) window:setReputation(window.reputation + points) end)
    end
    self.rep_button = self:addBevelPanel(20, ry + 34, WIDTH - 40, 30, col.button)
    self.rep_button:makeButton(0, 0, WIDTH - 40, 30, nil, self.sendReputation)
    self:setReputation(self.reputation)
    y = y + REP_HEIGHT
  end
  -- (A message shows left of Close; nothing there until there is one.)
  self.status_panel = self:addBevelPanel(20, y + 43, WIDTH - 160, 25, col.bg)
  self.status_panel:setLabel("")
  self.status_panel.lowered = true
  self.status_panel:setVisible(false)
  self:addBevelPanel(WIDTH - 130, y + 40, 110, 30, col.button):setLabel(S.trade_close)
      :makeButton(0, 0, 110, 30, nil, self.close)
end

--! The next player hospital after `current` (wrapping), other than ours.
function UIMultiplayerTrade:draw(canvas, x_, y_)
  UIResizable.draw(self, canvas, x_, y_)
  MultiplayerSession.drawTitleTabs(canvas, self, x_, y_, self.target)
end

function UIMultiplayerTrade:_nextTarget(current)
  local hospitals = self.world.hospitals
  local n = self.world.mp_coop and self.world.mp_coop.players or 1
  local start = current and self.world:getHospitalIndex(current) or 0
  for step = 1, n do
    local h = hospitals[(start + step - 1) % n + 1]
    if h and self.world:mpMayTrade(self.hospital, h) then return h end
  end
end

function UIMultiplayerTrade:setStatus(text)
  if self.status_panel then self.status_panel:setLabel(text or ""):setVisible((text or "") ~= "") end
end

function UIMultiplayerTrade:sendMoney(amount)
  local session = TheApp.mp_session
  if not session then return end
  session:issue({kind = "give_money", to = self.world:getHospitalIndex(self.target), amount = amount})
  self:setStatus(_S.multiplayer_window.trade_sent)
end

--! Set the reputation points to give, 1 to MultiplayerSession.REP_MAX_GIVE.
function UIMultiplayerTrade:setReputation(points)
  self.reputation = math.max(1, math.min(MultiplayerSession.REP_MAX_GIVE, points))
  self.rep_panel:setLabel(_S.multiplayer_window.rep_amount:format(self.reputation))
  if self.rep_button then
    self.rep_button:setLabel(_S.multiplayer_window.rep_give_button:format(self.reputation))
  end
end

function UIMultiplayerTrade:sendReputation()
  local session = TheApp.mp_session
  if not session then return end
  session:issue({kind = "give_reputation", to = self.world:getHospitalIndex(self.target), amount = self.reputation})
  self:setStatus(_S.multiplayer_window.rep_sent)
end

--! Set the price asked for the member of staff, $0 to STAFF_MAX_PRICE.
function UIMultiplayerTrade:setPrice(price)
  self.price = math.max(0, math.min(MultiplayerSession.STAFF_MAX_PRICE, price))
  local S = _S.multiplayer_window
  self.price_panel:setLabel(self.price > 0 and S.trade_price:format(self.price) or S.trade_free)
end

function UIMultiplayerTrade:_pages()
  return math.max(1, math.ceil(#self.staff_list / self.staff_rows))
end

--! Show the staff of the current page; the selected one toggled on, the
--! ones already offered greyed out.
function UIMultiplayerTrade:_showPage()
  local first = (self.page - 1) * self.staff_rows
  for row, button in ipairs(self.rows) do
    local entry = self.staff_list[first + row]
    local label = entry and entry.label or ""
    if entry and entry.offered then label = label .. "  " .. _S.multiplayer_window.trade_on_the_way end
    button:setLabel(label)
    button:enable(entry ~= nil and not entry.offered)
    button:setToggleState(entry ~= nil and entry == self.selected)
  end
  self.page_panel:setLabel(_S.multiplayer_window.research_page:format(self.page, self:_pages()))
end

function UIMultiplayerTrade:turnPage(delta)
  self.page = math.min(self:_pages(), math.max(1, self.page + delta))
  self:_showPage()
end

function UIMultiplayerTrade:selectStaff(row, state)
  local entry = self.staff_list[(self.page - 1) * self.staff_rows + row]
  self.selected = state and entry or nil
  self:_showPage()
end

function UIMultiplayerTrade:sendStaff()
  local session = TheApp.mp_session
  if not session then return end
  if not self.selected then
    self:setStatus(_S.multiplayer_window.trade_select_staff)
    return
  end
  local staff = self.selected.staff
  -- An offer: they move only if the other player accepts it.
  session:issue({kind = "offer_staff", to = self.world:getHospitalIndex(self.target),
      staff = staff.mp_id, index = self.selected.index, key = MultiplayerSession.staffKey(staff),
      price = self.price > 0 and self.price or nil})
  self:setStatus(_S.multiplayer_window.trade_offered)
  -- They are on their way: they cannot be sent again from this window.
  self.selected.offered = true
  self.selected = nil
  self:_showPage()
end

function UIMultiplayerTrade:nextPlayer()
  local ui = self.ui
  local target = self:_nextTarget(self.target)
  local staff = self.selected and self.selected.staff
  local price, rep = self.price, self.reputation
  local rival = self.world:mpRivals(self.hospital, self.target)
  self:close()
  local window = UIMultiplayerTrade(ui, target, staff)
  ui:addWindow(window)
  -- (The price stays from one ally to the next, or one rival to the next.)
  if window.price_panel and rival == self.world:mpRivals(self.hospital, target) then window:setPrice(price) end
  if window.rep_panel then window:setReputation(rep) end
end

--! Draw the purple "send to another player" icon (w x h, default 24 x 28,
--! at ix, iy, UI scale s): a person and an arrow, centred. Used in the
--! patient and staff windows.
function UIMultiplayerTrade.drawSendIcon(canvas, ix, iy, s, w, h)
  w, h = w or 24, h or 28
  local edge = h >= 28 and 2 or 1
  canvas:drawRect(canvas:mapRGB(48, 16, 74), ix, iy, w * s, h * s)
  canvas:drawRect(canvas:mapRGB(150, 76, 206), ix + edge * s, iy + edge * s, (w - 2 * edge) * s, (h - 2 * edge) * s)
  -- The figure is 16 x 16 (at 4, 5 in the 24 x 28 icon).
  local fx, fy = ix + (math.floor((w - 16) / 2) - 4) * s, iy + (math.floor((h - 16) / 2) - 5) * s
  local light = canvas:mapRGB(246, 238, 255)
  canvas:drawRect(light, fx + 6 * s, fy + 5 * s, 5 * s, 5 * s)   -- head
  canvas:drawRect(light, fx + 4 * s, fy + 11 * s, 9 * s, 6 * s)  -- shoulders
  canvas:drawRect(light, fx + 5 * s, fy + 17 * s, 7 * s, 4 * s)  -- body
  local arrow = canvas:mapRGB(255, 214, 90)                       -- "to another hospital"
  canvas:drawRect(arrow, fx + 14 * s, fy + 13 * s, 5 * s, 2 * s)
  canvas:drawRect(arrow, fx + 17 * s, fy + 11 * s, 2 * s, 6 * s)
  canvas:drawRect(arrow, fx + 19 * s, fy + 12 * s, 1 * s, 4 * s)
end

--! Draw the purple "send to another player" button (MATROFTT's 24 x 24
--! pixel art, at ix, iy, UI scale s; centred in size x size: 26 in the staff
--! list, 24 in the patient window like its Close button), red while held.
function UIMultiplayerTrade.drawSendButton(canvas, ix, iy, s, size, pressed)
  local d = math.floor(((size or 24) - 24) / 2)
  MultiplayerSession.drawIcon(canvas, pressed and "transferstuff_pressed" or "transferstuff",
      ix + d * s, iy + d * s, s)
end

--! Open the window (co-op only), optionally with a member of staff selected.
function UIMultiplayerTrade.open(ui, staff)
  if not (TheApp.mp_session and ui.app.world and ui.app.world.mp_coop) then return end
  local window = ui:getWindow(UIMultiplayerTrade)
  if window then window:close() end
  ui:addWindow(UIMultiplayerTrade(ui, nil, staff))
end
