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
require("corsixth")
require("epidemic")

local Epidemic = _G["Epidemic"]

-- Multiplayer: an epidemic spreads to its own hospital's patients only. A
-- rival's patient walking through the corridors caught it and was then
-- counted, faxed and timed in the wrong hospital (Argus, eu2 2026-11-07).
describe("Epidemic infection", function()
  local function patient(hospital, disease)
    return {hospital = hospital, disease = disease, tile_x = 5, tile_y = 5,
        getRoom = function() return nil end, updateDynamicInfo = function() end,
        removeAnyEpidemicStatus = function(p) p.status_cleared = true end}
  end

  local function epidemic_with(own, foreign)
    local disease = {contagious = true}
    local mine = {isInHospital = function() return true end, patients = {},
        getReceptionDesks = function() return {} end}
    local theirs = {isInHospital = function() return true end}
    local infector = patient(mine, disease)
    local victims = {patient(foreign and theirs or mine, disease)}
    if own then victims[#victims + 1] = patient(mine, disease) end
    local world = {entity_map = {getPatientsInAdjacentSquares = function() return victims end},
        map = {level_config = {gbv = {}}}}
    mine.world = world
    local epidemic = Epidemic(mine, infector)
    epidemic.infected_patients = {infector}
    infector.infected = true
    epidemic.spread_factor = 200 -- (always: total/attempted < 1)
    epidemic.total_infections, epidemic.attempted_infections = 0, 0
    return epidemic, victims, mine
  end

  it("does not infect another hospital's patient", function()
    local epidemic, victims = epidemic_with(true, true)
    epidemic:infectOtherPatients()
    assert.is_falsy(victims[1].infected)
    assert.is_true(victims[2].infected)
    assert.equal(2, #epidemic.infected_patients)
  end)

  it("lets go of another hospital's patient infected before", function()
    local epidemic, _, mine = epidemic_with(false, false)
    local foreign = patient({}, epidemic.disease)
    foreign.infected = true
    epidemic.infected_patients[#epidemic.infected_patients + 1] = foreign
    epidemic:checkPatientsForRemoval()
    assert.equal(1, #epidemic.infected_patients)
    assert.equal(mine, epidemic.infected_patients[1].hospital)
    assert.is_false(foreign.infected)
    assert.is_true(foreign.status_cleared)
  end)
end)
