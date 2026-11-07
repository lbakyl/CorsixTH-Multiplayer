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

-- Smoke test of a built game's LuaSec (docs/multiplayer/ENCRYPTION.md), run
-- by the game's own program and Lua, without game data:
--   CorsixTH --interpreter=tls_smoke.lua [--resources=DIR] [--server=H:P]
--       [--fingerprint=HEX] [--out=FILE]
-- Checks that require("ssl") works in the game's Lua (so LuaSec and the
-- OpenSSL libraries were shipped), makes a TLS context, and with --server
-- does what the game does: STARTTLS to a multiplayer server, the handshake,
-- the certificate's SHA-256 fingerprint (compared with --fingerprint), then
-- HELLO and WELCOME through the encrypted connection. Prints what it did
-- (also appended to --out, for programs that have no console) and ends with
-- "TLS SMOKE OK" and exit code 0, or "TLS SMOKE FAILED: reason" and 1.
--   --resources=DIR  a folder with the Lua modules (the macOS app's
--                    Contents/Resources); not needed where the game finds
--                    them by itself

local opts = {}
for _, a in ipairs({...}) do
  local k, v = tostring(a):match("^%-%-([%w_]+)=(.*)$")
  if k then opts[k] = v end
end

local function out(text)
  print(text)
  if opts.out then
    local f = io.open(opts.out, "a")
    if f then
      f:write(text, "\n")
      f:close()
    end
  end
end

if opts.resources then
  local res = opts.resources
  if res:sub(-1) ~= "/" then res = res .. "/" end
  package.cpath = res .. "?.so;" .. package.cpath
  package.path = res .. "?.lua;" .. res .. "?/init.lua;" .. package.path
end

local ok, err = pcall(function()
  local socket = require("socket")
  local ssl_ok, ssl = pcall(require, "ssl")
  assert(ssl_ok, "require(\"ssl\") failed: " .. tostring(ssl))
  out(string.format("TLS SMOKE %s, LuaSec %s, LuaSocket %s", _VERSION, tostring(ssl._VERSION),
      tostring(socket._VERSION)))
  -- A context needs OpenSSL to be loaded and working.
  assert(ssl.newcontext({mode = "client", protocol = "any", verify = "none"}), "no TLS context")
  out("TLS SMOKE context: ok")

  if opts.server then
    local host, port = opts.server:match("^(.+):(%d+)$")
    local conn = assert(socket.connect(host, tonumber(port)))
    conn:settimeout(10)
    assert(conn:send("STARTTLS\n"))
    local line = assert(conn:receive("*l"))
    assert(line == "STARTTLS ok", "unexpected answer to STARTTLS: " .. tostring(line))
    local tls = assert(ssl.wrap(conn, {mode = "client", protocol = "any", verify = "none"}))
    tls:settimeout(10)
    assert(tls:dohandshake())
    local cert = assert(tls:getpeercertificate(), "no certificate")
    local fingerprint = cert:digest("sha256"):gsub("[^%x]", ""):lower()
    out("TLS SMOKE handshake: ok, certificate sha256 " .. fingerprint)
    if opts.fingerprint then
      assert(fingerprint == opts.fingerprint:gsub("[^%x]", ""):lower(), "another certificate than expected")
    end
    assert(tls:send("HELLO proto=1 build=smoke name=smoke\n"))
    line = assert(tls:receive("*l"))
    out("TLS SMOKE server: " .. line)
    assert(line:match("^WELCOME"), "unexpected answer to HELLO")
    tls:close()
  end
end)
if not ok then
  out("TLS SMOKE FAILED: " .. tostring(err))
  os.exit(1)
end
out("TLS SMOKE OK")
os.exit(0)
