-- A quick check of the bot's text helpers (what counts as a request, a request for
-- money, the sum named, what a bank gives): the helpers are cut out of bot.lua.
-- Usage: lua scripts/multiplayer/bot_text_test.lua scripts/multiplayer/bot.lua
-- (any Lua 5.1 to 5.5).
local f = assert(io.open(arg[1])); local src = f:read("*a"); f:close()
local function cut(from, to)
  local a = assert(src:find(from, 1, true)); local b = assert(src:find(to, a, true))
  return src:sub(a, b - 1)
end
local code = cut("local function has_word", "local function reply_kind") ..
  cut("-- Words of a request", "--------------------------------------------------------------------------------\n-- The bot")
code = code .. "\nreturn {has_word=has_word,is_request=is_request,is_money_request=is_money_request,parse_amount=parse_amount}"
local T = assert((loadstring or load)(code))()
local function eq(a, b, what) if a ~= b then print("FAIL", what, tostring(a), tostring(b)) os.exit(1) end end
for text, want in pairs({
  ["Agnes, can you send me $20,000?"] = 20000, ["send me 20k"] = 20000, ["I need 2.5k please"] = 2500,
  ["give me 5000 dollars"] = 5000, ["need 20 000"] = 20000, ["send $ 3000"] = 3000, ["pošli mi 5000"] = 5000,
  ["could you spare some cash"] = false, ["20.000 dollars"] = 20000, ["send me $50"] = false,
}) do eq(T.parse_amount(text) or false, want, "amount " .. text) end
for text, want in pairs({
  ["Agnes, can you send me $20,000?"] = true, ["please send some cash"] = true, ["I sent you the money"] = false,
  ["we need money for the loan"] = true, ["nice weather"] = false, ["thanks for the cash!"] = false,
  ["can I have some money"] = true, ["pošli mi prosím peníze"] = true, ["I have lots of money"] = false,
  ["could you lend me 10k"] = true, ["I'm broke, can you help?"] = true,
}) do eq(T.is_money_request(text), want, "money " .. text) end
eq(T.is_request("build a toilet next to the gp"), true, "req1")
eq(T.is_request("nice hospital"), false, "req2")
eq(T.is_request("thanks for the doctor"), false, "req3")
print("text helpers ok")
local g = assert((loadstring or load)("local Bot = {}\nlocal GIVE_ABOVE, GIVE_KEEP = 20000, 15000\n" ..
  cut("function Bot.giftFor", "--! An ally asked in the chat for money") .. "\nreturn Bot.giftFor"))()
local function gift(b, a, wg, ws) local x, y = g(b, a) eq(x, wg, "give " .. b .. "/" .. tostring(a)) eq(y, ws, "spare " .. b .. "/" .. tostring(a)) end
gift(20000, 1000, 0, 0)     -- not more than 20000
gift(20001, 1000, 1000, 5000)
gift(30000, 15000, 15000, 15000)
gift(30000, 16000, 0, 15000)
gift(25500, nil, 5000, 10000)
gift(60000, nil, 10000, 45000)
gift(40000, nil, 10000, 25000)
gift(22000, nil, 3000, 7000)
gift(20500, nil, 2000, 5000)
gift(19000, nil, 0, 0)
print("gift ok")
