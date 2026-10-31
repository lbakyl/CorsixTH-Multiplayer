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

class "MultiplayerTransport"

---@class MultiplayerTransport
---@operator call: MultiplayerTransport
local MultiplayerTransport = _G["MultiplayerTransport"] ---@type MultiplayerTransport

local socket_ok, socket = pcall(require, "socket")

function MultiplayerTransport.available()
  return socket_ok and socket ~= nil
end

function MultiplayerTransport:MultiplayerTransport(conn)
  self.conn = conn
  self.conn:settimeout(0)
  self.conn:setoption("tcp-nodelay", true)
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
  return MultiplayerTransport(conn)
end

--! Connect to a host, retrying until the timeout (in seconds). Each attempt
--! waits at most for the time left: a plain socket.connect would wait for
--! the operating system to give up (20 seconds and more on Windows) when
--! nothing answers at that address.
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
  return MultiplayerTransport(conn)
end

--! Start connecting to a host without waiting for it (the lobby window must
--! not freeze while a server at a wrong address does not answer). Poll the
--! returned table with MultiplayerTransport.pollJoin every frame.
function MultiplayerTransport.startJoin(address, port, timeout)
  assert(MultiplayerTransport.available(), "LuaSocket is not available")
  local tcp = socket.tcp()
  tcp:settimeout(0)
  local pending = {tcp = tcp, deadline = socket.gettime() + (timeout or 10)}
  local ok, err = tcp:connect(address, port)
  if ok then
    pending.connected = true
  elseif err ~= "timeout" then -- ("timeout": still connecting)
    tcp:close()
    pending.err = err
  end
  return pending
end

--! A connection started by startJoin: nil while it is still being made, a
--! transport once it is, or false and the reason it failed.
function MultiplayerTransport.pollJoin(pending)
  if pending.err then return false, pending.err end
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
  return MultiplayerTransport(pending.tcp)
end

--! Give up a connection started by startJoin.
function MultiplayerTransport.cancelJoin(pending)
  if pending.tcp then pending.tcp:close() end
  pending.tcp = nil
end

function MultiplayerTransport:_flush()
  if self.out_buf == "" or self.closed then return end
  local sent, err, partial = self.conn:send(self.out_buf)
  local n = sent or partial or 0
  if err == "closed" then self.closed = true end
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
    if err == "closed" then self.closed = true end
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
  local deadline = socket.gettime() + 5
  while self.out_buf ~= "" and not self.closed and socket.gettime() < deadline do
    self:_flush()
    if self.out_buf ~= "" then socket.sleep(0.01) end
  end
  self.conn:close()
  self.closed = true
end
