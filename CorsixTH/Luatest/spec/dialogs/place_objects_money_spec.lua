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

-- Who pays for objects in the object window, and who is refunded when it
-- closes with objects not yet placed (eu2 desyncs, 2026-11-21: a bot's own
-- bench window closed while its room was being built, inside the command,
-- and refunded $40 in that bot's game only).
describe("Object window money", function()
  local saved_session
  setup(function()
    require("corsixth")
    require("class_test_base")
    require("TH")
    require("utility")
    require("window")
    require("dialogs/place_objects")
    saved_session = rawget(_G, "MultiplayerSession")
  end)
  teardown(function()
    _G["MultiplayerSession"] = saved_session
  end)

  --! A window with one bench not yet placed; `refunds` collects the money
  --! given back.
  local function window(mp_local, refunds)
    local hospital = {}
    function hospital.getObjectBuildCost() return 40 end
    function hospital.receiveMoney(_, amount) refunds[#refunds + 1] = amount end
    local w = {
      mp_local = mp_local,
      ui = {hospital = hospital},
      objects = {{object = {id = "bench", name = "Bench"}, qty = 1}},
      active_index = 1,
      list_header = {},
      paysItself = UIPlaceObjects.paysItself,
    }
    for _, name in ipairs({"clearBlueprint", "resize", "setActiveIndex", "setBlueprintCell",
        "setOrientation", "close"}) do
      w[name] = function() end
    end
    return w
  end

  local function remove(w)
    local old_S = rawget(_G, "_S")
    rawset(_G, "_S", {transactions = {sell_object = "Sold"}})
    local ok, err = pcall(UIPlaceObjects.removeObject, w, w.objects[1], true, false, false)
    rawset(_G, "_S", old_S)
    if not ok then error(err, 0) end
  end

  local function session(applying)
    _G["MultiplayerSession"] = {actionsAreCommands = function() return not applying end}
  end

  it("refunds an unplaced purchase in single player", function()
    _G["MultiplayerSession"] = {actionsAreCommands = function() return false end}
    local refunds = {}
    remove(window(nil, refunds))
    assert.same({40}, refunds)
  end)

  it("refunds in an editor run inside a multiplayer command, on every peer", function()
    session(true)
    local refunds = {}
    remove(window(nil, refunds))
    assert.same({40}, refunds)
  end)

  it("never refunds from a player's own window, even closed while a command runs", function()
    session(true)
    local refunds = {}
    remove(window(true, refunds))
    assert.same({}, refunds)
    session(false)
    remove(window(true, refunds))
    assert.same({}, refunds)
  end)

  it("marks a window opened by the player in a multiplayer game as their own", function()
    session(false)
    assert.is_false(UIPlaceObjects.paysItself({mp_local = true}))
    session(true)
    assert.is_true(UIPlaceObjects.paysItself({}))
  end)
end)
