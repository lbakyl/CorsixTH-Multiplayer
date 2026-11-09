--[[ Copyright (c) 2012 Stephen Baker

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

--! Layer which handles the Lua-facing side of loading and playing video.

local TH = require("TH")
local pathsep = package.config:sub(1, 1)

class "MoviePlayer"

---@class MoviePlayer
---@operator call: MoviePlayer
local MoviePlayer = _G["MoviePlayer"] ---@type MoviePlayer

--! Calculate the position and size for a movie
--!
--! Returns x and y position, width and height, and the scale factor of the
--! movie to be displayed based on the native size of the movie and the current
--! screen dimensions.
--!
--! Theme Hospital movies were 320x240 but played in game at 640x480 so when
--! scaling other assets to match the movies they should be scaled by half
--! the returned scaling factor. Some movies were 320x200 and those should
--! be aspect corrected to 4:3 during scaling.
--!
--!param me The MoviePlayer object
local calculateSize = function(me)
  -- calculate target dimensions
  local x, y, w, h, scale
  local screen_w, screen_h = me.app.video:getRenderSize()
  local native_w = me.moviePlayer:getNativeWidth()
  local native_h = me.moviePlayer:getNativeHeight()
  if native_w == 320 and native_h == 200 then
    -- This resolution was intended to be stretched for a 4:3 screen
    native_h = 240
  end
  if native_w ~= 0 and native_h ~= 0 then
    local ar = native_w / native_h
    if math.abs((screen_w / screen_h) - ar) < 0.001 then
      x, y = 0, 0
      w, h = screen_w, screen_h
      scale = screen_h / native_h
    else
      if screen_w > screen_h / native_h * native_w then
        w = math.floor(screen_h / native_h * native_w)
        h = screen_h
        x = math.floor((screen_w - w) / 2)
        y = 0
        scale = screen_h / native_h
      else
        w = screen_w
        h = math.floor(screen_w / native_w * native_h)
        x = 0
        y = math.floor((screen_h - h) / 2)
        scale = screen_w / native_w
      end
    end
  else
    x, y = 0, 0
    w, h = screen_w, screen_h
    scale = 1
  end

  return x, y, w, h, scale
end

local destroyMovie = function(me)
  me.moviePlayer:unload()
  if me.opengl_mode_index then
    me.app.modes[me.opengl_mode_index] = "opengl"
  end
  if me.holding_bg_music then
    -- If possible we want to continue playing music where we were
    me.audio:pauseBackgroundTrack()
    me.holding_bg_music = false
  end
  if me.sound then
    me.audio:stopSound(me.sound)
    me.sound = nil
  end
  me.refresh_overlay = nil
  me.letter = nil
  if me.typing_sound then me.audio:stopSound(me.typing_sound) end
  me.typing_sound = nil
  me.playing = false
  me.movie_over = false
  if me.callback_on_destroy_movie then
    me.callback_on_destroy_movie()
    me.callback_on_destroy_movie = nil
  end
end

local loseMovieOverlay = function(me, lose_movie_index)

  -- These are the times in milliseconds when the headline should appear as
  -- determined experimentally
  local start_movie_pts = {
    me.movie_length - 1760,
    me.movie_length - 860,
    me.movie_length - 1600,
    me.movie_length - 1000,
    me.movie_length - 860,
    me.movie_length - 780,
  }

  local start_pts = start_movie_pts[lose_movie_index]
  local headlines = _S.newspaper[lose_movie_index]
  local headline = headlines[math.cosmetic_random(#headlines)]

  -- The LOSE movies are 320x240 but are drawn in the original game at 640x480
  -- before drawing the font over them. The headline area at double size is 40px
  -- tall and 590px wide if we exclude the padding which has no other ink. If we
  -- let the headline fill the entire width of the paper it could be 618px wide.
  --
  -- The widest original english headline is headline 4 for LOSE5 which is 708px
  -- wide in standard font and 520px wide in narrow font.
  local hl_font = me.lose_font
  local hl_top = 132
  local hl_w, hl_h = me.lose_font:sizeOf(headline)
  if me.lose_font:isBitmap() then
    if hl_w > 590 then
      hl_font = me.lose_font_narrow

      -- The narrow font and standard font have a different baseline so we need
      -- to adjust the top.
      hl_top = 138
    end
  else
    -- For TTF fonts we try to vertically center them in the headline area
    hl_top = 132 + math.floor((52 - hl_h) / 2)
  end

  return function(player, x, y, w, h, scale, pts)
    if pts >= start_pts then
      local vs = scale * 0.5
      player.video:scale(vs)
      hl_font:draw(player.video, headline, math.floor(x / vs), math.floor(y / vs) + hl_top, 640, 0, "center")
      player.video:scale(1)
    end
  end
end

-- The letter's cross and tick (LETTR02V in the movie's palette: 1 tick,
-- 2 tick lit, 3 cross, 4 cross lit; 41x40), where the original game has them
-- on the paper (at 640x480). The tick takes the first choice, the cross the
-- second.
local LETTER_BUTTONS = {
  {sprite = 3, lit = 4, x = 340, y = 401, choice = 2},
  {sprite = 1, lit = 2, x = 390, y = 401, choice = 1},
}
local LETTER_BUTTON_W, LETTER_BUTTON_H = 41, 40

-- The letter types itself out, as in the original game: characters a
-- second (Jan: 40 to 50).
local LETTER_TYPING_CPS = 45

-- The typewriter is part of the movie, whose own sound plays at full volume
-- whatever the volume settings, so it does not follow them either. Its
-- recording (TYPING.WAV) is quiet: it peaks at -25 dB, the movie's fanfare at
-- -1 dB (Argus: the fanfare very loud, the typing very quiet). This volume
-- plays it 6.3 times (16 dB) louder (Audio:playSound; the sound effects' gain
-- is 0.01 * e^(4.6 * volume), 1 at a volume of 1).
local LETTER_TYPING_VOLUME = 1.4

--! The UTF-8 characters of `text`, in a list.
local function utf8_chars(text)
  local chars = {}
  for c in text:gmatch("[^\128-\191][\128-\191]*") do chars[#chars + 1] = c end
  return chars
end

--! `text` in lines of at most `width` of `font`'s pixels: broken between
--! words, and between characters where a word is wider than a line (Chinese
--! and Japanese have no spaces). Laid out once, so a word being typed does
--! not jump to the next line when it is complete.
--!return (table) the lines (strings)
local function wrap_lines(font, text, width)
  local lines, line = {}, ""
  local function fits(t) return (font:sizeOf(t)) <= width end
  for word in text:gmatch("%S+") do
    local longer = line == "" and word or line .. " " .. word
    if fits(longer) then
      line = longer
    else
      if line ~= "" then lines[#lines + 1] = line end
      line = ""
      if fits(word) then
        line = word
      else
        for _, c in ipairs(utf8_chars(word)) do
          if line ~= "" and not fits(line .. c) then
            lines[#lines + 1] = line
            line = ""
          end
          line = line .. c
        end
      end
    end
  end
  if line ~= "" then lines[#lines + 1] = line end
  return lines
end

--! The letter at the end of the level won movie (WINLEVEL), written as the
--! original game writes it there: the paragraphs on the paper below its
--! letter head, typed out (Font35V in the movie's own palette, winlevel.pl8,
--! LETTER_TYPING_CPS characters a second; a click finishes it), a blank line
--! between them, smaller when they would not fit (down to half); with
--! `choose`, the cross and tick to answer it once typed
--! (MoviePlayer:letterClick).
--!param paragraphs (table) the letter's paragraphs (strings or _S strings)
--!param choose (function) [optional] called with the choice (1 tick, 2 cross)
--!return (function) the overlay for MoviePlayer:refresh, or nil without the
--! font
local winLetterOverlay = function(me, paragraphs, choose)
  local SDL = require("sdl") -- (the clock for the typing; here, not at the top: not in the unit tests)
  local gfx = me.app.gfx
  local ok, font, buttons = pcall(function()
    local palette = gfx:getPalette("winlevel.pl8")
    local text_font = gfx:loadFontAndSpriteTable("QData", "Font35V", false, palette)
    return text_font, choose and gfx:loadSpriteTable("QData", "Lettr02V", true, palette)
  end)
  if not ok or not font then return nil end

  -- The movie is 320x240, drawn at 640x480 like the lose movies' headlines.
  -- The paper there, once it has settled (about 0.25 s before the end), runs
  -- from x = 161 to 466 and y = 25 to 470; the letter head ends at y = 88.
  -- The original's text starts at x = 187, y = 158, its lines 258 wide.
  local left, top, width = 187, 158, 258
  local bottom = buttons and 396 or 452
  local start_pts = me.movie_length - 250

  -- The paragraphs as plain strings (_S strings unwrapped), laid out in rows
  -- with a blank line between paragraphs.
  local texts = {}
  for i, text in ipairs(paragraphs) do
    texts[i] = type(text) == "string" and text or tostring((TH.stringProxy._unwrap(text)))
  end
  local _, line_h = font:sizeOf("Ag")
  -- The rows in lines `line_w` font pixels wide, their height, and how many
  -- characters they have.
  local function layout(line_w)
    local rows, y, total = {}, 0, 0
    for i, text in ipairs(texts) do
      if i > 1 then y = y + line_h end
      for _, line in ipairs(wrap_lines(font, text, line_w)) do
        local chars = utf8_chars(line)
        rows[#rows + 1] = {text = line, chars = chars, y = y}
        total = total + #chars
        y = y + line_h
      end
    end
    return {rows = rows, total = total}, y
  end
  -- The text on a screen with `vs` pixels to each of the letter's: a whole
  -- number of screen pixels to each font pixel (a pixel font stretched by an
  -- uneven 3.75 has strokes of uneven width, and on Jan's MacBook S looked
  -- like B), the nearest one at which it fits on the paper, else a smaller
  -- one down to half the letter's size, else smaller as it comes.
  local page_w, page_h = width, bottom - top
  local function textFor(vs)
    local k = math.max(1, math.floor(vs + 0.5))
    while k >= 1 and k >= vs * 0.5 do
      local text, height = layout(math.floor(page_w * vs / k))
      if height * k <= page_h * vs then
        text.scale = k
        return text
      end
      k = k - 1
    end
    local fit = 1
    local text, height = layout(page_w)
    while fit > 0.5 and height * fit > page_h do
      fit = fit - 0.05
      text, height = layout(math.floor(page_w / fit))
    end
    text.scale = vs * fit
    return text
  end
  local laid_out, laid_out_vs

  local letter = {shown = false, typed = false, choose = choose}
  me.letter = letter

  return function(player, x, y, _, _, scale, pts)
    if pts < start_pts then return end
    -- Hold the letter: the movie's very last frame is its first one again (a
    -- Smacker ring frame, for looping), so it is paused here until the letter
    -- is answered or skipped (Jan saw the text over the casebook). Paused
    -- again if the pause key lets it run on.
    if not letter.hold_pts or pts > letter.hold_pts + 40 then
      player:togglePause()
      letter.hold_pts = pts
    end
    local vs = scale * 0.5
    local ui = player.app.ui
    local now = SDL.getTicks()
    if not letter.shown then
      letter.typing_from = now
      if buttons and ui and ui.default_cursor then
        ui:setCursor(ui.default_cursor) -- (the pointer, to click the buttons)
      end
    end
    letter.shown, letter.x, letter.y, letter.vs = true, x, y, vs
    if laid_out_vs ~= vs then
      laid_out, laid_out_vs = textFor(vs), vs
    end
    local total = laid_out.total
    -- How much of it is typed by now.
    local to_draw = total
    if not letter.typed then
      to_draw = math.floor((now - letter.typing_from) * LETTER_TYPING_CPS / 1000)
      if to_draw >= total then letter.typed = true end
    end
    player:letterTyping(not letter.typed)
    local s = laid_out.scale
    letter.text_scale = s
    player.video:scale(s)
    local tx = math.floor((x + left * vs) / s)
    local ty = math.floor((y + top * vs) / s)
    for _, row in ipairs(laid_out.rows) do
      if to_draw <= 0 then break end
      local n = #row.chars
      local text = row.text
      if to_draw < n then text = table.concat(row.chars, "", 1, to_draw) end
      font:draw(player.video, text, tx, ty + row.y)
      to_draw = to_draw - n
    end
    if buttons and letter.typed then
      player.video:scale(vs)
      local hover = player:letterButtonAt(player.mouse_x, player.mouse_y)
      for _, button in ipairs(LETTER_BUTTONS) do
        buttons:draw(player.video, hover == button and button.lit or button.sprite,
            math.floor(x / vs) + button.x, math.floor(y / vs) + button.y)
      end
    end
    player.video:scale(1)
    -- A cursor the screen draws itself (no hardware cursor; the movie hides
    -- the screen): drawn on the letter, or it cannot be seen (Jan).
    local cursor = buttons and ui and ui.simulated_cursor
    if cursor and player.mouse_x then
      cursor.draw(player.video, player.mouse_x, player.mouse_y)
    end
  end
end

function MoviePlayer:MoviePlayer(app, audio, video)
  self.app = app
  self.audio = audio
  self.video = video
  self.playing = false
  self.holding_bg_music = false
  self.sound = nil
  self.lose_movies = {}
  self.advance_movies = {}
  self.intro_movie = nil
  self.demo_movie = nil
  self.win_game_movie = nil
  self.win_level_movie = nil
  self.wait_for_stop = false
  self.wait_for_over = false
  self.movie_over = false
  self.movie_length = 0
  self.lose_font = nil
  self.lose_font_narrow = nil
end

--! Initialises the different movies used in the game
function MoviePlayer:init()
  self.moviePlayer = TH.moviePlayer()
  self.moviePlayer:setRenderer(self.video)

  local lose_palette = self.app.gfx:getPalette("lose.pl8")
  self.lose_font = self.app.gfx:loadFontAndSpriteTable("QData", "Font39v", false, lose_palette)
  self.lose_font_narrow = self.app.gfx:loadFontAndSpriteTable("QData", "Font40v", false, lose_palette)

  --find movies in Anims folder
  local fs = self.app.fs
  local movies = fs:listFiles("Anims")
  if movies then
    for _, movie in pairs(movies) do
      local num

      --lose level movies
      num = movie:upper():match(pathsep .. "LOSE(%d+)%.[^" .. pathsep .. "]+$")
      if num then
        self.lose_movies[tonumber(num, 10)] = fs:fileUri(movie)
      end

      --advance level movies
      num = movie:upper():match(pathsep .. "AREA(%d+)V%.[^" .. pathsep .. "]+$")
      if num then
        self.advance_movies[tonumber(num, 10)] = fs:fileUri(movie)
      end

      --win game movie
      if movie:upper():match(pathsep .. "WINGAME%.[^" .. pathsep .. "]+$") then
        self.win_game_movie = fs:fileUri(movie)
      end

      --win level movie
      if movie:upper():match(pathsep .. "WINLEVEL%.[^" .. pathsep .. "]+$") then
        self.win_level_movie = fs:fileUri(movie)
      end
    end
  end

  --find intro and demo movies
  movies = self.app.fs:listFiles("Intro")
  if movies then
    for _, movie in pairs(movies) do
      if movie:upper():match(pathsep .. "INTRO%.SM4$") then
        self.intro_movie = fs:fileUri(movie)
      elseif movie:upper():match(pathsep .. "ATTRACT.SMK$") then
        self.demo_movie = fs:fileUri(movie)
      end
    end
  end
end

--! Plays the opening movie from TH
--!param callback_after_movie (function) What to do once movie ends
function MoviePlayer:playIntro(callback_after_movie)
  self:playMovie(self.intro_movie, false, callback_after_movie)
end

--! Plays the demo gameplay footage movie from TH
function MoviePlayer:playDemoMovie()
  self:playMovie(self.demo_movie, false)
end

--! Plays the movie for winning the game
function MoviePlayer:playWinMovie()
  self:playMovie(self.win_game_movie, false)
end

--! Play the movie for winning the level
--!param callback (function) [optional] What to do after the movie ends (or
--! at once without it)
--!param letter (table) [optional] paragraphs to write on the letter it ends
--! with (otherwise the letter stays blank)
--!param choose (function) [optional] with a letter: its cross and tick to
--! answer it, called with the choice (1 tick, 2 cross); the movie then ends
--! (and `callback` follows)
function MoviePlayer:playWinLevelMovie(callback, letter, choose)
  self:playMovie(self.win_level_movie, true, callback)
  if self.playing and letter and #letter > 0 then
    -- (The mouse where it was: the screen does not track it during a movie.)
    local ui = self.app.ui
    self.mouse_x, self.mouse_y = ui and ui.cursor_x, ui and ui.cursor_y
    self.refresh_overlay = winLetterOverlay(self, letter, choose)
  end
end

--! The win letter's button (LETTER_BUTTONS) at screen position (mx, my), once
--! the letter shows, or nil.
function MoviePlayer:letterButtonAt(mx, my)
  local letter = self.letter
  if not (letter and letter.shown and letter.typed and letter.choose and mx and my) then
    return nil
  end
  local lx, ly = (mx - letter.x) / letter.vs, (my - letter.y) / letter.vs
  for _, button in ipairs(LETTER_BUTTONS) do
    if lx >= button.x and lx < button.x + LETTER_BUTTON_W and
        ly >= button.y and ly < button.y + LETTER_BUTTON_H then
      return button
    end
  end
end

--! The typewriter while the win letter types itself out: the game's own key
--! strike (TYPING.WAV) round and round, until it is typed, unless sound
--! effects are off.
--!param on (boolean) typing now
function MoviePlayer:letterTyping(on)
  if on and self.typing_sound == nil then
    -- (false: no sound to be had, or sound effects off; not tried again)
    local ok, sound = false, nil
    if self.app.config.play_sounds then
      ok, sound = pcall(self.audio.playSound, self.audio, "TYPING.WAV", nil, false, nil, nil, -1,
          LETTER_TYPING_VOLUME)
    end
    self.typing_sound = ok and sound or false
  elseif not on and self.typing_sound then
    self.audio:stopSound(self.typing_sound)
    self.typing_sound = false
  end
end

--! The mouse has moved while a movie plays (the win letter's buttons light up).
function MoviePlayer:mouseMove(x, y)
  self.mouse_x, self.mouse_y = x, y
end

--! A left click while a movie plays. On the win letter while it types
--! itself out, the click finishes it. Once typed, on a letter with buttons a
--! button answers it and ends the movie, and a click anywhere else does
--! nothing (nor one before the letter shows, within 2 seconds); a letter
--! without buttons ends with the click. (The stop movie key still ends it
--! without an answer.)
--!return (boolean) true if the letter took the click (the movie goes on)
function MoviePlayer:letterClick(x, y)
  local letter = self.letter
  if not letter then return false end
  if not letter.shown then return letter.choose ~= nil end
  if not letter.typed then
    letter.typed = true
    return true
  end
  if not letter.choose then return false end
  local button = self:letterButtonAt(x, y)
  if button then
    self.letter = nil
    letter.choose(button.choice)
    self:stop()
  end
  return true
end

--! Plays the level advance movie, which is going to the next level on the game board
--! This is for the original campaign only.
--!param level (number) What level we're going to.
function MoviePlayer:playAdvanceMovie(level)
  local filename = self.advance_movies[level]

  if self.moviePlayer == nil or not self.moviePlayer:getEnabled() or
      not self.app.config.movies or filename == nil then
    return
  end

  if self.audio.background_music then
    self.holding_bg_music = self.audio:pauseBackgroundTrack()
  end

  if level == 12 then
    self.sound = self.audio:playSound("DICE122M.WAV")
  else
    self.sound = self.audio:playSound("DICEYFIN.WAV")
  end
  self:playMovie(filename, true)
end

--! Plays one of the lose scenario movies at random
--!param callback (function) [optional] What to do after the movie ends (or
--! at once without it)
function MoviePlayer:playLoseMovie(callback)
  if #self.lose_movies > 0 then
    local lose_movie_index = math.cosmetic_random(#self.lose_movies)
    local filename = self.lose_movies[lose_movie_index]
    self:playMovie(filename, true, callback)
    self.refresh_overlay = loseMovieOverlay(self, lose_movie_index)
  elseif callback then
    callback()
  end
end

--! Function used to tell the Movie Player to play something.
--!param filename (string) Location of the movie file
--!param wait_for_stop (boolean) If true, movie will not dismiss automatically
--! (requires a mouse/key press)
--!param callback (function) What to do after the movie ends
function MoviePlayer:playMovie(filename, wait_for_stop, callback)
  local success, warning

  if self.moviePlayer == nil or not self.moviePlayer:getEnabled() or
      not self.app.config.movies or filename == nil then
    if callback then
      callback()
    end
    return
  end

  success, warning = self.moviePlayer:load(filename)
  if warning ~= nil and warning ~= "" then
    local message = "MoviePlayer:playMovie - Warning: " .. warning
    if self.app.world then
      self.app.world:gameLog(message)
    elseif self.app.config.debug then
      print(message)
    end
  end
  if not success then
    -- Indicates failure to load movie
    if callback then
      callback()
    end
    return
  end
  -- Abort any loading of music
  self.audio.load_music = false
  if self.moviePlayer:hasAudioTrack() then
    if self.audio.background_music then
      self.holding_bg_music = self.audio:pauseBackgroundTrack()
    end
  end

  self.movie_length = self.moviePlayer:getLength()

  self.video:startFrame()
  self.video:fillBlack()
  self.video:endFrame()

  self.wait_for_stop = wait_for_stop
  self.wait_for_over = true

  self.callback_on_destroy_movie = callback

  self.opengl_mode_index = nil
  for i=1, #self.app.modes do
    if self.app.modes[i] == "opengl" then
      self.opengl_mode_index = i
    end
  end
  if self.opengl_mode_index then
    self.app.modes[self.opengl_mode_index] = ""
  end

  warning = self.moviePlayer:play()
  if warning ~= nil and warning ~= "" then
    local message = "MoviePlayer:playMovie - Warning: " .. warning
    if self.app.world then
      self.app.world:gameLog(message)
    elseif self.app.config.debug then
      print(message)
    end
  end
  self.playing = true
end

--NB: Call after any changes to TH.surface
function MoviePlayer:allocatePictureBuffer()
  if self.moviePlayer == nil then return end

  self.moviePlayer:allocatePictureBuffer()
end

--NB: Call before any changes to TH.surface
function MoviePlayer:deallocatePictureBuffer()
  if self.moviePlayer == nil then return end

  self.moviePlayer:deallocatePictureBuffer()
end

--! Handles when the movie ends
function MoviePlayer:onMovieOver()
  if self.moviePlayer == nil then return end

  self.movie_over = true
  self.wait_for_over = false
  if not self.wait_for_stop then
    destroyMovie(self)
  end
end

--! Handles ending the movie prematurely (user input)
function MoviePlayer:stop()
  if self.moviePlayer == nil then return end

  self.moviePlayer:stop()
  self.wait_for_stop = false
  if not self.wait_for_over then
    destroyMovie(self)
  end
end

function MoviePlayer:refresh()
  if self.moviePlayer == nil then return end

  local x, y, w, h, scale = calculateSize(self)
  local pts = self.moviePlayer:refresh(x, y, w, h)
  if self.refresh_overlay then
    self.refresh_overlay(self, x, y, w, h, scale, pts)
  end
end

function MoviePlayer:updateRenderer()
  if self.moviePlayer == nil then return end

  self.moviePlayer:setRenderer(self.video)
end

function MoviePlayer:togglePause()
  if self.moviePlayer == nil then return end

  self.moviePlayer:togglePause()
  if self.sound then
    self.audio:togglePauseSound(self.sound)
  end
end
