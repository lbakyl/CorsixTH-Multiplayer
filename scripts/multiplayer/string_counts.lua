--[[ Usage: corsix-th --interpreter=scripts/multiplayer/string_counts.lua --config-file=...
(CORSIXTH_SOURCE: the checkout)

Prints, for every language, how many entries the string lists have that the
game picks from at random (string tables' __random): staff names and
descriptions; and one multiplayer text, to see each language has its own.
In multiplayer every computer must draw the same random
numbers; with Lua 5.4 and later math.random(1, n) may draw more than once
depending on n, so a list of another length in another language would put
the games out of step. ]]

local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
assert(TheApp.good_install_folder, "Game data was not accepted")

local lists = {"humanoid_name_starts", "humanoid_name_ends", "staff_descriptions.good",
  "staff_descriptions.misc", "staff_descriptions.bad"}
local function count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end
local languages = {}
for i, language in ipairs(TheApp.strings.languages) do languages[i] = language end
languages[#languages + 1] = "English" -- (again last: no other language changed it)
for _, language in ipairs(languages) do
  local ok, S = pcall(TheApp.strings.load, TheApp.strings, language)
  if ok then
    local parts = {}
    for _, path in ipairs(lists) do
      local t = S
      for key in path:gmatch("[^.]+") do t = t[key] end
      parts[#parts + 1] = path .. "=" .. count(t)
    end
    print("COUNTS " .. language .. " " .. table.concat(parts, " ") .. " | " ..
        tostring(S.multiplayer_window.game_options) .. " | " .. tostring(S.multiplayer_window.auction_title))
  else
    print("COUNTS " .. language .. " failed: " .. tostring(S))
  end
end
print("COUNTS DONE")
os.exit(0)
