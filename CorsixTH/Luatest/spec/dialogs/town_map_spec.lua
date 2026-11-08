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

-- Where the town map is a window (a screen larger than the map), pressing
-- the mouse on it begins a drag of the window. A click on a plot's sell or
-- hand-over button must end that drag, or the map follows the mouse (Jan's
-- Mac, eu2 2026-11-08).
describe("Town map plot buttons", function()
  setup(function()
    require("corsixth")
    require("class_test_base")
    require("TH")
    require("utility")
    require("window")
    require("dialogs/fullscreen")
    require("dialogs/fullscreen/town_map")
  end)

  local function dragged_map(kind)
    local UITownMap = _G["UITownMap"]
    local ui = {drag_mouse_move = function() end, app = {runtime_config = {}}}
    local map = setmetatable({ui = ui, dragging = true, buttons = {}, scrollbars = {},
        x_original = 10, y_original = 20}, {__index = UITownMap})
    map.buttonAt = function() return {kind = kind, plot = 3} end
    map.asked = {}
    map.askToSell = function(self, plot) self.asked[#self.asked + 1] = plot end
    return map, ui
  end

  it("ends the window drag when the sell button is clicked", function()
    local map, ui = dragged_map("sell")
    assert.is_true(map:onMouseUp("left", 50, 50))
    assert.is_false(map.dragging)
    assert.is_nil(ui.drag_mouse_move)
    assert.same({3}, map.asked)
  end)

  it("ends the window drag when the hand-over button is clicked", function()
    local map, ui = dragged_map("give")
    local opened
    local saved = _G.UIMultiplayerGivePlot
    finally(function() _G.UIMultiplayerGivePlot = saved end)
    _G.UIMultiplayerGivePlot = {open = function(_, plot) opened = plot end}
    assert.is_true(map:onMouseUp("left", 50, 50))
    assert.is_false(map.dragging)
    assert.is_nil(ui.drag_mouse_move)
    assert.equal(3, opened)
  end)
end)
