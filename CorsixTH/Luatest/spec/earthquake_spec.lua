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

require("class_test_base")
require("earthquake")

local Earthquake = _G["Earthquake"]

-- Multiplayer: every computer must damage the machines in the same order (a
-- machine that explodes first spares the others in its room their random
-- draw), whatever order pairs() gives over a room's objects.
describe("Earthquake damage", function()
  it("reaches the machines in entity order", function()
    local hit = {}
    local function machine(id)
      return {mp_id = id, tile_x = 1, tile_y = 1, isMachine = function() return true end,
          earthquakeImpact = function() hit[#hit + 1] = id end}
    end
    local function other() return {isMachine = function() return false end} end
    local room1 = {id = 1, objects = {[machine(7)] = true, [other()] = true, [machine(3)] = true}}
    local room2 = {id = 2, objects = {[machine(5)] = true, [machine(1)] = true}}
    local hospital = {patients = {}, tickEarthquake = function() end}
    local world = {rooms = {room1, room2}, hours_per_tick = 1,
        getLocalPlayerHospital = function() return hospital end}
    local quake = setmetatable({world = world, active = true, warning_timer = 0, damage_timer = 0,
        remaining_damage = 3, size = 5}, {__index = Earthquake})
    quake:tick(1)
    assert.same({1, 3, 5, 7}, hit)
  end)
end)
