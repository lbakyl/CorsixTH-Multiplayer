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

--! Multiplayer co-op: send money or a member of staff to another player's
--! hospital. Every action is a lockstep command (give_money, send_staff).
class "UIMultiplayerTrade" (UIResizable)

---@type UIMultiplayerTrade
local UIMultiplayerTrade = _G["UIMultiplayerTrade"]

local col = {
  bg             = Colours.PanelDefault,
  button         = Colours.PanelDefault,
  setting        = Colours.Setting,
  setting_active = Colours.SettingActive,
  title          = Colours.Title,
  caption        = Colours.Caption,
}

local WIDTH = 380
local STAFF_ROWS = 8
local AMOUNTS = {1000, 5000, 20000}

--!param target (Hospital) optional: the player to trade with
--!param staff (Staff) optional: this member of staff selected
function UIMultiplayerTrade:UIMultiplayerTrade(ui, target, staff)
  local height = 120 + STAFF_ROWS * 25 + 36 + 70
  self:UIResizable(ui, WIDTH, height, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.2)
  self.default_button_sound = "selectx.wav"
  local S = _S.multiplayer_window
  local world = ui.app.world
  self.world = world
  self.hospital = ui.hospital
  self.target = target or self:_nextTarget(nil)
  self.selected = nil

  local title = self.target and S.trade_caption:format(self.target.name) or S.trade_alone
  self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title):setLabel(title).lowered = true
  if not self.target then
    self:addBevelPanel(WIDTH - 140, height - 45, 120, 30, col.button):setLabel(S.trade_close)
        :makeButton(0, 0, 120, 30, nil, self.close)
    return
  end

  -- Money
  for i, amount in ipairs(AMOUNTS) do
    local w = math.floor((WIDTH - 40 - 10 * (#AMOUNTS - 1)) / #AMOUNTS)
    self:addBevelPanel(20 + (i - 1) * (w + 10), 40, w, 30, col.button)
        :setLabel(S.trade_send_money:format(amount))
        :makeButton(0, 0, w, 30, nil, function() self:sendMoney(amount) end)
  end

  -- Staff of this player's hospital, a page of STAFF_ROWS at a time
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
        self.page = math.ceil(#self.staff_list / STAFF_ROWS)
      end
    end
  end
  if #self.staff_list == 0 then
    self:addBevelPanel(20, 85, WIDTH - 40, 25, col.caption):setLabel(S.trade_no_staff).lowered = true
  end
  self.rows = {}
  for row = 1, STAFF_ROWS do
    self.rows[row] = self:addBevelPanel(20, 80 + (row - 1) * 25, WIDTH - 40, 23,
        col.setting, nil, nil, nil, col.setting_active)
        :makeToggleButton(0, 0, WIDTH - 40, 23, nil, function(window, state) window:selectStaff(row, state) end)
  end
  local y = 85 + STAFF_ROWS * 25
  -- (The game's font has no arrows or slashes: words instead.)
  self.page_panel = self:addBevelPanel(20, y, WIDTH - 180, 28, col.caption)
  self.page_panel.lowered = true
  self:addBevelPanel(WIDTH - 150, y, 60, 28, col.button):setLabel(S.research_previous)
      :makeButton(0, 0, 60, 28, nil, function(window) window:turnPage(-1) end)
  self:addBevelPanel(WIDTH - 80, y, 60, 28, col.button):setLabel(S.research_next)
      :makeButton(0, 0, 60, 28, nil, function(window) window:turnPage(1) end)
  self:_showPage()

  y = y + 36
  self:addBevelPanel(20, y, 180, 30, col.button):setLabel(S.trade_send_staff)
      :makeButton(0, 0, 180, 30, nil, self.sendStaff)
  self:addBevelPanel(210, y, WIDTH - 230, 30, col.button):setLabel(S.trade_next_player)
      :makeButton(0, 0, WIDTH - 230, 30, nil, self.nextPlayer)
  self.status_panel = self:addBevelPanel(20, y + 40, WIDTH - 160, 25, col.bg)
  self.status_panel:setLabel("")
  self.status_panel.lowered = true
  self:addBevelPanel(WIDTH - 130, y + 37, 110, 30, col.button):setLabel(S.trade_close)
      :makeButton(0, 0, 110, 30, nil, self.close)
end

--! The next player hospital after `current` (wrapping), other than ours.
function UIMultiplayerTrade:_nextTarget(current)
  local hospitals = self.world.hospitals
  local n = self.world.mp_coop and self.world.mp_coop.players or 1
  local start = current and self.world:getHospitalIndex(current) or 0
  for step = 1, n do
    local h = hospitals[(start + step - 1) % n + 1]
    if h and h ~= self.hospital then return h end
  end
end

function UIMultiplayerTrade:setStatus(text)
  if self.status_panel then self.status_panel:setLabel(text) end
end

function UIMultiplayerTrade:sendMoney(amount)
  local session = TheApp.mp_session
  if not session then return end
  session:issue({kind = "give_money", to = self.world:getHospitalIndex(self.target), amount = amount})
  self:setStatus(_S.multiplayer_window.trade_sent)
end

function UIMultiplayerTrade:_pages()
  return math.max(1, math.ceil(#self.staff_list / STAFF_ROWS))
end

--! Show the staff of the current page; the selected one toggled on, the
--! ones already offered greyed out.
function UIMultiplayerTrade:_showPage()
  local first = (self.page - 1) * STAFF_ROWS
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
  local entry = self.staff_list[(self.page - 1) * STAFF_ROWS + row]
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
      index = self.selected.index, key = MultiplayerSession.staffKey(staff)})
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
  self:close()
  ui:addWindow(UIMultiplayerTrade(ui, target, staff))
end

--! Open the window (co-op only), optionally with a member of staff selected.
function UIMultiplayerTrade.open(ui, staff)
  if not (TheApp.mp_session and ui.app.world and ui.app.world.mp_coop) then return end
  local window = ui:getWindow(UIMultiplayerTrade)
  if window then window:close() end
  ui:addWindow(UIMultiplayerTrade(ui, nil, staff))
end
