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

-- (Wider than it was: the buttons name the player now. Argus, 2026-11-13:
-- who you deal with was shown in one place, the button to change it in
-- another.)
local WIDTH = 440
-- Rows of the staff list: as many as the screen has room for, 4 to 8 (a
-- screen of 1080 lines at double size has 540: Jan's did not show it all).
local MAX_STAFF_ROWS = 8
local MIN_STAFF_ROWS = 4
-- Money to send: a slider over these amounts (as far as the bank balance
-- goes), then a question before anything is sent (Jan, 2026-11-12: three
-- buttons that sent $1,000, $5,000 or $20,000 at a click, and he sent
-- $1,000 twice by mistake, meaning to set a doctor's price).
local AMOUNTS = {1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 12000, 15000, 20000, 25000,
    30000, 40000, 50000, 75000, 100000}
-- The room for the reputation rows: a line of text, the points, the button.
local REP_HEIGHT = 94
-- The row to ask an ally for money, under the one to send it (Argus,
-- 2026-11-13: in the trade window, not the bank manager).
local REQUEST_HEIGHT = 36
-- The window but for the staff rows (and the reputation and request rows).
local FIXED_HEIGHT = 85 + 36 + 34 + 30 + 10 + 30 + 10

--! Label `panel` with `long` (the player named), or with `short` where the
--! long one is too wide for it (a long name, a long language).
local function fit_label(panel, long, short)
  panel:setLabel(long)
  local s = panel.apply_ui_scale and TheApp.gfx:getUIScale() or 1
  local font = panel.label_font
  if font and font.sizeOf and font:sizeOf(long) > (panel.w - 10) * s then panel:setLabel(short) end
  return panel
end

--! How many staff rows fit on the screen, with the ally's rows or not.
local function staff_rows(vouch)
  local video = TheApp and TheApp.video
  local gfx = TheApp and TheApp.gfx
  if not (video and gfx and video.getRenderSize) then return MAX_STAFF_ROWS end
  local _, screen_h = video:getRenderSize()
  local free = math.floor(screen_h / gfx:getUIScale()) - 20 - FIXED_HEIGHT -
      (vouch and REP_HEIGHT + REQUEST_HEIGHT or 0)
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
  local height = FIXED_HEIGHT + rows * 25 + (vouch and REP_HEIGHT + REQUEST_HEIGHT or 0)
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

  if not self.target then
    self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title):setLabel(S.trade_alone).lowered = true
  else
    -- Who you deal with, and the buttons to change it, in one row at the
    -- top: the name on the player's colour, ally or rival.
    local c = world.mp_coop and MultiplayerSession.markerColour(world, self.target)
    local band = c and {red = c[1], green = c[2], blue = c[3]} or col.title
    -- (A dark colour lightened: the name is black.)
    if c and c[1] * 0.3 + c[2] * 0.59 + c[3] * 0.11 < 110 then
      band = {red = math.floor((c[1] + 255) / 2), green = math.floor((c[2] + 255) / 2),
          blue = math.floor((c[3] + 255) / 2)}
    end
    local bots = world.mp_coop and world.mp_coop.bot_hospitals or {}
    local relation = world:mpRivals(self.hospital, self.target) and S.trade_rival or S.trade_ally
    if bots[world:getHospitalIndex(self.target)] then relation = relation .. ", " .. S.trade_is_bot end
    self:addBevelPanel(20, 8, 76, 26, col.button):setLabel(S.trade_previous_player)
        :makeButton(0, 0, 76, 26, nil, self.previousPlayer)
    self.who_panel = self:addBevelPanel(102, 8, WIDTH - 204, 26, band)
    fit_label(self.who_panel, S.trade_who:format(self.target.name, relation), self.target.name)
    self:addBevelPanel(WIDTH - 96, 8, 76, 26, col.button):setLabel(S.trade_next_player_short)
        :makeButton(0, 0, 76, 26, nil, self.nextPlayer)
  end
  if not self.target then
    self:addBevelPanel(WIDTH - 140, height - 45, 120, 30, col.button):setLabel(S.trade_close)
        :makeButton(0, 0, 120, 30, nil, self.close)
    return
  end

  -- Money (only to an ally: a rival in a race gets none, Jan 2026-11-12):
  -- the amount on a slider, the button asks before it sends.
  if vouch then
    self.amounts = {}
    for _, amount in ipairs(AMOUNTS) do
      if amount <= self.hospital.balance then self.amounts[#self.amounts + 1] = amount end
    end
    if #self.amounts == 0 then self.amounts[1] = AMOUNTS[1] end
    local n = #self.amounts
    -- (The slider's knob a tenth of the bar or so: a page of that many.)
    local page = math.max(1, math.ceil(n / 9))
    local bar = self:addBevelPanel(20, 45, 170, 20, col.caption)
    bar.lowered = true
    self.money_bar = bar:makeScrollbar(col.button,
        --[[persistable:multiplayer_trade_money_slider]] function() self:setMoney(self.money_bar.value) end,
        1, n + page - 1, page, 1)
    self.money_bar.direction = "x"
    self.money_bar:setRange(1, n + page - 1, page, 1)
    self.money_button = self:addBevelPanel(200, 40, WIDTH - 220, 30, col.button)
    self.money_button:makeButton(0, 0, WIDTH - 220, 30, nil, self.askSendMoney)
    self:setMoney(1)
    -- Ask them for money: the button left, its slider right (the other
    -- player pays or declines in a fax; MultiplayerSession ask_money).
    self.request_amounts = {}
    for _, amount in ipairs(AMOUNTS) do
      if amount >= MultiplayerSession.ASK_MIN and amount <= MultiplayerSession.ASK_MAX then
        self.request_amounts[#self.request_amounts + 1] = amount
      end
    end
    local rn = #self.request_amounts
    local rpage = math.max(1, math.ceil(rn / 9))
    self.request_button = self:addBevelPanel(20, 76, 230, 30, col.button)
    self.request_button:makeButton(0, 0, 230, 30, nil, self.requestMoney)
    local rbar = self:addBevelPanel(260, 81, WIDTH - 280, 20, col.caption)
    rbar.lowered = true
    self.request_bar = rbar:makeScrollbar(col.button,
        --[[persistable:multiplayer_trade_request_slider]] function() self:setRequest(self.request_bar.value) end,
        1, rn + rpage - 1, rpage, 1)
    self.request_bar.direction = "x"
    self.request_bar:setRange(1, rn + rpage - 1, rpage, 1)
    self:setRequest(1)
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
  local top = vouch and REQUEST_HEIGHT or 0
  if #self.staff_list == 0 then
    self:addBevelPanel(20, top + 85, WIDTH - 40, 25, col.caption):setLabel(S.trade_no_staff).lowered = true
  end
  self.rows = {}
  for row = 1, rows do
    self.rows[row] = self:addBevelPanel(20, top + 80 + (row - 1) * 25, WIDTH - 40, 23,
        col.setting, nil, nil, nil, col.setting_active)
        :makeToggleButton(0, 0, WIDTH - 40, 23, nil, function(window, state) window:selectStaff(row, state) end)
  end
  local y = top + 85 + rows * 25
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
  self.offer_button = self:addBevelPanel(20, y, WIDTH - 40, 30, col.button)
  fit_label(self.offer_button, S.trade_send_staff_to:format(self.target.name), S.trade_send_staff)
  self.offer_button:makeButton(0, 0, WIDTH - 40, 30, nil, self.sendStaff)
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
  -- A dark frame round the player's name (a lavender player stood out
  -- little from the window's own purple).
  local who = self.who_panel
  if who then
    local s = TheApp.gfx:getUIScale()
    local fx, fy = self.x * s + x_ + (who.x - 2) * s, self.y * s + y_ + (who.y - 2) * s
    local fw, fh = (who.w + 4) * s, (who.h + 4) * s
    local dark = canvas:mapRGB(48, 32, 64)
    canvas:drawRect(dark, fx, fy, fw, 2 * s)
    canvas:drawRect(dark, fx, fy + fh - 2 * s, fw, 2 * s)
    canvas:drawRect(dark, fx, fy, 2 * s, fh)
    canvas:drawRect(dark, fx + fw - 2 * s, fy, 2 * s, fh)
  end
end

function UIMultiplayerTrade:_nextTarget(current)
  local hospitals = self.world.hospitals
  local n = self.world.mp_coop and self.world.mp_coop.players or 1
  local start = current and self.world:getHospitalIndex(current) or 0
  -- (Opened without one: an ally first, then a rival.)
  if not current then
    for i = 1, n do
      local h = hospitals[i]
      if h and self.world:mpMayTrade(self.hospital, h) and not self.world:mpRivals(self.hospital, h) then return h end
    end
  end
  for step = 1, n do
    local h = hospitals[(start + step - 1) % n + 1]
    if h and self.world:mpMayTrade(self.hospital, h) then return h end
  end
end

function UIMultiplayerTrade:setStatus(text)
  if self.status_panel then self.status_panel:setLabel(text or ""):setVisible((text or "") ~= "") end
end

--! The slider's place `index` (1 = the least): the amount to send.
function UIMultiplayerTrade:setMoney(index)
  self.money = self.amounts[math.max(1, math.min(#self.amounts, index or 1))]
  local S = _S.multiplayer_window
  fit_label(self.money_button, S.trade_send_money_to:format(self.money, self.target.name),
      S.trade_send_money:format(self.money))
end

--! The send button: "Do you really want to send $X to NAME?" first.
function UIMultiplayerTrade:askSendMoney()
  local amount, target = self.money, self.target
  if not amount or not target then return end
  if amount > self.hospital.balance then
    self:setStatus(_S.multiplayer_window.trade_money_short)
    return
  end
  -- (The game goes on meanwhile: no pause in multiplayer.)
  self.ui:addWindow(UIConfirmDialog(self.ui, false,
      _S.multiplayer_window.trade_money_confirm:format(amount, target.name),
      --[[persistable:multiplayer_trade_money_ok]] function()
        if self.target == target then self:sendMoney(amount) end
      end))
end

--! The request slider's place `index` (1 = the least): the amount to ask for.
function UIMultiplayerTrade:setRequest(index)
  self.request = self.request_amounts[math.max(1, math.min(#self.request_amounts, index or 1))]
  local S = _S.multiplayer_window
  fit_label(self.request_button, S.trade_request_money_from:format(self.target.name, self.request),
      S.trade_request_money:format(self.request))
end

--! Ask the ally for the amount: a command, so every peer makes the request
--! (a fax for them) at the same step.
function UIMultiplayerTrade:requestMoney()
  local session = TheApp.mp_session
  if not session or not self.target or not self.request then return end
  session:issue({kind = "ask_money", to = self.world:getHospitalIndex(self.target), amount = self.request})
  self:setStatus(_S.multiplayer_window.ask_asked)
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
    local S = _S.multiplayer_window
    fit_label(self.rep_button, S.rep_give_button_to:format(self.target.name, self.reputation),
        S.rep_give_button:format(self.reputation))
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

--! The player before this one (wrapping), as nextPlayer goes the other way.
function UIMultiplayerTrade:previousPlayer()
  local hospitals = self.world.hospitals
  local n = self.world.mp_coop and self.world.mp_coop.players or 1
  local start = self.world:getHospitalIndex(self.target) or 1
  for step = 1, n do
    local h = hospitals[(start - step - 1) % n + 1]
    if h and h ~= self.target and self.world:mpMayTrade(self.hospital, h) then
      return self:nextPlayer(h)
    end
  end
end

--!param target (Hospital) optional: this player instead of the next one
function UIMultiplayerTrade:nextPlayer(target)
  local ui = self.ui
  target = target or self:_nextTarget(self.target)
  local staff = self.selected and self.selected.staff
  local price, rep = self.price, self.reputation
  self:close()
  local window = UIMultiplayerTrade(ui, target, staff)
  ui:addWindow(window)
  -- (The price stays as it was set, for any player: Argus, 2026-11-12.)
  if window.price_panel and price then window:setPrice(price) end
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
