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

---@type MultiplayerTransport
local MultiplayerTransport = _G["MultiplayerTransport"]

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

--! Connect to a host, retrying until the timeout.
function MultiplayerTransport.join(address, port, timeout)
  assert(MultiplayerTransport.available(), "LuaSocket is not available")
  local deadline = socket.gettime() + (timeout or 60)
  local conn, err
  repeat
    conn, err = socket.connect(address, port)
    if not conn then socket.sleep(0.2) end
  until conn or socket.gettime() > deadline
  if not conn then return nil, err end
  return MultiplayerTransport(conn)
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
