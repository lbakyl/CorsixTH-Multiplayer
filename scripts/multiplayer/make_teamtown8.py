"""Make CorsixTH/Levels/teamtown8.map, TEAM TOWN for up to 8 hospitals, from
Matroftt's map for 4 (CorsixTH/Levels/level40teams.map).

Usage: python scripts/multiplayer/make_teamtown8.py [--check]

The town stays as it is. Four of its plots for sale become the starting
plots of players 5 to 8: two north of the middle (plots 5 and 6) and two
south of it (17 and 18, which swap numbers with 7 and 8: a map's starting
plots are plots 1 to <players>). Each new hospital's camera looks at its
plot; its helicopter lands on the nearest of the four heliports. The tiles
of players 5 to 8 go in bytes the original map format leaves empty
(th_map.cpp, load_from_th_file). With fewer than 8 players the plots of the
missing ones are for sale (Map:load). --check only compares the result with
the file in the repository.
"""
import os
import struct
import sys

W = H = 128
SIZE = 163948
PARCELS = 131106            # a 2-byte plot number per tile
CAMERAS, HELIPORTS = 163876, 163884              # players 1 to 4
EXTRA_CAMERAS, EXTRA_HELIPORTS = 163892, 163900  # players 5 to 8
# The new starting plots (the source map's numbers), for players 5 to 8.
NEW_STARTS = (5, 6, 17, 18)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
SOURCE = os.path.join(ROOT, "CorsixTH", "Levels", "level40teams.map")
TARGET = os.path.join(ROOT, "CorsixTH", "Levels", "teamtown8.map")


def tile(data, offset):
    index = struct.unpack_from("<H", data, offset)[0]
    return index % W, index // W


def make(source):
    data = bytearray(source)
    assert len(data) == SIZE and data[0] == 4, "not a map for 4 players"
    plots = list(struct.unpack_from("<%dH" % (W * H), data, PARCELS))
    # Plots 5 to 8 start: 5 and 6 already have those numbers; 17 and 18 swap
    # with 7 and 8.
    swap = {17: 7, 7: 17, 18: 8, 8: 18}
    plots = [swap.get(p, p) for p in plots]
    struct.pack_into("<%dH" % (W * H), data, PARCELS, *plots)
    heliports = [tile(data, HELIPORTS + 2 * i) for i in range(4)]
    for n, plot in enumerate(range(5, 9)):
        cells = [(i % W, i // W) for i, p in enumerate(plots) if p == plot]
        cx = sum(x for x, _ in cells) / len(cells)
        cy = sum(y for _, y in cells) / len(cells)
        # The plot's own tile nearest its middle.
        x, y = min(cells, key=lambda c: ((c[0] - cx) ** 2 + (c[1] - cy) ** 2, c[1], c[0]))
        struct.pack_into("<H", data, EXTRA_CAMERAS + 2 * n, y * W + x)
        hx, hy = min(heliports, key=lambda h: (h[0] - cx) ** 2 + (h[1] - cy) ** 2)
        struct.pack_into("<H", data, EXTRA_HELIPORTS + 2 * n, hy * W + hx)
        print("player %d: plot %d (was %d), %d tiles, camera %d,%d, heliport %d,%d" % (
            plot, plot, NEW_STARTS[n], len(cells), x, y, hx, hy))
    data[0] = 8
    return bytes(data)


def main():
    result = make(open(SOURCE, "rb").read())
    if "--check" in sys.argv:
        same = os.path.exists(TARGET) and open(TARGET, "rb").read() == result
        print("teamtown8.map is " + ("up to date" if same else "OUT OF DATE"))
        sys.exit(0 if same else 1)
    open(TARGET, "wb").write(result)
    print("wrote " + os.path.normpath(TARGET))


main()
