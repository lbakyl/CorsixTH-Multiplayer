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

--! The levels of a multiplayer game with a hospital each (co-op and
--! competitive). The map is one of Theme Hospital's original multiplayer maps
--! (LEVEL.L<players><n>), whose own level files (NET<players><n>.SAM) let
--! every disease come and every room be researched from the start, with a
--! reputation goal only. Instead, what a level has is taken from a single
--! player campaign level: the diseases that come and from when, the rooms and
--! machines there at the start, what can be researched, the emergencies and
--! how fast patients come. Level 1 has the fewest rooms. The goals and the
--! starting money are our own (below).
local levels = {}

--! Criteria numbers of the level files (see endconditions.lua).
local REPUTATION, BALANCE, PERCENTAGE_CURED, NUM_CURED, PERCENTAGE_KILLED, VALUE = 1, 2, 3, 4, 5, 6

--! campaign: the single player level the diseases, rooms and research come
--! from; cash: starting money; goals: all of them to win (value: hospital
--! value above what the biggest starting plot is worth).
levels.LEVELS = {
  {campaign = 1, cash = 40000,
    goals = {reputation = 550, balance = 20000, value = 40000, cured = 40, cure_rate = 40}},
  {campaign = 3, cash = 50000,
    goals = {reputation = 600, balance = 50000, value = 70000, cured = 100, cure_rate = 45}},
  {campaign = 5, cash = 50000,
    goals = {reputation = 650, balance = 100000, value = 110000, cured = 200, cure_rate = 50}},
  {campaign = 8, cash = 60000,
    goals = {reputation = 700, balance = 200000, value = 150000, cured = 350, cure_rate = 55}},
  {campaign = 11, cash = 70000,
    goals = {reputation = 750, balance = 350000, value = 200000, cured = 500, cure_rate = 60}},
}
levels.COUNT = #levels.LEVELS

--! What a level takes from its campaign level.
local FROM_CAMPAIGN = {"visuals", "non_visuals", "visuals_available", "non_visuals_available",
    "expertise", "objects", "rooms", "emergency_control", "popn"}

--! The level (1 .. COUNT) a room's level number stands for.
function levels.clamp(level)
  level = math.floor(tonumber(level) or 1)
  return math.max(1, math.min(levels.COUNT, level))
end

--! Put level `level`'s content into `config` (the multiplayer map's level
--! config): the sections above from `campaign` (the campaign level's
--! config), the starting money, and the goals. The value goal is set later
--! by levels.setValueGoal, once the map's plots are known.
function levels.apply(config, campaign, level)
  local def = levels.LEVELS[levels.clamp(level)]
  for _, key in ipairs(FROM_CAMPAIGN) do
    config[key] = campaign[key]
  end
  -- Every level but the first has the training room from the start (with
  -- its projector, lecture chairs, skeleton and bookcase): the staff to hire
  -- are few, so training must begin early. (object numbers: TheApp.objects)
  if levels.clamp(level) > 1 then
    for _, thob in ipairs({36, 37, 56, 60}) do
      local spec = config.objects and config.objects[thob]
      if spec then spec.StartAvail, spec.AvailableForLevel = 1, 1 end
    end
  end
  -- (a multiplayer map's level number is no campaign town: `town` is used)
  config.town = {StartCash = def.cash, StartRep = 500, InterestRate = 100, OverdraftDiff = 200}
  local g = def.goals
  local function goal(criterion, value, group, bound, max_min)
    return {Criteria = criterion, MaxMin = max_min or 1, Value = value, Group = group, Bound = bound or 0}
  end
  config.win_criteria = {
    [0] = goal(REPUTATION, g.reputation, 1),
    goal(BALANCE, g.balance, 1),
    goal(VALUE, g.value, 1),
    goal(NUM_CURED, g.cured, 1),
    goal(PERCENTAGE_CURED, g.cure_rate, 1),
  }
  -- Out of the race (or the team in trouble) at a year end: deep in debt, or
  -- killing half the patients.
  config.lose_criteria = {
    [0] = goal(BALANCE, -20000, 1, -15000, 0),
    goal(PERCENTAGE_KILLED, 50, 2, 40),
  }
  config.mp_level = levels.clamp(level)
end

--! The value goal: what the biggest of the players' starting plots is worth
--! (with the 20000 every hospital starts with) plus the level's amount.
--!param map (Map) loaded, with the plots counted
function levels.setValueGoal(map)
  local config = map.level_config
  local def = levels.LEVELS[config.mp_level]
  local start = 0
  for plot = 1, map.th:getPlayerCount() do
    start = math.max(start, map:getParcelPrice(plot) + 20000)
  end
  -- (rounded up to $5,000)
  local goal = math.ceil((start + def.goals.value) / 5000) * 5000
  for _, crit in pairs(config.win_criteria) do
    if crit.Criteria == VALUE then crit.Value = goal end
  end
end

return levels
