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

-- MultiplayerTransport's STARTTLS negotiation against a small server in this
-- same process (a non-blocking LuaSec server, driven by pump()). Needs
-- LuaSocket, LuaSec and the openssl command for a throwaway certificate; the
-- tests that need them are skipped without.

require("corsixth")
require("class_test_base")
require("mp_transport")

local MultiplayerTransport = _G["MultiplayerTransport"]

local socket_ok, socket = pcall(require, "socket")
local ssl_ok, ssl = pcall(require, "ssl")
local have_openssl = (os.execute("openssl version > /dev/null 2>&1") == 0)
  or (os.execute("openssl version > /dev/null 2>&1") == true)
local can_run = socket_ok and ssl_ok and have_openssl

local tmp_files = {}

local function tmp_name()
  local n = os.tmpname()
  tmp_files[#tmp_files + 1] = n
  return n
end

local function make_certificate()
  local crt, key = tmp_name(), tmp_name()
  local ok = os.execute("openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -keyout " ..
      key .. " -out " .. crt .. " -days 2 -subj /CN=test > /dev/null 2>&1")
  assert(ok == 0 or ok == true, "openssl failed")
  return crt, key
end

-- A server for one test: behaviour "tls" (answers STARTTLS), "no_tls" (an
-- ERROR, then goes on in clear), "old" (answers like a server from before
-- STARTTLS: an ERROR, then hangs up). It echoes the lines it gets
-- ("ECHO <line>") and counts the bytes of lines starting with "BULK".
local function new_server(behaviour, crt, key)
  local listener = assert(socket.bind("127.0.0.1", 0))
  listener:settimeout(0)
  local _, port = listener:getsockname()
  local srv = {port = tonumber(port), conns = {}, bulk_bytes = 0, accepted = 0, behaviour = behaviour}
  function srv.step()
    local sock = listener:accept()
    if sock then
      sock:settimeout(0)
      srv.accepted = srv.accepted + 1
      srv.conns[#srv.conns + 1] = {sock = sock, buf = "", out = "", tls = false}
    end
    for _, c in ipairs(srv.conns) do
      if c.shut then
        c.dead = true -- (a closed LuaSec socket must not be used again)
      elseif c.handshake then
        local ok, err = c.sock:dohandshake()
        if ok then c.handshake = false
        elseif err ~= "wantread" and err ~= "wantwrite" then c.dead = true end
      elseif not c.dead then
        local data, err, partial = c.sock:receive(65536)
        data = data or partial
        if data and data ~= "" then c.buf = c.buf .. data end
        if err == "closed" then c.dead = true end
        while true do
          local nl = c.buf:find("\n", 1, true)
          if not nl then break end
          local line = c.buf:sub(1, nl - 1)
          c.buf = c.buf:sub(nl + 1)
          if line == "STARTTLS" then
            if behaviour == "tls" then
              c.sock:send("STARTTLS ok\n")
              c.sock = assert(ssl.wrap(c.sock, {mode = "server", protocol = "any", key = key,
                  certificate = crt, verify = "none", options = {"all"}}))
              c.sock:settimeout(0)
              c.tls, c.handshake = true, true
              break
            elseif behaviour == "no_tls" then
              c.out = c.out .. "ERROR code=no_tls text=No%20certificate\n"
            else
              c.out = c.out .. "ERROR code=expected_hello text=Send%20HELLO%20first\n"
              c.hangup = true
            end
          elseif line:sub(1, 4) == "BULK" then
            srv.bulk_bytes = srv.bulk_bytes + #line + 1
            c.out = c.out .. "BULKOK " .. #line .. "\n"
          else
            c.out = c.out .. "ECHO " .. line .. "\n"
          end
        end
        if c.out ~= "" and not c.handshake then
          local sent, _, sent_partial = c.sock:send(c.out)
          c.out = c.out:sub((sent or sent_partial or 0) + 1)
        end
        if c.hangup and c.out == "" then
          c.sock:close()
          c.shut, c.dead = true, true
        end
      end
    end
  end
  function srv.close()
    for _, c in ipairs(srv.conns) do
      if not c.shut then pcall(c.sock.close, c.sock) end
    end
    listener:close()
  end
  return srv
end

--! Run the server and the client's poll function until it gives a result.
local function pump(srv, poll, seconds)
  local deadline = socket.gettime() + (seconds or 10)
  while socket.gettime() < deadline do
    srv.step()
    local a, b, c = poll()
    if a ~= nil then return a, b, c end
    socket.sleep(0.002)
  end
  error("timeout")
end

local function connect(srv)
  local pending = MultiplayerTransport.startJoin("127.0.0.1", srv.port, 10)
  return pump(srv, function() return MultiplayerTransport.pollJoin(pending) end)
end

local function roundtrip(srv, transport, line)
  transport:send(line)
  return pump(srv, function() return transport:receive() end)
end

local describe_if = can_run and describe or pending

describe_if("MultiplayerTransport with TLS", function()
  local crt, key, trust

  setup(function()
    crt, key = make_certificate()
  end)

  teardown(function()
    for _, f in ipairs(tmp_files) do os.remove(f) end
  end)

  before_each(function()
    trust = tmp_name()
    os.remove(trust)
    MultiplayerTransport.mode = "on" -- (also to 127.0.0.1)
    MultiplayerTransport.trust_file = trust
  end)

  after_each(function()
    MultiplayerTransport.mode = nil
    MultiplayerTransport.trust_file = nil
  end)

  it("upgrades to TLS, remembers the certificate and keeps lines intact", function()
    local srv = new_server("tls", crt, key)
    local t = connect(srv)
    assert.is_truthy(t)
    assert.is_true(t.encrypted)
    assert.is_true(t.new_server)
    assert.equal(64, #t.fingerprint)
    assert.equal("ECHO HELLO proto=1", roundtrip(srv, t, "HELLO proto=1"))
    t:close()
    -- The fingerprint is in the file, under the server's address.
    local f = assert(io.open(trust, "r"))
    local text = f:read("*a")
    f:close()
    assert.is_truthy(text:find("127.0.0.1:" .. srv.port .. " " .. t.fingerprint, 1, true))
    -- The second time it is known, not new.
    local t2 = connect(srv)
    assert.is_true(t2.encrypted)
    assert.is_falsy(t2.new_server)
    t2:close()
    srv.close()
  end)

  it("refuses a server whose certificate is not the remembered one", function()
    local srv = new_server("tls", crt, key)
    local f = assert(io.open(trust, "w"))
    f:write("127.0.0.1:" .. srv.port .. " " .. string.rep("ab", 32) .. "\n")
    f:close()
    local pending = MultiplayerTransport.startJoin("127.0.0.1", srv.port, 10)
    local t, err, code = pump(srv, function() return MultiplayerTransport.pollJoin(pending) end)
    assert.is_false(t)
    assert.equal("cert_changed", code)
    assert.is_truthy(err:find("changed", 1, true))
    srv.close()
  end)

  it("refuses a server that is not the pinned one", function()
    local srv = new_server("tls", crt, key)
    MultiplayerTransport.PINNED["127.0.0.1:" .. srv.port] = string.rep("cd", 32)
    local pending = MultiplayerTransport.startJoin("127.0.0.1", srv.port, 10)
    local t, _, code = pump(srv, function() return MultiplayerTransport.pollJoin(pending) end)
    MultiplayerTransport.PINNED = {}
    assert.is_false(t)
    assert.equal("cert_changed", code)
    srv.close()
  end)

  it("goes on in clear when the server has no certificate", function()
    local srv = new_server("no_tls")
    local t = connect(srv)
    assert.is_false(t.encrypted)
    assert.equal("server", t.note)
    assert.equal("ECHO HELLO", roundtrip(srv, t, "HELLO"))
    t:close()
    srv.close()
  end)

  it("connects again without STARTTLS to a server that does not know it", function()
    local srv = new_server("old")
    local t = connect(srv)
    assert.is_false(t.encrypted)
    assert.equal("old_server", t.note)
    assert.equal(2, srv.accepted)
    assert.equal("ECHO HELLO", roundtrip(srv, t, "HELLO"))
    t:close()
    srv.close()
  end)

  it("fails when encryption is required and the server cannot", function()
    MultiplayerTransport.mode = "require"
    local srv = new_server("no_tls")
    local pending = MultiplayerTransport.startJoin("127.0.0.1", srv.port, 10)
    local t, _, code = pump(srv, function() return MultiplayerTransport.pollJoin(pending) end)
    assert.is_false(t)
    assert.equal("no_tls", code)
    srv.close()
  end)

  it("does not try TLS to this computer by default, nor when off", function()
    local srv = new_server("tls", crt, key)
    MultiplayerTransport.mode = "auto"
    local t = connect(srv)
    assert.is_false(t.encrypted)
    assert.equal("local", t.note)
    t:close()
    MultiplayerTransport.mode = "off"
    t = connect(srv)
    assert.equal("off", t.note)
    t:close()
    srv.close()
  end)

  it("sends and receives long lines over TLS without losing a byte", function()
    local srv = new_server("tls", crt, key)
    local t = connect(srv)
    -- Several megabytes at once (a shared save is hundreds of kilobytes),
    -- more than the sockets take at a time: partial writes.
    local line = "BULK " .. string.rep("0123456789abcdef", 65536) -- 1 MB
    for _ = 1, 4 do t:send(line) end
    t:send("ECHO-ME")
    assert.is_true(#t.out_buf > 0) -- the sockets took only part of it
    local answers = {}
    pump(srv, function()
      local l = t:receive()
      if l then answers[#answers + 1] = l end
      if #answers == 5 then return true end
    end, 30)
    assert.equal(4 * (#line + 1), srv.bulk_bytes)
    assert.equal("BULKOK " .. #line, answers[1])
    assert.equal("ECHO ECHO-ME", answers[5])
    assert.is_false(t.closed)
    t:close()
    srv.close()
  end)

  it("reports a closed connection", function()
    local srv = new_server("tls", crt, key)
    local t = connect(srv)
    for _, c in ipairs(srv.conns) do
      c.shut = true
      c.sock:close()
    end
    pump(srv, function()
      t:receive()
      if t.closed then return true end
    end)
    assert.is_true(t.closed)
    t:close()
    srv.close()
  end)
end)
