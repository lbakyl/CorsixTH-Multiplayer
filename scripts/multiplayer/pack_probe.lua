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

-- Getting a server's build of the game in the game (CorsixTH/Lua/mp_pack.lua),
-- driven like a player. Run through the CorsixTH executable with
-- --interpreter=<this file>; the game restarts once, which runs this again.
--
-- First start (the installed game): main menu -> Multiplayer -> connect; the
-- server turns this build away and offers its own -> the button -> the
-- download window until the game restarts as the server's build.
-- Second start (the downloaded build): it joins the server by itself -> the
-- room list. Logs "PACK PROBE: REJOINED <build id>".
--
-- Environment:
--   CORSIXTH_SOURCE   checkout root (required)
--   MP_SERVER         server address host:port (default 127.0.0.1:47800)
--   MP_NAME           player name (default probe)
--   MP_SHOT_DIR       if set, screenshots of each step (PNG)
--   MP_PACK_EXPECT    the offer expected: download (default), switch, install
--                     or newer_game (then it stops there); refused: a download
--                     the game must not take (a bad signature)
--   MP_LUA_CPATH, MP_LUA_PATH  where LuaSocket is, as for lobby_probe.lua

local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local server = os.getenv("MP_SERVER") or "127.0.0.1:47800"
local name = os.getenv("MP_NAME") or "probe"
local shot_dir = os.getenv("MP_SHOT_DIR")
local expect = os.getenv("MP_PACK_EXPECT") or "download"

if os.getenv("MP_LUA_CPATH") then package.cpath = os.getenv("MP_LUA_CPATH") .. ";" .. package.cpath end
if os.getenv("MP_LUA_PATH") then package.path = os.getenv("MP_LUA_PATH") .. ";" .. package.path end

local function log(msg)
  io.stdout:write("[" .. name .. "] " .. msg .. "\n")
  io.stdout:flush()
end

-- (An error ends the run: the game would wait on its error screen.)
local function guarded(fn, ...)
  local ok, err = xpcall(fn, debug.traceback, ...)
  if not ok then
    io.stderr:write("PACK PROBE: FAILED " .. tostring(err) .. "\n")
    io.stderr:flush()
    os.exit(1)
  end
end

guarded(assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua")), unpack_args(args))
local function run()
  local socket = require("socket")
  local downloaded = TheApp.command_line["pack-of"] ~= nil
  corsixth.require("mp_lobby")
  local build = MultiplayerLobby.buildId()
  log("PACK PROBE: started as " .. (downloaded and "the downloaded build" or "the installed game") .. " " .. build)

  local function restarting() return debug.getregistry()._RESTART end

  local function tick()
    TheApp:onTick()
  end

  local function wait_for(what, cond, seconds)
    local deadline = socket.gettime() + (seconds or 20)
    while not cond() do
      if restarting() then return end
      if socket.gettime() > deadline then
        log("PACK PROBE: FAILED waiting for " .. what)
        os.exit(1)
      end
      tick()
      socket.sleep(0.01)
    end
  end

  local shots = 0
  local function shot(what)
    if not shot_dir then return end
    shots = shots + 1
    TheApp:drawFrame()
    TheApp:drawFrame()
    local path = string.format("%s/%02d-%s.png", shot_dir, shots, what)
    local ok, err = TheApp.video:takeScreenshot(path)
    log(ok and ("SHOT " .. path) or ("SHOT FAILED " .. tostring(err)))
  end

  local function window(class_name)
    return TheApp.ui:getWindow(_G[class_name])
  end

  if downloaded then
    -- It joins the server it was downloaded for by itself.
    wait_for("the room list", function()
      local lobby = TheApp.mp_lobby
      local w = window("UIMultiplayer")
      return lobby and lobby.state == "connected" and w and w.view == "rooms"
    end, 30)
    shot("rejoined")
    log("PACK PROBE: REJOINED " .. build)
    os.exit(0)
  end

  TheApp.ui:addWindow(UIMultiplayer(TheApp.ui))
  local w = window("UIMultiplayer")
  w.address_box:setText(server)
  w.name_box:setText(name)
  w:buttonConnect()
  wait_for("the server's offer", function()
    local win = window("UIMultiplayer")
    return win and (win.pack_offer or win.download)
  end, 20)
  w = window("UIMultiplayer")
  local offer = w.pack_offer
  log(string.format("PACK PROBE: offer %s %s (%s bytes), status: %s", offer and offer.how or "none",
      offer and offer.build or "-", tostring(offer and offer.size or "-"), tostring(w.status_text)))
  shot("offer")
  local want = expect == "refused" and "download" or expect
  if not offer or offer.how ~= want then
    log("PACK PROBE: FAILED expected the offer " .. expect)
    os.exit(1)
  end
  if expect == "newer_game" then
    log("PACK PROBE: DONE")
    os.exit(0)
  end
  w:buttonGetVersion()
  if want == "download" then
    local dl_window = window("UIMultiplayerDownload")
    local dl = dl_window.download
    local shown_half = false
    wait_for("the download", function()
      if not shown_half and dl.size > 0 and dl.received >= dl.size / 2 then
        shown_half = true
        shot("downloading")
        log(string.format("PACK PROBE: downloading %d of %d bytes", dl.received, dl.size))
      end
      if dl.state == "failed" then
        shot("failed")
        if expect == "refused" then
          log("PACK PROBE: REFUSED " .. tostring(dl.error) .. ": " .. tostring(dl_window.text_panel.label))
          os.exit(0)
        end
        log("PACK PROBE: FAILED download: " .. tostring(dl.error))
        os.exit(1)
      end
      return dl.state == "done"
    end, 120)
    log("PACK PROBE: downloaded and checked")
    wait_for("the restart", function()
      if dl_window.starting == 1 then shot("starting") end
      return false
    end, 20)
  end
  if restarting() then
    log("PACK PROBE: restarting as " .. offer.build)
  else
    log("PACK PROBE: FAILED no restart")
    os.exit(1)
  end
end

guarded(run)
