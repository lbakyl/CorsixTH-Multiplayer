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
--! their bids, the town with the lot in red and the other plots for sale in
--! sand, this player's next bid (the tick), the highest bid, and the seconds
--! left in big digits. Every player sees it; those whose land borders the
--! lot bid. Bids are commands (auction_bid, auction_pass). The town map
--! button opens the game's town map; the auction comes back after it.
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
local LOAN_X, LOAN_Y, LOAN_W, LOAN_H = 30, 334, 186, 26 -- the bank, under the bars
local LOAN_STEP = 5000
local loan_col = {
  text   = {red = 70, green = 44, blue = 28},
  button = {red = 132, green = 92, blue = 56},
}
local MAP_BG = {44, 96, 52}
local LOT_COLOUR = {236, 52, 28}
local FOR_SALE_COLOUR = {196, 172, 112} -- (plots nobody owns yet: Argus, 2026-11-12)
-- The seconds left: big digits in a box next to the gavel (Jan, 2026-11-12),
-- in the middle under this player's bid.
-- The leader (Jan: the box under the map looked like a mistake, the same
-- name twice): their bar framed, "Winning bidder" under the box.
local BAR_X, BAR_W, BAR_H = 12, 285, 47 -- a bidder bar (from ROW_Y)
local LEADER_FRAME = 4 -- the yellow frame round the leader's bar, pixels
local WIN_Y, WIN_W = 434, 260 -- the caption under the leader's box (one row in all 22 languages)
local CLOCK_W, CLOCK_H = 70, 38
local CLOCK_X, CLOCK_Y = BID_X + math.floor((BID_W - CLOCK_W) / 2), 434
local DIGIT_W, DIGIT_H, DIGIT_T, DIGIT_GAP = 18, 28, 4, 6
local TOWN_LEADER_MID = 461 -- the middle of the leader's box (name and sum)
-- (The town map button: the map's top left corner, Jan.)
local TOWN_X, TOWN_Y, TOWN_W, TOWN_H = MAP_X + 4, MAP_Y + 4, 120, 22

-- The gavel: frames 10 (raised) to 3 (down). As in the original game it
-- comes down slowly while nobody bids, is raised again by every bid, and
-- the plot is sold when it is down (Mantroftt, via Jan).
local GAVEL_UP, GAVEL_DOWN = 10, 3

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
    -- (The line at the top, at twice the size: drawn on a scaled canvas.)
    self.big_font = gfx:loadFontAndSpriteTable("QData", "Font01V", nil, nil, {ttf_shadow = true})
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
  -- The bank: borrow (or pay back) $5,000 without leaving the auction.
  self.loan_panel = self:addBevelPanel(LOAN_X, LOAN_Y, LOAN_W, LOAN_H, loan_col.text)
  self.loan_panel.lowered = true
  self.loan_panel:setTooltip(_S.multiplayer_window.auction_loan_tooltip)
  self.loan_panel:setLabel(_S.multiplayer_window.auction_loan:format(math.floor(ui.hospital.balance),
      ui.hospital.loan or 0))
  self.repay_button = self:addBevelPanel(LOAN_X + LOAN_W + 6, LOAN_Y, 32, LOAN_H, loan_col.button):setLabel("-")
      :makeButton(0, 0, 32, LOAN_H, nil, self.repayLoan):setTooltip(_S.multiplayer_window.auction_repay_tooltip)
  self.borrow_button = self:addBevelPanel(LOAN_X + LOAN_W + 42, LOAN_Y, 32, LOAN_H, loan_col.button):setLabel("+")
      :makeButton(0, 0, 32, LOAN_H, nil, self.borrow):setTooltip(_S.multiplayer_window.auction_borrow_tooltip)
  self.town_button = self:addBevelPanel(TOWN_X, TOWN_Y, TOWN_W, TOWN_H, loan_col.button)
      :setLabel(_S.tooltip.toolbar.town_map:format("F4"))
      :makeButton(0, 0, TOWN_W, TOWN_H, nil, self.openTownMap)
  self.gavel_frame = GAVEL_UP
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
  local for_sale = rgb(FOR_SALE_COLOUR, 1)
  local border = video:mapRGB(28, 36, 28)
  local parcel = {} -- each tile's plot (0: none)
  local wall = video:mapRGB(36, 28, 24)
  -- Each tile: what it shows (nil: grass), and the part of the map with land.
  local flags = {}
  local tile = {}
  local x0, y0, x1, y1 = w, h, 1, 1
  for y = 1, h do
    for x = 1, w do
      local p = th:getCellFlags(x, y, flags).parcelId or 0
      parcel[(y - 1) * w + x] = p
      local c
      if p ~= 0 then
        if auction and p == auction.plot then
          c = lot
        else
          local who = th:getPlotOwner(p)
          local owner = owners[who]
          if owner then
            c = world:getRoom(x, y) and owner.room or owner.floor
          elseif who == 0 then
            c = for_sale
          end
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
    return c and c ~= lot and c ~= for_sale
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
  -- Thin lines between the plots (and round them), and each plot's number
  -- in its middle (Argus, 2026-11-12: as on the town map, to see how many
  -- plots there are).
  local function plot_at(x, y)
    return x >= 1 and y >= 1 and x <= w and y <= h and parcel[(y - 1) * w + x] or 0
  end
  local one = 1 / px -- (a screen pixel, in tiles)
  local tiles_of = {}
  for y = y0, y0 + bh - 1 do
    for x = x0, x0 + bw - 1 do
      local p = plot_at(x, y)
      if p ~= 0 then
        local t = tiles_of[p] or {n = 0, sx = 0, sy = 0}
        tiles_of[p] = t
        t.n, t.sx, t.sy = t.n + 1, t.sx + x, t.sy + y
      end
      if p ~= plot_at(x + 1, y) and (p ~= 0 or plot_at(x + 1, y) ~= 0) then
        add(x - one, y - 1, one, 1, border)
      end
      if p ~= plot_at(x, y + 1) and (p ~= 0 or plot_at(x, y + 1) ~= 0) then
        add(x - 1, y - one, 1, one, border)
      end
    end
  end
  self.plot_labels = {}
  for p, t in pairs(tiles_of) do
    -- (The tile of the plot nearest its middle: an L-shaped plot's middle
    -- may be outside it.)
    local mx, my = t.sx / t.n, t.sy / t.n
    local best, best_d
    for y = y0, y0 + bh - 1 do
      for x = x0, x0 + bw - 1 do
        if plot_at(x, y) == p then
          local d = (x - mx) ^ 2 + (y - my) ^ 2
          if not best_d or d < best_d then best, best_d = {x, y}, d end
        end
      end
    end
    -- (Only where the number fits: a plot of a few pixels gets none.)
    if best and t.n * px * px >= 120 then
      self.plot_labels[#self.plot_labels + 1] = {p, math.floor(ox + (best[1] - 0.5) * px),
          math.floor(oy + (best[2] - 0.5) * px)}
    end
  end
  table.sort(self.plot_labels, function(a, b) return a[1] < b[1] end)
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

--! The largest loan this hospital may have (as at the bank).
function UIMultiplayerAuction:maxLoan()
  local hospital = self.ui.hospital
  if self.world.free_build_mode then return 0 end
  return math.floor((hospital.value * 0.33) / 5000) * 5000 + 10000
end

--! "+": borrow $5,000 (a shared command, as the bank manager's).
function UIMultiplayerAuction:borrow()
  local hospital, session = self.ui.hospital, TheApp.mp_session
  if not session or hospital.loan + LOAN_STEP > self:maxLoan() then
    self.ui:playSound("wrong2.wav")
    return
  end
  session:issue({kind = "loan", amount = LOAN_STEP})
  self.ui:playSound("selectx.wav")
end

--! "-": pay $5,000 of the loan back.
function UIMultiplayerAuction:repayLoan()
  local hospital, session = self.ui.hospital, TheApp.mp_session
  if not session or hospital.loan < LOAN_STEP or hospital.balance < LOAN_STEP then
    self.ui:playSound("wrong2.wav")
    return
  end
  session:issue({kind = "loan", amount = -LOAN_STEP})
  self.ui:playSound("selectx.wav")
end

--! The town map (to see every plot), over this screen; the auction comes
--! back when it is closed (MultiplayerSession:syncAuction).
function UIMultiplayerAuction:openTownMap()
  local town = rawget(_G, "UITownMap")
  if not town then return end
  self.ui:addWindow(town(self.ui))
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

--! The auction ended (MultiplayerSession:syncAuction): the gavel down with
--! a knock, then the screen closes.
function UIMultiplayerAuction:finish()
  if self.closing_in then return end
  self.closing_in = 50 -- ticks (about 2 seconds)
  self.gavel_frame = GAVEL_DOWN
  self.ui:playSound("selectx.wav")
  self:makeRuns() -- the lot in its new owner's colour
end

function UIMultiplayerAuction:onTick()
  self.timer = self.timer + 1
  -- The bank: balance and loan.
  local hospital = self.ui.hospital
  self.loan_panel:setLabel(_S.multiplayer_window.auction_loan:format(math.floor(hospital.balance), hospital.loan or 0))
  if self.closing_in then
    self.closing_in = self.closing_in - 1
    if self.closing_in <= 0 then self:close() end
  else
    -- The gavel sinks as the time without a bid runs out.
    local auction = self.world.mp_auction
    if auction and auction.id == self.auction_id and auction.limit > 0 then
      local done = math.min(1, auction.frames / auction.limit)
      self.gavel_frame = GAVEL_UP - math.floor(done * (GAVEL_UP - GAVEL_DOWN) + 0.5)
    end
    self.going = self:going_stage()
  end
  return UIFullscreen.onTick(self)
end

--! 0, or 1 (going once) / 2 (going twice) near the end of the time.
function UIMultiplayerAuction:going_stage()
  local auction = self.world.mp_auction
  if not auction or auction.id ~= self.auction_id then return self.going end
  local left = (auction.limit - auction.frames) * 18 / 1000 -- seconds
  if left <= 2 then return 2 elseif left <= 4 then return 1 end
  return 0
end

function UIMultiplayerAuction:draw(canvas, x_, y_)
  local s = TheApp.gfx:getUIScale()
  canvas:scale(s, "bitmap")
  self.background:draw(canvas, self.x * s + x_, self.y * s + y_)
  canvas:scale(1, "bitmap")
  local x, y = self.x * s + x_, self.y * s + y_
  local world = self.world
  local auction = world.mp_auction
  if auction and auction.id ~= self.auction_id then auction = nil end
  -- The town, the lot in red (blinking).
  local mx, my = x + MAP_X * s, y + MAP_Y * s
  local lot_on = math.floor(self.timer / 12) % 2 == 0 or not auction
  canvas:drawRect(canvas:mapRGB(MAP_BG[1], MAP_BG[2], MAP_BG[3]), mx, my, MAP_W * s, MAP_H * s)
  for _, r in ipairs(self.rects) do
    if lot_on or not r[6] then canvas:drawRect(r[5], mx + r[1] * s, my + r[2] * s, r[3] * s, r[4] * s) end
  end
  -- Each plot's number, small: dark digits on a light tag.
  local tag, ink = canvas:mapRGB(250, 244, 220), canvas:mapRGB(40, 24, 20)
  for _, label in ipairs(self.plot_labels or {}) do
    local digits = tostring(label[1])
    local tw = #digits * 4 + 1 -- (digits 3 wide, 1 apart, a pixel's margin)
    local lx, ly = mx + (label[2] - math.floor(tw / 2)) * s, my + (label[3] - 4) * s
    canvas:drawRect(tag, lx, ly, tw * s, 7 * s)
    for i = 1, #digits do
      UIMultiplayerAuction.drawDigit(canvas, ink, tonumber(digits:sub(i, i)), lx + (1 + (i - 1) * 4) * s, ly + s,
          3 * s, 5 * s, s)
    end
  end
  UIFullscreen.draw(self, canvas, x_, y_)
  local last = not auction and world.mp_auction_last
  if last and last.id ~= self.auction_id then last = nil end
  local shown = auction or last
  local S = _S.multiplayer_window
  local name_font, sum_font = self.name_font, self.sum_font
  -- (The fonts' letters sit a little high: a few pixels lower is the
  -- middle of a bar or box.) A name too long ends in "...".
  -- (This font has no "+", as in a shared hospital's "JAN + BOT AGNES":
  -- that one is drawn by hand, in the font's colour.)
  local plus_w = 13 * s -- (with a little room on both sides)
  local function shorten(text, w)
    if name_font:sizeOf(text) <= w then return text end
    local n = #text
    while n > 1 and name_font:sizeOf(text:sub(1, n) .. "...") > w do n = n - 1 end
    return text:sub(1, n):gsub("[%s_]+$", "") .. "..." -- (this font draws _ as a blank)
  end
  local function name_text(text, tx, ty, w, h)
    local parts = {}
    for part in (tostring(text) .. "+"):gmatch("([^+]*)%+") do
      parts[#parts + 1] = part:match("^%s*(.-)%s*$")
    end
    local px = tx
    for i, part in ipairs(parts) do
      if i > 1 then
        local cx, cy = px, ty + 16 * s -- (the middle of the letters; the name before has room after it)
        local colour = canvas:mapRGB(244, 228, 140)
        canvas:drawRect(colour, cx, cy + 3 * s, 7 * s, s)
        canvas:drawRect(colour, cx + 3 * s, cy, s, 7 * s)
        px = px + plus_w
      end
      local left = w - (px - tx)
      if left <= 0 then break end
      part = shorten(part, left)
      name_font:draw(canvas, part, px, ty + 5 * s, left, h, "left")
      px = px + name_font:sizeOf(part) + 2 * s
    end
  end
  local function sum_text(text, tx, ty, w, h)
    sum_font:draw(canvas, text, tx, ty + 4 * s, w, h, "center")
  end

  -- The bidders: name, bid (or "out"), colour; the leader's bar framed.
  if shown then
    for row, index in ipairs(shown.bidders) do
      local ry = ROW_Y[row]
      if not ry then break end
      if auction and index == auction.leader then
        -- (Four pixels wide, outside the bar: Argus, 2026-11-13, the two
        -- before were easy to miss.)
        local frame = canvas:mapRGB(250, 220, 90)
        local t = LEADER_FRAME
        local fx, fy = x + (BAR_X - t) * s, y + (ry - 1 - t) * s
        local fw, fh = (BAR_W + 2 * t) * s, (BAR_H + 2 * t) * s
        canvas:drawRect(frame, fx, fy, fw, t * s)
        canvas:drawRect(frame, fx, fy + fh - t * s, fw, t * s)
        canvas:drawRect(frame, fx, fy, t * s, fh)
        canvas:drawRect(frame, fx + fw - t * s, fy, t * s, fh)
      end
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

  -- The seconds left, big (Argus: he could not tell 1 from 2).
  if auction and auction.limit > 0 then
    local left = math.max(0, math.ceil((auction.limit - auction.frames) * 18 / 1000))
    local cx, cy = x + CLOCK_X * s, y + CLOCK_Y * s
    canvas:drawRect(canvas:mapRGB(250, 240, 200), cx - s, cy - s, (CLOCK_W + 2) * s, (CLOCK_H + 2) * s)
    canvas:drawRect(canvas:mapRGB(40, 24, 20), cx, cy, CLOCK_W * s, CLOCK_H * s)
    local colour = left <= 3 and canvas:mapRGB(250, 70, 50) or canvas:mapRGB(250, 220, 90)
    local digits = tostring(math.min(left, 99))
    local dw, dh, t, gap = DIGIT_W, DIGIT_H, DIGIT_T, DIGIT_GAP
    local total = #digits * dw + (#digits - 1) * gap
    local dx = cx + math.floor((CLOCK_W - total) / 2) * s
    for i = 1, #digits do
      UIMultiplayerAuction.drawDigit(canvas, colour, tonumber(digits:sub(i, i)), dx,
          cy + math.floor((CLOCK_H - dh) / 2) * s, dw * s, dh * s, t * s)
      dx = dx + (dw + gap) * s
    end
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
    -- "Winning bidder" under that box, big, on a dark plaque.
    if S.auction_winning then
      self:drawPlaque(canvas, S.auction_winning, x + (TOWN_LEADER_MID - WIN_W / 2) * s, y + WIN_Y * s, WIN_W, 0)
    end
  end

  -- What is going on, at the top: short, big, on a dark plaque (Jan,
  -- 2026-11-12: "XYZ wants to buy the highlighted plot. Bid $500 or more.";
  -- the long line was barely seen). Who asked for the plot, then what this
  -- player may do.
  local status
  if not auction then
    status = last and (last.sold and S.auction_sold:format(last.plot, last.name, last.bid) or
        S.auction_not_sold:format(last.plot)) or ""
  else
    local going = self:going_stage()
    local now
    if going == 2 then now = S.auction_going_twice
    elseif going == 1 then now = S.auction_going_once
    elseif standing == "watch" then now = S.auction_watching
    elseif standing == "lead" then now = S.auction_leading
    elseif standing == "out" then now = S.auction_dropped
    elseif standing == "poor" then now = S.auction_no_money_loan
    else now = S.auction_bid_more:format(auction.step) end
    local asker = world.hospitals[auction.by or 0]
    status = (asker and S.auction_wants:format(asker.name) or S.auction_title:format(auction.plot)) ..
        " " .. now
  end
  if status ~= "" then
    self:drawPlaque(canvas, status, x + (STATUS_X - 6) * s, y + (STATUS_Y - 3) * s, STATUS_W + 12, 6)
  end
end

--! Text at twice the size, centred on a dark plaque `w` wide (in the
--! picture's pixels) with its top left corner at (px, py) on the screen,
--! `inset` pixels from its sides. The plaque is as high as the text's rows.
function UIMultiplayerAuction:drawPlaque(canvas, text, px, py, w, inset)
  local s = TheApp.gfx:getUIScale()
  local k = 2 * s
  local font = self.big_font
  local text_w = w - 2 * inset
  local _, text_h = font:sizeOf(text, text_w / 2)
  local ph = text_h * k + 8 * s
  canvas:drawRect(canvas:mapRGB(236, 208, 150), px - s, py - s, (w + 2) * s, ph + 2 * s)
  canvas:drawRect(canvas:mapRGB(56, 22, 14), px, py, w * s, ph)
  -- (The letters fill a row's top part, a row is 12 of the font's pixels:
  -- their middle in the plaque's middle. Jan: "Winning bidder" sat too high.)
  local letters_h = text_h * k - 10 * s
  local top = py + math.floor((ph - letters_h) / 2) - 2 * s
  canvas:scale(k)
  font:drawWrapped(canvas, text, math.floor((px + inset * s) / k), math.floor(top / k), math.floor(text_w / 2),
      "center")
  canvas:scale(1)
end

-- A digit's lit bars: top, top right, bottom right, bottom, bottom left,
-- top left, middle.
local SEGMENTS = {[0] = "abcdef", "bc", "abged", "abgcd", "fgbc", "afgcd", "afgedc", "abc", "abcdefg",
    "abcdfg"}

--! Draw digit `d` (0-9) as lit bars, w x h at (x, y), bars t thick.
function UIMultiplayerAuction.drawDigit(canvas, colour, d, x, y, w, h, t)
  local lit = SEGMENTS[d] or ""
  local half = math.floor(h / 2)
  local function bar(name, bx, by, bw, bh)
    if lit:find(name, 1, true) then canvas:drawRect(colour, bx, by, bw, bh) end
  end
  bar("a", x, y, w, t)
  bar("b", x + w - t, y, t, half)
  bar("c", x + w - t, y + half, t, h - half)
  bar("d", x, y + h - t, w, t)
  bar("e", x, y + half, t, h - half)
  bar("f", x, y, t, half)
  bar("g", x, y + half - math.floor(t / 2), w, t)
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

--------------------------------------------------------------------------------

--! While the game stands still for the others (MultiplayerSession.startHold):
--! the annual report or a win fax still open somewhere. It goes when the
--! hold is over (MultiplayerSession:syncHold).
class "UIMultiplayerHoldWait" (UIResizable)

---@class UIMultiplayerHoldWait: UIResizable
---@operator call: UIMultiplayerHoldWait
local UIMultiplayerHoldWait = _G["UIMultiplayerHoldWait"] ---@type UIMultiplayerHoldWait

function UIMultiplayerHoldWait:UIMultiplayerHoldWait(ui)
  -- (Two lines: with several names the text ran out of the box. Below them
  -- the time until the game goes on by itself, so nobody wonders how long
  -- it may take, Jan and Lewry.)
  self:UIResizable(ui, 400, 108, wait_col.bg)
  self.esc_closes = false
  self.resizable = false
  self.on_top = true
  self:setDefaultPosition(0.5, 0.35)
  self.text_panel = self:addBevelPanel(20, 12, 360, 56, wait_col.text)
  self.text_panel.lowered = true
  self.time_panel = self:addBevelPanel(20, 74, 360, 22, wait_col.text)
  self.time_panel.lowered = true
  self:onTick()
end

--! "2:41": minutes and seconds. (Made here: the game's own string format
--! knows %s and %d, not %02d.)
function UIMultiplayerHoldWait.clock(seconds)
  seconds = math.max(0, math.floor(seconds))
  return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function UIMultiplayerHoldWait:onTick()
  local world = self.ui.app.world
  local hold = world and world.mp_hold
  if hold then
    local names = {}
    -- (Not this player's own hospital: their fax or report is on their
    -- screen; the box named them too.)
    local mine = self.ui.hospital
    for i = 1, #world.hospitals do
      if hold.waiting[i] and world.hospitals[i] ~= mine then names[#names + 1] = world.hospitals[i].name end
    end
    local S = _S.multiplayer_window
    local text = hold.kind == "year" and S.hold_year or S.hold_win
    local panel = self.text_panel
    panel:setLabel(text:format(table.concat(names, ", ")), nil, "center")
    -- One line: drawn in the middle of the panel; longer (several names)
    -- wrapped from the top (Font:drawWrapped does not centre vertically).
    local s = TheApp.gfx:getUIScale()
    local _, _, rows = panel.label_font:sizeOf(panel.label, (panel.w - 4) * s)
    panel.wrap_text = (rows or 1) > 1
    local left = MultiplayerSession.holdSecondsLeft(hold)
    self.time_panel:setLabel(S.hold_left:format(UIMultiplayerHoldWait.clock(left)))
  end
  return UIResizable.onTick(self)
end
