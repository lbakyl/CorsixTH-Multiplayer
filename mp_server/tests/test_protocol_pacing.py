from corsixth_mp import pacing
from corsixth_mp.protocol import (command_peer, decode, decode_value, encode, encode_value,
                                  parse_step_report)


def test_values_round_trip():
    for value in ["plain", "two words", "a=b", "100%", "tab\there", "Zdeněk", ""]:
        assert decode_value(encode_value(value)) == value
    assert " " not in encode_value("two words")


def test_encoding_matches_lua_session():
    # MultiplayerSession.encodeCommand escapes %, = and whitespace as %XX.
    assert encode_value("a b=c%") == "a%20b%3Dc%25"
    assert encode("C", kind="hire", peer=2) == "C kind=hire peer=2"


def test_decode_message():
    verb, fields = decode("JOIN room=Ward%207 password=")
    assert verb == "JOIN" and fields == {"room": "Ward 7", "password": ""}


def test_game_line_helpers():
    assert parse_step_report("S 2 41 2026-01-01 bal=1") == (2, 41, "2026-01-01 bal=1")
    assert command_peer("C kind=hire peer=12 seq=1") == 12
    assert command_peer("C kind=hire seq=1") is None


def test_pacing_loopback():
    # Delay 2 leaves one step (18 ms at the fastest speed) for the network:
    # enough on a loopback connection.
    p = pacing.recommend([1.0, 1.0])
    assert p.delay == 2 and p.max_speed == "And then some more"


def test_pacing_internet_needs_more_delay():
    # Two players with 40 ms round trips: 40 ms one way through the relay.
    # Normal would fit with delay 2, but delay 3 allows Max speed.
    p = pacing.recommend([40.0, 40.0])
    assert pacing.speed_ok(54, 2, p.one_way_ms)
    assert not pacing.speed_ok(36, 2, p.one_way_ms)
    assert p.delay == 3 and p.max_speed == "Max speed"


def test_pacing_helsinki_jitter_keeps_max_speed():
    # Pings seen from Prague to Helsinki: about 40 ms with some spread.
    rtts = [pacing.effective_rtt([38, 43, 41, 52, 40]), pacing.effective_rtt([36, 39, 44, 39, 37])]
    p = pacing.recommend(rtts)
    assert p.delay == 3 and p.max_speed == "Max speed"


def test_pacing_slow_link_caps_speed():
    p = pacing.recommend([400.0, 300.0])
    assert p.delay == pacing.MAX_DELAY
    assert pacing.speed_rank(p.max_speed) < pacing.speed_rank("Normal")


def test_effective_rtt_includes_jitter():
    assert pacing.effective_rtt([10, 10, 30]) == 10 + 5
