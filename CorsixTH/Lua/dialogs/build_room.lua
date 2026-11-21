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

local TH = require("TH")

local Window = _G['Window'] ---@type Window

class "UIBuildRoom" (Window)

---@class UIBuildRoom: Window
---@operator call: UIBuildRoom
local UIBuildRoom = _G["UIBuildRoom"] ---@type UIBuildRoom

function UIBuildRoom:UIBuildRoom(ui)
  self:Window()

  local app = ui.app
  self.ui = ui
  self.modal_class = "main"
  self.esc_closes = true
  self.width = 297
  self.height = 294
  self:setDefaultPosition(0.5, 0.5)
  local selected_label_color = { red = 40, green = 40, blue = 250 }
  self.panel_sprites = app.gfx:loadSpriteTable("QData", "Req09V", true)
  self.white_font = app.gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil, { apply_ui_scale = true })
  self.blue_font = app.gfx:loadFontAndSpriteTable("QData", "Font02V", nil, nil, {ttf_color = selected_label_color, apply_ui_scale = true })
  self.category_index = 0
  self.list_hover_index = 0
  self.hover_sound = nil
  self.preview_anim = false
  self.default_button_sound = "selectx.wav"

  local function cat(n)
    return --[[persistable:build_room_set_category]] function(window)
      return window:setCategory(n)
    end
  end
  local room_n = 1
  local function rm()
    local n = room_n
    room_n = room_n + 1
    return --[[persistable:build_room_build_room]] function(window)
      return window:buildRoom(n)
    end
  end

  self:addPanel(210,   0,   0):makeButton(9, 9, 129, 32, 211, cat(1)):setTooltip(_S.tooltip.build_room_window.room_classes.diagnosis)
  self:addPanel(212,   0,  41):makeButton(9, 0, 129, 31, 213, cat(2)):setTooltip(_S.tooltip.build_room_window.room_classes.treatment)
  -- Clinics should really be at y=73, but TH skips a pixel here
  -- so that the left and right columns are the same height
  self:addPanel(214,   0,  72):makeButton(9, 0, 129, 32, 215, cat(3)):setTooltip(_S.tooltip.build_room_window.room_classes.clinic)
  self:addPanel(216,   0, 104):makeButton(9, 0, 129, 32, 217, cat(4)):setTooltip(_S.tooltip.build_room_window.room_classes.facilities)
  self:addPanel(218,   0, 146) -- Grid top
  for y = 179, 249, 10 do
    self:addPanel(219,   0,   y) -- Grid body
  end
  self:addPanel(220,   0, 259) -- Grid bottom
  self:addPanel(221, 146,   0) -- List top
  for y = 34, 205, 19 do
    self:addPanel(222, 146,   y):makeButton(12, 0, 126, 19, 223, rm()) -- List body
      .enabled = false
  end

  -- The close button has no sprite for when pressed, so it has to be custom drawn
  local build_room_dialog_close = TheApp.gfx:loadSpriteTable("Bitmap", "aux_ui", true)
  self:addPanel(224, 146, 224):makeButton(8, 34, 134, 27, 224, self.close):setTooltip(_S.tooltip.build_room_window.close)
  .panel_for_sprite.custom_draw = --[[persistable:build_room_draw_close_button]] function(panel, canvas, x, y)
    local s = TheApp.gfx:getUIScale()
    x = x + panel.x * s
    y = y + panel.y * s
    panel.window.panel_sprites:draw(canvas, panel.sprite_index, x, y, { scaleFactor = s })
    local btn = panel.window.active_button
    if btn and btn.panel_for_sprite == panel and btn.active then
      build_room_dialog_close:draw(canvas, 1, x + 8 * s, y + 34 * s, { scaleFactor = s })
    end
  end

  self.list_title = _S.build_room_window.pick_department
  self.cost_box = _S.build_room_window.cost .. "0"
  self.list = {}
  self.category_titles = {
    _S.room_classes.diagnosis,
    _S.room_classes.treatment,
    _S.room_classes.clinics,
    _S.room_classes.facilities
  }

  self:updateBuildableRooms()

  self:makeTooltip(_S.tooltip.build_room_window.cost, 160, 228, 282, 242)
end

--! Checks what rooms are now available to build
function UIBuildRoom:updateBuildableRooms()
  local app = self.ui.app
  self.category_rooms = {}
  for i, category in ipairs({"diagnosis", "treatment", "clinics", "facilities"}) do
    local rooms = {}
    self.category_rooms[i] = rooms
    for _, room_disc in pairs(self.ui.hospital.room_discoveries) do
      local room = room_disc.room
      -- NB: Unimplemented rooms are hidden unless in debug mode
      if (app.config.debug or room.class) and room.categories[category] and
          room_disc.is_discovered then
        rooms[#rooms + 1] = room
      end
    end
    table.sort(rooms, function(r1, r2) return r1.categories[category] < r2.categories[category] end)
  end
end

local cat_label_y = {21, 53, 84, 116}

--! How many rooms of each kind `hospital` has (room id -> number): built or
--! being built, not crashed. The list shows it beside each kind (Argus and
--! Jan, 2026-11-21: to see at a glance what is built, and how often).
function UIBuildRoom.roomCounts(world, hospital)
  local counts = {}
  for _, room in pairs(world and world.rooms or {}) do
    if room.hospital == hospital and not room.crashed and room.room_info then
      local id = room.room_info.id
      counts[id] = (counts[id] or 0) + 1
    end
  end
  return counts
end

-- Kinds of room never counted as missing (Argus: not worth a reminder).
local NOT_MISSED = {training = true, research = true}

--! How many kinds of room `hospital` may build and has none of yet: the
--! number on the build button (Argus, 2026-11-21: what is left to build,
--! and when research has found a new kind). The kinds the build window
--! lists, but the training room and the research department.
function UIBuildRoom.missingRoomKinds(world, hospital)
  local counts = UIBuildRoom.roomCounts(world, hospital)
  local n = 0
  for _, disc in pairs(hospital.room_discoveries or {}) do
    local room = disc.room
    if disc.is_discovered and room and room.class and not NOT_MISSED[room.id] and not counts[room.id] then
      n = n + 1
    end
  end
  return n
end

-- The circles: missing kinds in the pale red of the Facilities button (the
-- build button's number, a 0 in the list), what the hospital has in the
-- green of the Treatment button; each with a darker rim.
UIBuildRoom.COUNT_MISSING = {fill = {202, 142, 138}, rim = {120, 64, 62}}
UIBuildRoom.COUNT_HAVE = {fill = {73, 194, 93}, rim = {30, 96, 40}}

--! A filled circle of radius `r` around (`cx`, `cy`), one line at a time.
local function fill_circle(canvas, colour, cx, cy, r)
  for dy = -r, r - 1 do
    local yy = dy + 0.5
    local half = math.floor(math.sqrt(r * r - yy * yy) + 0.5)
    canvas:drawRect(colour, cx - half, cy + dy, half * 2, 1)
  end
end

--! The number `n` in a small circle of `style` (COUNT_MISSING, COUNT_HAVE)
--! around (`cx`, `cy`), in `font`.
function UIBuildRoom.drawCount(canvas, font, cx, cy, n, style)
  local s = TheApp.gfx:getUIScale()
  local r = 6 * s
  fill_circle(canvas, canvas:mapRGB(style.rim[1], style.rim[2], style.rim[3]), cx, cy, r)
  fill_circle(canvas, canvas:mapRGB(style.fill[1], style.fill[2], style.fill[3]), cx, cy, r - s)
  font:draw(canvas, tostring(n), cx - r, cy - r + s, 2 * r, 2 * r)
end

-- One character of UTF-8 text.
local CHAR = "[\1-\127\194-\244][\128-\191]*"

--! `name` made to fit `width` (screen pixels) in `font`, so the count beside
--! it stays clear (Jan, 2026-11-21): its last word cut to four letters and a
--! full stop ("General Diag."), or if that is still too long, as many
--! letters as fit and a full stop. Any language.
function UIBuildRoom.fitName(font, name, width)
  if font:sizeOf(name) <= width then return name end
  local head, last = name:match("^(.*%s)(%S+)$")
  if last then
    local short, n = "", 0
    for ch in last:gmatch(CHAR) do
      if n == 4 then break end
      short, n = short .. ch, n + 1
    end
    local try = head .. short .. "."
    if #short < #last and font:sizeOf(try) <= width then return try end
  end
  local cut = name
  while #cut > 1 do
    cut = cut:gsub(CHAR .. "$", "")
    local try = cut:gsub("[%s%.,]+$", "") .. "."
    if font:sizeOf(try) <= width then return try end
  end
  return name
end

function UIBuildRoom:draw(canvas, x, y)
  Window.draw(self, canvas, x, y)

  local s = TheApp.gfx:getUIScale()
  x, y = self.x * s + x, self.y * s + y
  self.white_font:draw(canvas, self.list_title, x + 163 * s, y + 18 * s)
  for i = 1, 4 do
    (i == self.category_index and self.blue_font or self.white_font)
      :draw(canvas, self.category_titles[i], x + 19 * s, y + cat_label_y[i] * s)
  end

  -- Each kind with how many of it the hospital has, at the line's end (a
  -- long name is shortened to leave the room for it).
  local counts = #self.list > 0 and UIBuildRoom.roomCounts(self.ui.app.world, self.ui.hospital) or {}
  self.fitted = self.fitted or {}
  local width = 103 * s
  for i, room in ipairs(self.list) do
    local font = i == self.list_hover_index and self.blue_font or self.white_font
    -- (A translated name is a string proxy: its text, as mp_sabotage does.)
    local name = tostring(room.name):gsub("^<LocalisedString> Current value:", "")
    local key = name .. "|" .. width .. (font == self.blue_font and "|b" or "|w")
    if not self.fitted[key] then self.fitted[key] = UIBuildRoom.fitName(font, name, width) end
    font:draw(canvas, self.fitted[key], x + 163 * s, y + 21 * s + i * 19 * s)
    local n = counts[room.id] or 0
    UIBuildRoom.drawCount(canvas, self.white_font, x + 275 * s, y + 24 * s + i * 19 * s, n,
        (n == 0 and not NOT_MISSED[room.id]) and UIBuildRoom.COUNT_MISSING or UIBuildRoom.COUNT_HAVE)
  end

  self.white_font:draw(canvas, self.cost_box, x + 163 * s, y + 232 * s)

  if self.preview_anim then
    self.preview_anim:setScaleFactor(s)
    self.preview_anim:draw(canvas, x + 70 * s, y + 200 * s)
  end
end

function UIBuildRoom:setCategory(index)
  if index == 1 then
    self.ui:tutorialStep(3, 2, 3)
  else
    self.ui:tutorialStep(3, 3, 2)
  end
  self.category_index = index
  self:updateBuildableRooms()
  self.list_title = _S.build_room_window.pick_room_type
  self.list = self.category_rooms[index]

  local last = #self.list + 5
  for i = 5, 14 do
    self.buttons[i].enabled = i < last
    if i < last then
      self.buttons[i]:setTooltip(self.list[i - 4].tooltip)
    else
      self.buttons[i]:setTooltip()
    end
  end
end

function UIBuildRoom:buildRoom(index)
  local hosp = self.ui.hospital
  local world = self.ui.app.world

  if index == 1 then self.ui:tutorialStep(3, 3, 4) end

  local cost = world.free_build_mode and 0 or
      hosp.research.research_progress[self.list[index]].build_cost
  if world.free_build_mode or hosp.balance >= cost then
    -- Close any full screen window currently open.
    local fullscreen = self.ui:getWindow(UIFullscreen)
    if fullscreen then
      fullscreen:close()
    end
    local edit_dlg = UIEditRoom(self.ui, self.list[index])
    self.ui:addWindow(edit_dlg)
  else
    -- give visual warning that player doesn't have enough $ to build
    self.ui.adviser:say(_A.warnings.money_very_low_take_loan, false, true)
    self.ui:playSound("Wrong2.wav")
  end
end

function UIBuildRoom:onMouseMove(x, y, dx, dy)
  local repaint = Window.onMouseMove(self, x, y, dx, dy)

  local s = TheApp.gfx:getUIScale()
  local hover_idx = 0
  if 156 * s <= x and x < 287 * s and 31 * s <= y and y < 226 * s then
    for i = 5, 14 do
      local btn = self.buttons[i]
      if btn.enabled and btn.x * s <= x and x < btn.r * s and btn.y * s <= y and y < btn.b * s then
        hover_idx = i - 4
        break
      end
    end
  end

  if hover_idx ~= self.list_hover_index then
    if self.hover_sound then
      self.ui:stopSound(self.hover_sound)
    end
    self.hover_sound = self.ui:playSound("HLight5.wav")
    if hover_idx == 0 then
      self.cost_box = _S.build_room_window.cost .. "0"
      self.preview_anim = false
    else
      local hosp = self.ui.hospital
      local world = self.ui.app.world
      local cost = world.free_build_mode and 0 or
          hosp.research.research_progress[self.list[hover_idx]].build_cost
      self.cost_box = _S.build_room_window.cost .. cost
      self.preview_anim = TH.animation()
      self.preview_anim:setAnimation(self.ui.app.anims, self.list[hover_idx].build_preview_animation)
    end
    self.list_hover_index = hover_idx
    repaint = true
  end

  return repaint
end

function UIBuildRoom:close()
  self.ui:tutorialStep(3, {2, 3}, 1)
  return Window.close(self)
end

function UIBuildRoom:afterLoad(old, new)
  Window.afterLoad(self, old, new)

  if old < 236 then
    local selected_label_color = { red = 40, green = 40, blue = 250 }
    self.white_font = TheApp.gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil, { apply_ui_scale = true })
    self.blue_font = TheApp.gfx:loadFontAndSpriteTable("QData", "Font02V", nil, nil, {ttf_color = selected_label_color, apply_ui_scale = true })
  end
end
