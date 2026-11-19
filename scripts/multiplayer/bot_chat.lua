--[[ Copyright (c) 2026 Jan Bakalar

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

--[[ The bots' chat lines (bot_chat in the language files) for the bot itself
and for checking translations.

As a module (require or dofile): M.load(path) -> the bot_chat table a language
file assigns (plain tables of strings; only what that file itself assigns, not
what it inherits).

As a script, checking a translation against English:
  lua scripts/multiplayer/bot_chat.lua --check LANGUAGE_FILE ENGLISH_FILE
prints every difference (a missing or extra list, a list of another length, a
line whose {placeholders} differ, a %s count that differs in bot_chat.words) and
exits 1 if there is any. Any Lua 5.1 to 5.5. ]]

local M = {}

--! The bot_chat table of a language file, run with stubs for Language,
--! Inherit, Font and the like.
--!param path (string) the language file
--!return (table|nil) bot_chat as the file assigns it
function M.load(path)
  local root = {}
  local node
  -- (A table assigned anywhere, adviser.goals = {...}, may get more keys
  -- later, adviser.goals.lose.kill = ...: it extends like the others.)
  local function vivify(t)
    if getmetatable(t) then return end
    for _, child in pairs(t) do
      if type(child) == "table" then vivify(child) end
    end
    node(t)
  end
  node = function(t)
    return setmetatable(t, {
      __index = function(self, k)
        local child = node({})
        rawset(self, k, child)
        return child
      end,
      __newindex = function(self, k, v)
        if type(v) == "table" then vivify(v) end
        rawset(self, k, v)
      end,
      -- (A key already there: plain assignment, so a table assigned over an
      -- existing one is made extendable by the parent's assignment below.)
    })
  end
  node(root)
  local env = setmetatable({}, {
    __index = function(_, k)
      if k == "string" or k == "table" or k == "math" or k == "pairs" or k == "ipairs" or k == "type" then
        return _G[k]
      end
      if k == "Language" or k == "Inherit" or k == "Font" or k == "Encoding" or k == "SetSpeechFile" or
          k == "IsArabicNumerals" or k == "LoadStrings" or k == "utf8" or k == "cp437" then
        return function(...) return ... end
      end
      return root[k]
    end,
    __newindex = function(_, k, v)
      -- (rawset: an assignment to a key already there skips __newindex.)
      if type(v) == "table" then vivify(v) end
      rawset(root, k, v)
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
  local chat = rawget(root, "bot_chat")
  -- (Plain tables from here: no metatables that make missing keys.)
  local function plain(t)
    local out = {}
    for k, v in pairs(t) do out[k] = type(v) == "table" and plain(v) or v end
    return out
  end
  return type(chat) == "table" and plain(chat) or nil
end

--! The {placeholders} of a line, sorted and joined ("{name}{room}").
function M.placeholders(line)
  local found = {}
  for p in line:gmatch("{%w+}") do found[#found + 1] = p end
  table.sort(found)
  return table.concat(found)
end

--! The differences between a translation's bot_chat and English's.
--!return (table) one line of text per difference
function M.compare(tr, en)
  local out = {}
  local function walk(path, a, b)
    if type(b) ~= "table" then
      if type(a) ~= type(b) then
        out[#out + 1] = path .. ": " .. type(b) .. " in English, " .. type(a) .. " here"
      elseif type(b) == "string" then
        if path:find("^words%.") then
          local _, na = a:gsub("%%s", ""); local _, nb = b:gsub("%%s", "")
          if na ~= nb then out[#out + 1] = path .. ": " .. nb .. " %s in English, " .. na .. " here" end
        end
        if M.placeholders(a) ~= M.placeholders(b) then
          out[#out + 1] = path .. ": placeholders " .. M.placeholders(b) .. " in English, " ..
              M.placeholders(a) .. " here: " .. a
        end
        if (b:sub(1, 1) == " ") ~= (a:sub(1, 1) == " ") then
          out[#out + 1] = path .. ": the English line starts with a space " ..
              (b:sub(1, 1) == " " and "(it is added to another line)" or "(this one should not)")
        end
      end
      return
    end
    if type(a) ~= "table" then
      out[#out + 1] = path .. ": missing"
      return
    end
    if #b > 0 and #a ~= #b then
      out[#out + 1] = path .. ": " .. #b .. " lines in English, " .. #a .. " here"
    end
    for k, v in pairs(b) do walk(path .. "." .. tostring(k), a[k], v) end
    for k in pairs(a) do
      if b[k] == nil then out[#out + 1] = path .. "." .. tostring(k) .. ": not in English" end
    end
  end
  for k, v in pairs(en) do walk(tostring(k), tr and tr[k], v) end
  table.sort(out)
  return out
end

local args = {...}
if args[1] == "--check" and args[2] and args[3] then
  local tr, en = M.load(args[2]), assert(M.load(args[3]), "no bot_chat in " .. args[3])
  local diffs = tr and M.compare(tr, en) or {"no bot_chat in " .. args[2]}
  for _, line in ipairs(diffs) do print(line) end
  local count = 0
  local function strings(t) for _, v in pairs(t) do if type(v) == "table" then strings(v) else count = count + 1 end end end
  if tr then strings(tr) end
  print(string.format("%d strings, %d differences", count, #diffs))
  os.exit(#diffs == 0 and 0 or 1)
end

return M
