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

--! Experimental line-based TCP transport for MultiplayerSession, using
--! LuaSocket. Connecting blocks (with a timeout); after that, send() and
--! receive() never block the game: data that cannot be written yet is kept
--! and flushed later, and receive() returns nil when no full line is there.
--!
--! LuaSocket is optional: if it is missing, MultiplayerTransport.available()
--! returns false and multiplayer cannot be started.
--!
--! Encryption (docs/multiplayer/ENCRYPTION.md). With LuaSec (the "ssl"
--! module, also optional) a connection to a server is upgraded to TLS on the
--! same port before anything else is sent: the first line is `STARTTLS`, the
--! server answers `STARTTLS ok`, and both sides switch to TLS. A server
--! without a certificate answers an ERROR (`no_tls`) and the connection goes
--! on in clear, as it does to servers from before this existed (they close it
--! and the transport connects again without STARTTLS). The server's
--! certificate is self-signed and is not validated against authorities: its
--! SHA-256 fingerprint is remembered the first time a server is used (trust
--! on first use) and a different one later refuses the connection. Without
--! LuaSec everything works as before, in clear (transport.encrypted is false
--! and says why in transport.note).
--!
--! Setting, environment variable CORSIXTH_MP_TLS:
--!   auto (default)  try TLS, except to this computer (127.0.0.1, ::1,
--!                   localhost: nothing to protect, and the server's own bots
--!                   and referee connect that way)
--!   on              try TLS also to this computer; go on in clear if the
--!                   server or this build cannot
--!   require         only an encrypted connection
--!   off             never
--! CORSIXTH_MP_TRUST_FILE names the file of remembered fingerprints (default:
--! mp_known_servers.txt next to the game's config file). For tests, the
--! fields MultiplayerTransport.mode and .trust_file take the place of both.

class "MultiplayerTransport"

---@class MultiplayerTransport
---@operator call: MultiplayerTransport
local MultiplayerTransport = _G["MultiplayerTransport"] ---@type MultiplayerTransport

local socket_ok, socket = pcall(require, "socket")
local ssl_ok, ssl = pcall(require, "ssl")
if not (ssl_ok and type(ssl) == "table" and type(ssl.wrap) == "function") then
  ssl_ok, ssl = false, nil
end

function MultiplayerTransport.available()
  return socket_ok and socket ~= nil
end

--! Can this build encrypt (is LuaSec there)?
function MultiplayerTransport.tlsAvailable()
  return ssl_ok
end

--! Built-in fingerprints of known servers ("host:port" -> SHA-256 of the
--! certificate, 64 hex digits). A server listed here is trusted only with
--! this certificate, also on a computer that never saw it before. Empty:
--! no server has a fixed certificate yet; add the lines of
--! docs/multiplayer/ENCRYPTION.md once one does.
MultiplayerTransport.PINNED = {}

-- How long the TLS negotiation may take, in seconds (after the connection).
local TLS_TIMEOUT = 10

-- Why a connection is not encrypted (transport.note):
--   "off" (setting), "local" (this computer), "no_ssl" (this build has no
--   LuaSec), "server" (the server has no certificate), "old_server" (it does
--   not know STARTTLS).

--! The TLS setting: "auto", "on", "require" or "off".
function MultiplayerTransport.tlsMode()
  local mode = MultiplayerTransport.mode or os.getenv("CORSIXTH_MP_TLS")
  if mode == "on" or mode == "require" or mode == "off" then return mode end
  return "auto"
end

local function isLocal(host)
  host = tostring(host):lower()
  return host == "localhost" or host == "::1" or host:match("^127%.%d+%.%d+%.%d+$") ~= nil
end

-- Remembered servers ---------------------------------------------------------

local function serverKey(host, port)
  return tostring(host):lower() .. ":" .. tostring(port)
end

--! The file with the remembered fingerprints; nil if this program has no
--! place for it (then they are remembered until the game ends).
function MultiplayerTransport.trustFile()
  if MultiplayerTransport.trust_file then return MultiplayerTransport.trust_file end
  local env = os.getenv("CORSIXTH_MP_TRUST_FILE")
  if env and env ~= "" then return env end
  local ok, finder = pcall(function() return corsixth.require("config_finder") end)
  local dir = ok and finder and finder.config_filename and finder.config_filename:match("(.*[/\\])")
  if dir then return dir .. "mp_known_servers.txt" end
  return nil
end

local known_in_memory = {}

local function readTrust()
  local known = {}
  for k, v in pairs(known_in_memory) do known[k] = v end
  local path = MultiplayerTransport.trustFile()
  local f = path and io.open(path, "r")
  if f then
    for line in f:lines() do
      local key, fp = line:match("^%s*(%S+)%s+(%x+)%s*$")
      if key and #fp == 64 then known[key:lower()] = fp:lower() end
    end
    f:close()
  end
  return known
end

local function rememberServer(key, fingerprint)
  known_in_memory[key] = fingerprint
  local path = MultiplayerTransport.trustFile()
  if not path then return end
  local fresh = io.open(path, "r") == nil
  local f = io.open(path, "a")
  if not f then return end
  if fresh then
    f:write("# Multiplayer servers this game has seen: address, SHA-256 of the server's certificate.\n",
        "# If a server really got a new certificate, delete its line to trust the new one.\n")
  end
  f:write(key, " ", fingerprint, "\n")
  f:close()
end

--! Check a server's certificate fingerprint: built-in pins first, then the
--! remembered one; a server seen for the first time is remembered.
--!return true (and "new" the first time), or false and a message
local function checkFingerprint(host, port, fingerprint)
  local key = serverKey(host, port)
  local pinned = MultiplayerTransport.PINNED[key]
  if pinned then
    if pinned:lower() ~= fingerprint then
      return false, "The certificate of " .. key .. " is not the one this game knows"
    end
    return true
  end
  local known = readTrust()[key]
  if known then
    if known ~= fingerprint then
      return false, "The certificate of " .. key .. " has changed"
    end
    return true
  end
  rememberServer(key, fingerprint)
  return true, "new"
end

local function peerFingerprint(conn)
  local ok, cert = pcall(conn.getpeercertificate, conn)
  if not ok or not cert then return nil end
  local ok2, hex = pcall(cert.digest, cert, "sha256")
  if not ok2 or type(hex) ~= "string" then return nil end
  hex = hex:gsub("[^%x]", ""):lower()
  if #hex ~= 64 then return nil end
  return hex
end

-- Connections ----------------------------------------------------------------

--! (Internal) conn is a LuaSocket TCP object or a LuaSec one.
--!param info (table) optional: encrypted (bool), note (why not), fingerprint, new_server
function MultiplayerTransport:MultiplayerTransport(conn, info)
  self.conn = conn
  self.conn:settimeout(0)
  info = info or {}
  self.encrypted = info.encrypted or false
  self.note = info.note
  self.fingerprint = info.fingerprint
  self.new_server = info.new_server
  if not self.encrypted then
    self.conn:setoption("tcp-nodelay", true)
  end
  self.out_buf = ""
  self.in_buf = ""
  self.closed = false
end

--! Wait for one peer to connect.
function MultiplayerTransport.host(address, port, timeout)
  assert(MultiplayerTransport.available(), "LuaSocket is not available")
  local server = assert(socket.bind(address or "*", port))
  server:settimeout(timeout or 60)
  local conn, err = server:accept()
  server:close()
  if not conn then return nil, err end
  return MultiplayerTransport(conn, {note = "local"})
end

--! Connect to a host, retrying until the timeout (in seconds). Each attempt
--! waits at most for the time left: a plain socket.connect would wait for
--! the operating system to give up (20 seconds and more on Windows) when
--! nothing answers at that address.
--!return a transport, or nil and the reason (and a code for some)
function MultiplayerTransport.join(address, port, timeout)
  assert(MultiplayerTransport.available(), "LuaSocket is not available")
  local deadline = socket.gettime() + (timeout or 60)
  local conn, err
  repeat
    local left = deadline - socket.gettime()
    if left <= 0 then break end
    local tcp = socket.tcp()
    tcp:settimeout(math.min(left, 5))
    local ok, e = tcp:connect(address, port)
    if ok then
      conn = tcp
    else
      tcp:close()
      err = e
      if socket.gettime() < deadline then socket.sleep(0.2) end
    end
  until conn or socket.gettime() > deadline
  if not conn then return nil, err or "timeout" end
  -- The encryption is negotiated like in startJoin, here waiting for it.
  conn:settimeout(0)
  local pending = {host = address, port = port, tcp = conn, connected = true, stage = "connect",
      deadline = socket.gettime() + TLS_TIMEOUT + 5}
  while true do
    local transport, perr, code = MultiplayerTransport.pollJoin(pending)
    if transport ~= nil then
      if transport then return transport end
      return nil, perr, code
    end
    socket.sleep(0.01)
  end
end

local function openSocket(pending)
  local tcp = socket.tcp()
  tcp:settimeout(0)
  pending.tcp = tcp
  pending.stage = "connect"
  local ok, err = tcp:connect(pending.host, pending.port)
  if ok then
    pending.connected = true
  elseif err ~= "timeout" then -- ("timeout": still connecting)
    tcp:close()
    pending.tcp = nil
    pending.err = err
  end
end

--! Start connecting to a host without waiting for it (the lobby window must
--! not freeze while a server at a wrong address does not answer). Poll the
--! returned table with MultiplayerTransport.pollJoin every frame.
function MultiplayerTransport.startJoin(address, port, timeout)
  assert(MultiplayerTransport.available(), "LuaSocket is not available")
  local pending = {host = address, port = port, deadline = socket.gettime() + (timeout or 10)}
  openSocket(pending)
  return pending
end

local function failJoin(pending, message, code)
  MultiplayerTransport.cancelJoin(pending)
  pending.err, pending.err_code = message, code
  return false, message, code
end

--! A connected pending join is done: the transport, in clear.
local function clearTransport(pending, note)
  return MultiplayerTransport(pending.tcp, {note = note})
end

--! The server wants the connection in clear, or does not know STARTTLS: go on
--! in clear on this connection (`no_tls`) or on a new one.
local function goClear(pending, reopen, note)
  if pending.mode == "require" then
    return failJoin(pending, "This server does not support encrypted connections", "no_tls")
  end
  if reopen then
    pending.tcp:close()
    pending.no_starttls, pending.note = true, note
    pending.reply = nil
    openSocket(pending)
    if pending.err then return false, pending.err end
    return nil
  end
  return clearTransport(pending, note)
end

--! Wrap the connection in TLS (after `STARTTLS ok`).
local function startHandshake(pending)
  pending.tcp:setoption("tcp-nodelay", true) -- (LuaSec's sockets have no setoption)
  local params = {mode = "client", protocol = "any", verify = "none",
      options = {"all", "no_sslv2", "no_sslv3", "no_tlsv1", "no_tlsv1_1"}}
  local ok, conn, err = pcall(ssl.wrap, pending.tcp, params)
  if not ok or not conn then
    -- (Older LuaSec versions may not know every option name.)
    params.options = nil
    ok, conn, err = pcall(ssl.wrap, pending.tcp, params)
  end
  if not ok or not conn then
    return failJoin(pending, "TLS cannot start: " .. tostring(ok and err or conn), "tls")
  end
  conn:settimeout(0)
  pending.tcp = conn
  pending.stage = "handshake"
  pending.deadline = socket.gettime() + TLS_TIMEOUT
  return nil
end

--! The ERROR line of the server's STARTTLS answer: code and text.
local function parseError(line)
  local code = line:match("code=([%w_]+)")
  local text = line:match("text=(%S+)")
  if text then
    text = text:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  end
  return code, text
end

--! The answer to STARTTLS: nil while it is not all there.
local function pollStarttlsReply(pending)
  local data, err, partial = pending.tcp:receive("*l")
  if partial and partial ~= "" then pending.reply = (pending.reply or "") .. partial end
  if data then
    local line = ((pending.reply or "") .. data):gsub("\r$", "")
    pending.reply = nil
    if line == "STARTTLS ok" then return startHandshake(pending) end
    if line:match("^ERROR") then
      local code, text = parseError(line)
      if code == "no_tls" then return goClear(pending, false, "server") end
      if code == "expected_hello" or code == "protocol" then
        return goClear(pending, true, "old_server") -- a server from before STARTTLS
      end
      return failJoin(pending, text or code or "The server refused the connection", code)
    end
    return goClear(pending, true, "old_server")
  elseif err == "closed" then
    return goClear(pending, true, "old_server")
  end
  return nil
end

--! The TLS handshake: nil while it goes on.
local function pollHandshake(pending)
  local ok, err = pending.tcp:dohandshake()
  if not ok then
    if err == "wantread" or err == "wantwrite" or err == "timeout" then return nil end
    return failJoin(pending, "TLS handshake failed: " .. tostring(err), "tls")
  end
  local fingerprint = peerFingerprint(pending.tcp)
  if not fingerprint then
    return failJoin(pending, "The server sent no usable certificate", "tls")
  end
  local trusted, what = checkFingerprint(pending.host, pending.port, fingerprint)
  if not trusted then
    return failJoin(pending, what, "cert_changed")
  end
  return MultiplayerTransport(pending.tcp, {encrypted = true, fingerprint = fingerprint,
      new_server = what == "new"})
end

--! A connection started by startJoin: nil while it is still being made, a
--! transport once it is, or false, the reason it failed and a code for some
--! reasons ("cert_changed", "no_tls", "tls").
function MultiplayerTransport.pollJoin(pending)
  if pending.err then return false, pending.err, pending.err_code end
  if pending.stage == "handshake" then
    if socket.gettime() > pending.deadline then return failJoin(pending, "TLS handshake timeout", "tls") end
    return pollHandshake(pending)
  end
  if pending.stage == "reply" then
    if socket.gettime() > pending.deadline then return failJoin(pending, "timeout") end
    return pollStarttlsReply(pending)
  end
  -- stage "connect" (set by openSocket; a join() has made the connection)
  pending.stage = pending.stage or "connect"
  if not pending.connected then
    local _, writable = socket.select(nil, {pending.tcp}, 0)
    if writable and writable[1] then
      -- Writable either way; only a made connection has a peer.
      if not pending.tcp:getpeername() then
        MultiplayerTransport.cancelJoin(pending)
        pending.err = "connection refused"
        return false, pending.err
      end
      pending.connected = true
    elseif socket.gettime() > pending.deadline then
      MultiplayerTransport.cancelJoin(pending)
      pending.err = "timeout"
      return false, pending.err
    else
      return nil
    end
  end
  -- Connected: ask for TLS, if wanted and possible.
  local mode = MultiplayerTransport.tlsMode()
  pending.mode = mode
  if pending.no_starttls then -- (an old server, connected again without it)
    return clearTransport(pending, pending.note)
  elseif mode == "off" then
    return clearTransport(pending, "off")
  elseif mode == "auto" and isLocal(pending.host) then
    return clearTransport(pending, "local")
  elseif not ssl_ok then
    if mode == "require" then
      return failJoin(pending, "This game cannot encrypt (LuaSec is missing)", "no_ssl")
    end
    return clearTransport(pending, "no_ssl")
  end
  pending.tcp:send("STARTTLS\n") -- (nine bytes into an empty buffer)
  pending.stage = "reply"
  pending.deadline = socket.gettime() + TLS_TIMEOUT
  return nil
end

--! Give up a connection started by startJoin.
function MultiplayerTransport.cancelJoin(pending)
  if pending.tcp then pending.tcp:close() end
  pending.tcp = nil
end

-- Reading and writing --------------------------------------------------------

local function wouldBlock(err)
  return err == "timeout" or err == "wantread" or err == "wantwrite"
end

function MultiplayerTransport:_flush()
  if self.out_buf == "" or self.closed then return end
  local data = self.out_buf
  -- A TLS write that has to wait must be tried again with the same bytes
  -- (OpenSSL): not with more behind them, whatever was queued meanwhile.
  if self.retry_len and self.retry_len < #data then data = data:sub(1, self.retry_len) end
  local sent, err, partial = self.conn:send(data)
  local n = sent or partial or 0
  if err == "closed" then
    self.closed = true
  elseif err and self.encrypted and not wouldBlock(err) then
    self.closed = true -- a TLS error ends the connection
  end
  self.retry_len = (err == "wantwrite" or err == "wantread") and (#data - n) or nil
  self.out_buf = self.out_buf:sub(n + 1)
end

function MultiplayerTransport:send(line)
  self.out_buf = self.out_buf .. line .. "\n"
  self:_flush()
end

--! Next complete line, or nil if none has arrived yet.
function MultiplayerTransport:receive()
  self:_flush()
  local nl = self.in_buf:find("\n", 1, true)
  -- Read what has arrived (a shared save comes in long lines).
  local reads = 0
  while not nl and not self.closed and reads < 64 do
    reads = reads + 1
    local data, err, partial = self.conn:receive(65536)
    data = data or partial
    if data and data ~= "" then self.in_buf = self.in_buf .. data end
    if err == "closed" then
      self.closed = true
    elseif err and self.encrypted and not wouldBlock(err) then
      self.closed = true
    end
    nl = self.in_buf:find("\n", 1, true)
    if not data or #data < 65536 then break end
  end
  if not nl then return nil end
  local line = self.in_buf:sub(1, nl - 1)
  self.in_buf = self.in_buf:sub(nl + 1)
  return line
end

--! Send everything still buffered (blocking, bounded), then close.
function MultiplayerTransport:close()
  if self.conn_closed then return end -- (closing a LuaSec socket twice can crash)
  local deadline = socket.gettime() + 5
  while self.out_buf ~= "" and not self.closed and socket.gettime() < deadline do
    self:_flush()
    if self.out_buf ~= "" then socket.sleep(0.01) end
  end
  self.conn_closed = true
  self.conn:close()
  self.closed = true
end
