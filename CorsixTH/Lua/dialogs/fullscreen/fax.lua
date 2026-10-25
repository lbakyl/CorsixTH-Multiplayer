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

corsixth.require("announcer")

local AnnouncementPriority = _G["AnnouncementPriority"]

class "UIFax" (UIFullscreen)

---@type UIFax
local UIFax = _G["UIFax"]

function UIFax:UIFax(ui, icon)
  self:UIFullscreen(ui)
  local gfx = ui.app.gfx
  self.background = gfx:loadRaw("Fax01V", 640, 480, "QData", "QData", "Fax01V.pal", true)
  local palette = gfx:getPalette("Fax01V.pal")
  self.panel_sprites = gfx:loadSpriteTable("QData", "Fax02V", true, palette)
  self.fax_font = gfx:loadFontAndSpriteTable("QData", "Font51V", false, palette, { apply_ui_scale = true })
  self.icon = icon
  self.message = icon.message or {}
  self.owner = icon.owner

  self.code = ""

  -- Add choice buttons
  local choices = self.message.choices
  self.choice_buttons = {}
  local orig_y = 175
  if choices then
    for i = 1, #choices do
      local y = orig_y + ((i-1) + (3-#choices)) * 48
      local choice = choices[i].choice
      -- NB: both nil and true result in enabled; also handle old "disabled" choice
      local enabled = (choices[i].enabled ~= false) and (choice ~= "disabled")
      local --[[persistable:fax_choice_button]] function callback()
        self:buttonChoice(i)
      end
      self.choice_buttons[i] = self:addPanel(17, 492, y, nil, nil, true, DrawFlags.Nearest)
        :makeButton(0, 0, 43, 43, 18, callback)
        :setDisabledSprite(19)
        :enable(enabled)
    end
  end

  -- Close button
  self:addPanel(0, 598, 440):makeButton(0, 0, 26, 26, 16, self.close):setTooltip(_S.tooltip.fax.close)

  self:addPanel(0, 471, 349):makeButton(0, 0, 87, 20, 14, self.cancel) -- Cancel code button
  self:addPanel(0, 474, 372):makeButton(0, 0, 91, 27, 15, self.validate) -- Validate code button

  self:addPanel(0, 168, 348):makeButton(0, 0, 43, 10, 1, self.correct) -- Correction button

  local function button(char)
    return --[[persistable:fax_button]] function() self:appendNumber(char) end
  end

  self:addPanel(0, 220, 348):makeButton(0, 0, 43, 10,  2, button("1")):setSound("Fax_1.wav")
  self:addPanel(0, 272, 348):makeButton(0, 0, 44, 10,  3, button("2")):setSound("Fax_2.wav")
  self:addPanel(0, 327, 348):makeButton(0, 0, 43, 10,  4, button("3")):setSound("Fax_3.wav")

  self:addPanel(0, 219, 358):makeButton(0, 0, 44, 10,  5, button("4")):setSound("Fax_4.wav")
  self:addPanel(0, 272, 358):makeButton(0, 0, 43, 10,  6, button("5")):setSound("Fax_5.wav")
  self:addPanel(0, 326, 358):makeButton(0, 0, 44, 10,  7, button("6")):setSound("Fax_6.wav")

  self:addPanel(0, 218, 370):makeButton(0, 0, 44, 11,  8, button("7")):setSound("Fax_7.wav")
  self:addPanel(0, 271, 370):makeButton(0, 0, 44, 11,  9, button("8")):setSound("Fax_8.wav")
  self:addPanel(0, 326, 370):makeButton(0, 0, 44, 11, 10, button("9")):setSound("Fax_9.wav")

  self:addPanel(0, 217, 382):makeButton(0, 0, 45, 12, 11, button("*"))
  self:addPanel(0, 271, 382):makeButton(0, 0, 44, 11, 12, button("0")):setSound("Fax_0.wav")
  self:addPanel(0, 326, 382):makeButton(0, 0, 44, 11, 13, button("#"))
end

-- Faxes pause the game. Not in multiplayer: there a pause on one computer
-- stops everybody's game. The fax's message keeps its timer instead, and
-- when it runs out the default answer is taken (on every computer alike).
function UIFax:mustPause()
  return not TheApp.mp_session
end

function UIFax:updateChoices()
  local choices = self.message.choices
  for i, button in ipairs(self.choice_buttons) do
    -- NB: both nil and true result in enabled; also handle old "disabled" choice
    local enabled = (choices[i].enabled ~= false) and (choices[i].choice ~= "disabled")
    button:enable(enabled)
  end
end

function UIFax:draw(canvas, x, y)
  local s = TheApp.gfx:getUIScale()
  canvas:scale(s, "bitmap")
  self.background:draw(canvas, self.x * s + x, self.y * s + y)
  canvas:scale(1, "bitmap")
  UIFullscreen.draw(self, canvas, x, y)
  x, y = self.x * s + x, self.y * s + y

  if self.message then
    local last_y = y + 40 * s
    for _, message in ipairs(self.message) do
      last_y = self.fax_font:drawWrapped(canvas, message.text, x + 190 * s,
                                         last_y + (message.offset or 0), 360 * s,
                                         "center")
    end
    local choices = self.message.choices
    if choices then
      local orig_y = y + 190 * s
      for i = 1, #choices do
        last_y = orig_y + ((i - 1) + (3 - #choices)) * 48 * s
        self.fax_font:drawWrapped(canvas, choices[i].text, x + 190 * s,
                                  last_y + (choices[i].offset or 0), 300 * s)
      end
    end
  end
end

--! The player clicked a choice. In multiplayer every peer applies it at the
--! same step (fax_choice command); the fax closes here meanwhile.
function UIFax:buttonChoice(choice_number)
  local choices = self.message.choices
  if choices and choices[choice_number] and choices[choice_number].choice == "mp_refer" then
    -- Multiplayer co-op: refer the patient to another player (which one is
    -- chosen first if there are several); the fax is answered "wait".
    local wait
    for i, c in ipairs(choices) do
      if c.choice == "wait" then wait = i end
    end
    UIMultiplayerChooseHospital.start(self.ui, self.owner, {msg = self.icon.mp_id, wait = wait})
    self:close()
    return
  end
  if MultiplayerSession.actionsAreCommands() and self.icon.mp_id then
    TheApp.mp_session:issue({kind = "fax_choice", msg = self.icon.mp_id, choice = choice_number})
    self:close()
    return
  end
  self:choice(choice_number)
end

--A choice was made for the fax.
--!param choice_number (integer) Number of the choice
function UIFax:choice(choice_number)
  local choices = self.message.choices
  local choice, additionalInfo
  if choices and choice_number >= 1 and choice_number <= #choices then
    choice = choices[choice_number].choice
    additionalInfo = choices[choice_number].additionalInfo
  else
    choice = "disabled"
    additionalInfo = nil
  end

  -- The hospital the fax is for (multiplayer co-op: maybe not this player's).
  local hospital = self.icon.hospital or self.ui.hospital
  local owner = self.owner
  -- Multiplayer co-op: an offer from another player answered (or timed out).
  if choice == "mp_offer_accept" or choice == "mp_offer_decline" then
    MultiplayerSession.resolveOffer(self.ui.app.world, self.message.mp_offer, choice == "mp_offer_accept")
    self.icon:removeMessage()
    self:close()
    return
  end
  if owner and owner.humanoid_class then
    local humanoid = owner
    -- A choice was made, the patient is no longer waiting for a decision
    humanoid:setMood("patient_wait", "deactivate")
    humanoid.message_callback = nil
    if choice == "send_home" then
      humanoid:goHome("kicked")
      if humanoid.diagnosed then
        -- No treatment rooms
        humanoid:setDynamicInfoText(_S.dynamic_info.patient.actions.no_treatment_available)
      else
        -- No diagnosis rooms
        humanoid:setDynamicInfoText(_S.dynamic_info.patient.actions.no_diagnoses_available)
      end
    elseif choice == "wait" then
      -- Wait two months before going home
      humanoid.waiting = 60
      if humanoid.diagnosed then
        -- Waiting for treatment room
        humanoid:setDynamicInfoText(_S.dynamic_info.patient.actions.waiting_for_treatment_rooms)
      else
        -- Waiting for diagnosis room
        humanoid:setDynamicInfoText(_S.dynamic_info.patient.actions.waiting_for_diagnosis_rooms)
      end
    elseif choice == "guess_cure" then
      humanoid:setDiagnosed()
      if humanoid:agreesToPay(humanoid.disease.id) then
        humanoid:setNextAction(SeekRoomAction(humanoid.disease.treatment_rooms[1]):enableTreatmentRoom())
      else
        humanoid:goHome("over_priced", humanoid.disease.id)
      end
    elseif choice == "research" then
      humanoid:unregisterCallbacks()
      humanoid:setMood("idea", "activate")
      humanoid:setNextAction(SeekRoomAction("research"))
    end
  end
  local vip_ignores_refusal = math.random(1, 2)
  if choice == "accept_emergency" then
    self.ui.app.world:newObject("helicopter", "north", nil, nil, nil, hospital)
    if self.ui.app.world.mp_coop then
      -- The countdown runs in the simulation; the watch only shows it, to
      -- the player whose emergency it is.
      hospital.mp_emergency_timer = World.newCountdown(52)
      if hospital == self.ui.hospital then
        self.ui:addWindow(UIWatch(self.ui, "emergency", hospital))
      end
    else
      self.ui:addWindow(UIWatch(self.ui, "emergency", hospital))
    end
  elseif choice == "refuse_emergency" then
    -- Multiplayer co-op asks the hospital whether an emergency is under way.
    if self.ui.app.world.mp_coop then hospital.emergency = nil end
    self.ui.app.world:nextEmergency()
  -- VIP may choose to visit anyway if he is refused too often
  elseif (hospital.vip_declined > 2 and vip_ignores_refusal == 2) and choice == "refuse_vip" then
    hospital.num_vips = hospital.num_vips + 1
    self.ui.app.world:spawnVIP(additionalInfo.name, hospital)
    hospital.vip_declined = 0
  elseif choice == "refuse_vip" then
    self.ui.app.world:nextVip() -- don't start an inspection
    hospital.vip_declined = hospital.vip_declined + 1
  elseif choice == "accept_vip" then
    hospital.num_vips = hospital.num_vips + 1
    self.ui.app.world:spawnVIP(additionalInfo.name, hospital)
  elseif choice == "declare_epidemic" then
    local epidemic = hospital.epidemic
    if epidemic then
      epidemic:resolveDeclaration()
    end
  elseif choice == "cover_up_epidemic" then
    local epidemic = hospital.epidemic
    if epidemic then
      epidemic:startCoverUp()
    end
  elseif choice == "accept_new_level" then
    -- Set the new salary.
    hospital.player_salary = hospital.salary_offer
    if tonumber(self.ui.app.world.map.level_number) then
      local next_level = self.ui.app.world.map.level_number + 1
      if self.ui.app:loadLevel(next_level, self.ui.app.map.difficulty, nil, nil,
          nil, nil, _S.errors.load_level_prefix) then
        self.ui.app.moviePlayer:playAdvanceMovie(next_level)
      end
    else
      local campaign_info = self.ui.app.world.campaign_info
      for i, level in ipairs(campaign_info.levels) do
        local filename = self.ui.app.world.map.level_filename or self.ui.app.world.map.level_number
        if filename == level then
          local level_info, _ = self.ui.app:readLevelFile(campaign_info.levels[i + 1], campaign_info.folder)
          if level_info then
            self.ui.app:loadLevel(level_info.path, nil, level_info.name,
                level_info.map_file, level_info.briefing, nil, _S.errors.load_level_prefix, campaign_info)
            if campaign_info.movie then
              local n = math.max(1, 12 - #campaign_info.levels + i)
              self.ui.app.moviePlayer:playAdvanceMovie(n)
            end
            break
          end
        end
      end
    end
  elseif choice == "return_to_main_menu" then
    if TheApp.mp_session then
      -- Multiplayer: the game ends for everybody, back to the lobby.
      TheApp.mp_session:finish({_S.multiplayer_window.level_won_end})
    else
      self.ui.app.moviePlayer:playWinMovie()
      self.ui.app:loadMainMenu()
    end
  elseif choice == "stay_on_level" then
    hospital.win_declined = true
  end
  self.icon:removeMessage()
  self:close()
end

function UIFax:cancel()
  self.code = ""
end

function UIFax:correct()
  if self.code ~= "" then
    self.code = string.sub(self.code, 1, -2) --Remove last character
  end
end

function UIFax:validate()
  if self.code == "" then
    return
  end
  local code = self.code
  self.code = ""
  if MultiplayerSession.blockUnsupported(self.ui) then return end -- cheat codes change the shared game
  local code_n = (tonumber(code) or 0) / 10^5
  local x = math.abs((code_n ^ 5.00001 - code_n ^ 5) * 10^5 - code_n ^ 5)
  local cheats = self.ui.hospital.hosp_cheats
  print("Code typed on fax:", code)
  if code == "24328" then
    -- Original game cheat code
    self.ui.adviser:say(_A.cheats.th_cheat)
    self.ui:addWindow(UICheats(self.ui))
  elseif code == "112" then
    -- simple, unobfuscated cheat for everyone :)
    -- not that critical, but we want to make to make sure it's played fairly soon
    self.ui:playAnnouncement("rand*.wav", AnnouncementPriority.Critical)

  -- Pass cheat code to the Cheats system to handle
  elseif not cheats:processCheatCode(x) then
    -- no valid cheat code entered
    self.ui:playSound("fax_no.wav")
    return
  -- else Cheat executed, nothing to do here
  end
  self.ui:playSound("fax_yes.wav")

  -- TODO: Other cheats (preferably with slight obfuscation, as above)
end

function UIFax:appendNumber(number)
  self.code = self.code .. number
end

function UIFax:close()
  self.icon.fax = nil
  self.icon:adjustToggle()
  UIFullscreen.close(self)
end

function UIFax:afterLoad(old, new)
  if old < 236 then
    local gfx = TheApp.gfx
    self.background = gfx:loadRaw("Fax01V", 640, 480, "QData", "QData", "Fax01V.pal", true)
    local palette = gfx:getPalette("Fax01V.pal")
    self.panel_sprites = gfx:loadSpriteTable("QData", "Fax02V", true, palette)
    self.fax_font = gfx:loadFontAndSpriteTable("QData", "Font51V", false, palette, { apply_ui_scale = true })
  end
  UIFullscreen.afterLoad(self, old, new)
  if old < 59 then
    -- self.choice_buttons added, changes to disabled buttons.
    -- Since it's hard to add retroactively, just close any opened fax window.
    self:close()
  end
end
