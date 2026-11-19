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

corsixth.require("mp_pack")

--! Downloading a multiplayer server's build of the game (mp_pack.lua): a
--! progress bar, then the game restarts as that build and joins the server.
class "UIMultiplayerDownload" (UIResizable)

---@class UIMultiplayerDownload: UIResizable
---@operator call: UIMultiplayerDownload
local UIMultiplayerDownload = _G["UIMultiplayerDownload"] ---@type UIMultiplayerDownload

local col = {
  bg = Colours.PanelDefault,
  title = Colours.Title,
  bar_back = Colours.Textbox,
  bar = Colours.SettingActive,
}

local W, H = 400, 150
local BAR_W = W - 40

--! Megabytes, for showing ("3.4 MB"; the number is formatted here, as the
--! game's texts take %s and %d only).
function UIMultiplayerDownload.megabytes(bytes)
  return _S.multiplayer_window.megabytes:format(string.format("%.1f", (bytes or 0) / (1024 * 1024)))
end

--!param offer (table) MultiplayerPack.offer's: the build and its size
--!param address (string) the server ("host:port"), joined again afterwards
--!param name (string) the player's name there
function UIMultiplayerDownload:UIMultiplayerDownload(ui, offer, address, name)
  local S = _S.multiplayer_window
  self:UIResizable(ui, W, H, col.bg)
  self.resizable = false
  self.on_top = true
  self.esc_closes = true
  self:setDefaultPosition(0.5, 0.4)
  self.default_button_sound = "selectx.wav"
  self.offer, self.address, self.name = offer, address, name
  self:addBevelPanel(20, 10, W - 40, 20, col.title):setLabel(S.version_caption).lowered = true
  self.text_panel = self:addBevelPanel(20, 40, W - 40, 20, col.bg)
  self.text_panel.lowered = true
  self:addBevelPanel(20, 68, BAR_W, 20, col.bar_back).lowered = true
  self.bar = self:addBevelPanel(20, 68, 1, 20, col.bar)
  self.button = self:addBevelPanel(W / 2 - 70, 100, 140, 30, col.bg):setLabel(S.version_cancel)
      :makeButton(0, 0, 140, 30, nil, self.buttonCancel)
  self.download = MultiplayerPack(address, offer)
  self.ticks_checking = 0
  self:_update()
end

function UIMultiplayerDownload:buttonCancel()
  self.download:cancel()
  self:close()
end

--! What went wrong, in the player's words.
local function failure(why)
  local S = _S.multiplayer_window
  if why == "newer game" then return S.version_newer_game end
  if why == "signature" or why == "damaged" or why == "another build" or why == "incomplete" or
      why == "bad answer" then
    return S.version_bad
  end
  return S.version_failed:format(tostring(why))
end

function UIMultiplayerDownload:_update()
  local S, dl = _S.multiplayer_window, self.download
  local text
  if self.starting then
    text = S.version_starting
  elseif dl.state == "connecting" then
    text = S.connecting:format(self.address)
  elseif dl.state == "receiving" then
    text = S.version_downloading:format(UIMultiplayerDownload.megabytes(dl.received),
        UIMultiplayerDownload.megabytes(dl.size))
  elseif dl.state == "checking" or dl.state == "done" then
    text = S.version_checking
  else
    text = failure(dl.error)
  end
  self.text_panel:setLabel(text)
  local width = math.floor(BAR_W * dl:progress())
  self.bar:setSize(math.max(1, width), 20)
  self.bar:setVisible(width > 0 and dl.state ~= "failed")
  if dl.state == "failed" then self.button:setLabel(S.version_close) end
  if self.starting then self.button:enable(false) end -- (too late to cancel)
end

function UIMultiplayerDownload:onTick()
  local dl = self.download
  if self.starting then
    -- ("Starting" has been shown; restart as the server's build.)
    self.starting = self.starting + 1
    if self.starting > 3 then
      MultiplayerPack.switchTo(TheApp, self.offer.build, self.address, self.name)
      return
    end
  elseif dl.state == "checking" and self.ticks_checking < 3 then
    -- (Let "Checking" be drawn before the work that takes a moment.)
    self.ticks_checking = self.ticks_checking + 1
  elseif dl.state == "done" then
    self.starting = 1
  elseif dl.state ~= "failed" then
    dl:poll(TheApp)
  end
  self:_update()
  UIResizable.onTick(self)
end

function UIMultiplayerDownload:close()
  if self.download.state ~= "done" then self.download:cancel() end
  UIResizable.close(self)
end
