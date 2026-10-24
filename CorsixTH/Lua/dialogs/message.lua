--[[ Copyright (c) 2009 Peter "Corsix" Cawley

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

--! Small fax notification window which sits on the bottom bar.
class "UIMessage" (Window)

---@type UIMessage
local UIMessage = _G["UIMessage"]

function UIMessage:UIMessage(ui, x, stop_x, onClose, type, message, owner, timeout, default_choice, callback)
  self:Window()

  local app = ui.app

  self.esc_closes = false
  self.on_top = false
  self.onClose = onClose
  self.timer = timeout
  self.default_choice = default_choice
  self.ui = ui
  self.message = message
  self.callback = callback
  if owner then
    self.owner = owner
    if owner.message_callback then
      owner:message_callback(true) -- There can be only one message per owner, just remove any existing one
    end
    assert(owner.message_callback == nil)
    owner.message_callback = --[[persistable:owner_of_message_callback]] function(_, do_remove)
      if do_remove then
        self:removeMessage()
      else
        self:openMessage()
      end
    end
  end
  self.width = 30
  self.height = 28
  self.stop_x = stop_x
  self.stop_y = -24
  self.x = x
  self.y = 4
  self.panel_sprites = app.gfx:loadSpriteTable("Data", "Panel02V", true)
  self.type = type

  local types = { emergency = 43, epidemy = 45, strike = 47, personality = 49, information = 51, disease = 53, report = 55,
                  mp_offer = 51, mp_research = 51 } -- multiplayer co-op offers: drawn below, not sprites
  local kind = types[type]

  self.can_dismiss = self.type ~= "strike" and #self.message.choices == 1

  self.button = self:addPanel(kind, 0, 0)
    :setTooltip(self.can_dismiss and _S.tooltip.message.button_dismiss or _S.tooltip.message.button) -- FIXME: tooltip doesn't work very well here
    :makeToggleButton(0, 0, 30, 28, kind + 1, self.openMessage, nil, self.dismissMessage)
  if type == "mp_offer" or type == "mp_research" then
    -- Multiplayer co-op offers (a person, or research): a raised purple
    -- button like the game's own message icons (UIMessage.drawOfferIcon).
    self.button.panel_for_sprite.custom_draw = --[[persistable:mp_offer_icon_draw]] function(panel, canvas, px, py)
      local s = TheApp.gfx:getUIScale()
      local window = panel.window
      local open = window.button and window.button.toggled
      -- (Through _G: a saved game keeps no reference to this file's locals.)
      _G.UIMessage.drawOfferIcon(canvas, px + panel.x * s, py + panel.y * s, s, open, window.type,
          window.panel_sprites)
    end
  end
  -- The emergency has a rotating siren
  if kind == 43 then
    self.rotator = {}
    for i = 57, 60 do
      self.rotator[i] = self:addPanel(i, 10, 8)
      self.rotator[i].visible = false
    end
    self.active = 57
  end
end

--! Draw a multiplayer offer icon (30 x 28): the game's own message icon
--! frame (the grey stand of the "?" icon), with its green square painted
--! purple and bevelled, pressed in while the offer's window is open, and a
--! white symbol on it: a person for staff and patient offers, a flask for
--! research.
--!param sprites the message's panel sprites (Panel02V)
function UIMessage.drawOfferIcon(canvas, ix, iy, s, open, kind, sprites)
  local function rect(c, x, y, w, h)
    canvas:drawRect(canvas:mapRGB(c[1], c[2], c[3]), ix + x * s, iy + y * s, w * s, h * s)
  end
  sprites:draw(canvas, 51, ix, iy, { scaleFactor = s }) -- the frame
  -- The square (18 x 18 at 6, 4): edges, ring and face; pressed in, the
  -- light and dark edges swap and the face darkens.
  local light, dark = {206, 168, 246}, {54, 12, 84}
  local ring, face, shine = {124, 60, 184}, {148, 78, 208}, {172, 112, 228}
  if open then
    light, dark = dark, {184, 142, 228}
    ring, face, shine = {100, 46, 156}, {120, 58, 176}, {120, 58, 176}
  end
  rect(dark, 6, 4, 18, 18)
  rect(light, 6, 4, 17, 1)
  rect(light, 6, 4, 1, 17)
  rect(ring, 7, 5, 16, 16)
  rect(face, 8, 6, 14, 14)
  rect(shine, 8, 6, 14, 2)
  rect(light, 8, 6, 2, 1)
  local white, tint = {243, 243, 243}, {214, 196, 240}
  local d = open and 1 or 0
  if kind == "mp_research" then
    -- A flask: cork, neck, widening glass, green liquid with bubbles.
    rect({206, 158, 100}, 13 + d, 6 + d, 4, 2)
    rect({150, 106, 60}, 16 + d, 6 + d, 1, 2)
    rect(white, 13 + d, 8 + d, 4, 4)
    rect(tint, 16 + d, 8 + d, 1, 4)
    rect(white, 12 + d, 12 + d, 6, 2)
    rect(white, 11 + d, 14 + d, 8, 2)
    rect(white, 10 + d, 16 + d, 10, 3)
    rect({120, 222, 150}, 11 + d, 15 + d, 8, 1)
    rect({84, 196, 120}, 11 + d, 16 + d, 8, 2)
    rect(tint, 10 + d, 18 + d, 10, 1)
    rect(white, 16 + d, 16 + d, 1, 1) -- bubbles
    rect(white, 13 + d, 17 + d, 1, 1)
  else
    -- A person in a white coat: head, shoulders, body, collar.
    rect(white, 13 + d, 6 + d, 4, 4)
    rect(tint, 16 + d, 7 + d, 1, 3)
    rect(white, 10 + d, 11 + d, 10, 3)
    rect(white, 11 + d, 14 + d, 8, 5)
    rect(tint, 18 + d, 12 + d, 1, 6)
    rect(face, 14 + d, 11 + d, 2, 2)
    rect(tint, 11 + d, 18 + d, 7, 1)
    rect(face, 13 + d, 6 + d, 1, 1) -- rounded head and shoulders
    rect(face, 16 + d, 6 + d, 1, 1)
    rect(face, 10 + d, 11 + d, 1, 1)
    rect(face, 19 + d, 11 + d, 1, 1)
  end
end

function UIMessage:draw(canvas, x, y)
  if self.on_top then
    Window.draw(self, canvas, x, y)
  else
    local width = canvas:getRenderSize()
    canvas:pushClip(0, y + self.stop_y, width, self.height, true)
    Window.draw(self, canvas, x, y)
    canvas:popClip()
  end
end

function UIMessage:close(...)
  assert(self.onClose == nil, "UIMessage closed improperly")
  return Window.close(self, ...)
end

-- Adjust the toggle state to match if the message is open or not
function UIMessage:adjustToggle()
  if (self.button.toggled and not self.fax) or
      (not self.button.toggled and self.fax) then
    self.button:toggle()
  end
end

--! Displays the fax/strike message to the player when opened from the bottom_panel.
function UIMessage:openMessage()
  if TheApp.world:isUserActionProhibited() then
    self.ui:playSound("wrong2.wav")
    self:adjustToggle()
    return
  end
  if self.type == "strike" then -- strikes are special cases, as they are not faxes
    -- (In multiplayer the answer is a command: UIStaffRise:_issueAnswer.)
    self.ui:addWindow(UIStaffRise(self.ui, self.owner, self.message))
    self:removeMessage()
  elseif self.type == "mp_offer" then
    -- Multiplayer co-op: an offer from another player, in its own window.
    if self.fax then
      self.fax:close()
    else
      self.fax = UIMultiplayerOffer(self.ui, self)
      self.ui:addWindow(self.fax)
    end
    self:adjustToggle()
  else
    if self.fax then
      self.fax:close()
    else
      self.fax = UIFax(self.ui, self)
      self.ui:addWindow(self.fax)
      self.ui:playSound("fax_in.wav")
    end
    -- Manual adjustion of toggle state is necessary if owner's message_callback was used
    self:adjustToggle()
  end
  TheApp.video:setBlueFilterActive(false)
end

-- Removes the Message, executing a choice if given, else just deletes it
--!param choice_number (number) if given, removes the message by executing this choice.
function UIMessage:removeMessage(choice_number)
  if choice_number then
    if not self.fax then
      self.fax = UIFax(self.ui, self) -- NB: just create, don't add to ui
    end
    self.fax:choice(choice_number)
  else
    if self.fax then
      self.fax:close()
    end
    if self.owner then
      self.owner.message = nil
      self.owner.message_callback = nil
    end
    if self.onClose then
      local onClose = self.onClose
      self.onClose = nil
      onClose(self)
    end
    self:close()
  end
end

-- Tries to dismiss the message. This is only possible if there is only one choice.
function UIMessage:dismissMessage()
  if self.can_dismiss then
    if MultiplayerSession.actionsAreCommands() then
      TheApp.mp_session:issue({kind = "fax_choice", msg = self.mp_id, choice = 1})
      self:adjustToggle()
      return
    end
    self:removeMessage(1)
  else
    self.ui:playSound("wrong2.wav")
    self:adjustToggle()
  end
end

function UIMessage:setXLimit(stop_x)
  self.stop_x = stop_x
end

function UIMessage:onTick()
  if self.on_top == false and self.y == self.stop_y then
    self.on_top = true
  end
  if self.y > self.stop_y then
    local y = self.y - 8
    if y > self.stop_y then
      self.y = y
    else
      self.y = self.stop_y
    end
  elseif self.x > self.stop_x then
    local x = self.x - 3
    if x > self.stop_x then
      self.x = x
    else
      self.x = self.stop_x
    end
  end
end

--! Count down one game hour; when the time is up, take the default choice.
function UIMessage:tickTimer()
  if self.timer then
    self.timer = self.timer - 1
    if self.timer <= 0 then
      self.timer = nil
      self:removeMessage(self.default_choice)
    end
  end
end

function UIMessage:onWorldTick()
  -- In multiplayer the bottom panel runs the timers (UIBottomPanel:onWorldTick).
  if not TheApp.mp_session then self:tickTimer() end
  if self.active then
    self.rotator[self.active].visible = false
    if self.active == 60 then
      self.active = 57
    else
      self.active = self.active + 1
    end
    self.rotator[self.active].visible = true
  end
end

function UIMessage:afterLoad(old, new)
  if old < 21 then
    -- self.button added; however check for existence first
    -- since the savegame bump was a couple of revisions later
    if not self.button then
      self.button = self.buttons[1]
    end
  end
  Window.afterLoad(self, old, new)
end
