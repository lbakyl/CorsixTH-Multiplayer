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

local TH = require("TH")
local Entity = _G['Entity'] ---@type Entity

--! The litter bomb of the original's network game, a multiplayer dirty trick
--! (mp_sabotage.lua): planted in a rival's corridor, its fuse burns down,
--! then it goes off and throws litter all around. The players of the
--! hospital it is in may click it to pick it up and throw it on.
local object = {}
object.id = "litter_bomb"
object.thob = 17 -- the original's own number for it (its name and tooltip)
object.name = _S.object.litter_bomb
object.tooltip = _S.tooltip.objects.litter_bomb
object.ticks = true
object.class = "LitterBomb"
-- The original's art: the bomb with its fuse burning down in 8 stages (2
-- flickering frames each), and its picture for the buy list.
object.fuse_animations = {4990, 4992, 4994, 4996, 4998, 5000, 5002, 5004}
object.build_preview_animation = 5062

class "LitterBomb" (Entity)

---@class LitterBomb: Entity
---@operator call: LitterBomb
local LitterBomb = _G["LitterBomb"] ---@type LitterBomb

LitterBomb.hover_cursor = TheApp.gfx:loadMainCursor("grab")

--! A bomb on the floor at (x, y) of `hospital` (World:newObject); the
--! sabotage module lights it (its state is `mp_bomb`).
function LitterBomb:LitterBomb(hospital, object_type, x, y)
  self:Entity(TH.animation())
  self.ticks = true
  self.object_type = object_type
  self.hospital = hospital
  self.world = hospital.world
  -- (Small: the box around it is easier to hit than its pixels.)
  self.permanent_flags = DrawFlags.BoundBoxHitTest
  self:setAnimation(object_type.fuse_animations[1])
  self:setTile(x, y)
end

function LitterBomb:getDrawingLayer()
  return DrawingLayers.Entity
end

--! The fuse stage animation for what is left of the fuse (1 = all of it).
function LitterBomb:showFuse(stage)
  local anims = self.object_type.fuse_animations
  stage = math.max(1, math.min(#anims, stage))
  if self.animation_idx ~= anims[stage] then self:setAnimation(anims[stage]) end
end

function LitterBomb:tick()
  Entity.tick(self)
  corsixth.require("mp_sabotage").bombTick(self)
end

-- When this machine last asked to pick a bomb up (not part of the game,
-- nor of a save): a second click meanwhile asks nothing.
local asked = setmetatable({}, {__mode = "k"})

--! A click picks it up (players of the hospital it is in; every peer at the
--! same step: the lockstep command `litter_bomb_pick`).
function LitterBomb:onClick(ui, button)
  if button ~= "left" then return end
  local session = TheApp.mp_session
  if not session or session.applying or not self.mp_bomb or self.mp_bomb.gone then return end
  if self.hospital ~= ui.hospital then return end
  local now = require("sdl").getTicks()
  if asked[self] and now - asked[self] < 2000 then return end
  asked[self] = now
  ui:playSound("pickup.wav")
  session:issue({kind = "litter_bomb_pick", bomb = self.mp_id})
end

return object
