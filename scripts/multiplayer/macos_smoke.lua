-- Smoke test of the macOS app (no game data needed): run as
--   CorsixTH.app/Contents/MacOS/CorsixTH --interpreter=<this file>
-- with CORSIXTH_APP set to the app. Loads the Lua modules multiplayer needs
-- from the app, as CorsixTH.lua finds them, and prints the Lua part of the
-- multiplayer build id (runtime and checksum of the game's Lua code), to
-- compare with the Windows and Linux builds of the same commit.
local res = assert(os.getenv("CORSIXTH_APP"), "Missing CORSIXTH_APP") .. "/Contents/Resources/"
package.cpath = res .. "?.so;" .. package.cpath
package.path = res .. "Lua/?.lua;" .. res .. "Lua/?/init.lua;" .. res .. "?.lua;" .. package.path
local lfs = require("lfs")
require("lpeg")
require("re")
local socket = require("socket")
assert(socket.tcp, "LuaSocket without tcp")
local TH = require("TH")
print("SMOKE: modules loaded: lfs " .. tostring(lfs._VERSION) .. ", " .. tostring(socket._VERSION))
-- The checksum of MultiplayerLobby.buildId.
local files = {}
local function walk(dir, rel)
  for name in lfs.dir(dir) do
    if name ~= "." and name ~= ".." then
      local path = dir .. name
      if lfs.attributes(path, "mode") == "directory" then
        walk(path .. "/", rel .. name .. "/")
      elseif name:match("%.lua$") then
        files[#files + 1] = {rel .. name, path}
      end
    end
  end
end
walk(res .. "Lua/", "")
table.sort(files, function(a, b) return a[1] < b[1] end)
local parts = {}
for _, f in ipairs(files) do
  local fh = assert(io.open(f[2], "rb"))
  parts[#parts + 1] = f[1] .. "\0" .. fh:read("*a"):gsub("\r", "")
  fh:close()
end
print(string.format("SMOKE: build id part %s-...-%08x (%d Lua files)", _VERSION:gsub("Lua ", "lua"),
    TH.CRC32File(table.concat(parts, "\0")), #files))
os.exit(0)
