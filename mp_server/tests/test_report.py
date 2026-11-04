import datetime
import json

from corsixth_mp import daily_report, stats


def _ts(day, hour, minute=0):
    tz = stats.timezone({})
    return datetime.datetime(*day, hour, minute, tzinfo=tz).timestamp()


def test_report_of_a_day(tmp_path):
    env = {"CORSIXTH_MP_STATS_DIR": str(tmp_path), "CORSIXTH_MP_SERVER_NAME": "eu2"}
    day = (2026, 11, 3)
    stats.record_game({"room": "Jan's room", "mode": "teamshared", "level": 3,
                       "started": _ts(day, 20), "ended": _ts(day, 21, 30),
                       "humans": ["Jan"], "bots": ["Bot Agnes", "Bot Bertie"], "repairs": 1}, env)
    stats.record_game({"room": "duo", "mode": "coop", "level": 2,
                       "started": _ts(day, 22), "ended": _ts(day, 22, 40),
                       "humans": ["jan", "Mira"], "bots": [], "repairs": 0}, env)
    # (Another day: not in it.)
    stats.record_game({"room": "old", "mode": "coop", "level": 1, "started": _ts((2026, 11, 2), 10),
                       "ended": _ts((2026, 11, 2), 11), "humans": ["X"], "bots": []}, env)
    stats.record_advice(0.25, _ts(day, 20, 5), env)
    stats.record_advice(0.05, _ts(day, 21), env)
    stats.record_advice(1.0, _ts((2026, 11, 4), 1), env)
    text = daily_report.report("2026-11-03", env)
    assert text.splitlines()[0] == "**eu2: Tue 03 Nov 2026**"
    assert "Games: 2, 2 h 10 min in all (longest 1 h 30 min)" in text
    assert "Human players: 2 different (3 in all games together)" in text
    assert "Bots: 2" in text
    assert "Desync repairs: 1" in text
    assert "Bot advice (Haiku): $0.30 for 2 answers" in text
    assert "- 20:00 Jan's room: 1 h 30 min, team hospitals, level 3; Jan + 2 bots" in text
    assert "- 22:00 duo: 40 min, co-op, level 2; jan, Mira" in text
    data = json.loads((tmp_path / "ai-daily.json").read_text())
    assert data["2026-11-04"] == {"usd": 1.0, "answers": 1}


def test_report_of_a_quiet_day(tmp_path):
    env = {"CORSIXTH_MP_STATS_DIR": str(tmp_path), "CORSIXTH_MP_SERVER_NAME": "eu1"}
    text = daily_report.report("2026-11-01", env)
    assert "No games played." in text and "$0.00 for 0 answers" in text
    stats.record_advice(0.01, _ts((2026, 11, 1), 12), env)
    assert "$0.01 for 1 answer" in daily_report.report("2026-11-01", env)


def test_nothing_kept_without_a_folder(tmp_path, monkeypatch):
    monkeypatch.delenv("CORSIXTH_MP_STATS_DIR", raising=False)
    env = {"CORSIXTH_MP_STATS_DIR": ""}
    assert stats.stats_dir(env) in (None, stats.stats_dir({}))
