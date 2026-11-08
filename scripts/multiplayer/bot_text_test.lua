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
code = code .. "\nreturn {has_word=has_word,is_request=is_request,is_money_request=is_money_request,parse_amount=parse_amount," ..
  "is_plot_request=is_plot_request,parse_plot=parse_plot}"
local T = assert((loadstring or load)(code))()
local function eq(a, b, what) if a ~= b then print("FAIL", what, tostring(a), tostring(b)) os.exit(1) end end
for text, want in pairs({
  ["Agnes, can you send me $20,000?"] = 20000, ["send me 20k"] = 20000, ["I need 2.5k please"] = 2500,
  ["give me 5000 dollars"] = 5000, ["need 20 000"] = 20000, ["send $ 3000"] = 3000, ["pošli mi 5000"] = 5000,
  ["could you spare some cash"] = false, ["20.000 dollars"] = 20000, ["send me $50"] = 50,
  ["give me 5 dollars"] = 5, ["send me money for 3 rooms"] = false,
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
-- A plot asked for (with its number, or any), and lines that are not that:
-- an offer of a plot, land for the bot itself, a room on a plot, money.
for text, want in pairs({
  ["Agnes, give me plot 7"] = true, ["can I have your plot 7?"] = true, ["sell me plot 7"] = true,
  ["give me one of your plots"] = true, ["can you spare a plot?"] = true, ["could you spare some land?"] = true,
  ["Bertie, can I buy plot 12 from you?"] = true, ["sell me plot 7 for 5000 dollars"] = true,
  ["dej mi pozemek 7"] = true, ["prodej mi parcelu 3 prosím"] = true, ["I need a plot please"] = true,
  ["I can spare a plot for you"] = false, ["you can have my plot 9"] = false, ["thanks for the plot!"] = false,
  ["buy more land please"] = false, ["build a toilet on plot 7"] = false, ["nice plot"] = false,
  ["I need money for land"] = false, ["send me $5000"] = false, ["I'll buy plot 7 myself"] = false,
}) do eq(T.is_plot_request(text), want, "plot request " .. text) end
for text, want in pairs({
  ["give me plot 7"] = 7, ["can I have plot #12?"] = 12, ["plot number 3 please"] = 3, ["parcel no. 5"] = 5,
  ["pozemek č. 4"] = 4, ["can you spare a plot?"] = false, ["give me plot, I have 20000"] = false,
  ["sell me plot 7 for $5000"] = 7, ["your plots 2"] = 2, ["one of your plots"] = false,
}) do eq(T.parse_plot(text) or false, want, "plot number " .. text) end
-- (A plot request is no money request when it names a plot: the plot comes first in Bot:onChat.)
eq(T.is_plot_request("sell me plot 7 for 5000 dollars") and T.parse_plot("sell me plot 7 for 5000 dollars"), 7, "plot first")
print("text helpers ok")
local g = assert((loadstring or load)("local Bot = {}\nlocal GIVE_KEEP, GIVE_MAX = 15000, 20000\n" ..
  cut("function Bot.giftFor", "--! An ally asked in the chat for money") .. "\nreturn Bot.giftFor"))()
-- gift(bank, sum asked or nil, what it sends, the most it could send now)
local function gift(b, a, wg, ws) local x, y = g(b, a) eq(x, wg, "give " .. b .. "/" .. tostring(a)) eq(y, ws, "most " .. b .. "/" .. tostring(a)) end
-- A sum named: min(asked, $20,000, bank - $15,000).
gift(15000, 1000, 0, 0)            -- at the floor: nothing
gift(15001, 1000, 1, 1)
gift(16000, 500, 500, 1000)        -- a small sum
gift(18000, 50, 50, 3000)
gift(15500, 1000, 500, 500)        -- less than asked: all above the floor
gift(30000, 15000, 15000, 15000)
gift(30000, 16000, 15000, 15000)
gift(60000, 50000, 20000, 20000)   -- at most $20,000 at once
gift(20000, 1000, 1000, 5000)      -- (before: refused, the bank was not over $20,000)
-- No sum named: half of the spare above $15,000, whole thousands, $1,000 to $10,000.
gift(25500, nil, 5000, 10500)
gift(60000, nil, 10000, 20000)
gift(40000, nil, 10000, 20000)
gift(22000, nil, 3000, 7000)
gift(20500, nil, 2000, 5500)
gift(19000, nil, 2000, 4000)
gift(16500, nil, 1000, 1500)
gift(15800, nil, 0, 800)
gift(14000, nil, 0, 0)
print("gift ok")
