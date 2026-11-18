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

-- Which Unicode font the game loads: the shipped pixel font replaces the old
-- smooth default, but never a font the player chose.
describe("Unicode font file", function()
  local Graphics
  setup(function()
    require("corsixth")
    require("class_test_base")
    require("TH")
    require("graphics")
    Graphics = _G["Graphics"]
  end)

  local dir = "/game/CorsixTH/"
  local pixel = dir .. "Fonts/fusion-pixel-12px-proportional-zh_hans.ttf"
  local function files(list)
    local set = {}
    for _, f in ipairs(list) do set[f] = true end
    return function(path) return set[path] == true end
  end

  it("prefers the shipped pixel font", function()
    local exists = files({pixel, dir .. "CorsixTHUnicode.ttf"})
    assert.equal(pixel, Graphics.chooseFontFile(nil, nil, dir, exists))
  end)

  it("replaces an old default the config file remembered", function()
    local exists = files({pixel, dir .. "CorsixTHUnicode.ttf", "CorsixTHUnicode.ttf"})
    assert.equal(pixel, Graphics.chooseFontFile("CorsixTHUnicode.ttf", nil, dir, exists))
    assert.equal(pixel, Graphics.chooseFontFile(dir .. "CorsixTHUnicode.ttf", nil, dir, exists))
    assert.equal(pixel, Graphics.chooseFontFile("C:\\Games\\CorsixTH\\GoNotoKurrent-Regular.ttf",
        nil, dir, exists))
  end)

  it("keeps a font the player chose", function()
    local exists = files({pixel, "/fonts/MyFont.ttf"})
    assert.equal("/fonts/MyFont.ttf", Graphics.chooseFontFile("/fonts/MyFont.ttf", nil, dir, exists))
  end)

  it("falls back to the old default without the pixel font", function()
    local exists = files({dir .. "CorsixTHUnicode.ttf"})
    assert.equal(dir .. "CorsixTHUnicode.ttf", Graphics.chooseFontFile(nil, nil, dir, exists))
    local old = files({"/old/CorsixTHUnicode.ttf"})
    assert.equal("/old/CorsixTHUnicode.ttf",
        Graphics.chooseFontFile("/old/CorsixTHUnicode.ttf", nil, dir, old))
  end)

  it("says why when there is no font at all", function()
    local file, err = Graphics.chooseFontFile("/fonts/Gone.ttf", nil, dir, files({}))
    assert.is_nil(file)
    assert.truthy(err:find("/fonts/Gone.ttf", 1, true))
  end)

  it("reads a pixel font's design size from its name", function()
    assert.equal(12, Graphics.pixelFontSize(pixel))
    assert.equal(10, Graphics.pixelFontSize("C:\\F\\Fusion-Pixel-10px-proportional-ja.ttf"))
    assert.is_nil(Graphics.pixelFontSize(dir .. "CorsixTHUnicode.ttf"))
  end)
end)
