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

local lfs = require("lfs")

--! The multiplayer lobby's "Load MP game": the saved multiplayer games
--! (MultiplayerLobby.savesDir) in the file list of the single player's Load
--! Game window, newest first. The game chosen is continued by the new room
--! (the lobby window opens again with it); Back goes back to the lobby too.
class "UILoadMultiplayerGame" (UIFileBrowser)

---@class UILoadMultiplayerGame: UIFileBrowser
---@operator call: UILoadMultiplayerGame
local UILoadMultiplayerGame = _G["UILoadMultiplayerGame"] ---@type UILoadMultiplayerGame

function UILoadMultiplayerGame:UILoadMultiplayerGame(ui)
  local dir = MultiplayerLobby.savesDir()
  if not lfs.attributes(dir, "mode") then lfs.mkdir(dir) end
  local treenode = FilteredFileTreeNode(dir, ".sav")
  treenode.label = "Multiplayer"
  self:UIFileBrowser(ui, "menu", _S.multiplayer_window.load_caption, 295, treenode, true,
      _S.load_game_window.load_button)
  self.control:sortByDate()
end

--! Only a save with the lobby's notes next to it (.mpinfo) can be continued.
function UILoadMultiplayerGame:checkChoice(node)
  return UIFileBrowser.checkChoice(self, node) and
      lfs.attributes((node.path:gsub("%.sav$", ".mpinfo")), "mode") == "file"
end

function UILoadMultiplayerGame:choiceMade(name)
  UIMultiplayer.chooseSave(name)
  self:close()
end

function UILoadMultiplayerGame:close()
  UIResizable.close(self)
  -- Back to the lobby (its room list), or the main menu if it went away.
  if TheApp.mp_lobby and TheApp.mp_lobby.state == "connected" then
    self.ui:addWindow(UIMultiplayer(self.ui))
  else
    self.ui:addWindow(UIMainMenu(self.ui))
  end
end
