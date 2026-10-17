"""CorsixTH multiplayer relay and lobby.

The server never simulates the game. It
  * keeps password-protected rooms and checks that everyone runs the same
    game build,
  * measures each player's round-trip time and recommends the lockstep delay
    and the fastest game speed (pacing.py),
  * starts the game with one seed, level and set of gameplay settings for
    everybody, and gives each player a peer number,
  * relays the game's lockstep lines ("C ..." commands and "S ..." step
    reports) to the other players of the room,
  * compares the step fingerprints of all players and announces a desync,
  * shares speed and pause changes, and tells the others when someone leaves.

Protocol: docs/multiplayer/protocol.md. One TCP connection per player, one
message per line (protocol.py).
"""

from __future__ import annotations

import argparse
import asyncio
import hashlib
import hmac
import logging
import os
import random
import secrets
import time
from dataclasses import dataclass, field

from . import pacing
from .protocol import (MAX_LINE_BYTES, PROTOCOL_VERSION, ProtocolError, command_peer,
                       decode, encode, is_game_line, parse_step_report)

log = logging.getLogger("corsixth_mp")

SERVER_VERSION = "0.1"
MAX_NAME = 32
MAX_ROOMS = 64
MODES = ("shared", "coop")
SPEED_CONTROL = ("any", "owner")
DIFFICULTIES = ("easy", "full", "hard")
PING_INTERVAL_LOBBY = 1.0
PING_INTERVAL_GAME = 5.0
HELLO_TIMEOUT = 15.0
# Gameplay settings every peer must use (lesson 4 in the handover README).
DEFAULT_SETTINGS = {"grant_wage_increase": 1, "free_build_mode": 0}


def _hash_password(password: str, salt: bytes) -> bytes:
    return hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 50_000)


@dataclass(eq=False)
class Player:
    pid: int
    writer: asyncio.StreamWriter
    name: str = ""
    build: str = ""
    room: "Room | None" = None
    peer: int = 0
    ready: bool = False
    rtt_samples: list[float] = field(default_factory=list)
    pings: dict[int, float] = field(default_factory=dict)
    next_ping_id: int = 1
    last_step: int = 0
    closed: bool = False

    @property
    def rtt(self) -> float:
        return pacing.effective_rtt(self.rtt_samples)

    def send(self, line: str) -> None:
        if self.closed:
            return
        try:
            self.writer.write(line.encode("utf-8") + b"\n")
        except (ConnectionError, RuntimeError):
            self.closed = True


@dataclass(eq=False)
class Room:
    name: str
    salt: bytes
    password_hash: bytes | None
    build: str
    max_players: int
    mode: str
    level: int
    difficulty: str
    speed_control: str
    owner: Player
    players: dict[int, Player] = field(default_factory=dict)
    state: str = "lobby"  # lobby | running
    seed: int = 0
    pace: pacing.Pacing | None = None
    speed: str = pacing.TARGET_SPEED
    fingerprints: dict[int, dict[int, str]] = field(default_factory=dict)
    desync_step: int | None = None
    left: dict[int, int] = field(default_factory=dict)  # peer -> last step

    def check_password(self, password: str) -> bool:
        if self.password_hash is None:
            return True
        return hmac.compare_digest(self.password_hash, _hash_password(password, self.salt))

    def broadcast(self, line: str, exclude: Player | None = None) -> None:
        for p in self.players.values():
            if p is not exclude:
                p.send(line)

    def free_peer(self) -> int | None:
        for n in range(1, self.max_players + 1):
            if n not in self.players and n not in self.left:
                return n
        return None

    def current_pacing(self) -> pacing.Pacing:
        return pacing.recommend([p.rtt for p in self.players.values()])


class Server:
    def __init__(self, motd: str = "") -> None:
        self.rooms: dict[str, Room] = {}
        self.players: dict[int, Player] = {}
        self.next_pid = 1
        self.motd = motd
        self._server: asyncio.base_events.Server | None = None
        self._writers: set[asyncio.StreamWriter] = set()

    # ---------------------------------------------------------------- network

    async def start(self, host: str, port: int) -> int:
        self._server = await asyncio.start_server(self._handle, host, port, limit=MAX_LINE_BYTES)
        sock = self._server.sockets[0]
        bound = sock.getsockname()[1]
        log.info("listening on %s:%d", host, bound)
        return bound

    async def serve_forever(self) -> None:
        assert self._server
        async with self._server:
            await self._server.serve_forever()

    async def close(self) -> None:
        if self._server:
            self._server.close()
        # Since Python 3.12 wait_closed() also waits for open connections.
        for writer in list(self._writers):
            writer.close()
        if self._server:
            await asyncio.wait_for(self._server.wait_closed(), 5)

    async def _handle(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        player = Player(pid=self.next_pid, writer=writer)
        self._writers.add(writer)
        self.next_pid += 1
        sock = writer.get_extra_info("socket")
        if sock is not None:
            import socket as _socket
            sock.setsockopt(_socket.IPPROTO_TCP, _socket.TCP_NODELAY, 1)
        peername = writer.get_extra_info("peername")
        log.info("connection %d from %s", player.pid, peername)
        pinger = asyncio.create_task(self._pinger(player))
        try:
            first = await asyncio.wait_for(reader.readline(), HELLO_TIMEOUT)
            if not first or not self._hello(player, first.decode("utf-8", "replace")):
                return
            self.players[player.pid] = player
            while not player.closed:
                raw = await reader.readline()
                if not raw:
                    break
                if not raw.endswith(b"\n"):
                    break  # over-long line or connection cut mid-line
                self._dispatch(player, raw.decode("utf-8", "replace").rstrip("\r\n"))
                await writer.drain()
        except (asyncio.TimeoutError, ConnectionError, asyncio.LimitOverrunError, ValueError) as exc:
            log.info("connection %d: %s", player.pid, exc.__class__.__name__)
        finally:
            pinger.cancel()
            self._writers.discard(writer)
            self._disconnect(player)
            player.closed = True
            try:
                writer.close()
            except RuntimeError:
                pass

    async def _pinger(self, player: Player) -> None:
        try:
            while True:
                running = player.room is not None and player.room.state == "running"
                await asyncio.sleep(PING_INTERVAL_GAME if running else PING_INTERVAL_LOBBY)
                if not player.name:
                    continue
                pid = player.next_ping_id
                player.next_ping_id += 1
                player.pings[pid] = time.monotonic()
                player.send(encode("PING", id=pid))
                room = player.room
                if room and room.state == "lobby" and room.owner is player:
                    self._send_lobby(room)  # refresh everyone's ping, once per room
        except asyncio.CancelledError:
            pass

    # --------------------------------------------------------------- messages

    def _error(self, player: Player, code: str, text: str) -> None:
        player.send(encode("ERROR", code=code, text=text))

    def _hello(self, player: Player, line: str) -> bool:
        try:
            verb, f = decode(line)
        except ProtocolError:
            verb, f = "", {}
        if verb != "HELLO":
            self._error(player, "expected_hello", "Send HELLO first")
            return False
        if f.get("proto") != str(PROTOCOL_VERSION):
            self._error(player, "protocol", f"Server speaks protocol {PROTOCOL_VERSION}")
            return False
        name = f.get("name", "").strip()[:MAX_NAME] or f"Player {player.pid}"
        player.name = name
        player.build = f.get("build", "")
        player.send(encode("WELCOME", proto=PROTOCOL_VERSION, id=player.pid,
                           server=SERVER_VERSION, motd=self.motd or None))
        log.info("player %d is %r, build %s", player.pid, name, player.build)
        return True

    def _dispatch(self, player: Player, line: str) -> None:
        if is_game_line(line):
            self._game_line(player, line)
            return
        try:
            verb, f = decode(line)
        except ProtocolError as exc:
            self._error(player, "bad_message", str(exc))
            return
        handler = getattr(self, "_on_" + verb.lower(), None)
        if handler is None:
            self._error(player, "unknown_verb", verb)
            return
        handler(player, f)

    def _on_pong(self, player: Player, f: dict[str, str]) -> None:
        sent = player.pings.pop(int(f.get("id", "0") or 0), None)
        if sent is not None:
            player.rtt_samples.append((time.monotonic() - sent) * 1000)
            del player.rtt_samples[:-20]

    def _on_ping(self, player: Player, f: dict[str, str]) -> None:
        player.send(encode("PONG", id=f.get("id")))

    def _on_list(self, player: Player, f: dict[str, str]) -> None:
        for room in sorted(self.rooms.values(), key=lambda r: r.name.lower()):
            player.send(encode("ROOM", room=room.name, players=len(room.players),
                               max=room.max_players, mode=room.mode, level=room.level,
                               locked=room.password_hash is not None, state=room.state,
                               build_ok=room.build == player.build))
        player.send(encode("ROOMS_END", count=len(self.rooms)))

    def _on_create(self, player: Player, f: dict[str, str]) -> None:
        if player.room:
            self._error(player, "in_room", "Leave your room first")
            return
        name = f.get("room", "").strip()[:MAX_NAME]
        if not name:
            self._error(player, "bad_room", "Room name missing")
            return
        if name in self.rooms:
            self._error(player, "room_exists", "A room with this name exists")
            return
        if len(self.rooms) >= MAX_ROOMS:
            self._error(player, "server_full", "Too many rooms")
            return
        try:
            max_players = min(4, max(2, int(f.get("max", "2"))))
            level = min(12, max(1, int(f.get("level", "1"))))
        except ValueError:
            self._error(player, "bad_room", "max and level must be numbers")
            return
        mode = f.get("mode", "shared")
        difficulty = f.get("difficulty", "full")
        speed_control = f.get("speed_control", "any")
        if mode not in MODES or difficulty not in DIFFICULTIES or speed_control not in SPEED_CONTROL:
            self._error(player, "bad_room", "Unknown mode, difficulty or speed control")
            return
        password = f.get("password", "")
        salt = secrets.token_bytes(16)
        room = Room(name=name, salt=salt,
                    password_hash=_hash_password(password, salt) if password else None,
                    build=player.build, max_players=max_players, mode=mode, level=level,
                    difficulty=difficulty, speed_control=speed_control, owner=player)
        self.rooms[name] = room
        log.info("room %r created by %r (%s, level %d, %d players)", name, player.name, mode,
                 level, max_players)
        self._add_to_room(player, room)

    def _on_join(self, player: Player, f: dict[str, str]) -> None:
        if player.room:
            self._error(player, "in_room", "Leave your room first")
            return
        room = self.rooms.get(f.get("room", ""))
        if room is None:
            self._error(player, "no_room", "No such room")
        elif not room.check_password(f.get("password", "")):
            self._error(player, "bad_password", "Wrong password")
        elif room.build != player.build:
            self._error(player, "build_mismatch",
                        f"The room runs build {room.build}; you run {player.build}")
        elif room.state != "lobby":
            self._error(player, "running", "The game has already started")
        elif len(room.players) >= room.max_players:
            self._error(player, "room_full", "The room is full")
        else:
            self._add_to_room(player, room)

    def _add_to_room(self, player: Player, room: Room) -> None:
        peer = room.free_peer()
        assert peer is not None
        player.room, player.peer, player.ready = room, peer, False
        room.players[peer] = player
        player.send(encode("JOINED", room=room.name, peer=peer, owner=room.owner is player,
                           mode=room.mode, level=room.level, difficulty=room.difficulty,
                           max=room.max_players))
        room.broadcast(encode("CHAT", peer=0, name="server", text=f"{player.name} joined"),
                       exclude=player)
        self._send_lobby(room)

    def _on_leave(self, player: Player, f: dict[str, str]) -> None:
        self._leave_room(player)

    def _on_ready(self, player: Player, f: dict[str, str]) -> None:
        if player.room and player.room.state == "lobby":
            player.ready = f.get("ready", "1") == "1"
            self._send_lobby(player.room)

    def _on_chat(self, player: Player, f: dict[str, str]) -> None:
        if player.room:
            player.room.broadcast(encode("CHAT", peer=player.peer, name=player.name,
                                         text=f.get("text", "")[:200]))

    def _send_lobby(self, room: Room) -> None:
        if room.state != "lobby":
            return
        p = room.current_pacing()
        for peer, pl in sorted(room.players.items()):
            room.broadcast(encode("PLAYER", peer=peer, name=pl.name, ready=pl.ready,
                                  rtt=round(pl.rtt), owner=room.owner is pl))
        room.broadcast(encode("LOBBY", room=room.name, count=len(room.players),
                              max=room.max_players, mode=room.mode, level=room.level,
                              delay=p.delay, speed=p.max_speed, one_way=p.one_way_ms,
                              latency=p.command_latency_ms.get(pacing.TARGET_SPEED)))

    def _on_start(self, player: Player, f: dict[str, str]) -> None:
        room = player.room
        if room is None or room.owner is not player:
            self._error(player, "not_owner", "Only the room owner can start")
            return
        if room.state != "lobby":
            return
        if len(room.players) < 2:
            self._error(player, "not_enough", "Wait for another player")
            return
        not_ready = [p.name for p in room.players.values() if not p.ready and p is not player]
        if not_ready:
            self._error(player, "not_ready", "Not ready: " + ", ".join(not_ready))
            return
        room.state = "running"
        room.pace = room.current_pacing()
        room.speed = room.pace.max_speed if pacing.speed_rank(room.pace.max_speed) < \
            pacing.speed_rank(pacing.TARGET_SPEED) else pacing.TARGET_SPEED
        room.seed = random.SystemRandom().randrange(1, 2**31 - 1)
        peers = ",".join(str(n) for n in sorted(room.players))
        log.info("room %r starts: seed %d, delay %d, max speed %s, peers %s", room.name,
                 room.seed, room.pace.delay, room.pace.max_speed, peers)
        for peer, pl in room.players.items():
            pl.last_step = 0
            pl.send(encode("START", peer=peer, peers=peers, seed=room.seed, level=room.level,
                           difficulty=room.difficulty, mode=room.mode,
                           delay=room.pace.delay, max_speed=room.pace.max_speed,
                           speed=room.speed, speed_control=room.speed_control,
                           **DEFAULT_SETTINGS))

    def _on_speed(self, player: Player, f: dict[str, str]) -> None:
        room = player.room
        if room is None or room.state != "running" or room.pace is None:
            return
        speed = f.get("speed", "")
        if speed != "Pause" and speed not in pacing.SPEED_NAMES:
            self._error(player, "bad_speed", f"Unknown speed {speed}")
            return
        if speed != "Pause" and pacing.speed_rank(speed) > pacing.speed_rank(room.pace.max_speed):
            self._error(player, "too_fast", f"The connection allows up to {room.pace.max_speed}")
            return
        if room.speed_control == "owner" and room.owner is not player:
            self._error(player, "not_owner", "Only the room owner changes the speed")
            return
        room.speed = speed
        room.broadcast(encode("SPEED", peer=player.peer, speed=speed, name=player.name))

    def _game_line(self, player: Player, line: str) -> None:
        room = player.room
        if room is None or room.state != "running":
            return
        if line.startswith("S "):
            report = parse_step_report(line)
            if report is None or report[0] != player.peer:
                self._error(player, "bad_report", "Step report for another peer")
                return
            _, step, fp = report
            player.last_step = step
            self._record_fingerprint(room, player.peer, step, fp)
        elif command_peer(line) != player.peer:
            self._error(player, "bad_command", "Command for another peer")
            return
        room.broadcast(line, exclude=player)

    def _record_fingerprint(self, room: Room, peer: int, step: int, fp: str) -> None:
        if room.desync_step is not None:
            return
        fps = room.fingerprints.setdefault(step, {})
        fps[peer] = fp
        active = set(room.players)
        if active <= set(fps):
            values = {fps[p] for p in active}
            del room.fingerprints[step]
            if len(values) > 1:
                room.desync_step = step
                log.warning("room %r: desync at step %d: %s", room.name, step,
                            {p: fps[p] for p in sorted(active)})
                room.broadcast(encode("DESYNC", step=step))

    # ------------------------------------------------------------ departures

    def _leave_room(self, player: Player) -> None:
        room = player.room
        if room is None:
            return
        room.players.pop(player.peer, None)
        player.room = None
        if room.state == "running":
            room.left[player.peer] = player.last_step
            room.broadcast(encode("LEFT", peer=player.peer, step=player.last_step,
                                  name=player.name))
            # Reports still missing only from the leaver are complete now.
            for step in sorted(room.fingerprints):
                fps = room.fingerprints[step]
                fps.pop(player.peer, None)
                if not fps:
                    del room.fingerprints[step]
                elif set(room.players) <= set(fps):
                    if len(set(fps.values())) > 1 and room.desync_step is None:
                        room.desync_step = step
                        room.broadcast(encode("DESYNC", step=step))
                    del room.fingerprints[step]
        else:
            room.broadcast(encode("CHAT", peer=0, name="server", text=f"{player.name} left"))
        if not room.players:
            del self.rooms[room.name]
            log.info("room %r closed", room.name)
            return
        if room.owner is player:
            room.owner = room.players[min(room.players)]
            room.owner.send(encode("OWNER"))
        self._send_lobby(room)

    def _disconnect(self, player: Player) -> None:
        self._leave_room(player)
        self.players.pop(player.pid, None)
        log.info("player %d (%r) disconnected", player.pid, player.name)

    def _on_quit(self, player: Player, f: dict[str, str]) -> None:
        player.closed = True


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="CorsixTH multiplayer relay and lobby")
    parser.add_argument("--host", default=os.environ.get("CORSIXTH_MP_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("CORSIXTH_MP_PORT", "47800")))
    parser.add_argument("--motd", default=os.environ.get("CORSIXTH_MP_MOTD", ""))
    parser.add_argument("--log-level", default=os.environ.get("CORSIXTH_MP_LOG", "INFO"))
    args = parser.parse_args(argv)
    logging.basicConfig(level=args.log_level.upper(),
                        format="%(asctime)s %(levelname)s %(message)s")

    async def run() -> None:
        server = Server(motd=args.motd)
        await server.start(args.host, args.port)
        await server.serve_forever()

    try:
        asyncio.run(run())
    except KeyboardInterrupt:
        pass
