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
