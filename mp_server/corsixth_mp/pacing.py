"""Choose the lockstep delay and the fastest game speed for a room.

At Normal and faster one lockstep step is one game hour; slower speeds (and
pause) step every 54 ms like Normal (the game, World:_mpTick). A peer may run
step n only after every other peer has reported step n - delay + 1, so the
reports of the slowest peer must cross the relay within (delay - 1) steps:

    (delay - 1) * step_ms >= one_way_ms * MARGIN + SLACK_MS

``one_way_ms`` between two players through the relay is about half of the sum
of their round-trip times to the server. ``SLACK_MS`` covers part of the 18 ms
game timer (a report leaves at the next tick).

A larger delay allows a faster speed but makes every click take effect later
(``delay`` steps of at least 54 ms). We pick the smallest delay that keeps
"Normal" smooth, raise it up to FAST_DELAY if that allows a faster speed, and
allow the fastest speed that this delay keeps smooth. (Before 2026-10-25 the
margin was 25 %, the slack a whole tick, the jitter allowance half the spread
and the delay was never raised: Max speed was often refused on the internet.)
"""

from __future__ import annotations

import statistics
from dataclasses import dataclass

TICK_MS = 18
SLACK_MS = 9
MARGIN = 1.0
MIN_DELAY = 2
MAX_DELAY = 6
FAST_DELAY = 3  # raise the delay up to this for a faster speed (3 x 54 ms per click at Normal)

# Name -> milliseconds per game hour (CorsixTH/Lua/world.lua tick_rates,
# 18 ms timer). Ordered slowest first.
SPEEDS: list[tuple[str, int]] = [
    ("Slowest", 56 * TICK_MS),
    ("Slower", 12 * TICK_MS),
    ("Normal", 3 * TICK_MS),
    ("Max speed", 2 * TICK_MS),
    ("And then some more", 1 * TICK_MS),
]
SPEED_NAMES = [name for name, _ in SPEEDS]
TARGET_SPEED = "Normal"


def speed_rank(name: str) -> int:
    return SPEED_NAMES.index(name)


def effective_rtt(samples: list[float]) -> float:
    """Typical round trip plus a quarter of the spread, for some jitter."""
    if not samples:
        return 0.0
    recent = samples[-10:]
    return statistics.median(recent) + (max(recent) - min(recent)) / 4


def worst_one_way(rtts: list[float]) -> float:
    """Largest player-to-player one-way time through the relay."""
    if len(rtts) < 2:
        return rtts[0] / 2 if rtts else 0.0
    ordered = sorted(rtts, reverse=True)
    return (ordered[0] + ordered[1]) / 2


def speed_ok(step_ms: int, delay: int, one_way_ms: float) -> bool:
    return (delay - 1) * step_ms >= one_way_ms * MARGIN + SLACK_MS


@dataclass(frozen=True)
class Pacing:
    delay: int
    max_speed: str
    one_way_ms: float

    @property
    def command_latency_ms(self) -> dict[str, int]:
        """How long a click takes to happen, per allowed speed."""
        return {name: self.delay * ms for name, ms in SPEEDS
                if speed_rank(name) <= speed_rank(self.max_speed)}


def recommend(rtts: list[float]) -> Pacing:
    """Pacing for players whose effective round-trip times are ``rtts``."""
    one_way = worst_one_way(rtts)
    target_ms = dict(SPEEDS)[TARGET_SPEED]
    delay = MIN_DELAY
    while delay < MAX_DELAY and not speed_ok(target_ms, delay, one_way):
        delay += 1
    # A faster speed for a slightly longer delay, up to FAST_DELAY.
    for _, ms in SPEEDS:
        if ms < target_ms and not speed_ok(ms, delay, one_way):
            for longer in range(delay + 1, FAST_DELAY + 1):
                if speed_ok(ms, longer, one_way):
                    delay = longer
                    break
    max_speed = SPEEDS[0][0]
    for name, ms in SPEEDS:
        if speed_ok(ms, delay, one_way):
            max_speed = name
    return Pacing(delay=delay, max_speed=max_speed, one_way_ms=round(one_way, 1))
