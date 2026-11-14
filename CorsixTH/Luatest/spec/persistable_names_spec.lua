-- Every --[[persistable:name]] comment must stand on the same line as the
-- function it names: persist_lua.cpp files the name under the comment's
-- line, and the game looks a function up by the line it starts on. A name on
-- the line before was never found, so no game could be saved while that
-- function was in use (the gates to hell animation: a multiplayer referee died
-- of it on eu2, 2026-11-13).

local ok, lfs = pcall(require, "lfs")

local function lua_files(dir, out)
  for name in lfs.dir(dir) do
    if name ~= "." and name ~= ".." then
      local path = dir .. "/" .. name
      local mode = lfs.attributes(path, "mode")
      if mode == "directory" then
        lua_files(path, out)
      elseif name:match("%.lua$") then
        out[#out + 1] = path
      end
    end
  end
  return out
end

describe("persistable function names", function()
  it("stand on the line of their function", function()
    if not ok then
      pending("lfs is not available")
      return
    end
    local bad = {}
    for _, path in ipairs(lua_files("../Lua", {})) do
      local n = 0
      for line in io.lines(path) do
        n = n + 1
        if line:match("%-%-%[%[persistable:[^%]]*%]%]%s*$") then bad[#bad + 1] = path .. ":" .. n end
      end
    end
    assert.are.same({}, bad)
  end)
end)
