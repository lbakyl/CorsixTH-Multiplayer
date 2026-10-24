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
--! each for a while, and opens the input line on Enter (when no other window
--! is waiting for Enter). UIMultiplayerChatInput is that line: Tab chooses
--! who it is for (everybody, then each other player), remembered for next
--! time; Enter sends, Escape closes.
class "UIMultiplayerChat" (Window)

---@type UIMultiplayerChat
local UIMultiplayerChat = _G["UIMultiplayerChat"]

local SHOW_MS = 15000 -- how long a line stays
local LINES = 6

local function now()
  local sdl = rawget(_G, "SDL")
  return sdl and sdl.getTicks() or 0
end

function UIMultiplayerChat:UIMultiplayerChat(ui)
  self:Window()
  self.ui = ui
  self.x, self.y = 0, 0
  self.width, self.height = 0, 0
  self.on_top = false
  self.lines = {}
  self.font = ui.app.gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil, { apply_ui_scale = true })
  self:addKeyHandler("global_confirm", self.openInput)
end

--! Never in the way of clicks on the map.
function UIMultiplayerChat:hitTest()
  return false
end

--! Add a line: {text, private}.
function UIMultiplayerChat:add(text, private)
  if type(text) == "userdata" then text = require("TH").stringProxy._unwrap(text) end -- a game string
  self.lines[#self.lines + 1] = {text = tostring(text), private = private, at = now()}
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
  for _, line in ipairs(shown) do
    local w = math.min(560, 12 + 7 * #line.text) * s
    canvas:drawRect(line.private and canvas:mapRGB(70, 30, 104) or canvas:mapRGB(30, 30, 40),
        x + 6 * s, ly, w, 16 * s)
    self.font:draw(canvas, line.text, x + 10 * s, ly + 3 * s)
    ly = ly + 18 * s
  end
end

--! Enter: open the input line, unless a dialog is waiting for Enter (its
--! handler runs too). The game screen's own Alt+Enter does not count.
function UIMultiplayerChat:openInput()
  for _, handler in ipairs(self.ui.key_handlers["return"] or {}) do
    if handler.window ~= self and handler.window ~= self.ui then return end
  end
  if self.ui:getWindow(UIMultiplayerChatInput) or not TheApp.mp_session then return end
  self.ui:addWindow(UIMultiplayerChatInput(self.ui))
end

class "UIMultiplayerChatInput" (UIResizable)

---@type UIMultiplayerChatInput
local UIMultiplayerChatInput = _G["UIMultiplayerChatInput"]

local WIDTH = 480

function UIMultiplayerChatInput:UIMultiplayerChatInput(ui)
  self:UIResizable(ui, WIDTH, 40, Colours.PanelDefault)
  self.resizable = false
  self.on_top = true
  self.esc_closes = true
  self:setPosition(10, -70) -- just above the bottom bar
  self.target_panel = self:addBevelPanel(8, 8, 110, 24, Colours.Caption)
  self.target_panel.lowered = true
  self.box = self:addBevelPanel(124, 8, WIDTH - 132, 24, Colours.Textbox, Colours.PanelDefault,
      Colours.PanelDefault):setAutoClip(true)
      :makeTextbox(--[[persistable:mp_chat_send]] function() self:send() end,
                   --[[persistable:mp_chat_abort]] function() self:close() end)
      :allowedInput({"alpha", "numbers", "misc"}):characterLimit(120)
  -- Tab (reserved by text boxes) chooses who the message is for.
  self.box.keyInput = --[[persistable:mp_chat_keyinput]] function(box, char, rawchar)
    if char == "tab" then
      box.panel.window:nextTarget()
      return true
    end
    return _G["Textbox"].keyInput(box, char, rawchar) -- (a global class, not declared for luacheck)
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

function UIMultiplayerChatInput:_showTarget()
  local lobby = self:_lobby()
  local S = _S.multiplayer_window
  local name
  for _, p in ipairs(self:_others()) do
    if lobby and p.peer == lobby.chat_target then name = p.name end
  end
  if lobby and not name then lobby.chat_target = nil end -- that player is gone
  self.target_panel:setLabel(name and S.chat_to:format(name) or S.chat_to_all)
end

--! Tab: everybody, then each other player in turn.
function UIMultiplayerChatInput:nextTarget()
  local lobby = self:_lobby()
  if not lobby then return end
  local others = self:_others()
  local next_target
  if lobby.chat_target == nil then
    next_target = others[1] and others[1].peer
  else
    for i, p in ipairs(others) do
      if p.peer == lobby.chat_target then next_target = others[i + 1] and others[i + 1].peer end
    end
  end
  lobby.chat_target = next_target
  self:_showTarget()
end

function UIMultiplayerChatInput:send()
  local lobby = self:_lobby()
  local text = tostring(self.box.text or ""):match("^%s*(.-)%s*$")
  if lobby and text ~= "" then
    lobby:send("CHAT", {text = text, to = lobby.chat_target})
  end
  self:close()
end
