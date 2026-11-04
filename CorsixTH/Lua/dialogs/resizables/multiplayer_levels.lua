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

--! The multiplayer lobby's level browser (the Level button of a new room):
--! the levels by name, what each one is about (starting money, the goals,
--! special rules, the briefing) and a preview of its map with every player's
--! starting plot. Two lists: the multiplayer levels, for a game with several
--! hospitals, and the campaign's, for one shared hospital (the room's
--! colours decide which one is played). Choose takes the level back to the
--! lobby window, which opens again.
class "UIMultiplayerLevels" (UIResizable)

---@class UIMultiplayerLevels: UIResizable
---@operator call: UIMultiplayerLevels
local UIMultiplayerLevels = _G["UIMultiplayerLevels"] ---@type UIMultiplayerLevels

local col = {
  bg      = Colours.PanelDefault,
  button  = Colours.PanelDefault,
  title   = Colours.Title,
  caption = Colours.Caption,
  row     = Colours.Setting,
  active  = Colours.SettingActive,
}

local WIDTH, HEIGHT = 600, 440
local ROWS = 12
-- The preview: 2 pixels a tile on a 128 tile map (256 pixels; a bigger map
-- in the same space).
local MAP_X, MAP_Y, TILE = 200, 75, 2
local INFO_X = MAP_X + 128 * TILE + 10
local TEXT_Y, TEXT_ROWS = 340, 4
local SCROLL_W = 20

-- The preview's colours: each player's starting plot in their hospital's
-- colour (the building darker), land for sale grey, the rest of the town
-- green.
local GROUND, NATURE = {112, 160, 88}, {66, 112, 58}
local SALE_IN, SALE_OUT = {120, 120, 128}, {168, 168, 176}

--! A game string (or anything) as a plain Lua string.
local function plain(v)
  if type(v) == "userdata" then return require("TH").stringProxy._unwrap(v) end
  return tostring(v)
end

--! An amount with thousands separators ("150,000").
local function amount(n)
  local text = tostring(math.floor(n))
  while true do
    local done
    text, done = text:gsub("^(%d+)(%d%d%d)", "%1,%2")
    if done == 0 then return text end
  end
end

--!param level (integer) the level picked now (1-12)
--!param players (integer) the room's number of players (the map shown)
function UIMultiplayerLevels:UIMultiplayerLevels(ui, level, players)
  self:UIResizable(ui, WIDTH, HEIGHT, col.bg)
  self.esc_closes = true
  self.resizable = false
  self.modal_class = "main menu"
  self.on_top = true
  self:setDefaultPosition(0.5, 0.25)
  self.default_button_sound = "selectx.wav"
  self.font = ui.app.gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil, {apply_ui_scale = true})
  self.levels = corsixth.require("mp_levels")
  self.level = level or 1
  -- (The map for this many players, or as many as a level has room for.)
  self.wanted_players = math.max(2, math.min(8, players or 2))
  self.players = self.wanted_players
  -- A level above the multiplayer ones is a campaign level for one shared
  -- hospital.
  self.shared = self.level > self.levels.COUNT
  self.skip = 0 -- the briefing's first row shown
  self.previews = {}
  local S = _S.multiplayer_window

  self:addBevelPanel(20, 10, WIDTH - 40, 20, col.title):setLabel(S.levels_caption).lowered = true
  self.several_button = self:addBevelPanel(20, 40, 175, 25, col.row, nil, nil, nil, col.active)
      :setLabel(S.levels_several):makeToggleButton(0, 0, 175, 25, nil, function() self:setShared(false) end)
  self.shared_button = self:addBevelPanel(200, 40, 175, 25, col.row, nil, nil, nil, col.active)
      :setLabel(S.levels_shared):makeToggleButton(0, 0, 175, 25, nil, function() self:setShared(true) end)
  self.players_button = self:addBevelPanel(WIDTH - 200, 40, 180, 25, col.button):setLabel("")
      :makeButton(0, 0, 180, 25, nil, self.buttonPlayers):setTooltip(_S.tooltip.multiplayer_window.levels_players)
  self.rows = {}
  for i = 1, ROWS do
    -- (A name too long for its row ends in "...".)
    self.rows[i] = self:addBevelPanel(20, MAP_Y + (i - 1) * 22, 170, 20, col.row, nil, nil, nil, col.active)
        :setLabel(""):setAutoClip(true):makeToggleButton(0, 0, 170, 20, nil, function() self:select(i) end)
  end
  -- The briefing scrolls (a scrollbar as in the game's other lists, or the
  -- mouse wheel).
  local bar_base = self:addBevelPanel(WIDTH - 20 - SCROLL_W, TEXT_Y, SCROLL_W, TEXT_ROWS * 14 + 2, col.bg)
  bar_base.lowered = true
  self.scrollbar = bar_base:makeScrollbar(col.row, function() self.skip = self.scrollbar.value - 1 end,
      1, 1, TEXT_ROWS, 1)
  self:addBevelPanel(20, HEIGHT - 40, 150, 30, col.button):setLabel(S.back)
      :makeButton(0, 0, 150, 30, nil, self.close)
  self.choose_button = self:addBevelPanel(WIDTH - 220, HEIGHT - 40, 200, 30, col.button):setLabel("")
      :makeButton(0, 0, 200, 30, nil, self.buttonChoose)
  self:setShared(self.shared)
end

--! How many levels the list has now.
function UIMultiplayerLevels:count()
  return self.shared and 12 or self.levels.COUNT
end

--! Show the campaign's levels (one shared hospital) or the multiplayer ones.
function UIMultiplayerLevels:setShared(shared)
  self.shared = shared
  self.several_button:setToggleState(not shared)
  self.shared_button:setToggleState(shared)
  self.players_button:setVisible(not shared)
  local count = self:count()
  for i = 1, ROWS do
    local row = self.rows[i]
    row:setVisible(i <= count)
    if i <= count then
      local name = self:levelName(i)
      row.panel_for_sprite:setLabel(i .. "  " .. name)
      row:setTooltip(name) -- (the whole name, also when the row cuts it short)
    end
  end
  self:select(math.min(self.level, count))
end

function UIMultiplayerLevels:select(i)
  self.level = i
  self.skip = 0
  self.players = math.min(self.wanted_players, self.levels.maxHospitals(i))
  -- The scrollbar: one step a row of the briefing.
  local s = TheApp.gfx:getUIScale()
  local _, text = self:details()
  local _, _, count = self.font:drawWrapped(nil, text, 0, 0, self:textWidth() * s)
  self.scrollbar:setRange(1, math.max(count or 1, TEXT_ROWS), TEXT_ROWS, 1)
  for k, row in ipairs(self.rows) do row:setToggleState(k == i) end
  self.choose_button.panel_for_sprite:setLabel(_S.multiplayer_window.levels_choose:format(i))
  self.players_button.panel_for_sprite:setLabel(_S.multiplayer_window.levels_map_players:format(self.players))
end

--! The map shown: for 2, 3, 4 players or (a level with room for more) up to 8:
--! the next one.
function UIMultiplayerLevels:buttonPlayers()
  self.players = self.players % self.levels.maxHospitals(self.level) + 1
  if self.players < 2 then self.players = 2 end
  self.wanted_players = self.players
  self:select(self.level)
end

--! The briefing's width (unscaled).
function UIMultiplayerLevels:textWidth()
  return WIDTH - 20 - SCROLL_W - 10 - MAP_X
end

--! The mouse wheel scrolls the briefing.
function UIMultiplayerLevels:onMouseWheel(x, y)
  if y == 0 then return UIResizable.onMouseWheel(self, x, y) end
  self:scroll(-y)
  return true
end

function UIMultiplayerLevels:scroll(rows)
  local bar = self.scrollbar
  bar:setRange(bar.min_value, bar.max_value, bar.page_size, math.max(1, bar.value + rows))
  self.skip = bar.value - 1
end

--! Back to the lobby with this level.
function UIMultiplayerLevels:buttonChoose()
  UIMultiplayer.chooseLevel(self.level)
  self:close()
end

function UIMultiplayerLevels:close()
  UIResizable.close(self)
  -- Back to the lobby (its room list), or the main menu if it went away.
  if TheApp.mp_lobby and TheApp.mp_lobby.state == "connected" then
    self.ui:addWindow(UIMultiplayer(self.ui))
  else
    self.ui:addWindow(UIMainMenu(self.ui))
  end
end

--! A level's name: the campaign town, or the multiplayer map's name (a
--! level with events of its own on another level's map says so).
function UIMultiplayerLevels:levelName(i)
  if self.shared then return plain(_S.level_names[i] or i):upper() end
  local name = self.levels.levelName(TheApp, self.players, i) or tostring(i)
  local def = self.levels.LEVELS[i]
  if def.scenario and not def.name then name = plain(_S.multiplayer_window.levels_events):format(name) end
  return name
end

--! The map file of the level shown (Levels folder): a campaign level's, or
--! the multiplayer map for this many players.
function UIMultiplayerLevels:mapFile()
  if self.shared then return "LEVEL.L" .. self.level, 1 end
  return self.levels.mapFile(TheApp, self.players, self.level), self.players
end

--! The preview of a map: per row, runs of tiles of one colour
--! ({x, length, {r, g, b}}), or false if the map cannot be read.
function UIMultiplayerLevels:preview()
  local file, players = self:mapFile()
  local key = file .. "/" .. players
  if self.previews[key] ~= nil then return self.previews[key] end
  local ok, data = pcall(TheApp.readDataFile, TheApp, "Levels", file)
  local th = ok and type(data) == "string" and require("TH").map()
  if not (th and th:load(data)) then
    self.previews[key] = false
    return false
  end
  -- (A map for more players than shown: the others' plots are for sale.)
  local owners = math.min(th:getPlayerCount(), players)
  local w, h = th:size()
  local rows = {}
  for y = 1, h do
    local runs, run = {}, nil
    for x = 1, w do
      local f = th:getCellFlags(x, y)
      local plot = f.parcelId or 0
      local c
      if plot == 0 then
        c = f.passable and GROUND or NATURE
      elseif plot <= owners then
        local rgb = MultiplayerSession.colourRGB(plot)
        local k = f.hospital and 0.6 or 1
        c = {math.floor(rgb[1] * k), math.floor(rgb[2] * k), math.floor(rgb[3] * k)}
      else
        c = f.hospital and SALE_IN or SALE_OUT
      end
      if run and run[3][1] == c[1] and run[3][2] == c[2] and run[3][3] == c[3] then
        run[2] = run[2] + 1
      else
        run = {x, 1, c}
        runs[#runs + 1] = run
      end
    end
    rows[y] = runs
  end
  rows.size = math.max(w, h)
  self.previews[key] = rows
  return rows
end

--! What to say about the level shown: {lines on the right}, the briefing.
function UIMultiplayerLevels:details()
  local S = _S.multiplayer_window
  if self.shared then
    local intro = _S.introduction_texts["level" .. self.level]
    intro = intro and (plain(intro):gsub("//", " "):gsub("^%s+", "")) or ""
    return {S.levels_shared_note:format(self.level)}, intro
  end
  local def = self.levels.LEVELS[self.level]
  local g = def.goals
  local lines = {
    S.levels_money:format(amount(def.cash)), S.levels_goals,
    S.levels_goal_reputation:format(g.reputation), S.levels_goal_balance:format(amount(g.balance)),
    S.levels_goal_value:format(amount(g.value)), S.levels_goal_cured:format(g.cured),
    S.levels_goal_cure_rate:format(g.cure_rate),
  }
  -- (A map a player made: who.)
  if def.map_author and self.levels.ownMap(def, self.players) then
    table.insert(lines, 1, S.levels_map_by:format(def.map_author))
  end
  local text = plain(S.levels_from_campaign):format(plain(_S.level_names[def.campaign] or def.campaign):upper(),
      def.campaign)
  if def.intro then text = text .. " " .. plain(S[def.intro]) end
  return lines, text
end

function UIMultiplayerLevels:draw(canvas, x, y)
  UIResizable.draw(self, canvas, x, y)
  local s = TheApp.gfx:getUIScale()
  x, y = x + self.x * s, y + self.y * s
  local rows = self:preview()
  if rows then
    local tile = 128 * TILE / (rows.size or 128) -- (pixels a tile: 2 on 128 tiles)
    for ty, runs in ipairs(rows) do
      for _, run in ipairs(runs) do
        local c = run[3]
        local rx, ry = math.floor((MAP_X + (run[1] - 1) * tile) * s), math.floor((MAP_Y + (ty - 1) * tile) * s)
        canvas:drawRect(canvas:mapRGB(c[1], c[2], c[3]), x + rx, y + ry,
            math.floor((MAP_X + (run[1] - 1 + run[2]) * tile) * s) - rx,
            math.max(1, math.floor((MAP_Y + ty * tile) * s) - ry))
      end
    end
  else
    self.font:drawWrapped(canvas, _S.multiplayer_window.levels_no_map, x + (MAP_X + 10) * s,
        y + (MAP_Y + 100) * s, (128 * TILE - 20) * s, "center")
  end
  local lines, text = self:details()
  local ly = y + MAP_Y * s
  for _, line in ipairs(lines) do
    ly = self.font:drawWrapped(canvas, line, x + INFO_X * s, ly, (WIDTH - 20 - INFO_X) * s) + 4 * s
  end
  if not self.shared then
    self.font:drawWrapped(canvas, _S.multiplayer_window.levels_legend, x + INFO_X * s, ly + 6 * s,
        (WIDTH - 20 - INFO_X) * s)
  end
  self.font:drawWrapped(canvas, text, x + MAP_X * s, y + TEXT_Y * s, self:textWidth() * s, nil,
      TEXT_ROWS, self.skip)
end
