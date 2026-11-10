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

--! Multiplayer in-game chat. Chat is not part of the game (no lockstep
--! command): the server relays CHAT lines, to everybody or to one player.
--!
--! UIMultiplayerChat shows the last lines at the top left of the game view,
--! each for a while on a bar in the sender's colour, and opens the input line
--! on Enter. UIMultiplayerChatInput is that line: Tab (or a click on the
--! "To ..." box) chooses who it is for (everybody, the own team in a race of
--! teams or the allies in co-op, then each other player), remembered for next
--! time; Enter sends, Escape closes.
class "UIMultiplayerChat" (Window)

---@class UIMultiplayerChat: Window
---@operator call: UIMultiplayerChat
local UIMultiplayerChat = _G["UIMultiplayerChat"] ---@type UIMultiplayerChat

local SHOW_MS = 30000 -- how long a line stays
local LINES = 6

-- The bar behind a player's lines (dark enough for the white font), by their
-- hospital in a game with a hospital each, else by peer: darker versions of
-- the hospital colours (mustard, salmon, lavender, white: the patients'
-- shirts and the staff bars, MultiplayerSession.markerColour). Bots are grey,
-- private lines get a purple mark at the start, team lines a green one.
local PLAYER_COLOURS = {
  {135, 98, 14}, {150, 62, 52}, {82, 66, 152}, {92, 104, 124},
  {45, 115, 30}, {30, 60, 155}, {20, 110, 125}, {12, 12, 12},
}
local BOT_COLOUR, NOTICE_COLOUR, PRIVATE_MARK = {75, 75, 75}, {30, 30, 40}, {180, 90, 255}
local TEAM_MARK = {70, 210, 90}

--! The colour of a player's chat lines.
--!param peer (integer) the sender's peer number (or, in a game with a
--! hospital each, their hospital's colour: MultiplayerSession.hospitalColour)
--!param bot (boolean) the sender is a computer player
function UIMultiplayerChat.colourOf(peer, bot)
  if bot then return BOT_COLOUR end
  if not peer then return NOTICE_COLOUR end
  return PLAYER_COLOURS[(peer - 1) % #PLAYER_COLOURS + 1]
end

-- Milliseconds. (SDL is a module, not a global: rawget(_G, "SDL") was always
-- nil, the clock always 0, and chat lines never went away.)
local clock
local function now()
  clock = clock or MultiplayerSession.defaultClock() -- (loaded after this file)
  return clock()
end

function UIMultiplayerChat:UIMultiplayerChat(ui)
  self:Window()
  self.ui = ui
  self.x, self.y = 0, 0
  self.width, self.height = 0, 0
  self.on_top = false
  self.lines = {}
  self.font = ui.app.gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil, { apply_ui_scale = true })
  self:addKeyHandler("ingame_mp_chat", self.openInput)
  self:addKeyHandler("ingame_mp_next_hospital", self.nextHospital)
end

--! The next hospital key (ingame_mp_next_hospital, N by default): the view
--! goes to the next hospital's starting place, each press the next one.
function UIMultiplayerChat:nextHospital()
  local world = self.ui.app.world
  if not world or not world.mp_coop then return end
  local last = self.looked_at or world:getHospitalIndex(self.ui.hospital)
  local index = MultiplayerSession.nextHospital(world, last)
  local hospital = index and world.hospitals[index]
  if not hospital then return end
  self.looked_at = index
  MultiplayerSession.lookAtHospital(self.ui, hospital)
  self:add(_S.multiplayer_window.looking_at:format(hospital.name), true,
      UIMultiplayerChat.colourOf(MultiplayerSession.hospitalColour(world, hospital)))
end

--! Never in the way of clicks on the map.
function UIMultiplayerChat:hitTest()
  return false
end

--! Add a line.
--!param private (boolean or "team") only for this player (or sent by them
--! to one), or a line to (or from) a team mate
--!param colour ({r, g, b} or nil) the sender's colour (UIMultiplayerChat.colourOf)
function UIMultiplayerChat:add(text, private, colour)
  if type(text) == "userdata" then text = require("TH").stringProxy._unwrap(text) end -- a game string
  self.lines[#self.lines + 1] = {text = tostring(text), private = private, at = now(),
      colour = colour or NOTICE_COLOUR}
  while #self.lines > 20 do table.remove(self.lines, 1) end
end

function UIMultiplayerChat:draw(canvas, x, y)
  local s = TheApp.gfx:getUIScale()
  local t = now()
  local shown = {}
  for i = #self.lines, 1, -1 do
    local line = self.lines[i]
    if t - line.at > SHOW_MS or #shown >= LINES then break end
    table.insert(shown, 1, line)
  end
  local ly = y + 28 * s -- below the menu bar
  -- (A long line wraps onto more rows, each on a bar as wide as its text.)
  local max_w = math.min(560 * s, (TheApp.config.width or 640) - 40 * s)
  for _, line in ipairs(shown) do
    local c = line.colour
    for _, row in ipairs(self:_rows(line, max_w)) do
      local w = self.font:sizeOf(row) + 8 * s
      canvas:drawRect(canvas:mapRGB(c[1], c[2], c[3]), x + 6 * s, ly, w, 16 * s)
      if line.private then
        local m = line.private == "team" and TEAM_MARK or PRIVATE_MARK
        canvas:drawRect(canvas:mapRGB(m[1], m[2], m[3]), x + 6 * s, ly, 3 * s, 16 * s)
      end
      self.font:draw(canvas, row, x + 10 * s, ly + 3 * s)
      ly = ly + 18 * s
    end
  end
end

--! A line's text word-wrapped to `max_w` pixels (kept until the width
--! changes).
function UIMultiplayerChat:_rows(line, max_w)
  if line.rows and line.rows_w == max_w then return line.rows end
  local rows, cur = {}, nil
  for word in line.text:gmatch("%S+") do
    local try = cur and (cur .. " " .. word) or word
    if cur and self.font:sizeOf(try) > max_w then
      rows[#rows + 1] = cur
      cur = word
    else
      cur = try
    end
  end
  rows[#rows + 1] = cur or ""
  line.rows, line.rows_w = rows, max_w
  return rows
end

--! The chat key (ingame_mp_chat, Y by default): open the input line. In
--! multiplayer the chat key is the chat's alone (see UI:onKeyDown).
function UIMultiplayerChat:openInput()
  if self.ui:getWindow(UIMultiplayerChatInput) or not TheApp.mp_session then return end
  local input = UIMultiplayerChatInput(self.ui)
  input.box.skip_key_text = true -- the letter of the key that opened it
  self.ui:addWindow(input)
end

--! The chat key's name for the menu, e.g. "Y".
function UIMultiplayerChat.keyLabel()
  local key = TheApp.hotkeys and TheApp.hotkeys.ingame_mp_chat or "y"
  if type(key) == "table" then key = table.concat(key, "+") end
  return string.upper(tostring(key))
end

class "UIMultiplayerChatInput" (UIResizable)

---@class UIMultiplayerChatInput: UIResizable
---@operator call: UIMultiplayerChatInput
local UIMultiplayerChatInput = _G["UIMultiplayerChatInput"] ---@type UIMultiplayerChatInput

local WIDTH = 480

function UIMultiplayerChatInput:UIMultiplayerChatInput(ui)
  self:UIResizable(ui, WIDTH, 40, Colours.PanelDefault)
  self.resizable = false
  self.on_top = true
  self.esc_closes = true
  self:setPosition(10, -70) -- just above the bottom bar
  self.target_panel = self:addBevelPanel(8, 8, 110, 24, Colours.Caption)
  self.target_panel.lowered = true
  -- (A click does what Tab does: the box says who it is for, and players
  -- did not find the team behind Tab.)
  self.target_panel:makeButton(0, 0, 110, 24, nil, self.nextTarget)
      :setTooltip(_S.tooltip.multiplayer_window.chat_target)
  self.box = self:addBevelPanel(124, 8, WIDTH - 132, 24, Colours.Textbox, Colours.PanelDefault,
      Colours.PanelDefault):setAutoClip(true)
      :makeTextbox(--[[persistable:mp_chat_send]] function() self:send() end,
                   --[[persistable:mp_chat_abort]] function() self:close() end)
      :allowedInput({"alpha", "numbers", "misc"}):characterLimit(120)
  -- Tab (reserved by text boxes) chooses who the message is for.
  self.box.keyInput = --[[persistable:mp_chat_keyinput]] function(box, char, rawchar)
    box.skip_key_text = nil -- the next key types as usual
    if char == "tab" then
      box.panel.window:nextTarget()
      return true
    end
    return _G["Textbox"].keyInput(box, char, rawchar) -- (a global class, not declared for luacheck)
  end
  -- The chat key's own letter arrives as text right after it opened the line.
  self.box.textInput = --[[persistable:mp_chat_textinput]] function(box, text)
    if box.skip_key_text then
      box.skip_key_text = nil
      return true
    end
    return _G["Textbox"].textInput(box, text)
  end
  self:_showTarget()
  self.box:setActive(true)
end

function UIMultiplayerChatInput:_lobby()
  local session = TheApp.mp_session
  return session and session.lobby, session
end

--! The other players still in the game: {peer, name}, in peer order.
function UIMultiplayerChatInput:_others()
  local lobby, session = self:_lobby()
  local others = {}
  for _, p in ipairs(lobby and lobby.game_players or {}) do
    if p.peer ~= session.peer_id and p.connected then others[#others + 1] = p end
  end
  return others
end

--! This player's team mates (a race of teams) or allies (co-op) still in the
--! game: their peers (MultiplayerLobby:teamMates).
function UIMultiplayerChatInput:_teamMates()
  local lobby, session = self:_lobby()
  return lobby and lobby:teamMates(TheApp.world, session.peer_id) or {}
end

--! Who a line can be for, in Tab order: everybody (nil), the own team
--! ("team": the team mates, or the allies, when there is one), then each other
--! player (their peer).
function UIMultiplayerChatInput:_targets()
  local targets = {false}
  if #self:_teamMates() > 0 then targets[#targets + 1] = "team" end
  for _, p in ipairs(self:_others()) do targets[#targets + 1] = p.peer end
  return targets
end

function UIMultiplayerChatInput:_showTarget()
  local lobby = self:_lobby()
  local S = _S.multiplayer_window
  local label
  if lobby and lobby.chat_target == "team" and #self:_teamMates() > 0 then
    label = MultiplayerLobby.alliesWord(TheApp.world) and S.chat_to_allies or S.chat_to_team
  end
  for _, p in ipairs(self:_others()) do
    if lobby and p.peer == lobby.chat_target then label = S.chat_to:format(p.name) end
  end
  if lobby and not label then lobby.chat_target = nil end -- that player (or team) is gone
  self.target_panel:setLabel(label or S.chat_to_all)
end

--! Tab: everybody, the own team, then each other player in turn.
function UIMultiplayerChatInput:nextTarget()
  local lobby = self:_lobby()
  if not lobby then return end
  local targets = self:_targets()
  local next_target = false
  for i, target in ipairs(targets) do
    if target == (lobby.chat_target or false) then next_target = targets[i + 1] or false end
  end
  lobby.chat_target = next_target or nil
  self:_showTarget()
end

function UIMultiplayerChatInput:send()
  local lobby = self:_lobby()
  local text = tostring(self.box.text or ""):match("^%s*(.-)%s*$")
  if lobby and text ~= "" then
    if lobby.chat_target == "team" then
      local mates = self:_teamMates()
      if #mates > 0 then lobby:send("CHAT", {text = text, to = table.concat(mates, ","), team = 1}) end
    else
      lobby:send("CHAT", {text = text, to = lobby.chat_target})
    end
  end
  self:close()
end
