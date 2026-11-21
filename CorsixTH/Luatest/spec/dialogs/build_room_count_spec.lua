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

-- The build window shows beside each kind of room how many of it the
-- hospital has (Argus and Jan, 2026-11-21).
describe("Build window room counts", function()
  setup(function()
    require("corsixth")
    require("class_test_base")
    require("TH")
    require("utility")
    require("window")
    require("dialogs/build_room")
  end)

  local hospital, other = {}, {}
  local function room(id, owner, crashed)
    return {room_info = {id = id}, hospital = owner, crashed = crashed}
  end

  it("counts the hospital's rooms of each kind", function()
    local world = {rooms = {room("gp", hospital), room("gp", hospital), room("ward", hospital)}}
    local counts = UIBuildRoom.roomCounts(world, hospital)
    assert.are.equal(2, counts.gp)
    assert.are.equal(1, counts.ward)
    assert.is_nil(counts.pharmacy)
  end)

  it("leaves out another hospital's rooms and crashed ones", function()
    local world = {rooms = {room("gp", other), room("x_ray", hospital, true), room("gp", hospital)}}
    local counts = UIBuildRoom.roomCounts(world, hospital)
    assert.are.equal(1, counts.gp)
    assert.is_nil(counts.x_ray)
  end)

  it("has nothing for a hospital without rooms", function()
    assert.are.same({}, UIBuildRoom.roomCounts({rooms = {}}, hospital))
  end)

  -- The number on the build button: discovered kinds with no room, not the
  -- training room or the research department, not unimplemented kinds.
  local function kind(id, discovered, unimplemented)
    return {room = {id = id, class = not unimplemented and "Room" or nil}, is_discovered = discovered}
  end
  local lab = {room_discoveries = {
    kind("gp", true), kind("pharmacy", true), kind("ward", true), kind("x_ray", false),
    kind("training", true), kind("research", true), kind("dentist", true, true),
  }}

  it("counts the kinds still missing", function()
    assert.are.equal(3, UIBuildRoom.missingRoomKinds({rooms = {}}, lab))
    local world = {rooms = {room("gp", lab), room("ward", other), room("pharmacy", lab, true)}}
    assert.are.equal(2, UIBuildRoom.missingRoomKinds(world, lab))
    world.rooms[#world.rooms + 1] = room("pharmacy", lab)
    world.rooms[#world.rooms + 1] = room("ward", lab)
    assert.are.equal(0, UIBuildRoom.missingRoomKinds(world, lab))
  end)

  -- Names that leave no room for the count are shortened (6 pixels a letter
  -- here).
  local font = {sizeOf = function(_, text) return 6 * #text end}

  it("keeps a name that fits", function()
    assert.are.equal("GP's Office", UIBuildRoom.fitName(font, "GP's Office", 103))
  end)

  it("cuts the last word to four letters and a full stop", function()
    assert.are.equal("General Diag.", UIBuildRoom.fitName(font, "General Diagnosis", 100))
  end)

  it("cuts further when that is not enough", function()
    assert.are.equal("Decontamina.", UIBuildRoom.fitName(font, "Decontamination", 72))
  end)
end)
