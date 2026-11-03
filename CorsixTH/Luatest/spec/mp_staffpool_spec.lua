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

require("corsixth")
require("class_test_base")
require("utility")
require("persistance")

-- (Loaded as in world_spec.lua.)
local saved_A = _G._A
_G._A = {cheats = {}}
require("map")
require("entity")
require("entities.humanoid")
require("entities.object")
require("entities.machine")
require("room")
require("humanoid_action")
require("world")
_G._A = saved_A

local World = _G["World"]

-- Multiplayer with a hospital each: every hospital hires from its own list,
-- the same people under other names.
describe("Multiplayer hiring list per hospital", function()
  local saved_strings, saved_initials
  before_each(function()
    saved_strings, saved_initials = _G._S, staff_initials_cache.initials
    _G._S = {humanoid_name_starts = {"BAN", "COR", "DUN", "FEL", "GRI"},
        humanoid_name_ends = {"SON", "TON", "LEY", "WICK"}}
    staff_initials_cache.initials = {[0] = "Z", "A", "B", "C"}
  end)
  after_each(function()
    _G._S, staff_initials_cache.initials = saved_strings, saved_initials
  end)

  local Profile = {}
  local function doctor(wage, skill, name, seed)
    return setmetatable({humanoid_class = "Doctor", wage = wage, skill = skill, name = name,
        initial = "A", name_seed = seed, is_surgeon = 1, hair_index = 3}, Profile)
  end

  local function world(coop)
    local h1, h2 = {}, {}
    local w = setmetatable({mp_coop = coop, hospitals = {h1, h2}, available_staff_made = 1,
        available_staff = {Doctor = {doctor(60, 0.5, "BANSON", 10), doctor(80, 0.9, "CORLEY", 400)}}},
        {__index = World})
    w.getHospitalIndex = function(_, h) return h == h1 and 1 or h == h2 and 2 or nil end
    w.getLocalPlayerHospital = function() return h1 end -- (in multiplayer always hospital 1)
    w.getUIHospital = function() return coop and h2 or h1 end -- (this machine's player: hospital 2)
    return w, h1, h2
  end

  it("gives every hospital the same people under other names", function()
    local w, h1, h2 = world({players = 2})
    local one, two = w:staffPool(h1).Doctor, w:staffPool(h2).Doctor
    assert.equal(2, #one)
    assert.equal(2, #two)
    for i = 1, 2 do
      local original = w.available_staff.Doctor[i]
      for _, copy in ipairs({one[i], two[i]}) do
        assert.equal(original.wage, copy.wage)
        assert.equal(original.skill, copy.skill)
        assert.equal(original.is_surgeon, copy.is_surgeon)
        assert.equal(original.hair_index, copy.hair_index)
        assert.equal(Profile, getmetatable(copy))
        assert.are_not.equal(original, copy)
      end
      assert.equal(original.name, one[i].name) -- hospital 1 keeps the names
      assert.are_not.equal(original.name, two[i].name)
    end
    -- The same copy on every peer (no random numbers).
    local again = world({players = 2})
    assert.equal(two[1].name, again:staffPool(again.hospitals[2]).Doctor[1].name)
  end)

  it("gives this machine's player their own hospital's list by default", function()
    local w, _, h2 = world({players = 2})
    assert.equal(w:staffPool(h2), w:staffPool())
  end)

  it("lets a hospital hire without taking anybody from another", function()
    local w, h1, h2 = world({players = 2})
    table.remove(w:staffPool(h1).Doctor, 1)
    assert.equal(1, #w:staffPool(h1).Doctor)
    assert.equal(2, #w:staffPool(h2).Doctor)
    assert.equal(2, #w.available_staff.Doctor)
  end)

  it("makes a new list each month", function()
    local w, h1 = world({players = 2})
    table.remove(w:staffPool(h1).Doctor, 1)
    w.available_staff = {Doctor = {doctor(70, 0.7, "DUNTON", 7)}}
    w.available_staff_made = 2
    assert.equal(1, #w:staffPool(h1).Doctor)
    assert.equal(70, w:staffPool(h1).Doctor[1].wage)
  end)

  it("keeps the one world list in single player", function()
    local w, h1 = world(nil)
    assert.equal(w.available_staff, w:staffPool(h1))
    assert.equal(w.available_staff, w:staffPool())
  end)
end)
