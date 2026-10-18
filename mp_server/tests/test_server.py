import asyncio

import pytest

from corsixth_mp import pacing, server as srv
from corsixth_mp.protocol import decode, encode


class Client:
    """Minimal test client that answers pings like the game does."""

    def __init__(self, reader, writer):
        self.reader, self.writer = reader, writer
        self.inbox: list[str] = []

    @classmethod
    async def connect(cls, port, name="p", build="b1"):
        r, w = await asyncio.open_connection("127.0.0.1", port)
        c = cls(r, w)
        c.send(encode("HELLO", proto=1, name=name, build=build))
        await c.expect("WELCOME")
        return c

    def send(self, line):
        self.writer.write(line.encode() + b"\n")

    async def line(self, timeout=3.0):
        while True:
            raw = await asyncio.wait_for(self.reader.readline(), timeout)
            if not raw:
                raise ConnectionError("closed")
            text = raw.decode().rstrip("\n")
            if text.startswith("PING "):
                self.send(encode("PONG", id=decode(text)[1]["id"]))
                continue
            return text

    async def expect(self, verb, timeout=3.0, **match):
        """Next message with this verb (and matching fields); others are kept."""
        while True:
            text = await self.line(timeout)
            if text.startswith(verb + " ") or text == verb:
                if verb in ("C", "S"):
                    return text
                fields = decode(text)[1]
                if all(fields.get(k) == str(v) for k, v in match.items()):
                    return fields
            self.inbox.append(text)

    async def close(self):
        self.writer.close()


@pytest.fixture
def run():
    def _run(coro_fn):
        async def main():
            server = srv.Server()
            port = await server.start("127.0.0.1", 0)
            try:
                await coro_fn(server, port)
            finally:
                await server.close()
        asyncio.run(main())
    return _run


async def two_players_in_room(port, password="pw", **room):
    a = await Client.connect(port, "Alice")
    b = await Client.connect(port, "Bob")
    a.send(encode("CREATE", room="r1", password=password, max=2, mode="shared", level=1, **room))
    joined = await a.expect("JOINED")
    assert joined["peer"] == "1" and joined["owner"] == "1"
    b.send(encode("JOIN", room="r1", password=password))
    joined = await b.expect("JOINED")
    assert joined["peer"] == "2" and joined["owner"] == "0"
    return a, b


async def start(a, b):
    b.send(encode("READY", ready=1))
    a.send(encode("START"))
    sa, sb = await a.expect("START"), await b.expect("START")
    return sa, sb


def test_hello_required(run):
    async def body(server, port):
        r, w = await asyncio.open_connection("127.0.0.1", port)
        w.write(b"LIST\n")
        fields = decode((await r.readline()).decode())[1]
        assert fields["code"] == "expected_hello"
        w.close()
    run(body)


def test_protocol_version_checked(run):
    async def body(server, port):
        r, w = await asyncio.open_connection("127.0.0.1", port)
        w.write(encode("HELLO", proto=99, name="x", build="b").encode() + b"\n")
        fields = decode((await r.readline()).decode())[1]
        assert fields["code"] == "protocol"
        w.close()
    run(body)


def test_room_list_password_and_build_check(run):
    async def body(server, port):
        a = await Client.connect(port, "Alice")
        a.send(encode("CREATE", room="Ward 7", password="secret", max=2, mode="coop", level=3))
        await a.expect("JOINED")
        c = await Client.connect(port, "Carol", build="other")
        c.send(encode("LIST"))
        room = await c.expect("ROOM")
        assert room["room"] == "Ward 7" and room["locked"] == "1" and room["build_ok"] == "0"
        assert room["mode"] == "coop" and room["level"] == "3"
        await c.expect("ROOMS_END", count=1)
        c.send(encode("JOIN", room="Ward 7", password="secret"))
        assert (await c.expect("ERROR"))["code"] == "build_mismatch"
        b = await Client.connect(port, "Bob")
        b.send(encode("JOIN", room="Ward 7", password="wrong"))
        assert (await b.expect("ERROR"))["code"] == "bad_password"
        b.send(encode("JOIN", room="Ward 7", password="secret"))
        assert (await b.expect("JOINED"))["peer"] == "2"
        d = await Client.connect(port, "Dave")
        d.send(encode("JOIN", room="Ward 7", password="secret"))
        assert (await d.expect("ERROR"))["code"] == "room_full"
    run(body)


def test_lobby_reports_players_ping_and_pacing(run):
    async def body(server, port):
        a, b = await two_players_in_room(port)
        # Pings are answered by the clients; the owner's pinger refreshes the lobby.
        lobby = await a.expect("LOBBY", timeout=4, count=2)
        assert lobby["count"] == "2"
        assert int(lobby["delay"]) >= 2
        assert lobby["speed"] in pacing.SPEED_NAMES
        players = [decode(m)[1] for m in a.inbox if m.startswith("PLAYER ")]
        assert {p["name"] for p in players} >= {"Alice", "Bob"}
    run(body)


def test_start_needs_ready_and_owner(run):
    async def body(server, port):
        a, b = await two_players_in_room(port)
        b.send(encode("START"))
        assert (await b.expect("ERROR"))["code"] == "not_owner"
        a.send(encode("START"))
        assert (await a.expect("ERROR"))["code"] == "not_ready"
        sa, sb = await start(a, b)
        assert sa["seed"] == sb["seed"] and sa["delay"] == sb["delay"]
        assert sa["peer"] == "1" and sb["peer"] == "2" and sa["peers"] == "1,2"
        assert sa["grant_wage_increase"] == "1" and sa["level"] == "1"
        # Nobody can join a running game.
        c = await Client.connect(port, "Carol")
        c.send(encode("JOIN", room="r1", password="pw"))
        assert (await c.expect("ERROR"))["code"] == "running"
    run(body)


def test_relay_and_fingerprint_check(run):
    async def body(server, port):
        a, b = await two_players_in_room(port)
        await start(a, b)
        a.send("C kind=hire peer=1 seq=1 step=3")
        assert await b.expect("C") == "C kind=hire peer=1 seq=1 step=3"
        a.send("S 1 1 fp-one")
        b.send("S 2 1 fp-one")
        assert await b.expect("S") == "S 1 1 fp-one"
        assert await a.expect("S") == "S 2 1 fp-one"
        # Someone else's peer number is refused and not relayed.
        b.send("C kind=hire peer=1 seq=9 step=4")
        assert (await b.expect("ERROR"))["code"] == "bad_command"
        a.send("S 1 2 fp-a")
        b.send("S 2 2 fp-b")
        assert (await a.expect("DESYNC"))["step"] == "2"
        assert (await b.expect("DESYNC"))["step"] == "2"
    run(body)


def test_speed_is_shared_and_capped(run):
    async def body(server, port):
        a, b = await two_players_in_room(port)
        sa, _ = await start(a, b)
        b.send(encode("SPEED", speed="Pause"))
        assert (await a.expect("SPEED"))["speed"] == "Pause"
        assert (await b.expect("SPEED"))["peer"] == "2"
        room = server.rooms["r1"]
        room.pace = pacing.Pacing(delay=2, max_speed="Normal", one_way_ms=10)
        a.send(encode("SPEED", speed="And then some more"))
        assert (await a.expect("ERROR"))["code"] == "too_fast"
        a.send(encode("SPEED", speed="Slower"))
        assert (await b.expect("SPEED"))["speed"] == "Slower"
    run(body)


def test_owner_speed_control(run):
    async def body(server, port):
        a, b = await two_players_in_room(port, speed_control="owner")
        await start(a, b)
        b.send(encode("SPEED", speed="Pause"))
        assert (await b.expect("ERROR"))["code"] == "not_owner"
    run(body)


def test_leaving_during_game(run):
    async def body(server, port):
        a, b = await two_players_in_room(port)
        await start(a, b)
        b.send("S 2 5 x")
        await a.expect("S")
        await b.close()
        left = await a.expect("LEFT")
        assert left["peer"] == "2" and left["step"] == "5"
        # A pending report of the leaver no longer blocks the comparison.
        a.send("S 1 6 y")
        await asyncio.sleep(0.1)
        assert server.rooms["r1"].fingerprints == {}
    run(body)


def test_owner_handover_in_lobby(run):
    async def body(server, port):
        a, b = await two_players_in_room(port)
        await a.close()
        await b.expect("OWNER")
        assert server.rooms["r1"].owner.name == "Bob"
        await b.close()
        await asyncio.sleep(0.1)
        assert "r1" not in server.rooms
    run(body)


def test_cosmetic_show_is_relayed_with_sender(run):
    async def body(server, port):
        a, b = await two_players_in_room(port)
        await start(a, b)
        a.send(encode("SHOW", kind="blueprint", room="gp", x=10, y=12, w=4, h=5, peer=9))
        show = await b.expect("SHOW")
        assert show == {"kind": "blueprint", "room": "gp", "x": "10", "y": "12", "w": "4",
                        "h": "5", "peer": "1"}
    run(body)


def test_health_check_answers_without_hello(run):
    async def body(server, port):
        r, w = await asyncio.open_connection("127.0.0.1", port)
        w.write(b"HEALTH\n")
        verb, fields = decode((await r.readline()).decode())
        assert verb == "OK" and fields["rooms"] == "0"
        w.close()
        assert server.players == {}
    run(body)


def test_connections_per_address_are_limited():
    async def main():
        server = srv.Server(max_per_address=2)
        port = await server.start("127.0.0.1", 0)
        try:
            a = await Client.connect(port, "a")
            b = await Client.connect(port, "b")
            r, w = await asyncio.open_connection("127.0.0.1", port)
            fields = decode((await r.readline()).decode())[1]
            assert fields["code"] == "busy"
            w.close()
            await a.close()
            await asyncio.sleep(0.1)
            c = await Client.connect(port, "c")  # a slot is free again
            await b.close()
            await c.close()
        finally:
            await server.close()
    asyncio.run(main())


def run_with_referee(body):
    """Like `run`, with a referee configured whose start only records the token."""
    started = []

    async def fake_start(config, port, room, token):
        started.append((port, room, token))
        return None

    async def main():
        orig = srv.start_referee
        srv.start_referee = fake_start
        server = srv.Server(referee=srv.RefereeConfig(binary="x", source="", data=""))
        port = await server.start("127.0.0.1", 0)
        try:
            await body(server, port, started)
        finally:
            srv.start_referee = orig
            await server.close()
    asyncio.run(main())


async def connect_referee(port, room, token, build="b1"):
    r, w = await asyncio.open_connection("127.0.0.1", port)
    c = Client(r, w)
    c.send(encode("HELLO", proto=1, name="x", build=build, role="referee", room=room, token=token))
    return c


def test_referee_follows_and_checks_the_players():
    async def body(server, port, started):
        a, b = await two_players_in_room(port)
        sa, _ = await start(a, b)
        for _ in range(50):
            if started:
                break
            await asyncio.sleep(0.01)
        assert started and started[0][:2] == (port, "r1")
        token = started[0][2]
        # What happened before the referee came is replayed to it.
        a.send("C kind=early peer=1 seq=1 step=2")
        assert await b.expect("C") == "C kind=early peer=1 seq=1 step=2"
        # A wrong token is refused.
        bad = await connect_referee(port, "r1", "nope")
        assert (await bad.expect("ERROR"))["code"] == "not_referee"
        ref = await connect_referee(port, "r1", token)
        await ref.expect("WELCOME")
        st = await ref.expect("START")
        assert st["peer"] == "0" and st["seed"] == sa["seed"] and st["peers"] == "1,2"
        assert await ref.expect("C") == "C kind=early peer=1 seq=1 step=2"
        # Player commands reach the referee; the referee's lines reach nobody.
        a.send("C kind=hire peer=1 seq=1 step=3")
        assert await ref.expect("C") == "C kind=hire peer=1 seq=1 step=3"
        ref.send("C kind=hire peer=0 seq=1 step=3")
        ref.send("S 0 1 fp-one")
        a.send("S 1 1 fp-one")
        b.send("S 2 1 fp-one")
        assert await a.expect("S") == "S 2 1 fp-one"
        # The players agree with each other but not with the referee.
        a.send("S 1 2 fp-two")
        b.send("S 2 2 fp-two")
        ref.send("S 0 2 fp-other")
        d = await a.expect("DESYNC")
        assert d["step"] == "2" and d["referee"] == "1"
        assert (await b.expect("DESYNC"))["step"] == "2"
        assert not any(x.startswith("C ") and "peer=0" in x for x in a.inbox + b.inbox)
        assert server.rooms["r1"].verified_step == 1
    run_with_referee(body)


def test_referee_with_another_build_is_refused():
    async def body(server, port, started):
        a, b = await two_players_in_room(port)
        await start(a, b)
        for _ in range(50):
            if started:
                break
            await asyncio.sleep(0.01)
        ref = await connect_referee(port, "r1", started[0][2], build="other")
        assert (await ref.expect("ERROR"))["code"] == "build_mismatch"
        assert server.rooms["r1"].referee is None
    run_with_referee(body)
