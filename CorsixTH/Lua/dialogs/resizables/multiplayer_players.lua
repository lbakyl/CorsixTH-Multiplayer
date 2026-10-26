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

--! Multiplayer: who is in this game. The server sends the list every 2
--! seconds (MultiplayerLobby:_onPLAYERS): connected or left, the ping, and
--! how long it has not heard from a player; the hospital figures come from
--! this game's own world (the same on every player's machine).
class "UIMultiplayerPlayers" (UIResizable)

---@type UIMultiplayerPlayers
local UIMultiplayerPlayers = _G["UIMultiplayerPlayers"]

local col = {
  bg      = Colours.PanelDefault,
  button  = Colours.PanelDefault,
  title   = Colours.Title,
  caption = Colours.Caption,
  row     = Colours.Setting,
}

-- Columns: key, width (all of them fit a 640 pixel wide screen).
local COLUMNS = {
  {"name", 95}, {"hospital", 75}, {"ping", 50}, {"status", 115},
  {"value", 65}, {"balance", 65}, {"reputation", 70}, {"goals", 60},
}
local MAX_ROWS = 4
local WIDTH = 20 * 2 + (#COLUMNS - 1) * 4
for _, c in ipairs(COLUMNS) do WIDTH = WIDTH + c[2] end

-- A player more steps behind the others than this is shown as behind.
local BEHIND_STEPS = 24
-- No word from a player for this long (seconds) is shown.
local QUIET_SECONDS = 5

function UIMultiplayerPlayers:UIMultiplayerPlayers(ui)
  local height = 70 + (MAX_ROWS + 1) * 25 + 75
  self:UIResizable(ui, WIDTH, height, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.2)
  self.default_button_sound = "selectx.wav"
  local S = _S.multiplayer_window

  self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title):setLabel(S.players_caption).lowered = true
  self.cells = {}
  for row = 0, MAX_ROWS do
    local x = 20
    self.cells[row] = {}
    for _, c in ipairs(COLUMNS) do
      local panel = self:addBevelPanel(x, 40 + row * 25, c[2], 23, row == 0 and col.caption or col.row)
      panel:setLabel(row == 0 and S["players_" .. c[1]] or "")
      panel.lowered = row > 0
      self.cells[row][c[1]] = panel
      x = x + c[2] + 4
    end
  end
  local y = 40 + (MAX_ROWS + 1) * 25 + 5
  self.note_panel = self:addBevelPanel(20, y, WIDTH - 40, 20, col.bg)
  self.note_panel:setLabel(S.players_note)
  self.note_panel.lowered = true
  self:addBevelPanel(WIDTH - 130, y + 28, 110, 30, col.button):setLabel(S.trade_close)
      :makeButton(0, 0, 110, 30, nil, self.close)
  self:refresh()
end

local function money(n)
  return "$" .. tostring(math.floor(tonumber(n) or 0))
end

--! The rows to show: {name, hospital, ping, status, value, balance, reputation}.
function UIMultiplayerPlayers.rows(lobby, session, world)
  local S = _S.multiplayer_window
  local rows = {}
  local list = lobby and lobby.game_players
  if not list then return rows end
  local newest = 0
  for _, p in ipairs(list) do
    if p.connected and p.step > newest then newest = p.step end
  end
  for _, p in ipairs(list) do
    local index = lobby.peer_hospital and lobby.peer_hospital[p.peer] or 1
    local hospital = world and world.hospitals[index]
    local status
    if not p.connected then
      status = S.players_left
    elseif p.quiet >= QUIET_SECONDS then
      status = S.players_quiet:format(p.quiet)
    elseif newest - p.step > BEHIND_STEPS then
      status = S.players_behind:format(newest - p.step)
    elseif session and p.peer == session.peer_id then
      status = S.players_you
    else
      status = S.players_playing
    end
    rows[#rows + 1] = {
      name = p.name,
      hospital = hospital and hospital.name or "-",
      ping = (p.connected and p.rtt >= 0) and S.players_ms:format(p.rtt) or "-",
      status = status,
      value = hospital and money(hospital.value) or "-",
      balance = hospital and money(hospital.balance) or "-",
      reputation = hospital and tostring(math.floor(hospital.reputation or 0)) or "-",
      -- Co-op: who has reached the level's goals, and who fails them.
      goals = not (hospital and world.mp_coop) and S.goals_open or
          world:mpPlaceText(hospital) or -- competitive: the place, or out
          (hospital.mp_goals_reached and S.goals_done) or
          (hospital.mp_failing_since and S.goals_failing) or S.goals_open,
    }
  end
  return rows
end

function UIMultiplayerPlayers:refresh()
  local rows = UIMultiplayerPlayers.rows(TheApp.mp_lobby, TheApp.mp_session, TheApp.world)
  for row = 1, MAX_ROWS do
    for _, c in ipairs(COLUMNS) do
      local text = rows[row] and rows[row][c[1]] or ""
      self.cells[row][c[1]]:setLabel(text)
    end
  end
  if #rows == 0 then
    self.cells[1].status:setLabel(_S.multiplayer_window.players_waiting)
  end
  self.shown_list = TheApp.mp_lobby and TheApp.mp_lobby.game_players
end

function UIMultiplayerPlayers:onTick()
  -- A new list from the server (every 2 seconds), or the hospital figures
  -- changed: show it again about once a second.
  self.ticks = (self.ticks or 0) + 1
  if self.ticks % 30 == 0 or (TheApp.mp_lobby and TheApp.mp_lobby.game_players ~= self.shown_list) then
    self:refresh()
  end
  return UIResizable.onTick(self)
end
