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

-- Smoke test of the macOS app without game data, run by the app's own
-- program and Lua (CorsixTH --interpreter=macos_smoke.lua):
--   --resources=DIR  the app's Contents/Resources
--   --server=H:P     a multiplayer server to ask for HEALTH (optional)
-- Loads the bundled Lua modules as the game does (CorsixTH.lua's search
-- paths), prints the Lua runtime and the checksum of the Lua game code (the
-- last part of the multiplayer build id, MultiplayerLobby.buildId), and
-- exits 0 if everything worked.

local opts = {}
for _, a in ipairs({...}) do
  local k, v = tostring(a):match("^%-%-([%w_]+)=(.*)$")
  if k then opts[k] = v end
end
local res = assert(opts.resources, "--resources=DIR missing")
if res:sub(-1) ~= "/" then res = res .. "/" end
local code_dir = res .. "Lua/"
package.cpath = res .. "?.so;" .. package.cpath
package.path = code_dir .. "?.lua;" .. code_dir .. "?/init.lua;" .. res .. "?.lua;" .. package.path

local ok, err = pcall(function()
  local lfs = require("lfs")
  require("lpeg")
  require("re")
  local socket = require("socket")
  local TH = require("TH")

  -- The checksum of the Lua game code, as MultiplayerLobby.buildId.
  local files = {}
  local function walk(dir, rel)
    for name in lfs.dir(dir) do
      if name ~= "." and name ~= ".." then
        local path = dir .. name
        local mode = lfs.attributes(path, "mode")
        if mode == "directory" then
          walk(path .. "/", rel .. name .. "/")
        elseif name:match("%.lua$") then
          files[#files + 1] = {rel .. name, path}
        end
      end
    end
  end
  walk(code_dir, "")
  table.sort(files, function(a, b) return a[1] < b[1] end)
  local parts = {}
  for _, f in ipairs(files) do
    local fh = assert(io.open(f[2], "rb"))
    parts[#parts + 1] = f[1] .. "\0" .. fh:read("*a"):gsub("\r", "")
    fh:close()
  end
  local runtime = _VERSION:gsub("Lua ", "lua")
  print(string.format("MACOS SMOKE runtime=%s files=%d crc=%08x socket=%s", runtime, #files,
      TH.CRC32File(table.concat(parts, "\0")), tostring(socket._VERSION)))
  assert(runtime == "lua5.5", "the builds for Windows and Linux use Lua 5.5")

  if opts.server then
    local host, port = opts.server:match("^(.+):(%d+)$")
    local conn = assert(socket.connect(host, tonumber(port)))
    conn:settimeout(5)
    assert(conn:send("HEALTH\n"))
    local line = assert(conn:receive("*l"))
    conn:close()
    print("MACOS SMOKE server: " .. line)
    assert(line:match("^OK "), "unexpected answer")
  end
end)
if not ok then
  print("MACOS SMOKE FAILED: " .. tostring(err))
  os.exit(1)
end
print("MACOS SMOKE OK")
os.exit(0)
