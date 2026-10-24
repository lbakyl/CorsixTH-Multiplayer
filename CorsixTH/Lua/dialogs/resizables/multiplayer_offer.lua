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

--! Multiplayer co-op: an offer from another player (a member of staff or a
--! referred patient), opened from the purple icon in the bottom panel. The
--! answer is a fax_choice command for the offer's message (1 = accept,
--! 2 = decline); see MultiplayerSession.resolveOffer.
class "UIMultiplayerOffer" (UIResizable)

---@type UIMultiplayerOffer
local UIMultiplayerOffer = _G["UIMultiplayerOffer"]

-- Purple, like the icon.
local col = {
  bg      = {red = 96, green = 52, blue = 140},
  title   = {red = 70, green = 30, blue = 108},
  caption = {red = 120, green = 74, blue = 168},
  button  = {red = 140, green = 90, blue = 190},
}

local WIDTH = 380
local FACE_W = 65

local function pct(value)
  return math.floor((tonumber(value) or 0) * 100 + 0.5)
end

--! The lines describing the offered person.
local function describe(entity, offer)
  local S = _S.multiplayer_window
  if not entity or (offer.kind == "staff" and entity.fired) or entity.going_home or entity.dead then
    return {S.offer_gone_note:format(offer.name)}
  end
  local lines = {}
  if offer.kind == "staff" then
    local profile = entity.profile
    local job = StaffProfile.translateStaffClass(entity.humanoid_class) or entity.humanoid_class
    if entity.humanoid_class == "Doctor" then
      -- (Names and titles are localised strings: joined with .., not tostring.)
      job = profile.is_consultant and _S.staff_title.consultant or
          (profile.is_junior and _S.staff_title.junior or _S.staff_title.doctor)
      if (profile.is_surgeon or 0) >= 1 then job = job .. ", " .. _S.staff_title.surgeon end
      if (profile.is_psychiatrist or 0) >= 1 then job = job .. ", " .. _S.staff_title.psychiatrist end
      if (profile.is_researcher or 0) >= 1 then job = job .. ", " .. _S.staff_title.researcher end
    end
    lines[#lines + 1] = profile:getFullName()
    lines[#lines + 1] = S.offer_job:format(job)
    lines[#lines + 1] = S.offer_ability:format(pct(profile.skill))
    lines[#lines + 1] = S.offer_wage:format(profile.wage)
    lines[#lines + 1] = S.offer_tired:format(pct(entity:getAttribute("fatigue")))
    lines[#lines + 1] = S.offer_happy:format(pct(entity:getAttribute("happiness")))
    if entity.quitting_in then lines[#lines + 1] = S.offer_raise end
  else
    if entity.diagnosed and entity.disease then
      lines[#lines + 1] = S.offer_illness:format(entity.disease.name)
    else
      lines[#lines + 1] = S.offer_not_diagnosed:format(pct(entity.diagnosis_progress))
    end
    lines[#lines + 1] = S.offer_health:format(pct(entity:getAttribute("health")))
    lines[#lines + 1] = S.offer_happy:format(pct(entity:getAttribute("happiness")))
  end
  return lines
end

function UIMultiplayerOffer:UIMultiplayerOffer(ui, icon)
  local S = _S.multiplayer_window
  self.icon = icon
  self.message = icon.message
  self.offer = self.message.mp_offer
  local world = ui.app.world
  self.world = world
  self.entity = world:getEntityById(self.offer.entity)
  local from = world.hospitals[self.offer.from]
  local lines = describe(self.entity, self.offer)
  local face = self.offer.kind == "staff" and self.entity and self.entity.profile
  local height = 40 + 22 + math.max(#lines * 22, face and 80 or 0) + 60
  self:UIResizable(ui, WIDTH, height, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.25)
  self.default_button_sound = "selectx.wav"
  if face then
    self.face_parts = ui.app.gfx:loadRaw("Face01V", 65, 1350, nil, "Data", "MPalette.dat", false,
        { flags = DrawFlags.Nearest })
  end

  self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title)
      :setLabel(S.offer_caption:format(from and from.name or "?")).lowered = true
  self:addBevelPanel(20, 36, WIDTH - 40, 20, col.caption)
      :setLabel((self.offer.kind == "staff" and S.offer_staff_line or S.offer_patient_line)
      :format(from and from.name or "?")).lowered = true
  local x = face and (20 + FACE_W + 10) or 20
  for i, line in ipairs(lines) do
    self:addBevelPanel(x, 40 + i * 22, WIDTH - 20 - x, 20, col.caption):setLabel(line).lowered = true
  end

  local y = height - 45
  local w = math.floor((WIDTH - 40 - 30) / 4)
  self:addBevelPanel(20, y, w, 30, col.button):setLabel(S.offer_accept)
      :makeButton(0, 0, w, 30, nil, self.accept)
  self:addBevelPanel(30 + w, y, w, 30, col.button):setLabel(S.offer_decline)
      :makeButton(0, 0, w, 30, nil, self.decline)
  self:addBevelPanel(40 + 2 * w, y, w, 30, col.button):setLabel(S.offer_show)
      :makeButton(0, 0, w, 30, nil, self.show)
  self:addBevelPanel(50 + 3 * w, y, w, 30, col.button):setLabel(S.offer_later)
      :makeButton(0, 0, w, 30, nil, self.close)
end

function UIMultiplayerOffer:draw(canvas, x_, y_)
  UIResizable.draw(self, canvas, x_, y_)
  local entity = self.entity
  if self.face_parts and entity and entity.profile then
    local s = TheApp.gfx:getUIScale()
    local x, y = self.x * s + x_, self.y * s + y_
    entity.profile:drawFace(canvas, x + 20 * s, y + 62 * s, self.face_parts, s) -- Portrait
  end
end

--! Answer the offer: a command, so every peer resolves it at the same step.
function UIMultiplayerOffer:_answer(choice)
  local session = TheApp.mp_session
  if session and self.icon.mp_id then
    session:issue({kind = "fax_choice", msg = self.icon.mp_id, choice = choice})
  end
  self:close()
end

function UIMultiplayerOffer:accept() self:_answer(1) end
function UIMultiplayerOffer:decline() self:_answer(2) end

--! Centre the view on the offered person (in the other player's hospital).
function UIMultiplayerOffer:show()
  local entity = self.entity
  if not (entity and entity.tile_x and entity.th) then return end
  local px, py = self.ui.app.map:WorldToScreen(entity.tile_x, entity.tile_y)
  local dx, dy = entity.th:getPosition()
  self.ui:scrollMapTo(px + dx, py + dy)
end

--! The choice is made (UIMessage:removeMessage with a choice, on every peer).
function UIMultiplayerOffer:choice(choice_number)
  local choices = self.message.choices
  local choice = choices and choices[choice_number] and choices[choice_number].choice
  MultiplayerSession.resolveOffer(self.world, self.offer, choice == "mp_offer_accept")
  self.icon:removeMessage()
  self:close()
end

function UIMultiplayerOffer:close()
  if self.icon.fax == self then
    self.icon.fax = nil
    self.icon:adjustToggle()
  end
  return UIResizable.close(self)
end

--------------------------------------------------------------------------------

--! Multiplayer co-op: choose the hospital to refer a patient to (only with
--! more than one other player; with one, UIMultiplayerChooseHospital.start
--! sends the referral straight away).
class "UIMultiplayerChooseHospital" (UIResizable)

---@type UIMultiplayerChooseHospital
local UIMultiplayerChooseHospital = _G["UIMultiplayerChooseHospital"]

--! The other players' hospitals (index list).
local function other_hospitals(ui)
  local world = ui.app.world
  local list = {}
  local n = world.mp_coop and world.mp_coop.players or 0
  for i = 1, n do
    if world.hospitals[i] and world.hospitals[i] ~= ui.hospital then list[#list + 1] = i end
  end
  return list
end
UIMultiplayerChooseHospital.otherHospitals = other_hospitals

--! Send the referral of `patient` to hospital `index`. With a fax for the
--! patient (`fax` = {msg, wait}), that fax is answered with "wait".
local function refer(ui, patient, index, fax)
  local session = TheApp.mp_session
  if not session then return end
  session:issue({kind = "offer_patient", to = index, patient = patient.mp_id})
  if fax and fax.msg and fax.wait then
    session:issue({kind = "fax_choice", msg = fax.msg, choice = fax.wait})
  end
end

--! Refer a patient: straight away with one other player, else ask which.
--!param fax (table) optional {msg, wait}: the patient's fax to answer "wait"
function UIMultiplayerChooseHospital.start(ui, patient, fax)
  local ok, why = MultiplayerSession.referable(patient)
  if not ok then
    if ui.adviser then ui.adviser:say({text = MultiplayerSession.rejection_texts.offer_patient[why] or why,
        priority = 10}) end
    return
  end
  local others = other_hospitals(ui)
  if #others == 0 then
    if ui.adviser then ui.adviser:say({text = _S.multiplayer_window.trade_alone, priority = 10}) end
  elseif #others == 1 then
    refer(ui, patient, others[1], fax)
  else
    ui:addWindow(UIMultiplayerChooseHospital(ui, patient, fax, others))
  end
end

function UIMultiplayerChooseHospital:UIMultiplayerChooseHospital(ui, patient, fax, others)
  local S = _S.multiplayer_window
  self.patient = patient
  self.fax = fax
  local height = 40 + #others * 36 + 50
  self:UIResizable(ui, 300, height, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.3)
  self.default_button_sound = "selectx.wav"
  self:addBevelPanel(20, 10, 260, 20, col.title):setLabel(S.refer_choose).lowered = true
  local world = ui.app.world
  for i, index in ipairs(others) do
    local b = self:addBevelPanel(20, 4 + i * 36, 260, 30, col.button):setLabel(world.hospitals[index].name)
        :makeButton(0, 0, 260, 30, nil, self.choose)
    b.mp_index = index
  end
  self:addBevelPanel(160, height - 40, 120, 30, col.button):setLabel(S.trade_close)
      :makeButton(0, 0, 120, 30, nil, self.close)
end

function UIMultiplayerChooseHospital:choose(_, button)
  refer(self.ui, self.patient, button.mp_index, self.fax)
  self:close()
end
