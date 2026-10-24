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

-- The room definition reads its names from the game strings.
local function any_string()
  return setmetatable({}, {__index = function() return any_string() end})
end
_G["_S"] = _G["_S"] or any_string()

require("room")
require("rooms/gp")

describe("GP's office: ", function()
  local function newRoom(found)
    local room = setmetatable({objects = {}}, {__index = GPRoom})
    room.world = {findObjectNear = function(_, _, name) return table.unpack(found[name] or {}) end}
    local leave = {name = "leave"}
    room.createLeaveAction = function() return leave end
    local queued = {}
    local doctor = {
      queueAction = function(_, action) queued[#queued + 1] = action end,
      walkTo = function(_, x, y) queued[#queued + 1] = {name = "walk", x = x, y = y} end,
    }
    return room, doctor, queued, leave
  end

  it("a desk that cannot be reached sends the doctor out instead of stopping them", function()
    -- (The desk is found, but no tile to use it from: objects in the way.)
    local room, doctor, queued, leave = newRoom({desk = {{object_type = {id = "desk"}}}})
    assert.has_no.errors(function() room:doStaffUseCycle(doctor) end)
    assert.are.equal(leave, queued[#queued])
  end)

  it("a cabinet that cannot be reached is skipped", function()
    local room, doctor, queued, leave = newRoom({cabinet = {{object_type = {id = "cabinet"}}}})
    assert.has_no.errors(function() room:doStaffUseCycle(doctor) end)
    for _, action in ipairs(queued) do assert.are_not.equal("walk", action.name) end
    assert.is_nil(queued[1] and queued[1] ~= leave and queued[1].x)
  end)
end)
