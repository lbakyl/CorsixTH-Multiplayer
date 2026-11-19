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

require("corsixth")
require("class_test_base")
require("mp_lobby")

local MultiplayerLobby = _G["MultiplayerLobby"]

-- A bot's chat line shown in the player's language: the bot sends the line's
-- place in bot_chat and its values; game words come from the player's strings.
describe("A bot's chat line in the player's language", function()
  -- A made-up language: the words in brackets show where they came from.
  local root = {
    staff_class = {handyman = "Hausmeister"},
    staff_title = {doctor = "Arzt", surgeon = "Chirurg"},
    rooms_short = {gp = "Praxis", x_ray = "Röntgen"},
    rooms_long = {gp = "Allgemeinpraxis"},
    object = {bench = "Bank", plant = "Pflanze", x_ray = "Röntgengerät"},
    bot_chat = {
      lines = {
        tricked = {rats = {"Ratten, {name}?", "Keine Ratten mehr, {name}."}},
        staff_sent = {"{names}: {who}, ein {kind}, für deine {room}.{urgent}"},
        staff_for_emergency = {" Notfall!"},
        staff_ask_one = {"{names}, meine {room} braucht {needs}."},
        wish_done = {"{name}, dein(e) {what} ist fertig."},
        gift_none = {"Kein Geld, {name}."},
        gift_spent = {"Es ging in {spent}."},
        rescue_ask = {"Schickst du mir ${amount}, um {purpose} und {goal}?"},
        research_please = {"{name}, teilst du deine {item}-Forschung?"},
      },
      plot_ask = {wait = {"Grundstück {plot} gehört dir {terms}, {name}."}},
      replies = {greet = {friendly = {"Hallo {name}!"}}},
      words = {
        list_and = "%s und %s", list_comma = "%s, %s", list_or = "%s oder %s",
        wish_room = "{room}-Raum", wish_add = "{object} in der {room}", wish_bigger = "größere {room}",
        wish_remove = "{room}-Raum", wish_hire = "ein {staff}", wish_land = "mehr Land",
        near_reception = "Rezeption", near_entrance = "Eingang",
        terms_free = "gratis", terms_price = "für {price}",
        staff_count = "{n} × {staff}", everybody = "alle", lower_staff = 0,
        purpose_room = "einen neuen {what} zu bauen", purpose_hire = "{what} einzustellen",
        goal_value = "den Wert zu steigern", goal_other = "aufzuholen",
        spent_room = "den neuen {what} ({cost})", spent_gift = "das Geld für {name} ({cost})",
      },
    },
  }

  it("fills a line with a name", function()
    assert.equal("Keine Ratten mehr, Jan.",
        MultiplayerLobby.botChatText({line = "lines.tricked.rats.2", v_name = "Jan"}, root))
  end)

  it("writes game words in the player's language", function()
    local f = {line = "lines.staff_sent.1", v_names = "@names:and\tJan\tArgus\tPavel|Jan, Argus and Pavel",
        v_who = "Dr. Who", v_kind = "@staff:Surgeon|surgeon", v_room = "@room:gp|GP",
        v_urgent = "@line:lines.staff_for_emergency.1| It's for the emergency!"}
    assert.equal("Jan, Argus und Pavel: Dr. Who, ein Chirurg, für deine Allgemeinpraxis. Notfall!",
        MultiplayerLobby.botChatText(f, root))
  end)

  it("names a list joined with or, and a number of staff", function()
    local f = {line = "lines.staff_ask_one.1", v_names = "@names:or\tJan\tArgus|Jan or Argus",
        v_room = "@room:x_ray|X-Ray", v_needs = "@count:2:Doctor|2 doctors"}
    assert.equal("Jan oder Argus, meine Röntgen braucht 2 × Arzt.", MultiplayerLobby.botChatText(f, root))
  end)

  it("puts a wished-for project into words", function()
    local f = {line = "lines.wish_done.1", v_name = "Jan", v_what = "@wish:add:gp:plant|plant in the GP room"}
    assert.equal("Jan, dein(e) Pflanze in der Praxis ist fertig.", MultiplayerLobby.botChatText(f, root))
    f.v_what = "@wish:hire:Doctor|a doctor"
    assert.equal("Jan, dein(e) ein Arzt ist fertig.", MultiplayerLobby.botChatText(f, root))
  end)

  it("says two lines as one, each with its own values", function()
    local f = {line = "lines.gift_none.1", v_name = "Jan", line2 = "lines.gift_spent.1",
        w_spent = "@spent:room:x_ray:$12,000|the new X-Ray room ($12,000)"}
    assert.equal("Kein Geld, Jan. Es ging in den neuen Röntgen-Raum ($12,000).", MultiplayerLobby.botChatText(f, root))
  end)

  it("words why it needs money and its goal", function()
    local f = {line = "lines.rescue_ask.1", v_amount = "20,000", v_purpose = "@purpose:room:x_ray|build a new X-Ray room",
        v_goal = "@goal:value|raise the value of my hospital"}
    assert.equal("Schickst du mir $20,000, um einen neuen Röntgen-Raum zu bauen und den Wert zu steigern?",
        MultiplayerLobby.botChatText(f, root))
    f.v_goal = "@goal:reputation|improve my reputation"
    assert.truthy(MultiplayerLobby.botChatText(f, root):find("aufzuholen", 1, true), "an unknown goal: the general one")
  end)

  it("words a plot's terms and research items", function()
    assert.equal("Grundstück 7 gehört dir für $8,000, Jan.", MultiplayerLobby.botChatText({line = "plot_ask.wait.1",
        v_plot = "7", v_name = "Jan", v_terms = "@terms:price:$8,000|for $8,000, what it cost me"}, root))
    assert.equal("Jan, teilst du deine Röntgengerät-Forschung?", MultiplayerLobby.botChatText({
        line = "lines.research_please.1", v_name = "Jan", v_item = "@obj:x_ray|X-Ray"}, root))
  end)

  it("keeps the English words of a game word it cannot write", function()
    local f = {line = "lines.wish_done.1", v_name = "Jan", v_what = "@wish:mystery:thing|mystery thing"}
    assert.equal("Jan, dein(e) mystery thing ist fertig.", MultiplayerLobby.botChatText(f, root))
  end)

  it("gives nil (the English text is shown) for a line it does not have", function()
    assert.is_nil(MultiplayerLobby.botChatText({line = "lines.nonsense.1", v_name = "Jan"}, root))
    assert.is_nil(MultiplayerLobby.botChatText({line = "lines.tricked.rats.9", v_name = "Jan"}, root))
    assert.is_nil(MultiplayerLobby.botChatText({text = "hello"}, root))
    -- (A value missing: the placeholder would show, so the English text instead.)
    assert.is_nil(MultiplayerLobby.botChatText({line = "lines.tricked.rats.1"}, root))
  end)

  it("writes a staff kind in lower case where the language does, Cyrillic too", function()
    assert.equal("doctor", MultiplayerLobby.lowerFirst("Doctor"))
    assert.equal("хирург", MultiplayerLobby.lowerFirst("Хирург"))
    assert.equal("психиатр", MultiplayerLobby.lowerFirst("Психиатр"))
    assert.equal("ёж", MultiplayerLobby.lowerFirst("Ёж"))
    assert.equal("іспит", MultiplayerLobby.lowerFirst("Іспит"))
    assert.equal("ґанок", MultiplayerLobby.lowerFirst("Ґанок"))
    assert.equal("Ärzte", MultiplayerLobby.lowerFirst("Ärzte"), "other letters stay")
    assert.equal("", MultiplayerLobby.lowerFirst(""))
  end)

  it("reads a reply line", function()
    assert.equal("Hallo Jan!", MultiplayerLobby.botChatText({line = "replies.greet.friendly.1", v_name = "Jan"}, root))
  end)
end)
