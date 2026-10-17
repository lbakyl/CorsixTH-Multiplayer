"""Choose the lockstep delay and the fastest game speed for a room.

One lockstep step is one game hour. A peer may run step n only after every
other peer has reported step n - delay + 1, so the reports of the slowest
peer must cross the relay within (delay - 1) step durations:

    (delay - 1) * step_ms >= one_way_ms * MARGIN + TICK_MS

``one_way_ms`` between two players through the relay is about half of the sum
of their round-trip times to the server. ``TICK_MS`` covers the 18 ms game
timer: a report only leaves at the next tick.

A larger delay allows a faster speed but makes every click take effect later
(``delay`` steps). We pick the smallest delay that keeps "Normal" smooth, then
the fastest speed that this delay allows.
"""

from __future__ import annotations

import statistics
from dataclasses import dataclass

TICK_MS = 18
MARGIN = 1.25
MIN_DELAY = 2
MAX_DELAY = 6

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
    """Typical round trip plus half the spread, so jitter is covered."""
    if not samples:
        return 0.0
    recent = samples[-10:]
    return statistics.median(recent) + (max(recent) - min(recent)) / 2


def worst_one_way(rtts: list[float]) -> float:
    """Largest player-to-player one-way time through the relay."""
    if len(rtts) < 2:
        return rtts[0] / 2 if rtts else 0.0
    ordered = sorted(rtts, reverse=True)
    return (ordered[0] + ordered[1]) / 2


def speed_ok(step_ms: int, delay: int, one_way_ms: float) -> bool:
    return (delay - 1) * step_ms >= one_way_ms * MARGIN + TICK_MS


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
    max_speed = SPEEDS[0][0]
    for name, ms in SPEEDS:
        if speed_ok(ms, delay, one_way):
            max_speed = name
    return Pacing(delay=delay, max_speed=max_speed, one_way_ms=round(one_way, 1))
