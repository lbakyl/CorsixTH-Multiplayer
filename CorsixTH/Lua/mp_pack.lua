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

--! Game packs (OpenTH): a multiplayer server that runs another build of the
--! game than this one can send its build's scripts and data, a pack
--! (mp_server/corsixth_mp/packs.py). The game takes a pack only with the
--! signature of an OpenTH release key (TH.CheckPackSignature), unpacks it
--! next to the config file (builds/<build>/), restarts with it
--! (CorsixTH.lua and mp_pack_start.lua start the build named in
--! builds/current.txt) and joins the server again by itself.
--!
--! A download: MultiplayerPack(address, offer), then :poll() every frame
--! until .state is "done" or "failed".

corsixth.require("mp_lobby")

class "MultiplayerPack"

---@class MultiplayerPack
---@operator call: MultiplayerPack
local MultiplayerPack = _G["MultiplayerPack"] ---@type MultiplayerPack

local pathsep = package.config:sub(1, 1)

--! Limits: a pack file's size, its files' bytes and their number.
MultiplayerPack.MAX_BYTES = 32 * 1024 * 1024
MultiplayerPack.MAX_RAW_BYTES = 96 * 1024 * 1024
MultiplayerPack.MAX_FILES = 5000
--! How many downloaded builds are kept (the longest unused go first).
MultiplayerPack.KEEP = 4
--! What a pack may bring: these files and folders of the game's own.
MultiplayerPack.TOP = {
  ["CorsixTH.lua"] = "file", Lua = "dir", Campaigns = "dir", Levels = "dir", Sounds = "dir", Bitmap = "dir",
}
local MAGIC = "OPENTH-PACK 1"

-- Helpers -----------------------------------------------------------------------

local function lfs() return require("lfs") end

local function isBuild(build)
  return type(build) == "string" and build:match("^%x%x%x%x%x%x%x%x$") ~= nil and build == build:lower()
end

--! Whether a folder exists (with or without a separator at the end).
local function isDir(path)
  return lfs().attributes((path:gsub("[/\\]$", "")), "mode") == "directory"
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

local function writeFile(path, text)
  local f, err = io.open(path, "wb")
  if not f then return nil, err end
  local ok, werr = f:write(text)
  f:close()
  if not ok then return nil, werr end
  return true
end

--! Remove a file or a folder with all in it (links themselves, never what
--! they point to).
local function removeTree(path)
  local attributes = lfs().symlinkattributes or lfs().attributes
  local mode = attributes(path, "mode")
  if mode == "directory" then
    for name in lfs().dir(path) do
      if name ~= "." and name ~= ".." then removeTree(path .. pathsep .. name) end
    end
    lfs().rmdir(path)
  elseif mode then
    os.remove(path)
  end
end

--! Make the folders of a path (relative, "/" between its parts) under root.
local function makeDirs(root, rel)
  local path = root
  for part in rel:gmatch("[^/]+") do
    path = path .. pathsep .. part
    if lfs().attributes(path, "mode") ~= "directory" then
      local ok, err = lfs().mkdir(path)
      if not ok then return nil, err end
    end
  end
  return true
end

--! Whether a pack may carry a file of this name: its parts letters, digits
--! and a few signs, none starting with a dot; under one of TOP.
function MultiplayerPack.validPath(path)
  if type(path) ~= "string" or path == "" or #path > 200 then return false end
  local parts = {}
  for part in (path .. "/"):gmatch("([^/]*)/") do
    if not part:match("^[%w_][%w_%.' %-]*$") then return false end
    parts[#parts + 1] = part
  end
  local top = MultiplayerPack.TOP[parts[1]]
  return (top == "file" and #parts == 1) or (top == "dir" and #parts > 1)
end

-- Where builds are kept ------------------------------------------------------------

--! The folder of downloaded builds (ending with a separator): beside the
--! config file.
function MultiplayerPack.buildsDir(app)
  app = app or TheApp
  local config = app.command_line and app.command_line["config-file"] or "config.txt"
  return (config:match("^(.*[/\\])") or "") .. "builds" .. pathsep
end

--! The folder the installed game is in when this one is a downloaded build
--! (ending with a separator), else nil.
function MultiplayerPack.installDir(app)
  app = app or TheApp
  local dir = app.command_line and app.command_line["pack-of"]
  if not dir or dir == "" then return nil end
  if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then dir = dir .. pathsep end
  return dir
end

--! The Lua checksum of the installed game when this one is a downloaded
--! build (nil when this is the installed game).
function MultiplayerPack.installedBuild(app)
  local dir = MultiplayerPack.installDir(app)
  if not dir then return nil end
  if MultiplayerPack.cached_installed == nil then
    local ok, sum = pcall(MultiplayerLobby.luaChecksum, dir .. "Lua" .. pathsep)
    MultiplayerPack.cached_installed = ok and sum or false
  end
  return MultiplayerPack.cached_installed or nil
end

--! Whether a build was downloaded before and is complete.
function MultiplayerPack.have(app, build)
  if not isBuild(build) then return false end
  local dir = MultiplayerPack.buildsDir(app) .. build .. pathsep
  return lfs().attributes(dir .. "CorsixTH.lua", "mode") == "file" and
      lfs().attributes(dir .. "pack.txt", "mode") == "file"
end

--! Whether this game's engine can take packs at all.
function MultiplayerPack.supported()
  local ok, TH = pcall(require, "TH")
  return ok and type(TH) == "table" and TH.CheckPackSignature ~= nil and TH.InflatePack ~= nil
end

--! What this game can do about a server that turned it away for being
--! another build (an ERROR build_mismatch): nil (nothing: its web page is
--! still offered), or a table: build, release, size (bytes to download) and
--! how = "download" (get the server's build), "switch" (downloaded before),
--! "install" (the server's build is the installed game) or "newer_game" (the
--! server's build needs a newer game than this; only a full download helps).
function MultiplayerPack.offer(app, err)
  if not err or err.code ~= "build_mismatch" or not MultiplayerPack.supported() then return nil end
  local build = err.need
  if not isBuild(build) then return nil end
  local offer = {build = build, release = err.release or "", size = tonumber(err.pack) or 0}
  if MultiplayerPack.installedBuild(app) == build then
    offer.how = "install"
  elseif MultiplayerPack.have(app, build) then
    offer.how = "switch"
  elseif offer.size > 0 and offer.size <= MultiplayerPack.MAX_BYTES then
    local options = require("TH").GetCompileOptions()
    local api, engine = tonumber(err.pack_api), tonumber(err.pack_engine)
    if api ~= options.api_version or not engine or engine > (options.pack_engine or 0) then
      offer.how = "newer_game"
    else
      offer.how = "download"
    end
  else
    return nil
  end
  return offer
end

-- A pack's contents -------------------------------------------------------------

--! Read a pack's unpacked data: its header (build, api, engine, release) and
--! files ({path, first byte, size}, in order), or nil and what is wrong.
function MultiplayerPack.parse(raw)
  local head_end = raw:find("\ndata\n", 1, true)
  if not head_end then return nil, "no data" end
  local head = raw:sub(1, head_end)
  local info, files = {}, {}
  local at, total = head_end + 6, 0
  local first = true
  for line in head:gmatch("([^\n]*)\n") do
    if first then
      if line ~= MAGIC then return nil, "not a game pack" end
      first = false
    else
      local key, value = line:match("^(%S+) (.*)$")
      if key == "file" then
        local size, path = value:match("^(%d+) (.+)$")
        size = tonumber(size)
        if not size or not MultiplayerPack.validPath(path) then
          return nil, "bad file " .. tostring(value)
        end
        files[#files + 1] = {path = path, at = at + total, size = size}
        total = total + size
        if #files > MultiplayerPack.MAX_FILES then return nil, "too many files" end
      elseif key then
        info[key] = value
      end
    end
  end
  if first then return nil, "not a game pack" end
  if at + total - 1 ~= #raw then return nil, "file sizes do not add up" end
  info.api, info.engine = tonumber(info.api), tonumber(info.engine)
  if not isBuild(info.build) or not info.api or not info.engine then return nil, "bad header" end
  local seen = {}
  for _, f in ipairs(files) do
    local key = f.path:lower()
    if seen[key] then return nil, "file twice: " .. f.path end
    seen[key] = true
  end
  if not seen["corsixth.lua"] or not seen["lua/app.lua"] then return nil, "no game in it" end
  return info, files
end

--! Check a downloaded pack file and its signature, and unpack it into the
--! builds folder as builds/<build>/. Returns true, or nil and what is wrong.
function MultiplayerPack.install(app, build, blob, signature)
  local TH = require("TH")
  if not TH.CheckPackSignature(blob, signature or "") then
    return nil, "signature"
  end
  local raw = TH.InflatePack(blob, MultiplayerPack.MAX_RAW_BYTES)
  if not raw then return nil, "damaged" end
  local info, files = MultiplayerPack.parse(raw)
  if not info then return nil, files end
  local options = TH.GetCompileOptions()
  if info.build ~= build then return nil, "another build" end
  if info.api ~= options.api_version or info.engine > (options.pack_engine or 0) then
    return nil, "newer game"
  end
  local builds = MultiplayerPack.buildsDir(app)
  local root = builds .. build
  local part = root .. ".part"
  local ok, err
  if not isDir(builds) then
    ok, err = lfs().mkdir(builds:sub(1, -2))
    if not ok then return nil, tostring(err) end
  end
  removeTree(part)
  ok, err = lfs().mkdir(part)
  if not ok then return nil, tostring(err) end
  for _, f in ipairs(files) do
    local dir = f.path:match("^(.*)/[^/]+$")
    if dir then
      ok, err = makeDirs(part, dir)
      if not ok then return nil, tostring(err) end
    end
    ok, err = writeFile(part .. pathsep .. f.path:gsub("/", pathsep), raw:sub(f.at, f.at + f.size - 1))
    if not ok then return nil, tostring(err) end
  end
  -- (The game's own check: the code is the server's.)
  if MultiplayerLobby.luaChecksum(part .. pathsep .. "Lua" .. pathsep) ~= build then
    removeTree(part)
    return nil, "another build"
  end
  writeFile(part .. pathsep .. "pack.txt", "release " .. (info.release or "") .. "\n")
  removeTree(root)
  ok, err = os.rename(part, root)
  if not ok then return nil, tostring(err) end
  MultiplayerPack.prune(app, build)
  return true
end

--! Remove the longest unused downloaded builds beyond KEEP (never `keep`
--! nor the one running).
function MultiplayerPack.prune(app, keep)
  local builds = MultiplayerPack.buildsDir(app)
  if not isDir(builds) then return end
  local running = MultiplayerPack.installDir(app) and MultiplayerLobby.buildId(app):match("(%x+)$")
  local list = {}
  for name in lfs().dir(builds) do
    local dir = builds .. name
    if isBuild(name) and name ~= keep and name ~= running and isDir(dir) then
      local used = lfs().attributes(dir .. pathsep .. "pack.txt", "modification") or 0
      list[#list + 1] = {name = name, used = used}
    elseif name:match("^%x+%.part$") then
      removeTree(dir)
    end
  end
  table.sort(list, function(a, b) return a.used > b.used end)
  for i = MultiplayerPack.KEEP, #list do removeTree(builds .. list[i].name) end
end

-- Switching builds ------------------------------------------------------------------

--! Restart the game as another build (nil: the installed game), and join the
--! server at `address` as `name` once it has started.
function MultiplayerPack.switchTo(app, build, address, name)
  local builds = MultiplayerPack.buildsDir(app)
  if not isDir(builds) then lfs().mkdir(builds:sub(1, -2)) end
  if build then
    assert(writeFile(builds .. "current.txt", build .. "\n"))
    -- (When it was last used: prune keeps the latest.)
    local pack_txt = builds .. build .. pathsep .. "pack.txt"
    writeFile(pack_txt, readFile(pack_txt) or "")
  else
    os.remove(builds .. "current.txt")
  end
  if address then writeFile(builds .. "rejoin.txt", address .. "\n" .. (name or "") .. "\n") end
  app:saveConfig()
  app:reset()
end

--! The server to join after a restart (address, name), or nil.
function MultiplayerPack.rejoinPending(app)
  local text = readFile(MultiplayerPack.buildsDir(app) .. "rejoin.txt")
  if not text then return nil end
  local address, name = text:match("^([^\n]+)\n([^\n]*)")
  return address, name
end

--! After the main menu is up: this build started fine (so it starts again
--! next time), and join the server it was started for.
function MultiplayerPack.afterStart(app)
  local builds = MultiplayerPack.buildsDir(app)
  os.remove(builds .. "starting.txt")
  local address, name = MultiplayerPack.rejoinPending(app)
  if not address then return end
  os.remove(builds .. "rejoin.txt")
  local UIMultiplayer = rawget(_G, "UIMultiplayer")
  if not UIMultiplayer or not app.ui then return end
  if name and name ~= "" then app.config.player_name = name end
  app.config.multiplayer_server = address
  local window = UIMultiplayer(app.ui)
  app.ui:addWindow(window)
  if window.buttonConnect then window:buttonConnect() end
end

-- A download ------------------------------------------------------------------------

--!param address (string) the server, "host:port"
--!param offer (table) from MultiplayerPack.offer (build, size)
function MultiplayerPack:MultiplayerPack(address, offer)
  self.build = offer.build
  self.size = offer.size
  self.received = 0
  self.parts = {}
  self.state = "connecting" -- connecting | receiving | checking | done | failed
  self.error = nil
  corsixth.require("mp_transport")
  if not MultiplayerTransport.available() then
    self:_fail("LuaSocket is not available in this build")
    return
  end
  local host, port = MultiplayerLobby.parseAddress(address)
  if not host then
    self:_fail("No server address")
    return
  end
  self.join = MultiplayerTransport.startJoin(host, port, 15)
end

function MultiplayerPack:_fail(why)
  self.state = "failed"
  self.error = why
  self:_close()
end

function MultiplayerPack:_close()
  if self.join then MultiplayerTransport.cancelJoin(self.join) end
  self.join = nil
  if self.transport and not self.transport.closed then self.transport.conn:close() end
  self.transport = nil
end

--! How far the download is, 0 to 1.
function MultiplayerPack:progress()
  if self.state == "checking" or self.state == "done" then return 1 end
  if not self.size or self.size <= 0 then return 0 end
  return math.min(1, self.received / self.size)
end

function MultiplayerPack:cancel()
  if self.state ~= "done" then self:_fail("cancelled") end
end

--! Go on with the download; call every frame.
function MultiplayerPack:poll(app)
  if self.state == "connecting" then
    local transport, err = MultiplayerTransport.pollJoin(self.join)
    if transport == nil then return end
    self.join = nil
    if not transport then
      self:_fail(tostring(err))
      return
    end
    self.transport = transport
    transport:send(MultiplayerLobby.encode("PACK", {build = self.build, from = 0}))
    self.state = "receiving"
  end
  if self.state == "receiving" then
    -- (A tick's worth, 10 lines of 36000 bytes: the window stays smooth.)
    -- The connection counts as lost only once every line that came is read:
    -- a fast server is done and gone while lines still wait here.
    local drained = false
    for _ = 1, 10 do
      local line = self.transport:receive()
      if not line then
        drained = true
        break
      end
      local verb, f = MultiplayerLobby.decode(line)
      if verb == "PACKINFO" then
        self.size = tonumber(f.size) or 0
        self.signature = f.sig
        if f.build ~= self.build or self.size <= 0 or self.size > MultiplayerPack.MAX_BYTES then
          self:_fail("bad answer")
          return
        end
      elseif verb == "PACKDATA" then
        local data = MultiplayerLobby.fromBase64(f.d or "")
        self.parts[#self.parts + 1] = data
        self.received = self.received + #data
        if self.received > (self.size or 0) then
          self:_fail("bad answer")
          return
        end
      elseif verb == "PACKEND" then
        self:_close()
        self.state = "checking" -- (unpacked next frame, after this is drawn)
        return
      elseif verb == "ERROR" then
        self:_fail(f.text or f.code or "error")
        return
      end
    end
    if drained and self.transport and self.transport.closed and self.state == "receiving" then
      self:_fail("Connection to the server lost")
    end
    return
  end
  if self.state == "checking" then
    local blob = table.concat(self.parts)
    self.parts = {}
    if #blob ~= self.size then
      self:_fail("incomplete")
      return
    end
    local ok, err = MultiplayerPack.install(app or TheApp, self.build, blob, self.signature)
    if ok then
      self.state = "done"
    else
      self:_fail(err)
    end
  end
end

return MultiplayerPack
