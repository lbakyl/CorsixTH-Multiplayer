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

--! A random number stream for purely cosmetic choices (screen shake, which
--! sound variant to play, tips, headlines, ...).
--!
--! Gameplay must keep using math.random, whose state is saved with the game
--! and must evolve identically for every player in multiplayer. Rendering
--! and audio run at different rates on different machines and can be
--! disabled per player, so they must never consume the gameplay stream.
--!
--! Park-Miller "minimal standard" generator (multiplier 48271, modulus
--! 2^31 - 1). Every intermediate value fits exactly in a double, so this
--! behaves identically on Lua 5.1 to 5.5 and LuaJIT. Its state is not saved.
local MODULUS = 2147483647
local MULTIPLIER = 48271

--! Create a generator.
--!param seed (number) Any number; only its integer part modulo 2^31 - 1 is used.
--!return (function) Generator with the same calling convention as math.random:
--!  () -> float in [0, 1); (m) -> integer in [1, m]; (m, n) -> integer in [m, n].
local function new_cosmetic_random(seed)
  local state = math.floor(math.abs(seed or 0)) % MODULUS
  if state == 0 then state = 1 end

  return function(m, n)
    state = (state * MULTIPLIER) % MODULUS
    local u = (state - 1) / (MODULUS - 1) -- in [0, 1)
    if m == nil then
      return u
    end
    if n == nil then
      m, n = 1, m
    end
    assert(m <= n, "interval is empty")
    return m + math.floor(u * (n - m + 1))
  end
end

return new_cosmetic_random
