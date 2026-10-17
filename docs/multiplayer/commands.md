# Experimental multiplayer: first lockstep commands

First real player actions travelling between peers. Still a harness (the
actions come from a script, not from mouse clicks in the game UI), but the
command path is the one real multiplayer will use.

## How it works (`scripts/multiplayer/commands.lua`)

- A **command** is a player action as plain values, for example
  `place_object bench at 60,75 facing north`. Supported so far:
  `place_object`, `build_room`, `hire`.
- A peer issues a command at game hour *h*. It is scheduled for hour
  *h + 2* (`commands.DELAY`) and sent to the other peer together with that
  hour's fingerprint. Because peers wait for each other every hour, every
  peer has all commands for an hour before it reaches that hour.
- At the start of each hour every peer applies the commands due, sorted by
  hour, then player number (host 1, client 2), then sequence number.
- Commands carry **exact positions**, chosen by the issuing peer from its
  state. Validity is checked again when applying, against the same state on
  every peer, so an action that became impossible is rejected the same way
  everywhere.
- Applying a command must not advance game time. `build_room` therefore fails
  (on every peer) if people are standing in the area, instead of waiting.
- Wire format: one text line per command,
  `C class=... hour=52 kind=hire peer=2 seq=3 x=.. y=..`, keys sorted,
  values percent-encoded.

In the probe, `MP_SCRIPT` lists a peer's planned actions, e.g.
`30:object:bench;100:hire:Doctor;150:room:pharmacy:4:4`.

## Results (busy hospital, Linux, loopback, 2026-10-17)

| Test | Result |
|---|---|
| Client places a bench, a plant, hires a doctor, builds a pharmacy, adds a drinks machine; host issues nothing | Host applied all 5 at the same hours; IN SYNC |
| The same 5 commands applied locally in a solo run | Host fingerprints identical to the solo run for every hour |
| Both peers place a bench on the same tile in the same hour | Host's (player 1) applied, client's rejected "tile not free" on both peers; IN SYNC |
| Both peers hire in the same hour | Both applied, same order on both peers; IN SYNC |
| Client applies its command but never sends it | DESYNC reported at hour 32, the hour it was applied |

`run_sync_probe.sh` now runs seven checks (four from before plus these
three) in about 40 seconds and exits 0 only if all behave as expected.

## Next steps

1. Turn real UI actions into commands: intercept the point where the game
   commits an action (placing an object, confirming a room, hiring) and
   send a command instead of applying it immediately.
2. Shared rules for speed and pause, and for windows that pause the game.
3. Pay-rise requests, fax choices and similar decisions as commands.
4. A small host/join screen, then the first co-build test on Windows.
