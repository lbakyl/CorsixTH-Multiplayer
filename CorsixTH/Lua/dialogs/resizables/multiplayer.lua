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

corsixth.require("mp_lobby")

--! Multiplayer lobby window, opened from the main menu. Shows one of three
--! views depending on the lobby state: connect to a server, pick or create a
--! room, or wait in a room until the host starts the game.
class "UIMultiplayer" (UIResizable)

---@class UIMultiplayer: UIResizable
---@operator call: UIMultiplayer
local UIMultiplayer = _G["UIMultiplayer"] ---@type UIMultiplayer

local col = {
  bg             = Colours.PanelDefault,
  button         = Colours.PanelDefault,
  setting        = Colours.Setting,
  setting_active = Colours.SettingActive,
  title          = Colours.Title,
  caption        = Colours.Caption,
  textbox        = Colours.Textbox,
}

local WIDTH = 420
local ROOM_ROWS = 6
-- The room list asks the server again every few seconds while it is shown.
local ROOMS_REFRESH_MS = 3000

local function view_of(lobby)
  if not lobby or lobby.state == "closed" or lobby.state == "connecting" then return "connect" end
  if lobby.state == "in_room" then return "room" end
  return "rooms"
end

local heights = {connect = 225, rooms = 435, room = 325}

-- The new room's settings as last sent with Create: shown again when the
-- player leaves the room or a game ends, forgotten on Disconnect.
local last_room_form = nil

function UIMultiplayer:UIMultiplayer(ui, status)
  local lobby = TheApp.mp_lobby
  self.view = view_of(lobby)
  -- A server that turned this game version away says where to get its own.
  self.download = self.view == "connect" and lobby and MultiplayerLobby.downloadOffer(lobby.error)
      or nil
  self:UIResizable(ui, WIDTH, heights[self.view] + (self.download and 35 or 0), col.bg)
  self.esc_closes = true
  self.resizable = false
  self.modal_class = "main menu"
  self.on_top = true
  self:setDefaultPosition(0.5, 0.25)
  self.default_button_sound = "selectx.wav"
  self.lobby = lobby
  self.seen_version = lobby and lobby.version or 0
  self.status_text = status or ""

  local S = _S.multiplayer_window
  local title
  if self.view == "connect" then
    title = S.caption
  elseif self.view == "rooms" then
    title = S.rooms_caption:format(lobby.address)
  else
    title = S.room_caption:format(lobby.room.room)
  end
  self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title):setLabel(title).lowered = true

  if self.view == "connect" then
    self:_buildConnect()
  elseif self.view == "rooms" then
    self:_buildRooms()
  else
    self:_buildRoom()
  end
  self.status_panel = self:addBevelPanel(20, heights[self.view] - 75, WIDTH - 40, 20, col.bg)
  self.status_panel:setLabel(self.status_text)
  self.status_panel.lowered = true
end

--! Replace this window by a fresh one for the current lobby state.
function UIMultiplayer:rebuild(status)
  local ui = self.ui
  self.rebuilding = true
  self:close()
  ui:addWindow(UIMultiplayer(ui, status))
end

function UIMultiplayer:setStatus(text)
  self.status_text = text or ""
  self.status_panel:setLabel(self.status_text)
end

local function textbox(window, x, y, w, text, limit, input, tooltip)
  local box
  box = window:addBevelPanel(x, y, w, 25, col.textbox, col.bg, col.bg)
    :setAutoClip(true)
    :makeTextbox(function() end, function() end)
    :allowedInput(input):characterLimit(limit):setText(text)
  if tooltip then box.panel:setTooltip(tooltip) end
  return box
end

local function label(window, x, y, w, text)
  local panel = window:addBevelPanel(x, y, w, 25, col.caption, col.bg, col.bg)
  panel:setLabel(text)
  panel.lowered = true
  return panel
end

local function button(window, x, y, w, text, callback, tooltip)
  local b = window:addBevelPanel(x, y, w, 30, col.button):setLabel(text)
      :makeButton(0, 0, w, 30, nil, callback)
  if tooltip then b:setTooltip(tooltip) end
  return b
end

-- Connect view ----------------------------------------------------------------

--! The public servers offered on the connect view (eu2 is the default the
--! first time: test builds are played there).
UIMultiplayer.SERVERS = {
  {label = "server_eu1", address = "eu1.bachelor-tech.com:47800"},
  {label = "server_eu2", address = "eu2.bachelor-tech.com:47800"},
}

function UIMultiplayer:_buildConnect()
  local S, T = _S.multiplayer_window, _S.tooltip.multiplayer_window
  local config = TheApp.config
  local address = (config.multiplayer_server ~= "" and config.multiplayer_server) or
      UIMultiplayer.SERVERS[2].address
  local name = (config.player_name ~= "" and config.player_name) or os.getenv("USER")
      or os.getenv("USERNAME") or "Player"
  label(self, 20, 45, 130, S.server)
  self.address_box = textbox(self, 155, 45, WIDTH - 175, address, 60, {"all"}, T.server)
  label(self, 20, 75, 130, S.name)
  self.name_box = textbox(self, 155, 75, WIDTH - 175, name, 15, {"alpha", "numbers", "misc"}, T.name)
  -- The public servers, one click each (the address can still be typed).
  local half = math.floor((WIDTH - 185) / 2)
  for i, server in ipairs(UIMultiplayer.SERVERS) do
    button(self, 155 + (i - 1) * (half + 10), 108, half, S[server.label], function(window)
      window.address_box:setText(server.address)
    end, T[server.label])
  end
  button(self, 20, 185, 180, S.connect, self.buttonConnect, T.connect)
  button(self, WIDTH - 200, 185, 180, S.back, self.close)
  if self.download then
    local release = self.download.release ~= "" and self.download.release or S.server_version
    button(self, 20, 220, WIDTH - 40, S.download:format(release), self.buttonDownload, T.download)
  end
end

function UIMultiplayer:buttonDownload()
  openURL(self.download.url)
end

function UIMultiplayer:buttonConnect()
  local S = _S.multiplayer_window
  local address, name = self.address_box.text, self.name_box.text
  self:_stopConnecting()
  -- The window keeps working meanwhile (onTick polls); at most 10 seconds for
  -- a server that does not answer (a wrong address).
  local connecting, err = MultiplayerLobby.startConnect(address, name, 10)
  if not connecting then
    self:setStatus(err)
    return
  end
  self.connecting = connecting
  self.connecting_address = address
  self:setStatus(S.connecting:format(address))
end

function UIMultiplayer:_stopConnecting()
  if self.connecting then MultiplayerTransport.cancelJoin(self.connecting.join) end
  self.connecting = nil
end

--! The connection is made: the lobby takes over (the window shows the rooms
--! once the server has answered).
function UIMultiplayer:_connected(lobby, address, name)
  TheApp.mp_lobby = lobby
  self.lobby = lobby
  TheApp.config.multiplayer_server = address
  if name:find("%S") then TheApp.config.player_name = name end
  TheApp:saveConfig()
end

-- Room list view ----------------------------------------------------------------

function UIMultiplayer:_buildRooms()
  local S, T = _S.multiplayer_window, _S.tooltip.multiplayer_window
  local lobby = self.lobby
  self.selected_room = nil
  -- A row for each room shown; the list is filled in by _updateRooms, also
  -- when it comes again from the server (every few seconds), without
  -- disturbing the rest of the window.
  self.room_rows = {}
  for i = 1, ROOM_ROWS do
    self.room_rows[i] = self:addBevelPanel(20, 40 + (i - 1) * 27, WIDTH - 40, 25, col.setting, nil, nil, nil,
        col.setting_active)
        :makeToggleButton(0, 0, WIDTH - 40, 25, nil, function(window, state, btn)
          window:selectRoom(i, state, btn)
        end)
  end
  self.rooms_shown = nil
  self:_updateRooms()
  self.next_rooms_refresh = MultiplayerSession.defaultClock()() + ROOMS_REFRESH_MS
  local y = 40 + ROOM_ROWS * 27 + 5
  label(self, 20, y, 110, S.password)
  self.password_box = textbox(self, 135, y, 135, "", 20, {"alpha", "numbers", "misc"}, T.password)
  button(self, 280, y - 2, 60, S.join, self.buttonJoin)
  button(self, 345, y - 2, WIDTH - 365, S.refresh, self.buttonRefresh)

  y = y + 35
  label(self, 20, y, 110, S.new_room)
  local form = last_room_form or {}
  if form.password then self.password_box:setText(form.password) end
  self.room_name_box = textbox(self, 135, y, WIDTH - 155, form.room or (lobby.name or "My") .. "'s room", 20,
      {"alpha", "numbers", "misc"})
  y = y + 30
  -- (Who shares a hospital and who races whom is picked in the room: each
  -- player's colour and team. `new_mode` is only for scripted tests: a
  -- preset of the newcomers' colours and teams.)
  self.new_mode = form.mode
  self.new_level = form.level or 1
  self.new_max = form.max or 2
  self.level_button = button(self, 20, y, 180, S.level:format(self.new_level), self.buttonLevel, T.level)
  self.max_button = button(self, 205, y, WIDTH - 225, S.players:format(self.new_max), self.buttonMax, T.players)
  -- A new game, or a saved multiplayer game picked in the Load MP game
  -- window (x: a new game again).
  self.saves = nil
  self.continue_index = 0
  self.continue_button = button(self, 20, y + 35, WIDTH - 40, S.load_game, self.buttonContinue,
      T.continue_game)
  self.new_game_button = button(self, WIDTH - 50, y + 35, 30, "x", self.buttonNewGame, T.new_game)
  self.new_game_button:setVisible(false)
  if form.continue_path then self:_continueSave(form.continue_path) end
  y = heights.rooms - 50
  button(self, 20, y, 180, S.create, self.buttonCreate)
  button(self, WIDTH - 200, y, 180, S.disconnect, self.buttonDisconnect)
end

--! Show the lobby's room list in the rows. The selected room stays selected
--! if it is still there.
function UIMultiplayer:_updateRooms()
  local S = _S.multiplayer_window
  local rooms = self.lobby.rooms
  local lines = {}
  for i = 1, math.min(ROOM_ROWS, #rooms) do
    local r = rooms[i]
    lines[i] = S.room_line:format(r.room, tonumber(r.players) or 0, tonumber(r.max) or 0,
        MultiplayerLobby.modeLabel(r.mode), r.level or "?",
        (r.locked == "1" and S.locked or "") .. (r.build_ok == "0" and S.other_build or "") ..
        (r["continue"] == "1" and S.saved_flag or ""))
  end
  -- (Labels are localised strings: compared by their text.)
  local shown = {}
  for i, line in ipairs(lines) do shown[i] = tostring(line) end
  shown = table.concat(shown, "\n")
  if shown == self.rooms_shown then return end
  self.rooms_shown = shown
  local still_there
  for i, row in ipairs(self.room_rows) do
    local r = rooms[i]
    if i <= #lines then
      row.panel_for_sprite:setLabel(lines[i])
      row:enable(true)
      row:setToggleState(r.room == self.selected_room)
      if r.room == self.selected_room then still_there = true end
    else
      row.panel_for_sprite:setLabel(i == 1 and S.no_rooms or "")
      row:setToggleState(false)
      row:enable(false)
    end
  end
  if not still_there then self.selected_room = nil end
end

function UIMultiplayer:selectRoom(index, state, btn)
  for _, b in ipairs(self.buttons) do
    if b ~= btn and b.is_toggle then b:setToggleState(false) end
  end
  local room = self.lobby.rooms[index]
  self.selected_room = state and room and room.room or nil
end

function UIMultiplayer:buttonJoin()
  if not self.selected_room then
    self:setStatus(_S.multiplayer_window.select_room)
    return
  end
  self.lobby:joinRoom(self.selected_room, self.password_box.text)
end

function UIMultiplayer:buttonRefresh() self.lobby:refreshRooms() end

--! The Level button: the level browser (UIMultiplayerLevels), which opens
--! this window again when done.
function UIMultiplayer:buttonLevel()
  self:_rememberForm()
  local ui = self.ui
  self.rebuilding = true
  self:close()
  ui:addWindow(UIMultiplayerLevels(ui, self.new_level, self.new_max))
end

--! The level browser chose a level (1-12: the campaign's for one shared
--! hospital; with several hospitals a level above the multiplayer levels
--! plays the last).
function UIMultiplayer.chooseLevel(level)
  last_room_form = last_room_form or {}
  last_room_form.level = level
end

--! For scripted tests: the level, as the browser would choose it.
function UIMultiplayer:setLevel(level)
  self.new_level = math.max(1, math.min(12, level))
  self.level_button.panel_for_sprite:setLabel(_S.multiplayer_window.level:format(self.new_level))
end

function UIMultiplayer:buttonMax()
  self.new_max = self.new_max % 4 + 1
  if self.new_max < 2 then self.new_max = 2 end
  self.max_button.panel_for_sprite:setLabel(_S.multiplayer_window.players:format(self.new_max))
end

--! The new room's settings so far (kept while the Load MP game window is
--! open, and for the next room).
function UIMultiplayer:_rememberForm()
  local save = self.saves and self.saves[self.continue_index]
  last_room_form = {room = self.room_name_box.text, password = self.password_box.text,
      mode = self.new_mode, level = self.new_level, max = self.new_max, continue_path = save and save.path}
end

--! Load MP game: the saved multiplayer games in a file list
--! (UILoadMultiplayerGame), which opens this window again when done.
function UIMultiplayer:buttonContinue()
  self:_rememberForm()
  local ui = self.ui
  self.rebuilding = true
  self:close()
  ui:addWindow(UILoadMultiplayerGame(ui))
end

--! The Load MP game window chose a save (its path): the new room continues
--! it (the lobby window shows it when it opens again).
function UIMultiplayer.chooseSave(path)
  last_room_form = last_room_form or {}
  last_room_form.continue_path = path
end

--! The new room continues this save (a path in the multiplayer saves): it
--! decides the level and the number of players.
function UIMultiplayer:_continueSave(path)
  local S = _S.multiplayer_window
  self.saves = MultiplayerLobby.listSaves()
  self.continue_index = 0
  for i, save in ipairs(self.saves) do
    if save.path == path then self.continue_index = i end
  end
  local save = self.saves[self.continue_index]
  self.continue_button.panel_for_sprite:setLabel(save and S.continue_save:format(save.label) or S.load_game)
  -- (As wide as the buttons above it; shorter with the x beside it.)
  local w = save and WIDTH - 75 or WIDTH - 40
  self.continue_button.panel_for_sprite.w = w
  self.continue_button.r = self.continue_button.x + w
  self.new_game_button:setVisible(save ~= nil)
  if save then
    self.new_level = tonumber(save.info.level) or 1
    self.new_max = math.max(2, tonumber(save.info.players) or 2)
    self.level_button.panel_for_sprite:setLabel(S.level:format(self.new_level))
    self.max_button.panel_for_sprite:setLabel(S.players:format(self.new_max))
  end
  for _, b in ipairs({self.level_button, self.max_button}) do b:enable(not save) end
  return save
end

--! x: a new game instead of the saved one.
function UIMultiplayer:buttonNewGame()
  self:_continueSave(nil)
end

--! For scripted tests: choose a saved game by label ("latest": the newest).
function UIMultiplayer:selectContinue(wanted)
  for _, save in ipairs(MultiplayerLobby.listSaves()) do
    if wanted == "latest" or save.label == wanted then
      return self:_continueSave(save.path)
    end
  end
end

function UIMultiplayer:buttonCreate()
  self:_rememberForm()
  self.lobby:createRoom({room = self.room_name_box.text, password = self.password_box.text,
      max = self.new_max, mode = self.new_mode, level = self.new_level, difficulty = "full",
      continue_save = self.saves and self.saves[self.continue_index]})
end

function UIMultiplayer:buttonDisconnect()
  last_room_form = nil
  self.lobby:disconnect()
  self:rebuild()
end

-- Room view -------------------------------------------------------------------

function UIMultiplayer:_buildRoom()
  local S, T = _S.multiplayer_window, _S.tooltip.multiplayer_window
  self.player_panels = {}
  -- Each player's colour (the hospital: the same colour, the same hospital)
  -- and team (the same team wins together) on buttons at the end of their
  -- line. (A continued game shows its saved ones, fixed.)
  local colour_w, team_w = 30, 70
  local line_w = WIDTH - 40 - colour_w - team_w - 10
  self.colour_buttons, self.team_buttons = {}, {}
  for i = 1, 4 do
    local y = 40 + (i - 1) * 27
    self.player_panels[i] = label(self, 20, y, line_w, "")
    -- The host clicks an empty place to add a bot there, or a bot to take
    -- it away again.
    self.player_panels[i]:makeButton(0, 0, line_w, 25, nil, function() self:clickPlace(i) end)
    self.colour_buttons[i] = self:addBevelPanel(WIDTH - 20 - team_w - 5 - colour_w, y, colour_w, 25, col.button)
        :makeButton(0, 0, colour_w, 25, nil, function() self:clickColour(i) end)
        :setTooltip(T.colour)
    self.team_buttons[i] = self:addBevelPanel(WIDTH - 20 - team_w, y, team_w, 25, col.button)
        :setLabel(""):makeButton(0, 0, team_w, 25, nil, function() self:clickTeam(i) end)
        :setTooltip(T.team)
  end
  self.summary_panel = label(self, 20, 40 + 4 * 27 + 5, WIDTH - 40, "")
  self.mode_panel = label(self, 20, 40 + 5 * 27 + 5, WIDTH - 40, "")
  self.hint_panel = label(self, 20, 40 + 6 * 27 + 5, WIDTH - 40, S.room_hint)
  local y = heights.room - 50
  -- The host starts the game; the others say they are ready. Both buttons
  -- sit in the same place, and only the one for this player is shown.
  self.ready_button = self:addBevelPanel(20, y, 120, 30, col.setting, nil, nil, nil, col.setting_active)
      :setLabel(S.ready):makeToggleButton(0, 0, 120, 30, nil, self.buttonReady):setTooltip(T.ready)
  self.start_button = button(self, 20, y, 120, S.start, self.buttonStart, T.start)
  button(self, WIDTH - 140, y, 120, S.leave, self.buttonLeave)
  self:_updateRoom()
end

function UIMultiplayer:_updateRoom()
  local S = _S.multiplayer_window
  local lobby = self.lobby
  local max = tonumber(lobby.room.max) or 2
  local bots = lobby:canAddBots()
  -- Bots the server is still starting take the first empty places.
  local starting = tonumber(lobby.summary and lobby.summary.starting) or 0
  for i = 1, 4 do
    local p = lobby.players[i]
    local text = ""
    if p and p.bot == "1" then
      text = S.bot_line:format(p.name, bots and S.bot_remove or "")
    elseif p then
      -- (The host is not asked whether they are ready.)
      text = S.player_line:format(p.name, p.owner == "1" and S.owner_mark or "", p.rtt or "?",
          p.owner == "1" and "" or (p.ready == "1" and S.is_ready or S.not_ready))
    elseif i <= max and starting > 0 then
      starting = starting - 1
      text = S.bot_starting
    elseif i <= max then
      text = bots and S.add_bot or S.waiting_player
    end
    self.player_panels[i]:setLabel(text)
    -- (Only one's own, and the host anybody's, in a new game.)
    local seated = p ~= nil and tonumber(p.colour) ~= nil
    local may = seated and lobby:isFreeRoom() and (lobby:isOwner() or p.peer == lobby.room.peer)
    local colour_button, team_button = self.colour_buttons[i], self.team_buttons[i]
    colour_button:setVisible(seated)
    colour_button:enable(may)
    team_button:setVisible(seated)
    team_button:enable(may)
    if seated then
      local rgb = MultiplayerSession.colourRGB(tonumber(p.colour))
      local panel = colour_button.panel_for_sprite
      panel:setColour({red = rgb[1], green = rgb[2], blue = rgb[3]})
      panel.disabled_colour = panel.colour -- (the colour shows when fixed too)
      colour_button:setTooltip(S.colour_names[tonumber(p.colour)] .. ": " .. _S.tooltip.multiplayer_window.colour)
      team_button.panel_for_sprite:setLabel(S.team_button:format(tonumber(p.team) or 1))
    end
  end
  local s = lobby.summary
  self.summary_panel:setLabel(s and S.recommendation:format(s.speed, s.latency or "?") or S.measuring)
  -- What the colours and teams make now, and the level it plays.
  local mode = s and s.mode or lobby.room.mode
  local level = tonumber(lobby.room.level) or 1
  local level_text = S.level:format(level)
  local mp_count = corsixth.require("mp_levels").COUNT
  if MultiplayerLobby.hospitalEach(mode) and level > mp_count then
    level_text = S.mp_level:format(level_text, mp_count)
  end
  self.mode_panel:setLabel(MultiplayerLobby.modeLabel(mode) .. ", " .. level_text ..
      (lobby.room["continue"] == "1" and (", " .. S.continuing:format((lobby.room.date or ""):gsub("T.*", ""))) or ""))
  local owner = lobby:isOwner()
  self.start_button:setVisible(owner)
  self.start_button:enable(owner)
  self.ready_button:setVisible(not owner)
  self.ready_button:enable(not owner)
end

--! A place in the room's player list was clicked: the host adds a bot to an
--! empty place or takes a bot away.
function UIMultiplayer:clickPlace(i)
  local lobby = self.lobby
  if not lobby:canAddBots() then return end
  local p = lobby.players[i]
  if p and p.bot == "1" then
    lobby:removeBot(i)
  elseif not p and i <= (tonumber(lobby.room.max) or 2) then
    lobby:addBot()
  end
end

--! A player's colour button: the next colour (a colour somebody has means
--! sharing their hospital); the host may change anybody's.
function UIMultiplayer:clickColour(i)
  local lobby = self.lobby
  local p = lobby.players[i]
  if not (p and lobby:isFreeRoom()) then return end
  local colour = (tonumber(p.colour) or 1) % MultiplayerLobby.COLOURS + 1
  if p.peer == lobby.room.peer then
    lobby:setSeat(colour, nil)
  elseif lobby:isOwner() then
    lobby:setSeat(colour, nil, i)
  end
end

--! A player's team button: the next team (for everybody of their colour);
--! the host may change anybody's.
function UIMultiplayer:clickTeam(i)
  local lobby = self.lobby
  local p = lobby.players[i]
  if not (p and lobby:isFreeRoom()) then return end
  local team = (tonumber(p.team) or 1) % MultiplayerLobby.TEAMS + 1
  if p.peer == lobby.room.peer then
    lobby:setSeat(nil, team)
  elseif lobby:isOwner() then
    lobby:setSeat(nil, team, i)
  end
end

function UIMultiplayer:buttonReady(state)
  self.lobby:setReady(state)
end

function UIMultiplayer:buttonStart()
  if self.lobby:isOwner() then self.lobby:startGame() end
end

function UIMultiplayer:buttonLeave()
  self.lobby:leaveRoom()
end

-- Updates ---------------------------------------------------------------------

function UIMultiplayer:onTick()
  if self.connecting then
    local lobby, err = MultiplayerLobby.pollConnect(self.connecting)
    if lobby ~= nil then
      local name = self.connecting.name
      self.connecting = nil
      if lobby then
        self:_connected(lobby, self.connecting_address, name)
      else
        self:setStatus(err)
      end
    end
  end
  local lobby = self.lobby
  if lobby then
    lobby:poll()
    if lobby.state == "in_game" then return end -- the game UI replaced this one
    if lobby.version ~= self.seen_version then
      self.seen_version = lobby.version
      local status = lobby.error and lobby.error.text or nil
      -- Theme Hospital files of another edition: say what to do (once).
      if lobby.error and lobby.error.code == "data_mismatch" and lobby.data_help_shown ~= lobby.error then
        lobby.data_help_shown = lobby.error
        self.ui:addWindow(UIInformation(self.ui, {_S.multiplayer_window.data_mismatch_help}))
      end
      local download = self.view == "connect" and MultiplayerLobby.downloadOffer(lobby.error)
      if view_of(lobby) ~= self.view or (download and not self.download) then
        self:rebuild(status)
        return
      end
      if self.view == "room" then self:_updateRoom() end
      if self.view == "rooms" then self:_updateRooms() end
      if status then self:setStatus(status) end
    end
    -- The room list keeps itself up to date.
    if self.view == "rooms" and self.next_rooms_refresh then
      local now = MultiplayerSession.defaultClock()()
      if now >= self.next_rooms_refresh then
        self.next_rooms_refresh = now + ROOMS_REFRESH_MS
        lobby:refreshRooms()
      end
    end
  end
  UIResizable.onTick(self)
end

function UIMultiplayer:close()
  self:_stopConnecting()
  UIResizable.close(self)
  -- This window took the main menu's place; give it back (not when a game
  -- has just started and replaced the whole screen).
  if not self.rebuilding and not TheApp.world and not (self.lobby and self.lobby.state == "in_game") then
    self.ui:addWindow(UIMainMenu(self.ui))
  end
end
