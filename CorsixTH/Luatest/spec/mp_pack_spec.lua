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

require("corsixth")
require("class_test_base")
require("mp_pack")

local MultiplayerPack = _G["MultiplayerPack"]
local MultiplayerLobby = _G["MultiplayerLobby"]
local lfs = require("lfs")
local sep = package.config:sub(1, 1)

--! A pack's unpacked data, as packs.py writes it.
local function packData(build, files, header)
  local lines = {"OPENTH-PACK 1", "build " .. build, "api 2721", "engine 1", "release mp-test-x"}
  for _, line in ipairs(header or {}) do lines[#lines + 1] = line end
  local data = {}
  for _, f in ipairs(files) do
    lines[#lines + 1] = "file " .. #f[2] .. " " .. f[1]
    data[#data + 1] = f[2]
  end
  lines[#lines + 1] = "data"
  return table.concat(lines, "\n") .. "\n" .. table.concat(data)
end

local GAME = {{"CorsixTH.lua", "-- bootstrap\n"}, {"Lua/app.lua", "return 1\n"},
  {"Campaigns/Four Corners.map", "\0\1\2"}, {"Levels/st.peter's.level", "level"}}

local function tempDir()
  local name = os.tmpname()
  os.remove(name)
  assert(lfs.mkdir(name))
  return name .. sep
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local text = f:read("*a")
  f:close()
  return text
end

local function writeFile(path, text)
  local f = assert(io.open(path, "wb"))
  f:write(text)
  f:close()
end

describe("Game packs", function()
  local TH, saved, dir, app
  before_each(function()
    TH = require("TH")
    saved = {TH.CheckPackSignature, TH.InflatePack, TH.GetCompileOptions, MultiplayerLobby.luaChecksum}
    TH.CheckPackSignature = function(blob, sig) return sig == "good" end
    TH.InflatePack = function(blob) return blob end -- (the tests' packs are not zlib data)
    TH.GetCompileOptions = function() return {api_version = 2721, pack_engine = 1} end
    MultiplayerLobby.luaChecksum = function(root)
      return (readFile(root .. "app.lua") or "") == "return 1\n" and "0123abcd" or "ffffffff"
    end
    MultiplayerPack.cached_installed = nil
    dir = tempDir()
    app = {command_line = {["config-file"] = dir .. "config.txt"}, config = {},
      saveConfig = function(self) self.saved = true end,
      reset = function(self) self.restarted = true end}
  end)
  after_each(function()
    TH.CheckPackSignature, TH.InflatePack, TH.GetCompileOptions, MultiplayerLobby.luaChecksum =
        saved[1], saved[2], saved[3], saved[4]
  end)

  it("carries only the game's own files", function()
    for _, path in ipairs{"CorsixTH.lua", "Lua/app.lua", "Lua/dialogs/x.lua", "Campaigns/Four Corners.map",
        "Levels/st.peter's.level", "Bitmap/mp_icons.dat", "Sounds/a.wav"} do
      assert.is_true(MultiplayerPack.validPath(path), path)
    end
    for _, path in ipairs{"../x.lua", "Lua/../../x.lua", "/etc/passwd", "C:/x", "Lua", "Fonts/x.ttf",
        "Lua/.hidden.lua", "Lua\\x.lua", "CorsixTH.lua/x", "Lua//x.lua", "", "lua/app.lua", "Lua/a:b.lua"} do
      assert.is_false(MultiplayerPack.validPath(path), path)
    end
  end)

  it("reads a pack's header and files", function()
    local info, files = MultiplayerPack.parse(packData("0123abcd", GAME))
    assert.equal("0123abcd", info.build)
    assert.equal(2721, info.api)
    assert.equal(1, info.engine)
    assert.equal("mp-test-x", info.release)
    assert.equal(4, #files)
    local raw = packData("0123abcd", GAME)
    assert.equal("\0\1\2", raw:sub(files[3].at, files[3].at + files[3].size - 1))
  end)

  it("refuses packs that are not whole or not the game", function()
    local good = packData("0123abcd", GAME)
    assert.is_nil(MultiplayerPack.parse(good:gsub("^OPENTH", "OTHER")))
    assert.is_nil(MultiplayerPack.parse(good .. "x"))
    assert.is_nil(MultiplayerPack.parse(good:sub(1, -2)))
    assert.is_nil(MultiplayerPack.parse(packData("0123abcd", {GAME[1], GAME[2], {"lua/APP.lua", "x"}})))
    assert.is_nil(MultiplayerPack.parse(packData("0123abcd", {GAME[1]})))
    assert.is_nil(MultiplayerPack.parse(packData("0123abcd", {GAME[1], GAME[2], {"../evil.lua", "x"}})))
    assert.is_nil(MultiplayerPack.parse(packData("XYZ", GAME)))
  end)

  it("offers the server's version, or says when it needs a newer game", function()
    local err = {code = "build_mismatch", need = "0123abcd", release = "mp-test-x", pack = "3400000",
      pack_api = "2721", pack_engine = "1"}
    local offer = MultiplayerPack.offer(app, err)
    assert.equal("download", offer.how)
    assert.equal(3400000, offer.size)
    err.pack_engine = "2"
    assert.equal("newer_game", MultiplayerPack.offer(app, err).how)
    err.pack_engine, err.pack_api = "1", "2722"
    assert.equal("newer_game", MultiplayerPack.offer(app, err).how)
    -- (An older server, or one without the download: only its web page.)
    assert.is_nil(MultiplayerPack.offer(app, {code = "build_mismatch", need = "0123abcd"}))
    assert.is_nil(MultiplayerPack.offer(app, {code = "data_mismatch", need = "0123abcd", pack = "1"}))
    -- An engine without packs offers nothing.
    TH.CheckPackSignature = nil
    assert.is_nil(MultiplayerPack.offer(app, {code = "build_mismatch", need = "0123abcd", pack = "1"}))
  end)

  it("installs a signed pack, then switches to it without downloading", function()
    local raw = packData("0123abcd", GAME)
    assert.same({nil, "signature"}, {MultiplayerPack.install(app, "0123abcd", raw, "bad")})
    assert.same({nil, "another build"}, {MultiplayerPack.install(app, "99999999", raw, "good")})
    assert.is_true(MultiplayerPack.install(app, "0123abcd", raw, "good"))
    local root = dir .. "builds" .. sep .. "0123abcd" .. sep
    assert.equal("level", readFile(root .. "Levels" .. sep .. "st.peter's.level"))
    assert.equal("\0\1\2", readFile(root .. "Campaigns" .. sep .. "Four Corners.map"))
    assert.is_nil(lfs.attributes(dir .. "builds" .. sep .. "0123abcd.part"))
    local offer = MultiplayerPack.offer(app, {code = "build_mismatch", need = "0123abcd", pack = "10",
      pack_api = "2721", pack_engine = "1"})
    assert.equal("switch", offer.how)
  end)

  it("refuses a pack whose code is not the server's", function()
    local raw = packData("0123abcd", {GAME[1], {"Lua/app.lua", "return 2\n"}})
    assert.same({nil, "another build"}, {MultiplayerPack.install(app, "0123abcd", raw, "good")})
    assert.is_nil(lfs.attributes(dir .. "builds" .. sep .. "0123abcd"))
  end)

  it("restarts as the chosen build and joins the server again", function()
    MultiplayerPack.switchTo(app, "0123abcd", "eu2.openth.org:47800", "Алёна")
    assert.is_true(app.saved and app.restarted)
    local builds = dir .. "builds" .. sep
    assert.equal("0123abcd\n", readFile(builds .. "current.txt"))
    local address, name = MultiplayerPack.rejoinPending(app)
    assert.equal("eu2.openth.org:47800", address)
    assert.equal("Алёна", name)
    -- The installed game again.
    MultiplayerPack.switchTo(app, nil, "eu1.openth.org:47800", "Jan")
    assert.is_nil(readFile(builds .. "current.txt"))
  end)

  it("starts the chosen build, and the installed game after a failed start", function()
    local install = tempDir()
    local start = assert(loadfile("../Lua/mp_pack_start.lua"))
    local builds = dir .. "builds" .. sep
    lfs.mkdir(builds:sub(1, -2))
    local args = {"corsix-th", "--config-file=" .. dir .. "config.txt", "--hotkeys-file=" .. dir .. "hotkeys.txt"}
    assert.is_nil(start(install, install .. "Lua" .. sep, (table.unpack or unpack)(args)))
    writeFile(builds .. "current.txt", "0123abcd\n")
    assert.is_nil(start(install, install .. "Lua" .. sep, (table.unpack or unpack)(args))) -- (not downloaded)
    lfs.mkdir(builds .. "0123abcd")
    writeFile(builds .. "0123abcd" .. sep .. "CorsixTH.lua", "")
    local main, extra = start(install, install .. "Lua" .. sep, (table.unpack or unpack)(args))
    assert.equal(builds .. "0123abcd" .. sep .. "CorsixTH.lua", main)
    assert.equal("--pack-of=" .. install, extra[1])
    assert.equal("--config-file=" .. dir .. "config.txt", extra[2])
    -- A downloaded build does not start another one.
    assert.is_nil(start(install, install .. "Lua" .. sep, "--pack-of=" .. install, (table.unpack or unpack)(args)))
    -- It never reached the main menu: the installed game next time.
    assert.is_not_nil(readFile(builds .. "starting.txt"))
    assert.is_nil(start(install, install .. "Lua" .. sep, (table.unpack or unpack)(args)))
    assert.is_nil(readFile(builds .. "current.txt"))
    -- It did: it starts again.
    writeFile(builds .. "current.txt", "0123abcd\n")
    assert.equal(builds .. "0123abcd" .. sep .. "CorsixTH.lua", (start(install, install .. "Lua" .. sep, (table.unpack or unpack)(args))))
    MultiplayerPack.afterStart(app)
    assert.is_nil(readFile(builds .. "starting.txt"))
  end)
end)
