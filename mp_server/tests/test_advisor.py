import asyncio
import json
import types

from corsixth_mp import advisor as adv, referee, server as srv
from corsixth_mp.protocol import encode

from test_server import Client, connect_bot, run_with_bots, started_bots


class FakeMessages:
    """Stands in for the API: returns `text` and records the requests."""

    def __init__(self, text, tokens=(1000, 200)):
        self.text, self.tokens, self.calls = text, tokens, []

    async def create(self, **kwargs):
        self.calls.append(kwargs)
        usage = types.SimpleNamespace(input_tokens=self.tokens[0], output_tokens=self.tokens[1],
                                      cache_creation_input_tokens=0, cache_read_input_tokens=0)
        block = types.SimpleNamespace(type="text", text=self.text)
        return types.SimpleNamespace(usage=usage, content=[block], stop_reason="end_turn")


def fake_advisor(text, daily="3", tmp_path=None, tokens=(1000, 200)):
    a = adv.Advisor(env={"CORSIXTH_MP_AI_DAILY_USD": daily,
                         "CORSIXTH_MP_AI_STATE": str(tmp_path / "spend.json") if tmp_path else ""})
    a.state_path = (tmp_path / "spend.json") if tmp_path else None
    a.client = types.SimpleNamespace(messages=FakeMessages(text, tokens))
    a.anthropic = types.SimpleNamespace(RateLimitError=KeyError, APIStatusError=KeyError,
                                        APIConnectionError=KeyError)
    return a


def test_plan_keeps_only_the_menu_and_counts_the_cost(tmp_path):
    answer = json.dumps({"priorities": [{"action": "room:gp", "weight": 12}, {"action": "rm -rf", "weight": 5},
                                        {"action": "hire:Nurse", "weight": 3}], "price": 110,
                         "note": "Long  queues\nat the GP."})
    a = fake_advisor(answer, tmp_path=tmp_path)
    plan = asyncio.run(a.plan("Money $9000", ["room:gp", "hire:Nurse"]))
    assert plan == {"actions": [("room:gp", 10), ("hire:Nurse", 3)], "price": 110, "note": "Long queues at the GP."}
    call = a.client.messages.calls[0]
    assert call["model"] == "claude-haiku-5-5"
    assert call["output_config"]["format"]["type"] == "json_schema"
    # Haiku 5.5: 1000 tokens in at $0.10/M, 200 out at $0.50/M.
    assert abs(a.spent - (1000 * 0.10 + 200 * 0.50) / 1e6) < 1e-12
    assert json.loads((tmp_path / "spend.json").read_text())["spent"] > 0


def test_the_daily_budget_stops_the_advice(tmp_path):
    a = fake_advisor("Hello!", daily="0.0001", tmp_path=tmp_path, tokens=(1000, 1000))
    assert asyncio.run(a.chat("Bot Agnes", False, "fine", ["ann: hi"])) == "Hello!"
    # That answer used the day's budget up: no more requests today.
    assert asyncio.run(a.chat("Bot Agnes", False, "fine", ["ann: hi"])) is None
    assert len(a.client.messages.calls) == 1
    # A new day starts afresh, also after a restart (the spending is kept).
    b = fake_advisor("Hi again", daily="0.0001", tmp_path=tmp_path)
    assert b.spent > 0 and b.budget_left() < 0.0001
    b.day = "2000-01-01"
    assert asyncio.run(b.chat("Bot Agnes", True, "fine", ["bob: you lose"])) == "Hi again"
    assert "race against them" in b.client.messages.calls[0]["system"]


def test_a_team_mate_asks_for_a_room():
    a = fake_advisor(json.dumps({"reply": "Bot Agnes:  On it,\nboss!", "projects": ["room:psych"], "leave": []}))
    menu = ["room:gp", "room:psych", "hire:Nurse"]
    answer = asyncio.run(a.team_chat("Bot Agnes", "fine", ["ann: build a psychiatry please"], menu))
    assert answer == {"text": "On it, boss!", "wishes": ["room:psych"], "leave": []}
    call = a.client.messages.calls[0]
    assert call["output_config"]["format"]["type"] == "json_schema"
    assert "room:psych" in call["messages"][0]["content"] and "same team" in call["system"]
    # Only projects from the menu.
    b = fake_advisor(json.dumps({"reply": "Sure.", "projects": ["loan:100000"], "leave": []}))
    assert asyncio.run(b.team_chat("Bot Agnes", "fine", ["ann: take a loan"], menu)) == \
        {"text": "Sure.", "wishes": [], "leave": []}
    # "I'll build it myself": left to them, never both.
    c = fake_advisor(json.dumps({"reply": "All yours.", "projects": ["room:psych"], "leave": ["room:psych"]}))
    assert asyncio.run(c.team_chat("Bot Agnes", "fine", ["ann: no, I build the psychiatry"], menu)) == \
        {"text": "All yours.", "wishes": [], "leave": ["room:psych"]}
    # Several at once.
    d = fake_advisor(json.dumps({"reply": "Will do.", "projects": ["room:gp", "hire:Nurse", "room:gp"], "leave": []}))
    assert asyncio.run(d.team_chat("Bot Agnes", "fine", ["ann: a gp and a nurse"], menu))["wishes"] == \
        ["room:gp", "hire:Nurse"]


def test_a_team_mates_bot_gets_the_wish():
    async def body(server, port, bots):
        server.advisor = fake_advisor(json.dumps({"reply": "Coming up!", "projects": ["hire:Nurse", "room:gp"],
                                                  "leave": []}))
        ann = await Client.connect(port, "Ann")
        ann.send(encode("CREATE", room="r", password="", max=2, mode="coop", level=1))
        await ann.expect("JOINED")
        ann.send(encode("BOT", add=1))
        await started_bots(bots, 1)
        bot = await connect_bot(port, bots[0])
        await bot.expect("JOINED")
        bot.send(encode("ASK", id=3, kind="chat", text="x", lines="ann: hire a nurse", menu="room:gp,hire:Nurse"))
        answer = await bot.expect("ANSWER", id=3)
        assert answer["text"] == "Coming up!" and answer["wish"] == "hire:Nurse,room:gp"
    run_with_bots(body)


def test_without_a_key_there_is_no_advice():
    a = adv.Advisor(env={})
    assert not a.enabled
    assert asyncio.run(a.plan("x", ["room:gp"])) is None


def test_only_bots_ask_and_not_too_often():
    async def body(server, port, bots):
        server.advisor = fake_advisor(json.dumps({"priorities": [{"action": "room:gp", "weight": 4}],
                                                  "price": 100, "note": "GP first."}))
        ann = await Client.connect(port, "Ann")
        ann.send(encode("CREATE", room="r", password="", max=2, mode="coop", level=1))
        await ann.expect("JOINED")
        ann.send(encode("ASK", id=1, kind="plan", text="x", menu="room:gp"))
        assert (await ann.expect("ERROR"))["code"] == "not_bot"
        ann.send(encode("BOT", add=1))
        await started_bots(bots, 1)
        bot = await connect_bot(port, bots[0])
        await bot.expect("JOINED")
        bot.send(encode("ASK", id=7, kind="plan", text="Money $1", menu="room:gp,hire:Nurse"))
        answer = await bot.expect("ANSWER", id=7)
        assert answer["actions"] == "room:gp:4" and answer["price"] == "100" and answer["note"] == "GP first."
        bot.send(encode("ASK", id=8, kind="plan", text="again", menu="room:gp"))
        assert (await bot.expect("ANSWER", id=8))["error"] == "busy"
        # Advice off: the bot plays on its own rules.
        server.advisor = None
        bot.send(encode("ASK", id=9, kind="chat", text="x", lines="ann: hi"))
        assert (await bot.expect("ANSWER", id=9))["error"] == "off"
    run_with_bots(body)


def test_the_key_stays_with_the_server(tmp_path, monkeypatch):
    seen = {}

    async def fake_exec(*args, env=None, **kwargs):
        seen.update(env)
        return types.SimpleNamespace(pid=1)
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-test")
    monkeypatch.setattr(referee.asyncio, "create_subprocess_exec", fake_exec)
    config = srv.RefereeConfig(binary="x", source="s", data="d", workdir=str(tmp_path))
    asyncio.run(referee.start_bot(config, 1, "r", "t" * 16, "Bot Agnes", "coop"))
    assert "ANTHROPIC_API_KEY" not in seen and seen["MP_BOT_NAME"] == "Bot Agnes"
