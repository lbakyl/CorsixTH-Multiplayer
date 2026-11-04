--[[ Usage: lua scripts/multiplayer/mp_strings.lua LANGUAGE_FILE [--json | --missing ENGLISH_FILE]

The multiplayer strings of a language file (multiplayer_window and
tooltip.multiplayer_window): with --json as one JSON object, flat key path ->
text ("multiplayer_window.game_options"); with --missing those of
ENGLISH_FILE that LANGUAGE_FILE lacks, also as JSON. For the translations of
the multiplayer texts (the language files assign them key by key). Loads
the file with stubs for Language, Inherit, Font, Encoding and the like:
only what it assigns counts, not what it inherits. (Some language files
index tables they inherit; --missing stops with an error on those. The game
itself loads them: scripts/multiplayer/string_counts.lua prints a text of
each language.) ]]

local function load_strings(path)
  local root = {}
  local function node(t)
    return setmetatable(t, {__index = function(self, k)
      local child = node({})
      rawset(self, k, child)
      return child
    end})
  end
  node(root)
  local env = setmetatable({}, {
    __index = function(_, k)
      if k == "string" or k == "table" or k == "math" or k == "pairs" or k == "ipairs" or k == "type" then
        return _G[k]
      end
      if k == "Language" or k == "Inherit" or k == "Font" or k == "Encoding" or k == "SetSpeechFile" or
          k == "IsArabicNumerals" or k == "LoadStrings" or k == "utf8" then
        return function() end
      end
      return root[k]
    end,
    __newindex = function(_, k, v)
      -- (A whole table assigned, e.g. tooltip = {...}: later lines may
      -- still add tables into it, tooltip.multiplayer_window.x = ...)
      local function vivify(t)
        if getmetatable(t) then return end
        for _, child in pairs(t) do
          if type(child) == "table" then vivify(child) end
        end
        node(t)
      end
      if type(v) == "table" then vivify(v) end
      root[k] = v
    end,
  })
  local chunk
  if setfenv then
    chunk = assert(loadfile(path))
    setfenv(chunk, env)
  else
    chunk = assert(loadfile(path, "t", env))
  end
  chunk()
  local flat = {}
  local function walk(prefix, t)
    for k, v in pairs(t) do
      local key = prefix .. "." .. tostring(k)
      if type(v) == "table" then walk(key, v) elseif type(v) == "string" then flat[key] = v end
    end
  end
  local mw = rawget(root, "multiplayer_window")
  if type(mw) == "table" then walk("multiplayer_window", mw) end
  local tt = rawget(root, "tooltip")
  local tmw = type(tt) == "table" and rawget(tt, "multiplayer_window")
  if type(tmw) == "table" then walk("tooltip.multiplayer_window", tmw) end
  return flat
end

local function json(flat)
  local keys = {}
  for k in pairs(flat) do keys[#keys + 1] = k end
  table.sort(keys)
  local function esc(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
      if c == "\n" then return "\\n" end
      if c == '"' or c == "\\" then return "\\" .. c end
      return string.format("\\u%04x", c:byte())
    end) .. '"'
  end
  local out = {}
  for i, k in ipairs(keys) do out[i] = "  " .. esc(k) .. ": " .. esc(flat[k]) end
  return "{\n" .. table.concat(out, ",\n") .. "\n}\n"
end

local path, mode, english = ...
local flat = load_strings(path)
if mode == "--missing" then
  local have, missing = flat, {}
  for k, v in pairs(load_strings(english)) do
    if have[k] == nil then missing[k] = v end
  end
  flat = missing
end
io.write(json(flat))
