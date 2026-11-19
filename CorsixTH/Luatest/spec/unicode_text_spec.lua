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

-- Text beyond ASCII: a Russian letter is two bytes, a Chinese one three.
-- Text boxes edit whole letters, and text the original bitmap font cannot
-- show (a Russian name for a player of the English game) is drawn with the
-- Unicode font.
describe("Unicode text", function()
  setup(function()
    require("corsixth")
    require("class_test_base")
    require("TH")
    require("utility")
    require("window")
    require("graphics")
  end)

  describe("in a text box", function()
    local function box(limit)
      local Textbox = _G["Textbox"]
      local panel = {window = {ui = {app = {key_modifiers = {}}}}}
      function panel.setLabel(p, text) p.label = text end
      return setmetatable({active = true, text = "", cursor_pos = {1, 0}, char_limit = limit,
          allowed_input = {alpha = true, numbers = true, misc = true}, panel = panel}, {__index = Textbox})
    end

    it("Backspace takes off a whole letter", function()
      local b = box()
      b:textInput("Привет")
      b:keyInput("backspace")
      assert.are.equal("Приве", b.text)
      assert.are.equal(#"Приве", b.cursor_pos[2])
    end)

    it("the arrows go a whole letter, and Delete takes one", function()
      local b = box()
      b:textInput("абв")
      b:keyInput("left")
      assert.are.equal(#"аб", b.cursor_pos[2])
      b:keyInput("left")
      b:keyInput("delete")
      assert.are.equal("ав", b.text)
      b:keyInput("right")
      assert.are.equal(#"ав", b.cursor_pos[2])
    end)

    it("Ctrl+Backspace takes off a Russian word", function()
      local b = box()
      b:textInput("один два")
      b.panel.window.ui.app.key_modifiers.ctrl = true
      b:keyInput("backspace")
      assert.are.equal("один ", b.text)
    end)

    it("the limit counts letters, and a full box keeps its keys", function()
      local b = box(5)
      b:textInput("Привет")
      assert.are.equal("Приве", b.text)
      b:textInput("ы")
      assert.are.equal("Приве", b.text)
      -- (Not on to the hotkeys, e.g. N for the next hospital.)
      assert.is_true(b:keyInput("n"))
    end)

    it("ASCII as before", function()
      local b = box(10)
      b:textInput("Hello")
      b:keyInput("backspace")
      b:keyInput("left")
      b:keyInput("delete")
      assert.are.equal("Hel", b.text)
    end)
  end)

  describe("drawn with a bitmap font", function()
    local bitmap, unicode
    local function load_font(charset)
      bitmap = {draw = spy.new(function() end), sizeOf = spy.new(function() return 1 end),
          setSeparation = function() end, setSheet = function() end}
      unicode = {draw = spy.new(function() end), sizeOf = spy.new(function() return 2 end)}
      require("TH").bitmap_font = function() return bitmap end
      local gfx = setmetatable({th_charset = charset, ttf_font_data = "font", load_info = {}},
          {__index = _G["Graphics"]})
      gfx._loadTrueTypeFont = function() return unicode end
      return gfx:loadFont({isVisible = function() return true end}, {})
    end

    local function drawn_by(font, text)
      bitmap.draw:clear()
      unicode.draw:clear()
      font:draw(nil, text, 0, 0)
      if #bitmap.draw.calls == 1 then return "bitmap" end
      if #unicode.draw.calls == 1 then return "unicode" end
    end

    it("of the English game: Latin letters by the font, others by the Unicode font", function()
      local font = load_font(1)
      assert.are.equal("bitmap", drawn_by(font, "Hello"))
      assert.are.equal("bitmap", drawn_by(font, "Jürgen’s café"))
      assert.are.equal("unicode", drawn_by(font, "Привет"))
      assert.are.equal("unicode", drawn_by(font, "JAN + АЛЁНА"))
      assert.are.equal("unicode", drawn_by(font, "你好"))
      assert.are.equal(2, font:sizeOf("Привет"))
      assert.are.equal(1, font:sizeOf("Hello"))
    end)

    it("of the Russian game: Russian by the font, others by the Unicode font", function()
      local font = load_font(2)
      assert.are.equal("bitmap", drawn_by(font, "Привет"))
      assert.are.equal("bitmap", drawn_by(font, "Алёна «Ёж» — да"))
      assert.are.equal("unicode", drawn_by(font, "café"))
      assert.are.equal("unicode", drawn_by(font, "Привіт")) -- (Ukrainian і)
      assert.are.equal("unicode", drawn_by(font, "你好"))
    end)

    it("without a Unicode font: the bitmap font", function()
      bitmap = {draw = spy.new(function() end), setSeparation = function() end, setSheet = function() end}
      require("TH").bitmap_font = function() return bitmap end
      local gfx = setmetatable({th_charset = 1, load_info = {}}, {__index = _G["Graphics"]})
      local font = gfx:loadFont({isVisible = function() return true end}, {})
      font:draw(nil, "Привет", 0, 0)
      assert.are.equal(1, #bitmap.draw.calls)
    end)
  end)
end)
