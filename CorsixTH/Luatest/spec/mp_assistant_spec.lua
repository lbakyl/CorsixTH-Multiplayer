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

-- What the bots in a person's hospital do: a switch for each job, a shared
-- command, and the room's "Allied bots build" option as everybody's limit
-- (Argus and Jan, 2026-11-21).
require("corsixth")
require("class_test_base")
require("date")
require("mp_session")

local MultiplayerSession = _G["MultiplayerSession"]
local handlers = MultiplayerSession.default_handlers

describe("Assistant jobs", function()
  local function make(helpers_off)
    local a, b = {name = "A"}, {name = "B"}
    local world = {hospitals = {a, b}, mp_coop = {players = 2, helpers_off = helpers_off}}
    return world, a, b
  end

  it("has the defaults of a new game", function()
    local world, a = make()
    local may = MultiplayerSession.assistantMay
    assert.is_true(may(world, a, "build"))
    assert.is_true(may(world, a, "hire"))
    assert.is_false(may(world, a, "replace"))
    assert.is_false(may(world, a, "faxes"))
    assert.is_true(may(world, a, "loan"))
    assert.is_false(may(world, a, "auctions"))
  end)

  it("switches a job of the sender's hospital only", function()
    local world, a, b = make()
    assert.is_true(handlers.assistant_job(world, {hospital = 1, job = "hire", on = "0"}))
    assert.is_true(handlers.assistant_job(world, {hospital = 1, job = "faxes", on = "1"}))
    assert.is_false(MultiplayerSession.assistantMay(world, a, "hire"))
    assert.is_true(MultiplayerSession.assistantMay(world, a, "faxes"))
    assert.is_true(MultiplayerSession.assistantMay(world, b, "hire"))
    assert.is_false(MultiplayerSession.assistantMay(world, b, "faxes"))
    assert.is_true(handlers.assistant_job(world, {hospital = 1, job = "hire", on = 1}))
    assert.is_true(MultiplayerSession.assistantMay(world, a, "hire"))
  end)

  it("refuses an unknown job", function()
    local world, a = make()
    local ok, why = handlers.assistant_job(world, {hospital = 1, job = "prices", on = "1"})
    assert.is_false(ok)
    assert.are.equal("no such job", why)
    assert.is_nil(a.mp_assistant)
  end)

  it("never lets bots build when the game options say they do not", function()
    local world, a = make(true)
    assert.is_false(MultiplayerSession.assistantMay(world, a, "build"))
    local ok, why = handlers.assistant_job(world, {hospital = 1, job = "build", on = "1"})
    assert.is_false(ok)
    assert.are.equal("bots do not build in this game", why)
    assert.is_false(MultiplayerSession.assistantMay(world, a, "build"))
    -- (Switching it off is fine, and the other jobs are as before.)
    assert.is_true(handlers.assistant_job(world, {hospital = 1, job = "build", on = "0"}))
    assert.is_true(MultiplayerSession.assistantMay(world, a, "hire"))
  end)
end)
