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

--! Multiplayer: the land auction (world.mp_auction, see the auctions in
--! mp_session.lua), on the game's auction room picture: the bidders with
--! their bids, the town with the lot in red, this player's next bid (the
--! tick) and the highest bid. Every player sees it; those whose land borders
--! the lot bid. Bids are commands (auction_bid, auction_pass).
class "UIMultiplayerAuction" (UIFullscreen)

---@class UIMultiplayerAuction: UIFullscreen
---@operator call: UIMultiplayerAuction
local UIMultiplayerAuction = _G["UIMultiplayerAuction"] ---@type UIMultiplayerAuction

-- Places on the picture (640 x 480; the tick, the cross and "Lot 01" are
-- part of it).
local ROW_Y, ROW_H = {88, 151, 214, 277}, 32 -- the four bidder bars
local NAME_X, NAME_W = 30, 146
local VALUE_X, VALUE_W = 188, 78 -- (left of the colour)
local SWATCH_X, SWATCH_W = 269, 12
local MAP_X, MAP_Y, MAP_W, MAP_H = 330, 70, 262, 268 -- the frame's inside
local GAVEL_X, GAVEL_Y = 14, 452 -- bottom left of the gavel frames
local TICK_X, TICK_Y = 158, 392
local BID_X, BID_W, BID_Y = 190, 96, 383
local LEAD_X, LEAD_W, LEAD_VALUE_X, LEAD_VALUE_W = 330, 170, 508, 96
local CROSS_X, CROSS_Y = 608, 448
local STATUS_X, STATUS_Y, STATUS_W = 16, 6, 608
local MAP_BG = {44, 96, 52}
local LOT_COLOUR = {236, 52, 28}

-- The gavel: frames 3 (down) to 10 (raised). A blow: up, then down.
local GAVEL_REST = 3
local BLOW = {4, 6, 8, 10, 10, 8, 6, 4, 3, 3}

function UIMultiplayerAuction:UIMultiplayerAuction(ui)
  self:UIFullscreen(ui)
  local gfx = ui.app.gfx
  self.world = ui.app.world
  self.esc_closes = false
  if not pcall(function()
    self.background = gfx:loadRaw("Bid01V", 640, 480, "QData", "QData", "Bid01V.pal", true)
    local palette = gfx:getPalette("Bid01V.pal")
    self.panel_sprites = gfx:loadSpriteTable("QData", "Bid02V", true, palette)
    -- Names light yellow on the bars (the awards screen's font, in its own
    -- colours: with this picture's it looks worn), sums in the white boxes.
    self.name_font = gfx:loadFontAndSpriteTable("QData", "Font45V", false, gfx:getPalette("Award02V.pal"),
        {apply_ui_scale = true})
    self.sum_font = gfx:loadFontAndSpriteTable("QData", "Font60V", false, palette, {apply_ui_scale = true})
    self.status_font = gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil,
        {ttf_shadow = true, apply_ui_scale = true})
  end) then
    ui:addWindow(UIInformation(ui, {_S.errors.dialog_missing_graphics}))
    self:close()
    return
  end
  local auction = self.world.mp_auction
  self.auction_id = auction and auction.id
  -- (Pressed: the sprite over the picture's tick or cross.)
  self.tick = self:addPanel(0, TICK_X, TICK_Y):makeButton(0, 0, 28, 28, 1, self.bid)
  self.cross = self:addPanel(0, CROSS_X, CROSS_Y):makeButton(0, 0, 25, 25, 2, self.dropOut)
  self.gavel_frame = GAVEL_REST
  self.blow = nil
  self.going = 0
  self.timer = 0
  self:makeRuns()
  ui:playSound("selectx.wav")
end

--! The town for the small map, as rectangles (self.rects: x, y, w, h in
--! the map's pixels, colour, and whether it is the lot): the land owned so
--! far, the part of the map with land on it (all of it if it fits), each
--! hospital's floor in its colour, its rooms a little darker, walls and
--! furniture dark; the lot red.
function UIMultiplayerAuction:makeRuns()
  local world = self.world
  local auction = world.mp_auction
  local th = world.map.th
  local w, h = th:size()
  local video = TheApp.video
  local function rgb(c, f)
    return video:mapRGB(math.floor(c[1] * f), math.floor(c[2] * f), math.floor(c[3] * f))
  end
  local owners = {}
  for _, hospital in ipairs(world.hospitals) do
    local c = MultiplayerSession.markerColour(world, hospital)
    if c then owners[hospital:getPlayerIndex()] = {floor = rgb(c, 1), room = rgb(c, 0.78)} end
  end
  local lot = rgb(LOT_COLOUR, 1)
  local wall = video:mapRGB(36, 28, 24)
  -- Each tile: what it shows (nil: grass), and the part of the map with land.
  local flags = {}
  local tile = {}
  local x0, y0, x1, y1 = w, h, 1, 1
  for y = 1, h do
    for x = 1, w do
      local p = th:getCellFlags(x, y, flags).parcelId or 0
      local c
      if p ~= 0 then
        if auction and p == auction.plot then
          c = lot
        else
          local owner = owners[th:getPlotOwner(p)]
          if owner then c = world:getRoom(x, y) and owner.room or owner.floor end
        end
      end
      if c then
        tile[(y - 1) * w + x] = c
        x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
      end
    end
  end
  if x0 > x1 then x0, y0, x1, y1 = 1, 1, w, h end
  -- A margin, then as big as it fits (whole pixels a tile, 2 to 6).
  x0, y0 = math.max(1, x0 - 4), math.max(1, y0 - 4)
  x1, y1 = math.min(w, x1 + 4), math.min(h, y1 + 4)
  local bw, bh = x1 - x0 + 1, y1 - y0 + 1
  local px = math.max(2, math.min(6, math.floor(math.min(MAP_W / bw, MAP_H / bh))))
  if bw * px > MAP_W or bh * px > MAP_H then -- (a big map: all of it, smaller)
    x0, y0, bw, bh = 1, 1, w, h
    px = math.min(MAP_W / w, MAP_H / h)
  end
  local ox = (MAP_W - bw * px) / 2 - (x0 - 1) * px
  local oy = (MAP_H - bh * px) / 2 - (y0 - 1) * px
  local rects = {}
  local function add(tx, ty, tw, th_, colour)
    local rx, ry = math.floor(ox + tx * px), math.floor(oy + ty * px)
    rects[#rects + 1] = {rx, ry, math.max(1, math.floor(ox + (tx + tw) * px) - rx),
        math.max(1, math.floor(oy + (ty + th_) * px) - ry), colour, colour == lot}
  end
  -- Floors, in runs along each row.
  for y = y0, y0 + bh - 1 do
    local start, colour
    for x = x0, x0 + bw do
      local c = x < x0 + bw and tile[(y - 1) * w + x] or nil
      if c ~= colour then
        if colour then add(start - 1, y - 1, x - start, 1, colour) end
        start, colour = x, c
      end
    end
  end
  -- Walls (a north or west wall at a tile of owned land, or by one) and
  -- the furniture of the owned land (not the lot: its rooms are not shown).
  local line = math.max(1, math.floor(px / 3)) / px -- in tiles
  local function owned(x, y)
    local c = x >= 1 and y >= 1 and x <= w and y <= h and tile[(y - 1) * w + x]
    return c and c ~= lot
  end
  local function is_wall(block) block = block % 256 return block >= 82 and block <= 164 end
  for y = y0, y0 + bh - 1 do
    for x = x0, x0 + bw - 1 do
      if owned(x, y) or owned(x, y - 1) or owned(x - 1, y) then
        local _, north, west = th:getCell(x, y)
        if is_wall(north) and (owned(x, y) or owned(x, y - 1)) then add(x - 1, y - 1, 1, line, wall) end
        if is_wall(west) and (owned(x, y) or owned(x - 1, y)) then add(x - 1, y - 1, line, 1, wall) end
      end
    end
  end
  if px >= 3 then
    for _, e in ipairs(world.entities) do
      local x, y = e.tile_x, e.tile_y
      if x and e.object_type and owned(x, y) and x >= x0 and y >= y0 and x < x0 + bw and y < y0 + bh then
        add(x - 1 + 0.3, y - 1 + 0.3, 0.4, 0.4, wall)
      end
    end
  end
  self.rects = rects
end

--! Where this player stands: "bid" (may bid now), "lead", "out", "poor"
--! (cannot afford the next bid), "watch" (not a bidder) or "over".
function UIMultiplayerAuction:standing()
  local auction = self.world.mp_auction
  if not auction or auction.id ~= self.auction_id then return "over" end
  local index = self.world:getHospitalIndex(self.ui.hospital)
  local bidder = false
  for _, i in ipairs(auction.bidders) do bidder = bidder or i == index end
  if not bidder then return "watch" end
  if auction.out[index] then return "out" end
  if auction.leader == index then return "lead" end
  if auction.bid + auction.step > self.ui.hospital.balance then return "poor" end
  return "bid"
end

function UIMultiplayerAuction:bid()
  local auction = self.world.mp_auction
  local session = TheApp.mp_session
  if self:standing() ~= "bid" or not session then
    self.ui:playSound("wrong2.wav")
    return
  end
  session:issue({kind = "auction_bid", auction = auction.id, amount = auction.bid + auction.step})
end

--! The cross: a bidder drops out (and the screen closes); for the others it
--! only closes the screen.
function UIMultiplayerAuction:dropOut()
  local standing = self:standing()
  local session = TheApp.mp_session
  if (standing == "bid" or standing == "poor") and session then
    session:issue({kind = "auction_pass", auction = self.auction_id})
  elseif standing == "lead" then
    self.ui:playSound("wrong2.wav")
    return
  end
  if session then session.auction_closed = self.auction_id end
  self:close()
end

--! The auction ended (MultiplayerSession:syncAuction): a last blow of the
--! gavel, then the screen closes.
function UIMultiplayerAuction:finish()
  if self.closing_in then return end
  self.closing_in = 50 -- ticks (about 2 seconds)
  self.blow = 1
  self:makeRuns() -- the lot in its new owner's colour
end

function UIMultiplayerAuction:onTick()
  self.timer = self.timer + 1
  if self.blow then
    self.gavel_frame = BLOW[self.blow]
    self.blow = self.blow + 1
    if self.blow > #BLOW then self.blow, self.gavel_frame = nil, GAVEL_REST end
    if self.blow == 9 then self.ui:playSound("selectx.wav") end
  end
  if self.closing_in then
    self.closing_in = self.closing_in - 1
    if self.closing_in <= 0 then self:close() end
  else
    -- Going once, going twice: a blow each.
    local going = self:going_stage()
    if going > self.going then self.blow = 1 end
    self.going = going
  end
  return UIFullscreen.onTick(self)
end

--! 0, or 1 (going once) / 2 (going twice) near the end of the time.
function UIMultiplayerAuction:going_stage()
  local auction = self.world.mp_auction
  if not auction or auction.id ~= self.auction_id then return self.going end
  local left = (auction.limit - auction.frames) * 18 / 1000 -- seconds
  if left <= 3 then return 2 elseif left <= 6 then return 1 end
  return 0
end

function UIMultiplayerAuction:draw(canvas, x_, y_)
  local s = TheApp.gfx:getUIScale()
  canvas:scale(s, "bitmap")
  self.background:draw(canvas, self.x * s + x_, self.y * s + y_)
  canvas:scale(1, "bitmap")
  UIFullscreen.draw(self, canvas, x_, y_)
  local x, y = self.x * s + x_, self.y * s + y_
  local world = self.world
  local auction = world.mp_auction
  if auction and auction.id ~= self.auction_id then auction = nil end
  local last = not auction and world.mp_auction_last
  if last and last.id ~= self.auction_id then last = nil end
  local shown = auction or last
  local S = _S.multiplayer_window
  local name_font, sum_font = self.name_font, self.sum_font
  -- (The fonts' letters sit a little high: a few pixels lower is the
  -- middle of a bar or box.) A name too long ends in "...".
  local function name_text(text, tx, ty, w, h)
    text = tostring(text)
    if name_font:sizeOf(text) > w then
      local n = #text
      while n > 1 and name_font:sizeOf(text:sub(1, n) .. "...") > w do n = n - 1 end
      text = text:sub(1, n):gsub("[%s_]+$", "") .. "..." -- (this font draws _ as a blank)
    end
    name_font:draw(canvas, text, tx, ty + 5 * s, w, h, "left")
  end
  local function sum_text(text, tx, ty, w, h)
    sum_font:draw(canvas, text, tx, ty + 4 * s, w, h, "center")
  end

  -- The bidders: name, bid (or "out"), colour.
  if shown then
    for row, index in ipairs(shown.bidders) do
      local ry = ROW_Y[row]
      if not ry then break end
      local hospital = world.hospitals[index]
      name_text(hospital and hospital.name or "?", x + NAME_X * s, y + ry * s, NAME_W * s, ROW_H * s)
      local value = shown.out[index] and S.auction_out or tostring(shown.bids[index] or 0)
      sum_text(value, x + VALUE_X * s, y + ry * s, VALUE_W * s, ROW_H * s)
      local c = hospital and MultiplayerSession.markerColour(world, hospital)
      if c then
        canvas:drawRect(canvas:mapRGB(c[1], c[2], c[3]), x + SWATCH_X * s, y + (ry + 11) * s, SWATCH_W * s, 23 * s)
      end
    end
  end

  -- The town, the lot in red (blinking).
  local mx, my = x + MAP_X * s, y + MAP_Y * s
  local lot_on = math.floor(self.timer / 12) % 2 == 0 or not auction
  canvas:drawRect(canvas:mapRGB(MAP_BG[1], MAP_BG[2], MAP_BG[3]), mx, my, MAP_W * s, MAP_H * s)
  for _, r in ipairs(self.rects) do
    if lot_on or not r[6] then canvas:drawRect(r[5], mx + r[1] * s, my + r[2] * s, r[3] * s, r[4] * s) end
  end

  -- The gavel.
  local sprites = self.panel_sprites
  local _, gh = sprites:size(self.gavel_frame)
  sprites:draw(canvas, self.gavel_frame, x + GAVEL_X * s, y + (GAVEL_Y - gh) * s, {scaleFactor = s})

  -- This player's next bid, and the highest one.
  local standing = self:standing()
  if auction then
    local next_bid = (standing == "bid" or standing == "poor") and tostring(auction.bid + auction.step) or ""
    sum_text(next_bid, x + BID_X * s, y + BID_Y * s, BID_W * s, ROW_H * s)
    local leader = world.hospitals[auction.leader]
    name_text(leader and leader.name or "", x + LEAD_X * s, y + BID_Y * s, LEAD_W * s, ROW_H * s)
    sum_text(tostring(auction.bid), x + LEAD_VALUE_X * s, y + BID_Y * s, LEAD_VALUE_W * s, ROW_H * s)
  end

  -- What is going on, at the top.
  local status
  if not auction then
    status = last and (last.sold and S.auction_sold:format(last.plot, last.name, last.bid) or
        S.auction_not_sold:format(last.plot)) or ""
  else
    local going = self:going_stage()
    if going == 2 then status = S.auction_going_twice
    elseif going == 1 then status = S.auction_going_once
    elseif standing == "watch" then status = S.auction_watching
    elseif standing == "lead" then status = S.auction_leading
    elseif standing == "out" then status = S.auction_dropped
    elseif standing == "poor" then status = S.auction_no_money
    else status = S.auction_price:format(auction.price, auction.step) end
    status = S.auction_title:format(auction.plot) .. ". " .. status .. " " .. S.auction_paused
  end
  self.status_font:drawWrapped(canvas, status, x + STATUS_X * s, y + STATUS_Y * s, STATUS_W * s)
end

--------------------------------------------------------------------------------

--! While an auction this player closed the screen of is still on: the game
--! stands still, and this box says why, with the way back to the auction.
--! It cannot be closed; it goes when the auction is over
--! (MultiplayerSession:syncAuction).
class "UIMultiplayerAuctionWait" (UIResizable)

---@class UIMultiplayerAuctionWait: UIResizable
---@operator call: UIMultiplayerAuctionWait
local UIMultiplayerAuctionWait = _G["UIMultiplayerAuctionWait"] ---@type UIMultiplayerAuctionWait

local wait_col = {
  bg     = {red = 92, green = 60, blue = 40},
  text   = {red = 70, green = 44, blue = 28},
  button = {red = 132, green = 92, blue = 56},
}

function UIMultiplayerAuctionWait:UIMultiplayerAuctionWait(ui)
  local S = _S.multiplayer_window
  self:UIResizable(ui, 320, 96, wait_col.bg)
  self.esc_closes = false
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.4)
  self.default_button_sound = "selectx.wav"
  self:addBevelPanel(20, 12, 280, 26, wait_col.text):setLabel(S.auction_wait).lowered = true
  self:addBevelPanel(70, 52, 180, 30, wait_col.button):setLabel(S.auction_back)
      :makeButton(0, 0, 180, 30, nil, self.back)
end

--! Back to the auction screen.
function UIMultiplayerAuctionWait:back()
  local session = TheApp.mp_session
  local ui = self.ui
  self:close()
  if session then session.auction_closed = nil end
  local world = ui.app.world
  if world and world.mp_auction and not ui:getWindow(UIMultiplayerAuction) then
    ui:addWindow(UIMultiplayerAuction(ui))
  end
end
