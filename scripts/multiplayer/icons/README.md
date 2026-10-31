# Multiplayer icons

Pixel art by MATROFTT (2026-10-31). The game cannot load PNG files, so
`../make_mp_icons.py` turns these into `CorsixTH/Lua/mp_icons.lua`, which
`MultiplayerSession.drawIcon` draws. After changing an icon, run
`python3 scripts/multiplayer/make_mp_icons.py` (needs Pillow) and commit both.

| File | Where |
|---|---|
| `fax_transferstuff` | message icon: an offer of staff or a patient |
| `fax_shareresearch` | message icon: an offer of research |
| `fax_money` | message icon: a request for money |
| `fax_speed` | message icon: a vote on the game speed |
| `transferstuff` | send button in the staff list, Refer button in the patient window |

Message icons are 30 x 28 with the stand, the send button 24 x 24.
`_pressed` is the look while the offer's window is open or the button is
held. The staff window's send button (33 x 21, over the wage) is still drawn
in code (`UIMultiplayerTrade.drawSendIcon`).
