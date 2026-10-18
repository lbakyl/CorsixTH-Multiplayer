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

function UIMultiplayerTrade:UIMultiplayerTrade(ui, target)
  local height = 120 + STAFF_ROWS * 25 + 70
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

  -- Staff of this player's hospital
  self.staff_list = {}
  for i, staff in ipairs(self.hospital.staff) do
    if not staff.fired and #self.staff_list < STAFF_ROWS then
      self.staff_list[#self.staff_list + 1] = {staff = staff, index = i}
    end
  end
  if #self.staff_list == 0 then
    self:addBevelPanel(20, 85, WIDTH - 40, 25, col.caption):setLabel(S.trade_no_staff).lowered = true
  end
  for row, entry in ipairs(self.staff_list) do
    local staff = entry.staff
    -- Names are localised strings; concatenating keeps them displayable.
    local profession = _S.staff_class[staff.humanoid_class:lower()] or staff.humanoid_class
    local text = staff.profile:getFullName() .. "  (" .. profession .. ", $" .. staff.profile.wage .. ")"
    self:addBevelPanel(20, 80 + (row - 1) * 25, WIDTH - 40, 23, col.setting, nil, nil, nil,
        col.setting_active):setLabel(text)
        :makeToggleButton(0, 0, WIDTH - 40, 23, nil, function(window, state, btn)
          window:selectStaff(row, state, btn)
        end)
  end

  local y = 85 + STAFF_ROWS * 25
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

function UIMultiplayerTrade:selectStaff(row, state, btn)
  for _, b in ipairs(self.buttons) do
    if b ~= btn and b.is_toggle then b:setToggleState(false) end
  end
  self.selected = state and self.staff_list[row] or nil
end

function UIMultiplayerTrade:sendStaff()
  local session = TheApp.mp_session
  if not session then return end
  if not self.selected then
    self:setStatus(_S.multiplayer_window.trade_select_staff)
    return
  end
  local staff = self.selected.staff
  session:issue({kind = "send_staff", to = self.world:getHospitalIndex(self.target),
      index = self.selected.index, key = MultiplayerSession.staffKey(staff)})
  self:setStatus(_S.multiplayer_window.trade_sent)
  self.selected = nil
end

function UIMultiplayerTrade:nextPlayer()
  local ui = self.ui
  local target = self:_nextTarget(self.target)
  self:close()
  ui:addWindow(UIMultiplayerTrade(ui, target))
end
