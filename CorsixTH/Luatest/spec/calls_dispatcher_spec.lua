--[[ Copyright (c) 2026 CorsixTH contributors

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
require("utility")

require("calls_dispatcher")

-- A call checkpoint may carry no call (CallCheckPointAction allows nil): a
-- nurse queues one after her vaccination, also when the call was dropped
-- during her short wait. Replacing her queue then ran the interrupt handler,
-- which crashed on the missing call (a nurse's tick in a multiplayer game
-- with an epidemic).
describe("CallsDispatcher with a checkpoint without a call", function()
  it("interrupts and completes without an error", function()
    local nurse = {on_call = nil}
    local action = {call = nil}
    assert.has_no.errors(function()
      CallsDispatcher.actionInterruptHandler(action, nurse)
      CallsDispatcher.staffActionInterruptHandler(action, nurse)
      CallsDispatcher.onCheckpointCompleted(nil)
    end)
  end)

  it("still hands an interrupted call to other staff", function()
    local found
    local nurse = {world = {dispatcher = {findSuitableStaff = function(_, call) found = call end}}}
    local call = {assigned = nurse}
    nurse.on_call = call
    CallsDispatcher.actionInterruptHandler({call = call}, nurse)
    assert.is_nil(call.assigned)
    assert.is_nil(nurse.on_call)
    assert.equal(call, found)
  end)
end)

-- Multiplayer: the call queue is keyed by tables, so pairs() visits it in an
-- order that differs between the players' games. Of two calls with the same
-- score every game must hand the staff member the same one.
describe("CallsDispatcher:answerCall with tied calls in multiplayer", function()
  if not rawget(_G, "Handyman") then class "Handyman" end

  local function answer(rooms, mp)
    local dispatcher = setmetatable({call_queue = {}, world = {app = {mp_session = mp or nil}}},
        {__index = CallsDispatcher})
    for _, room in ipairs(rooms) do
      dispatcher.call_queue[room] = {Doctor = {object = room, key = "Doctor",
          verification = function() return true end, priority = function() return 5 end}}
    end
    local chosen
    dispatcher.executeCall = function(_, call) chosen = call.object end
    dispatcher:answerCall({hospital = {}})
    return chosen
  end

  it("picks the room with the lowest number, whatever the order", function()
    for _ = 1, 20 do
      local a = {room_info = {id = "gp"}, id = 7, x = 1, y = 1}
      local b = {room_info = {id = "gp"}, id = 3, x = 9, y = 9}
      local c = {room_info = {id = "gp"}, id = 12, x = 5, y = 5}
      assert.equal(b, answer({a, b, c}, true))
      assert.equal(b, answer({c, a, b}, true))
    end
  end)

  it("orders people and objects by their multiplayer number", function()
    local p1 = {mp_id = 40, tile_x = 1, tile_y = 1}
    local p2 = {mp_id = 9, tile_x = 5, tile_y = 5}
    assert.equal(p2, answer({p1, p2}, true))
    assert.is_true(CallsDispatcher.callComesFirst({object = p2, key = "a"}, {object = p1, key = "a"}))
    assert.is_true(CallsDispatcher.callComesFirst({object = p2, key = "a"}, {object = p2, key = "b"}))
  end)
end)
