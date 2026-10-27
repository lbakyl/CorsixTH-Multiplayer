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
import signal
import time
from dataclasses import dataclass, field

from . import pacing
from .referee import RefereeConfig, start_bot, start_referee
from .protocol import (MAX_LINE_BYTES, PROTOCOL_VERSION, ProtocolError, command_peer, command_step,
                       decode, encode, is_game_line, parse_step_report)

log = logging.getLogger("corsixth_mp")

SERVER_VERSION = "0.1"
MAX_NAME = 32
MAX_ROOMS = 64
MODES = ("shared", "coop", "competitive")
# Modes in which every player runs a hospital of their own.
HOSPITAL_EACH = ("coop", "competitive")
SPEED_CONTROL = ("any", "owner")
DIFFICULTIES = ("easy", "full", "hard")
PING_INTERVAL_LOBBY = 1.0
PING_INTERVAL_GAME = 2.0  # also how often players get the PLAYERS list
RTT_WINDOW = 10.0  # seconds of pings averaged for the PLAYERS list
HELLO_TIMEOUT = 15.0
# A public server should not let one address (or everybody) open unlimited
# connections. Defaults; see the CORSIXTH_MP_MAX_* environment variables.
MAX_CONNECTIONS = 256
MAX_PER_ADDRESS = 8
# Commands kept per room for a referee that joins late (bytes; later the
# referee's saves let the server forget older ones).
MAX_COMMAND_LOG = 16 * 1024 * 1024
# Game state a player may send for the log after a desync (DIAG).
MAX_DIAG_BYTES = 256 * 1024
# Desync recovery: the referee's save (base64, in SAVEDATA lines) may be this
# big, and everybody must have loaded it within the timeout.
MAX_SAVE_BYTES = 64 * 1024 * 1024
RECOVERY_TIMEOUT = 60.0
# Computer players (bots): the room owner adds them in the lobby; each is a
# headless game this server starts (like the referee) that joins the room as
# a player. Names given in this order; a bot that has not joined within the
# timeout is given up.
BOT_NAMES = ("Bot Agnes", "Bot Bertie", "Bot Clive", "Bot Dora", "Bot Edna", "Bot Fergus",
             "Bot Gwen", "Bot Hector")
BOT_START_TIMEOUT = 60.0
# Each bot is a whole game running on this server: at most this many at once
# (all rooms together; CORSIXTH_MP_MAX_BOTS).
MAX_BOTS = 6
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
    rtt_recent: list[tuple[float, float]] = field(default_factory=list)  # (time, ms)
    last_heard: float = field(default_factory=time.monotonic)
    pings: dict[int, float] = field(default_factory=dict)
    next_ping_id: int = 1
    last_step: int = 0
    closed: bool = False
    is_referee: bool = False
    is_bot: bool = False
    bot_proc: object = None
    diag_bytes: int = 0

    @property
    def rtt(self) -> float:
        return pacing.effective_rtt(self.rtt_samples)

    def recent_rtt(self, now: float) -> float | None:
        """Average round trip of the pings answered in the last RTT_WINDOW
        seconds (None: none answered)."""
        recent = [ms for t, ms in self.rtt_recent if now - t <= RTT_WINDOW]
        return sum(recent) / len(recent) if recent else None

    def send(self, line: str) -> None:
        if self.closed:
            return
        try:
            self.writer.write(line.encode("utf-8") + b"\n")
        except (ConnectionError, RuntimeError):
            self.closed = True


@dataclass
class Recovery:
    """A desync being repaired: everybody holds, the referee saves its game,
    everybody (the referee too) loads that save and the commands after it."""
    step: int                      # where the desync was found
    # player -> step it stopped at (None: rejoining, it has no game yet)
    held: dict[int, int | None] = field(default_factory=dict)
    asked: bool = False            # SAVE sent to the referee
    saver: "Player | None" = None  # who sends the save (the referee, or the host of a continued game)
    parts: list[str] = field(default_factory=list)
    size: int = 0


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
    left_names: dict[int, str] = field(default_factory=dict)  # peer -> name, for rejoining
    start_fields: dict[str, object] = field(default_factory=dict)  # START for everybody
    # A room continuing a saved game: the step it was saved at, its date, and
    # its hospitals' names (co-op: players get the hospital with their name).
    continue_step: int | None = None
    continue_date: str = ""
    seat_names: list[str] = field(default_factory=list)
    # The last shared save everybody loaded: (step, base64 parts), for a
    # referee that connects after it.
    base_save: tuple[int, list[str]] | None = None
    # Headless referee (peer 0): connection, process, its token, and the
    # fingerprints waiting to be checked against it (step -> fingerprint).
    referee: Player | None = None
    referee_proc: object = None
    referee_token: str = ""
    agreed: dict[int, str] = field(default_factory=dict)      # players agreed, referee not yet
    referee_fps: dict[int, str] = field(default_factory=dict)  # referee reported, players not yet
    verified_step: int = 0  # last step the referee confirmed
    # Everything a peer joining late needs (the referee): every command and
    # LEFT so far, and each player's latest step report.
    command_log: list[str] = field(default_factory=list)
    command_log_bytes: int = 0
    left_log: list[str] = field(default_factory=list)
    last_report: dict[int, str] = field(default_factory=dict)
    recovery: "Recovery | None" = None  # desync repair in progress
    recoveries: int = 0
    # Bots started but not joined yet: token -> (name, process or None).
    bots_pending: dict[str, list] = field(default_factory=dict)

    def humans(self) -> list[Player]:
        return [p for p in self.players.values() if not p.is_bot]

    def is_full(self) -> bool:
        return len(self.players) + len(self.bots_pending) >= self.max_players

    def check_password(self, password: str) -> bool:
        if self.password_hash is None:
            return True
        return hmac.compare_digest(self.password_hash, _hash_password(password, self.salt))

    def broadcast(self, line: str, exclude: Player | None = None,
                  referee: bool = False) -> None:
        for p in self.players.values():
            if p is not exclude:
                p.send(line)
        if referee and self.referee is not None and self.referee is not exclude:
            self.referee.send(line)

    def free_peer(self) -> int | None:
        for n in range(1, self.max_players + 1):
            if n not in self.players and n not in self.left:
                return n
        return None

    def current_pacing(self) -> pacing.Pacing:
        return pacing.recommend([p.rtt for p in self.players.values()])


class Server:
    def __init__(self, motd: str = "", max_connections: int = MAX_CONNECTIONS,
                 max_per_address: int = MAX_PER_ADDRESS,
                 referee: RefereeConfig | None = None, max_bots: int = MAX_BOTS) -> None:
        self.referee_config = referee
        self.max_bots = max_bots
        self.port = 0
        self.max_connections = max_connections
        self.max_per_address = max_per_address
        self.connections_by_address: dict[str, int] = {}
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
        self.port = bound
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
        peername = writer.get_extra_info("peername")
        address = str(peername[0]) if peername else "?"
        total = sum(self.connections_by_address.values())
        if (total >= self.max_connections or
                self.connections_by_address.get(address, 0) >= self.max_per_address):
            log.warning("refusing connection from %s: too many connections", address)
            writer.write(encode("ERROR", code="busy", text="Too many connections").encode() + b"\n")
            await self._close_writer(writer)
            return
        self.connections_by_address[address] = self.connections_by_address.get(address, 0) + 1
        try:
            await self._serve_connection(reader, writer, peername)
        finally:
            left = self.connections_by_address.get(address, 1) - 1
            if left > 0:
                self.connections_by_address[address] = left
            else:
                self.connections_by_address.pop(address, None)

    @staticmethod
    async def _close_writer(writer: asyncio.StreamWriter) -> None:
        try:
            await writer.drain()
            writer.close()
        except (ConnectionError, RuntimeError):
            pass

    async def _serve_connection(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter,
                                peername: object) -> None:
        try:
            first = await asyncio.wait_for(reader.readline(), HELLO_TIMEOUT)
        except (asyncio.TimeoutError, ConnectionError, ValueError):
            await self._close_writer(writer)
            return
        if first.strip() == b"HEALTH":
            # Health check (container HEALTHCHECK); answered quietly.
            writer.write(encode("OK", rooms=len(self.rooms), players=len(self.players)).encode() + b"\n")
            await self._close_writer(writer)
            return
        player = Player(pid=self.next_pid, writer=writer)
        self._writers.add(writer)
        self.next_pid += 1
        sock = writer.get_extra_info("socket")
        if sock is not None:
            import socket as _socket
            sock.setsockopt(_socket.IPPROTO_TCP, _socket.TCP_NODELAY, 1)
        log.info("connection %d from %s", player.pid, peername)
        pinger = asyncio.create_task(self._pinger(player))
        try:
            if not first or not self._hello(player, first.decode("utf-8", "replace")):
                return
            self.players[player.pid] = player
            while not player.closed:
                raw = await reader.readline()
                if not raw:
                    break
                player.last_heard = time.monotonic()
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
                if room and room.state == "running" and not player.is_referee:
                    player.send(self._players_line(room))
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
        if f.get("role") == "referee":
            return self._referee_hello(player, f)
        if f.get("role") == "bot":
            return self._bot_hello(player, f)
        name = f.get("name", "").strip()[:MAX_NAME] or f"Player {player.pid}"
        player.name = name
        player.build = f.get("build", "")
        player.send(encode("WELCOME", proto=PROTOCOL_VERSION, id=player.pid,
                           server=SERVER_VERSION, motd=self.motd or None))
        log.info("player %d is %r, build %s", player.pid, name, player.build)
        return True

    def _referee_hello(self, player: Player, f: dict[str, str]) -> bool:
        """The room's headless referee connects (started by this server)."""
        room = self.rooms.get(f.get("room", ""))
        if (room is None or room.state != "running" or not room.referee_token or
                not hmac.compare_digest(room.referee_token, f.get("token", ""))):
            self._error(player, "not_referee", "Unknown room or token")
            return False
        player.name, player.build, player.is_referee = "referee", f.get("build", ""), True
        if player.build != room.build:
            log.warning("room %r: referee build %s differs from the room's %s; no referee",
                        room.name, player.build, room.build)
            self._error(player, "build_mismatch", "The referee runs another build")
            return False
        player.room, player.peer = room, 0
        room.referee = player
        player.send(encode("WELCOME", proto=PROTOCOL_VERSION, id=player.pid, server=SERVER_VERSION))
        player.send(encode("START", peer=0, **room.start_fields))
        # Catch up: the game started before the referee was there. If
        # everybody loaded a shared save since, the referee loads it too.
        if room.base_save is not None and room.recovery is None:
            step, parts = room.base_save
            player.send(encode("LOAD", step=step, parts=len(parts),
                               peers=",".join(str(p) for p in sorted(room.players))))
            for part in parts:
                player.send(encode("SAVEDATA", d=part))
            player.send(encode("LOADEND", step=step))
        for line in room.command_log:
            player.send(line)
        if room.base_save is not None and room.recovery is None:
            player.send(encode("RESUME", step=room.base_save[0]))
        for peer in sorted(room.players):
            if peer in room.last_report:
                player.send(room.last_report[peer])
        for line in room.left_log:
            player.send(line)
        log.info("room %r: referee connected (%d commands to catch up)", room.name,
                 len(room.command_log))
        self._recovery_progress(room)
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

    def _players_line(self, room: Room) -> str:
        """PLAYERS: everybody who played in this running room, for the
        in-game player list: peer, name, average round trip over the last
        RTT_WINDOW seconds (-1: none), on (connected) or left, seconds since
        the server last heard from them, and the last step they reported."""
        now = time.monotonic()
        seats: dict[int, tuple[str, str, int, int, int]] = {}
        for peer, name in room.left_names.items():
            seats[peer] = (name, "left", -1, 0, room.left.get(peer, 0))
        for peer, pl in room.players.items():
            if pl.is_referee:
                continue
            rtt = pl.recent_rtt(now)
            seats[peer] = (pl.name, "on", -1 if rtt is None else round(rtt),
                           int(now - pl.last_heard), pl.last_step)
        fields: dict[str, object] = {"n": len(seats)}
        for i, peer in enumerate(sorted(seats), start=1):
            name, state, rtt, quiet, step = seats[peer]
            fields.update({f"peer{i}": peer, f"name{i}": name, f"state{i}": state,
                           f"rtt{i}": rtt, f"quiet{i}": quiet, f"step{i}": step})
        return encode("PLAYERS", **fields)

    def _on_pong(self, player: Player, f: dict[str, str]) -> None:
        sent = player.pings.pop(int(f.get("id", "0") or 0), None)
        if sent is not None:
            now = time.monotonic()
            player.rtt_samples.append((now - sent) * 1000)
            del player.rtt_samples[:-20]
            player.rtt_recent.append((now, (now - sent) * 1000))
            player.rtt_recent = [(t, ms) for t, ms in player.rtt_recent if now - t <= RTT_WINDOW]

    def _on_ping(self, player: Player, f: dict[str, str]) -> None:
        player.send(encode("PONG", id=f.get("id")))

    def _on_list(self, player: Player, f: dict[str, str]) -> None:
        for room in sorted(self.rooms.values(), key=lambda r: r.name.lower()):
            player.send(encode("ROOM", room=room.name, players=len(room.players),
                               max=room.max_players, mode=room.mode, level=room.level,
                               locked=room.password_hash is not None, state=room.state,
                               build_ok=room.build == player.build,
                               **{"continue": 1 if room.continue_step is not None else None}))
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
        continue_step = None
        seat_names: list[str] = []
        if f.get("continue") == "1":
            try:
                continue_step = max(0, int(f.get("step", "0")))
            except ValueError:
                self._error(player, "bad_room", "step must be a number")
                return
            seat_names = [n.strip()[:MAX_NAME] for n in f.get("seats", "").split(",") if n.strip()][:4]
            if mode in HOSPITAL_EACH and seat_names:
                max_players = min(4, max(2, len(seat_names)))
        password = f.get("password", "")
        salt = secrets.token_bytes(16)
        room = Room(name=name, salt=salt,
                    password_hash=_hash_password(password, salt) if password else None,
                    build=player.build, max_players=max_players, mode=mode, level=level,
                    difficulty=difficulty, speed_control=speed_control, owner=player,
                    continue_step=continue_step, continue_date=f.get("date", "")[:20],
                    seat_names=seat_names)
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
            self._rejoin(player, room)
        elif room.is_full():
            self._error(player, "room_full", "The room is full")
        else:
            self._add_to_room(player, room)

    def _rejoin(self, player: Player, room: Room) -> None:
        """A player who left a running game comes back under the same name:
        everybody, the newcomer too, loads the referee's game."""
        peer = next((p for p, n in sorted(room.left_names.items())
                     if n.lower() == player.name.lower()), None)
        if peer is None or not room.referee_token:
            self._error(player, "running", "The game has already started")
            return
        if room.recovery is not None:
            self._error(player, "busy", "The game is being repaired; try again")
            return
        del room.left_names[peer]
        room.left.pop(peer, None)
        player.room, player.peer, player.ready = room, peer, True
        room.players[peer] = player
        log.info("room %r: %r rejoins as player %d", room.name, player.name, peer)
        player.send(encode("JOINED", room=room.name, peer=peer, owner=False, mode=room.mode,
                           level=room.level, difficulty=room.difficulty, max=room.max_players))
        # The start as it was (hospital order, names), with today's players
        # and speed; the game itself comes with the shared save.
        fields = dict(room.start_fields, speed=room.speed, resume=1,
                      active=",".join(str(p) for p in sorted(room.players)))
        player.send(encode("START", peer=peer, **fields))
        room.broadcast(encode("CHAT", peer=0, name="server", text=f"{player.name} is back"),
                       exclude=player)
        room.broadcast(self._players_line(room))
        self._start_recovery(room, player.last_step, rejoining=peer)

    def _add_to_room(self, player: Player, room: Room, ready: bool = False) -> None:
        peer = room.free_peer()
        assert peer is not None
        player.room, player.peer, player.ready = room, peer, ready
        room.players[peer] = player
        player.send(encode("JOINED", room=room.name, peer=peer, owner=room.owner is player,
                           mode=room.mode, level=room.level, difficulty=room.difficulty,
                           max=room.max_players,
                           date=room.continue_date if room.continue_step is not None else None,
                           bots=1 if self.referee_config is not None else None,
                           **{"continue": 1 if room.continue_step is not None else None}))
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
        room = player.room
        if not room:
            return
        text = f.get("text", "")[:200]
        to = f.get("to", "")
        if to.isdigit() and int(to) in room.players:
            # A private line: only that player, and the sender sees it sent.
            line = encode("CHAT", peer=player.peer, name=player.name, text=text, to=int(to))
            room.players[int(to)].send(line)
            if int(to) != player.peer:
                player.send(line)
            return
        room.broadcast(encode("CHAT", peer=player.peer, name=player.name, text=text))

    # ------------------------------------------------------------------ bots

    def _bot_name(self, room: Room) -> str:
        """A name for a new bot: in a continued game the first saved
        hospital nobody has taken (the bot plays it), else the next free one
        of BOT_NAMES."""
        taken = {p.name.lower() for p in room.players.values()}
        taken |= {entry[0].lower() for entry in room.bots_pending.values()}
        for name in list(room.seat_names) + list(BOT_NAMES):
            if name.lower() not in taken:
                return name
        n = 1
        while f"bot {n}" in taken:
            n += 1
        return f"Bot {n}"

    def _on_bot(self, player: Player, f: dict[str, str]) -> None:
        """The room owner adds a bot (add=1) or takes one away (remove=<peer>)
        while the room waits in the lobby."""
        room = player.room
        if room is None or room.owner is not player:
            self._error(player, "not_owner", "Only the room owner adds bots")
            return
        if room.state != "lobby":
            return
        if f.get("remove"):
            bot = room.players.get(int(f["remove"])) if f["remove"].isdigit() else None
            if bot is None or not bot.is_bot:
                self._error(player, "not_bot", "That player is not a bot")
                return
            log.info("room %r: %r takes %r away", room.name, player.name, bot.name)
            self._stop_bot(bot)
            return
        if self.referee_config is None:
            self._error(player, "no_bots", "This server cannot run bots")
            return
        if room.is_full():
            self._error(player, "room_full", "The room is full")
            return
        running = sum(len(r.bots_pending) + sum(1 for p in r.players.values() if p.is_bot)
                      for r in self.rooms.values())
        if running >= self.max_bots:
            self._error(player, "too_many_bots", "This server runs as many bots as it can")
            return
        name = self._bot_name(room)
        token = secrets.token_hex(16)
        room.bots_pending[token] = [name, None]
        log.info("room %r: %r adds %r", room.name, player.name, name)
        loop = asyncio.get_running_loop()
        loop.create_task(self._spawn_bot(room, token, name))
        loop.call_later(BOT_START_TIMEOUT, self._bot_timeout, room, token)
        self._send_lobby(room)

    async def _spawn_bot(self, room: Room, token: str, name: str) -> None:
        try:
            proc = await start_bot(self.referee_config, self.port, room.name, token, name, room.mode)
        except OSError as exc:
            log.warning("room %r: cannot start %r: %s", room.name, name, exc)
            if token in room.bots_pending:
                self._bot_failed(room, token)
            return
        entry = room.bots_pending.get(token)
        if entry is not None:
            entry[1] = proc
            return
        # Taken away, or the room closed, while it started; or it has joined
        # already (its connection keeps the process).
        bot = next((p for p in room.players.values() if p.is_bot and p.name == name), None)
        if bot is not None and bot.bot_proc is None:
            bot.bot_proc = proc
        elif proc is not None and getattr(proc, "returncode", 0) is None:
            proc.terminate()

    def _bot_timeout(self, room: Room, token: str) -> None:
        if token in room.bots_pending:
            self._bot_failed(room, token)

    def _bot_failed(self, room: Room, token: str) -> None:
        name, proc = room.bots_pending.pop(token)
        if proc is not None and getattr(proc, "returncode", 0) is None:
            try:
                proc.terminate()
            except ProcessLookupError:
                pass
        log.warning("room %r: %r did not join", room.name, name)
        room.broadcast(encode("CHAT", peer=0, name="server", text=f"{name} could not start"))
        self._send_lobby(room)

    def _bot_hello(self, player: Player, f: dict[str, str]) -> bool:
        """A bot this server started joins its room."""
        room = self.rooms.get(f.get("room", ""))
        token = f.get("token", "")
        entry = room.bots_pending.get(token) if room is not None else None
        if room is None or entry is None or room.state != "lobby":
            self._error(player, "not_bot", "Unknown room or token")
            return False
        name, proc = room.bots_pending.pop(token)
        player.name, player.build, player.is_bot, player.bot_proc = name, f.get("build", ""), True, proc
        if player.build != room.build:
            log.warning("room %r: %r runs build %s, the room %s", room.name, name, player.build,
                        room.build)
            self._error(player, "build_mismatch", "The bot runs another build")
            room.broadcast(encode("CHAT", peer=0, name="server",
                                  text=f"{name} could not join: this server's bots run another build"))
            self._send_lobby(room)
            return False
        player.send(encode("WELCOME", proto=PROTOCOL_VERSION, id=player.pid, server=SERVER_VERSION))
        log.info("player %d is %r (a bot), build %s", player.pid, name, player.build)
        self._add_to_room(player, room, ready=True)
        return True

    def _send_lobby(self, room: Room) -> None:
        if room.state != "lobby":
            return
        p = room.current_pacing()
        for peer, pl in sorted(room.players.items()):
            room.broadcast(encode("PLAYER", peer=peer, name=pl.name, ready=pl.ready,
                                  rtt=round(pl.rtt), owner=room.owner is pl,
                                  bot=1 if pl.is_bot else None))
        room.broadcast(encode("LOBBY", room=room.name, count=len(room.players),
                              starting=len(room.bots_pending) or None,
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
        if len(room.players) + len(room.bots_pending) < 2:
            self._error(player, "not_enough", "Wait for another player")
            return
        not_ready = [p.name for p in room.players.values() if not p.ready and p is not player]
        not_ready += [entry[0] for entry in room.bots_pending.values()]
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
        room.start_fields = dict(peers=peers, seed=room.seed, level=room.level,
                                 difficulty=room.difficulty, mode=room.mode,
                                 delay=room.pace.delay, max_speed=room.pace.max_speed,
                                 speed=room.speed, speed_control=room.speed_control,
                                 names=",".join(room.players[n].name.replace(",", " ")
                                                for n in sorted(room.players)),
                                 **DEFAULT_SETTINGS)
        if room.continue_step is not None:
            # A saved game: nobody loads the level; the host sends the save,
            # and everybody loads it like after a desync repair.
            room.start_fields["resume"] = 1
            if room.mode in HOSPITAL_EACH:
                room.start_fields["seats"] = ",".join(
                    f"{p}:{i}" for p, i in sorted(self._seats(room).items()))
        for peer, pl in room.players.items():
            pl.last_step = room.continue_step or 0
            pl.send(encode("START", peer=peer, **room.start_fields))
        room.broadcast(self._players_line(room))  # the player list from the start
        if room.continue_step is not None:
            rec = room.recovery = Recovery(step=room.continue_step, asked=True, saver=room.owner)
            rec.held = {p: None for p in room.players}
            asyncio.get_running_loop().call_later(RECOVERY_TIMEOUT, self._recovery_timeout,
                                                  room, rec)
        if self.referee_config is not None:
            room.referee_token = secrets.token_hex(16)
            asyncio.get_running_loop().create_task(self._spawn_referee(room))

    @staticmethod
    def _seats(room: Room) -> dict[int, int]:
        """Co-op saved game: peer -> hospital (1-based). A player gets the
        hospital with their name; the others get the free ones in order."""
        names = [n.upper() for n in room.seat_names]
        seats: dict[int, int] = {}
        taken: set[int] = set()
        for peer in sorted(room.players):
            name = room.players[peer].name.upper()
            for i, n in enumerate(names, 1):
                if n == name and i not in taken:
                    seats[peer] = i
                    taken.add(i)
                    break
        free = [i for i in range(1, max(len(names), len(room.players)) + 1) if i not in taken]
        for peer in sorted(room.players):
            if peer not in seats:
                seats[peer] = free.pop(0)
        return seats

    async def _spawn_referee(self, room: Room) -> None:
        try:
            room.referee_proc = await start_referee(self.referee_config, self.port,
                                                    room.name, room.referee_token)
        except OSError as exc:
            log.warning("room %r: cannot start the referee: %s", room.name, exc)
            room.referee_token = ""
            if room.recovery is not None:
                self._recovery_failed(room)

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

    def _on_show(self, player: Player, f: dict[str, str]) -> None:
        """Cosmetic information for the other players (e.g. a room outline
        being drawn). Not part of the lockstep; relayed as it is."""
        room = player.room
        if room is None or room.state != "running":
            return
        fields = {k: v for k, v in f.items() if k != "peer"}
        room.broadcast(encode("SHOW", peer=player.peer, **fields), exclude=player)

    def _on_diag(self, player: Player, f: dict[str, str]) -> None:
        """A player's game state after a desync, for comparing the games in
        this log. Limited per player."""
        room = player.room
        text = f.get("text", "")
        player.diag_bytes += len(text)
        if room is None or player.diag_bytes > MAX_DIAG_BYTES:
            return
        log.warning("room %r: state of %r (player %d) at step %s, part %s: %s", room.name,
                    player.name, player.peer, f.get("step", "?"), f.get("part", "?"), text)

    def _game_line(self, player: Player, line: str) -> None:
        room = player.room
        if room is None or room.state != "running":
            return
        if player.is_referee:
            # The referee only reports; its lines never reach the players.
            report = parse_step_report(line) if line.startswith("S ") else None
            if report is not None and report[0] == 0:
                self._referee_fingerprint(room, report[1], report[2])
            return
        if line.startswith("S "):
            report = parse_step_report(line)
            if report is None or report[0] != player.peer:
                self._error(player, "bad_report", "Step report for another peer")
                return
            _, step, fp = report
            player.last_step = step
            room.last_report[player.peer] = line
            self._record_fingerprint(room, player.peer, step, fp)
        elif command_peer(line) != player.peer:
            self._error(player, "bad_command", "Command for another peer")
            return
        elif room.referee_token:
            room.command_log_bytes += len(line)
            if room.command_log_bytes > MAX_COMMAND_LOG:
                log.warning("room %r: command log full; no more referee", room.name)
                room.referee_token = ""
                room.command_log.clear()
            else:
                room.command_log.append(line)
        if line.startswith("C ") and "kind=set_speed" in line:
            self._note_speed(room, line)
        room.broadcast(line, exclude=player, referee=True)

    @staticmethod
    def _note_speed(room: Room, line: str) -> None:
        """The players change speed with a set_speed command (every game
        switches at the same step); the room remembers it for rejoining."""
        try:
            _, f = decode(line)
        except ProtocolError:
            return
        speed = f.get("speed", "")
        if speed == "Pause" or speed in pacing.SPEED_NAMES:
            room.speed = speed

    def _record_fingerprint(self, room: Room, peer: int, step: int, fp: str) -> None:
        if room.desync_step is not None or room.recovery is not None:
            return
        fps = room.fingerprints.setdefault(step, {})
        fps[peer] = fp
        active = set(room.players)
        if active <= set(fps):
            values = {fps[p] for p in active}
            del room.fingerprints[step]
            if len(values) > 1:
                log.warning("room %r: desync at step %d: %s", room.name, step,
                            {p: fps[p] for p in sorted(active)})
                self._desync(room, step)
            elif room.referee_token:
                # All players agree; the referee checks them too.
                self._check_with_referee(room, step, values.pop(), None)

    def _referee_fingerprint(self, room: Room, step: int, fp: str) -> None:
        if room.desync_step is not None or room.recovery is not None:
            return
        self._check_with_referee(room, step, None, fp)

    def _check_with_referee(self, room: Room, step: int, players_fp: str | None,
                            referee_fp: str | None) -> None:
        """Compare the players' agreed fingerprint for `step` with the
        referee's, whichever arrives second."""
        if players_fp is not None:
            referee_fp = room.referee_fps.pop(step, None)
            if referee_fp is None:
                room.agreed[step] = players_fp
                # A referee that never comes must not make this grow forever.
                while len(room.agreed) > 20000:
                    room.agreed.pop(min(room.agreed))
                return
        else:
            players_fp = room.agreed.pop(step, None)
            if players_fp is None:
                room.referee_fps[step] = referee_fp
                while len(room.referee_fps) > 20000:
                    room.referee_fps.pop(min(room.referee_fps))
                return
        if players_fp == referee_fp:
            room.verified_step = max(room.verified_step, step)
            return
        log.warning("room %r: the players differ from the referee at step %d: players %s, "
                    "referee %s", room.name, step, players_fp, referee_fp)
        self._desync(room, step)

    # ------------------------------------------------------------ recovery

    def _desync(self, room: Room, step: int) -> None:
        """The games differ at `step`: repair them from the referee's game if
        there is one, otherwise tell everybody it is over."""
        if room.recovery is not None:
            return
        # A referee still starting counts: it catches up, then saves.
        if room.referee_token:
            log.info("room %r: repairing the desync at step %d from the referee's game",
                     room.name, step)
            self._start_recovery(room, step)
            return
        room.desync_step = step
        room.broadcast(encode("DESYNC", step=step))

    def _start_recovery(self, room: Room, step: int, rejoining: int | None = None) -> None:
        rec = room.recovery = Recovery(step=step)
        if rejoining is not None:
            rec.held[rejoining] = None
        # (why: the games tell their players about a repaired desync, not
        # about a player rejoining.)
        why = "desync" if rejoining is None else "rejoin"
        for peer, p in room.players.items():
            if peer != rejoining:
                p.send(encode("HOLD", step=step, why=why))
        asyncio.get_running_loop().call_later(RECOVERY_TIMEOUT, self._recovery_timeout,
                                              room, rec)
        self._recovery_progress(room)

    def _recovery_timeout(self, room: Room, rec: Recovery) -> None:
        if room.recovery is rec:
            log.warning("room %r: desync repair timed out", room.name)
            self._recovery_failed(room)

    def _recovery_failed(self, room: Room) -> None:
        rec, room.recovery = room.recovery, None
        if rec is not None and room.name in self.rooms:
            room.desync_step = rec.step
            room.broadcast(encode("DESYNC", step=rec.step), referee=True)

    def _on_held(self, player: Player, f: dict[str, str]) -> None:
        room = player.room
        rec = room.recovery if room else None
        if rec is None or player.is_referee:
            return
        rec.held[player.peer] = int(f.get("step", "0") or 0)
        self._recovery_progress(room)

    def _recovery_progress(self, room: Room) -> None:
        """Once every player has stopped (so every command they sent is in the
        command log), ask the referee for its game as soon as it has run the
        steps all of them have run: nobody goes back further than needed."""
        rec = room.recovery
        if rec is None or rec.asked or room.referee is None:
            return
        if room.players and set(room.players) <= set(rec.held):
            rec.asked = True
            rec.saver = room.referee
            steps = [rec.held[p] for p in room.players if rec.held[p] is not None]
            # Nobody but a rejoining player: the referee saves where it is.
            room.referee.send(encode("SAVE", step=min(steps) if steps else 0))

    def _on_savedata(self, player: Player, f: dict[str, str]) -> None:
        room = player.room
        rec = room.recovery if room else None
        if rec is None or not rec.asked or player is not rec.saver:
            return
        part = f.get("d", "")
        rec.size += len(part)
        if rec.size > MAX_SAVE_BYTES:
            log.warning("room %r: the referee's save is too big", room.name)
            self._recovery_failed(room)
            return
        rec.parts.append(part)

    def _on_saved(self, player: Player, f: dict[str, str]) -> None:
        room = player.room
        rec = room.recovery if room else None
        if rec is None or not rec.asked or player is not rec.saver:
            return
        step = int(f.get("step", "0") or 0)
        if int(f.get("parts", "-1") or -1) != len(rec.parts):
            log.warning("room %r: the referee's save is incomplete", room.name)
            self._recovery_failed(room)
            return
        # Everybody (the referee too) loads the save, then gets every command
        # for the steps after it, then carries on from there.
        replay = [line for line in room.command_log if (command_step(line) or 0) > step]
        lines = [encode("LOAD", step=step, parts=len(rec.parts),
                        peers=",".join(str(p) for p in sorted(room.players)))]
        lines += [encode("SAVEDATA", d=part) for part in rec.parts]
        lines.append(encode("LOADEND", step=step))
        lines += replay
        lines.append(encode("RESUME", step=step))
        targets = list(room.players.values()) + ([room.referee] if room.referee else [])
        room.base_save = (step, list(rec.parts))
        for target in targets:
            for line in lines:
                target.send(line)
        room.command_log = replay
        room.command_log_bytes = sum(len(line) for line in replay)
        room.fingerprints.clear()
        room.agreed.clear()
        room.referee_fps.clear()
        room.last_report.clear()
        room.left_log.clear()  # LOAD names the players from now on
        for p in room.players.values():
            p.last_step = step
        room.recovery = None
        room.recoveries += 1
        room.verified_step = min(room.verified_step, step)
        log.info("room %r: repaired: everybody loads the referee's game at step %d "
                 "(%d bytes, %d commands after it)", room.name, step, rec.size, len(replay))

    # ------------------------------------------------------------ departures

    def _leave_room(self, player: Player) -> None:
        room = player.room
        if room is None:
            return
        room.players.pop(player.peer, None)
        player.room = None
        if player.is_referee:
            if room.referee is player:
                room.referee = None
                room.referee_token = ""  # no more repairs in this room
                log.warning("room %r: the referee disconnected", room.name)
                # (Only a repair from the referee's own save fails: a continued
                # game's save comes from its host.)
                rec = room.recovery
                if rec is not None and (rec.saver is player or not rec.asked):
                    self._recovery_failed(room)
            return
        if room.state == "running":
            room.left[player.peer] = player.last_step
            room.left_names[player.peer] = player.name
            left = encode("LEFT", peer=player.peer, step=player.last_step, name=player.name)
            room.last_report.pop(player.peer, None)
            room.left_log.append(left)
            room.broadcast(left, referee=True)
            room.broadcast(self._players_line(room))
            # Reports still missing only from the leaver are complete now.
            for step in sorted(room.fingerprints):
                fps = room.fingerprints[step]
                fps.pop(player.peer, None)
                if not fps:
                    del room.fingerprints[step]
                elif set(room.players) <= set(fps):
                    del room.fingerprints[step]
                    if len(set(fps.values())) > 1 and room.desync_step is None:
                        self._desync(room, step)
            self._recovery_progress(room)
        else:
            room.broadcast(encode("CHAT", peer=0, name="server", text=f"{player.name} left"))
        if not room.humans():
            # Nobody left to play with the bots: they go too.
            self._stop_bots(room)
        if not room.players:
            del self.rooms[room.name]
            self._stop_referee(room)
            if room.referee_token:
                log.info("room %r: referee confirmed steps through %d", room.name,
                         room.verified_step)
            log.info("room %r closed", room.name)
            return
        if room.owner is player and room.humans():
            room.owner = min(room.humans(), key=lambda p: p.peer)
            room.owner.send(encode("OWNER"))
        self._send_lobby(room)

    @staticmethod
    def _stop_referee(room: Room) -> None:
        proc = room.referee_proc
        if proc is not None and proc.returncode is None:
            try:
                proc.terminate()
            except ProcessLookupError:
                pass
        if room.referee is not None:
            ref, room.referee = room.referee, None
            ref.closed = True
            ref.writer.close()

    @staticmethod
    def _stop_bot(bot: Player) -> None:
        """Close a bot's connection and end its process (it then leaves the
        room like a player who closed the game)."""
        proc = bot.bot_proc
        if proc is not None and getattr(proc, "returncode", 0) is None:
            try:
                proc.terminate()
            except ProcessLookupError:
                pass
        if not bot.closed:
            bot.closed = True
            try:
                bot.writer.close()
            except RuntimeError:
                pass

    def _stop_bots(self, room: Room) -> None:
        for bot in [p for p in room.players.values() if p.is_bot]:
            self._stop_bot(bot)
        for token in list(room.bots_pending):
            _, proc = room.bots_pending.pop(token)
            if proc is not None and getattr(proc, "returncode", 0) is None:
                try:
                    proc.terminate()
                except ProcessLookupError:
                    pass

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
    parser.add_argument("--max-connections", type=int,
                        default=int(os.environ.get("CORSIXTH_MP_MAX_CONNECTIONS", MAX_CONNECTIONS)))
    parser.add_argument("--max-per-address", type=int,
                        default=int(os.environ.get("CORSIXTH_MP_MAX_PER_ADDRESS", MAX_PER_ADDRESS)))
    parser.add_argument("--max-bots", type=int,
                        default=int(os.environ.get("CORSIXTH_MP_MAX_BOTS", MAX_BOTS)))
    args = parser.parse_args(argv)
    logging.basicConfig(level=args.log_level.upper(),
                        format="%(asctime)s %(levelname)s %(message)s")

    async def run() -> None:
        referee = RefereeConfig.from_env()
        if referee:
            log.info("headless referee enabled: %s", referee.binary)
        server = Server(motd=args.motd, max_connections=args.max_connections,
                        max_per_address=args.max_per_address, referee=referee,
                        max_bots=args.max_bots)
        await server.start(args.host, args.port)
        # Stop cleanly on SIGTERM (docker stop) as well as Ctrl+C.
        stop = asyncio.Event()
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGTERM, signal.SIGINT):
            try:
                loop.add_signal_handler(sig, stop.set)
            except (NotImplementedError, RuntimeError):
                pass  # e.g. Windows; Ctrl+C still raises KeyboardInterrupt
        serving = asyncio.create_task(server.serve_forever())
        await stop.wait()
        log.info("shutting down")
        serving.cancel()
        await server.close()

    try:
        asyncio.run(run())
    except KeyboardInterrupt:
        pass
