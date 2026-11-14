"""Make MOUNT EVEREST's map (Levels/everest6.map, 256 x 256, 6 players)
from Jan's town square (his 256.map of 2026-11-14: a plaza with a fountain
and four small houses in the middle of a 256 x 256 map).

The town is symmetric about the middle (tile 127) both ways: three
hospitals north of the square and three south of it, the southern ones
mirrored, so every hospital is the same building with its main entrance
facing the square. Each has the same plot, the same doors and paths, its own
helipad on the edge road behind it. The square's four houses are plots for
sale. Everything else of the input map (roads, the unfinished buildings
south-east of the square) is replaced.

Player order: 1 north-west, 2 south-east, 3 north-east, 4 south-west,
5 north, 6 south (with 2 players the two far corners, with 4 the corners).

usage: make_everest6.py jan256.map out.map
"""
import random
import struct
import sys

N = 256
MID = 127                      # the axis of symmetry: x -> 254 - x
def MX(x): return 2 * MID - x
def MY(y): return 2 * MID - y

# --- tiles ------------------------------------------------------------------
CENTRE, H_MARK = 4, 3          # walkable pavement; the helipad's H
HOSP_FLOOR = 18                # red-blue floor tile
EDGES = {5, 6, 7, 8, 9, 10, 11, 12, 13, 60, 61, 62}
PIECES = {                     # corners paved (tl, tr, bl, br) -> piece
    (1, 1, 1, 1): CENTRE,
    (1, 1, 0, 0): 10, (0, 0, 1, 1): 6, (0, 1, 0, 1): 12, (1, 0, 1, 0): 8,
    (0, 0, 0, 1): 5, (0, 0, 1, 0): 7, (0, 1, 0, 0): 11, (1, 0, 0, 0): 9,
    (1, 1, 0, 1): 61, (1, 1, 1, 0): 60, (0, 1, 1, 1): 13, (1, 0, 1, 1): 62,
}
WALK = (62, 0, 16)             # flags: passable, outside (roads, paths)
BORDER = (63, 0, 16)           # not passable, outside (grass, edges)
# Walls: on the tile south of (north wall) or east of (west wall) the edge;
# which piece depends on whether that tile is inside.
N_IN, N_OUT, W_IN, W_OUT = 120, 112, 121, 113
# Entrance doors (3 tiles: left part with the left door, the right door, the
# right part), as Jan's houses have them: on a north wall / a west wall, the
# tile inside or outside.
DOOR = {('h', True): (218, 216), ('h', False): (214, 212),
        ('v', True): (219, 217), ('v', False): (215, 213)}
# Foliage (file values): shrubs and trees for gardens and the countryside.
TREES = [182, 186, 187, 189, 184]   # European shrub, shrub, dead tree, shrub 2, bush
FLOWERS = [185, 190, 183]           # red flowers, flowers, green plant


def main(src, dst):
    data = open(src, 'rb').read()
    assert data[:7] == b'CTHMAP1' and struct.unpack_from('<H', data, 8)[0] == N
    T = 16 + 34
    P = T + N * N * 8
    old = [[bytearray(data[T + (y * N + x) * 8:T + (y * N + x) * 8 + 8]) for x in range(N)]
           for y in range(N)]
    tiles = [[bytearray((0, 0, 1 + x % 2, 0, 0) + BORDER) for x in range(N)] for y in range(N)]
    parcel = [[0] * N for _ in range(N)]

    # --- the town square: Jan's, as it is -----------------------------------
    SQ = (104, 104, 150, 150)
    for y in range(SQ[1], SQ[3] + 1):
        for x in range(SQ[0], SQ[2] + 1):
            tiles[y][x] = bytearray(old[y][x])

    def in_square(x, y):
        return SQ[0] <= x <= SQ[2] and SQ[1] <= y <= SQ[3]

    building = set()   # tiles whose walls/doors/floor are set (no paving)

    def pave(x, y, piece=CENTRE):
        t = tiles[y][x]
        t[1] = 0
        t[2] = piece
        t[5:8] = bytes(WALK)

    def pave_rect(x0, y0, x1, y1):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if not in_square(x, y):
                    pave(x, y)

    # --- the layout -----------------------------------------------------------
    W, H = 59, 65                       # a hospital building (local 0..58, 0..64)
    XS = [28, MID - 29, MX(28 + W - 1)]  # left, middle (98), right (168)
    Y0 = 26                             # northern buildings: rows 26..90
    ROAD_COLS = [21, 91, MX(93), MX(23)]   # 3 wide: x .. x+2
    ROAD_ROWS = [19, 95, 126, MY(97), MY(21)]
    for x in ROAD_COLS:
        pave_rect(x, 0, x + 2, N - 1)
    for y in ROAD_ROWS:
        pave_rect(0, y, N - 1, y + 2)
    # The square's own street north to south (between the two band roads).
    pave_rect(126, 95, 128, MY(95))

    # --- the buildings (local tiles, the northern orientation: the square to
    # the south) ----------------------------------------------------------------
    # A district is a start hospital with five smaller buildings round it,
    # each a plot for sale of its own (as on Matroftt's maps: land to fight
    # over at auctions, a rival's too). A building: rectangles of floor,
    # minus courtyards (grass, walled in), and doors: ('h', b, first, dy):
    # 3 tiles in the wall between rows b - 1 and b from column `first`,
    # leading out north (dy -1) or south (dy 1); ('v', b, first, dx) between
    # columns b - 1 and b from row `first`. From each door a path leads
    # straight out to the nearest pavement.
    def building_def(rects, holes=(), doors=()):
        cells = set()
        for x0, y0, x1, y1 in rects:
            cells |= {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)}
        for x0, y0, x1, y1 in holes:
            cells -= {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)}
        return {'cells': cells, 'holes': list(holes), 'doors': list(doors)}

    start_hospital = building_def(
        [(12, 30, 46, 64)], holes=[(12, 30, 17, 37), (41, 30, 46, 37), (26, 42, 32, 48)],
        doors=[('h', 65, 28, 1),       # main entrance, to the square
               ('v', 12, 52, -1),      # west, onto the lane
               ('v', 47, 52, 1)])      # east, onto the lane
    annexes = [
        building_def([(0, 38, 8, 64)], doors=[('v', 9, 49, 1)]),             # front west
        building_def([(50, 38, 58, 64)], doors=[('v', 50, 49, -1)]),         # front east
        building_def([(0, 0, 24, 11), (0, 12, 10, 24)], doors=[('v', 0, 4, -1)]),    # back west
        building_def([(34, 0, 58, 11), (48, 12, 58, 24)], doors=[('v', 59, 4, 1)]),  # back east
        building_def([(14, 15, 44, 26)], holes=[(27, 18, 31, 23)],
                     doors=[('h', 15, 28, -1)]),                              # back middle
    ]
    # Lanes between the start hospital and the front annexes, from the
    # district's back to the road in front.
    lanes = [(9, 30, 11, 68), (47, 30, 49, 68)]
    camera_local = (29, 58)
    # The middle band, west of the square, north of its street: one big
    # building for sale (and its three mirror images).
    middle = building_def([(30, 101, 82, 121)], holes=[(52, 107, 60, 115)],
                          doors=[('h', 122, 55, 1), ('h', 101, 55, -1), ('v', 30, 110, -1),
                                 ('v', 83, 110, 1)])

    # The six districts: (player, left x, mirrored north-south?)
    sites = [(1, XS[0], False), (2, XS[2], True), (3, XS[2], False),
             (4, XS[0], True), (5, XS[1], False), (6, XS[1], True)]

    def to_global(x0, south):
        def f(lx, ly):
            return x0 + lx, (MY(Y0 + ly) if south else Y0 + ly)
        return f

    def place(defn, g, plot):
        """Build `defn` through the tile transform g on plot `plot`."""
        inside = {g(x, y) for x, y in defn['cells']}
        xs = [x for x, _ in inside]
        ys = [y for _, y in inside]
        for x, y in inside:
            tiles[y][x][0:8] = bytes((0, 0, HOSP_FLOOR, 0, 0, 0, 0, 0))
            parcel[y][x] = plot
            building.add((x, y))
        for hx0, hy0, hx1, hy1 in defn['holes']:
            for lx in range(hx0, hx1 + 1):
                for ly in range(hy0, hy1 + 1):
                    x, y = g(lx, ly)
                    if (x, y) not in inside and min(xs) <= x <= max(xs) and min(ys) <= y <= max(ys):
                        parcel[y][x] = plot   # (a courtyard belongs to its building)
        for y in range(min(ys), max(ys) + 2):
            for x in range(min(xs), max(xs) + 2):
                t = tiles[y][x]
                here = (x, y) in inside
                if here != ((x, y - 1) in inside):
                    t[3] = N_IN if here else N_OUT
                if here != ((x - 1, y) in inside):
                    t[4] = W_IN if here else W_OUT
        for kind, b, first, sign in defn['doors']:
            lin, lout = (b - 1, b) if sign > 0 else (b, b - 1)
            if kind == 'h':
                a_in, a_out = g(first, lin), g(first, lout)
                row = max(a_in[1], a_out[1])        # the tile with the wall
                cells = [(c, row) for c in sorted(g(first + i, b)[0] for i in range(3))]
            else:
                a_in, a_out = g(lin, first), g(lout, first)
                col = max(a_in[0], a_out[0])
                cells = [(col, r) for r in sorted(g(b, first + i)[1] for i in range(3))]
            out = (a_out[0] - a_in[0], a_out[1] - a_in[1])
            inner = cells[0] in inside
            first_piece, last_piece = DOOR[(kind, inner)]
            for i, (x, y) in enumerate(cells):
                t = tiles[y][x]
                t[0] = (1 if kind == 'v' else 0) if i < 2 else 0
                t[1] = (58, 59, 0)[i]
                wall = (first_piece, 0, last_piece)[i]
                if kind == 'h':
                    t[3] = wall
                else:
                    t[4] = wall
                if inner:
                    t[2] = HOSP_FLOOR
                    t[5:8] = bytes((2, 0, 0))
                else:
                    t[2] = CENTRE
                    t[5:8] = bytes(WALK)
                    tiles[y - out[1]][x - out[0]][5] = 2   # (inside, across the door)
                parcel[y][x] = plot
                building.add((x, y))
            for x, y in cells:
                x, y = x + out[0], y + out[1]
                while 0 <= x < N and 0 <= y < N and not road_centre(tiles, x, y):
                    if (x, y) in building:
                        sys.exit('a path from a door of plot %d runs into a building at %d,%d'
                                 % (plot, x, y))
                    pave(x, y)
                    parcel[y][x] = 0
                    x, y = x + out[0], y + out[1]

    # Plots: 1-6 the start hospitals, 7-10 the square's houses, 11-14 the
    # middle band, then the districts' buildings for sale.
    for player, x0, south in sites:
        g = to_global(x0, south)
        for lx0, ly0, lx1, ly1 in lanes:
            for lx in range(lx0, lx1 + 1):
                for ly in range(ly0, ly1 + 1):
                    pave(*g(lx, ly))
    middle_sites = [lambda x, y: (x, y), lambda x, y: (MX(x), y),
                    lambda x, y: (x, MY(y)), lambda x, y: (MX(x), MY(y))]
    for i, g in enumerate(middle_sites):
        place(middle, g, 11 + i)
    next_plot = 15
    cameras, helipads = {}, {}
    for player, x0, south in sites:
        g = to_global(x0, south)
        place(start_hospital, g, player)
        for annex in annexes:
            place(annex, g, next_plot)
            next_plot += 1
        cameras[player] = g(*camera_local)
        # The helipad: on the grass beyond the edge road behind the district.
        helipads[player] = (x0 + 29, MY(14) if south else 14)

    # Helipads: a 5 x 5 pad (an H on it) with its border, open to the road.
    for player, (cx, cy) in helipads.items():
        for y in range(cy - 2, cy + 3):
            for x in range(cx - 2, cx + 3):
                hx, hy = abs(x - cx), abs(y - cy)
                pave(x, y, H_MARK if (hx == 1 and hy <= 1) or (hx == 0 and hy == 0) else CENTRE)
        # (one tile wide, to the road)
        step = 1 if cy < MID else -1
        y = cy + 3 * step
        while not road_centre(tiles, cx, y):
            pave(cx, y)
            y += step

    # --- foliage: shrubs in the gardens, trees in the countryside ------------
    rnd = random.Random(1953)   # (the first ascent)
    plain = lambda x, y: (0 <= x < N and 0 <= y < N and tiles[y][x][2] in (1, 2) and
                          not tiles[y][x][3] and not tiles[y][x][4] and (x, y) not in building
                          and not in_square(x, y))

    def quiet(x, y):  # grass all round (no pavement edge, wall or door next to it)
        return all(plain(x + i, y + j) for i in (-1, 0, 1) for j in (-1, 0, 1))

    def plant(x, y, piece):
        # In all four mirror places, so the town stays symmetric.
        for qx, qy in {(x, y), (MX(x), y), (x, MY(y)), (MX(x), MY(y))}:
            if quiet(qx, qy):
                tiles[qy][qx][2] = piece
    # Courtyards: the same shrubs and flowers in every one (a pattern
    # symmetric both ways, so the town stays symmetric).
    pattern = [(0, 0, 182), (-1, -1, 189), (1, 1, 189), (-1, 1, 190), (1, -1, 190)]
    yards = [(to_global(x0, south), start_hospital['holes'][2]) for _, x0, south in sites]
    yards += [(to_global(x0, south), annexes[4]['holes'][0]) for _, x0, south in sites]
    yards += [(g, middle['holes'][0]) for g in middle_sites]
    for g, (hx0, hy0, hx1, hy1) in yards:
        mx, my = (hx0 + hx1) // 2, (hy0 + hy1) // 2
        for i, j, piece in pattern:
            x, y = g(mx + i, my + j)
            tiles[y][x][2] = piece
    # Countryside: the north-west quarter, mirrored.
    for _ in range(900):
        x, y = rnd.randrange(0, MID), rnd.randrange(0, MID)
        if parcel[y][x] == 0:
            plant(x, y, rnd.choice(TREES + TREES + FLOWERS))

    # --- pavement edges ---------------------------------------------------------
    def paved(x, y):
        if not (0 <= x < N and 0 <= y < N):
            return False
        t = tiles[y][x]
        return t[2] in (CENTRE, H_MARK) and not (t[5] & 1) and t[7] & 16

    for y in range(N):
        for x in range(N):
            if (x, y) in building or (in_square(x, y) and not on_rim(SQ, x, y)):
                continue
            t = tiles[y][x]
            if paved(x, y):
                continue
            if t[2] not in (1, 2) and t[2] not in EDGES:
                continue   # (foliage, the square's flower beds)
            corners = tuple(int(any(paved(cx - dx, cy - dy) for dx in (0, 1) for dy in (0, 1)))
                            for cx, cy in ((x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)))
            if corners == (0, 0, 0, 0):
                if t[2] in EDGES:
                    t[2] = 1 + x % 2
                continue
            if corners not in PIECES:
                sys.exit('no pavement piece for tile %d,%d: %s' % (x, y, corners))
            t[2] = PIECES[corners]
            t[5:8] = bytes(WALK if t[2] == CENTRE else BORDER)

    # --- the square's houses: plots for sale ---------------------------------
    houses = [(105, 105, 122, 122), (132, 105, 149, 122), (105, 132, 122, 149), (132, 132, 149, 149)]
    for i, (x0, y0, x1, y1) in enumerate(houses):
        for y in range(y0 - 1, y1 + 2):
            for x in range(x0 - 1, x1 + 2):
                t = tiles[y][x]
                floor = x0 <= x <= x1 and y0 <= y <= y1 and t[2] == HOSP_FLOOR and not (t[7] & 16)
                door = t[1] in (58, 59) or t[3] in (212, 214) or t[4] in (213, 215)
                if floor or door:
                    parcel[y][x] = 7 + i

    # --- write ------------------------------------------------------------------
    out = bytearray(b'CTHMAP1\0' + struct.pack('<HH', N, N) + b'\0' * 4)
    head = bytearray(34)
    head[0] = 6
    out += head
    for y in range(N):
        for x in range(N):
            out += tiles[y][x]
    for y in range(N):
        for x in range(N):
            out += struct.pack('<H', parcel[y][x])
    out += b'\0\0'
    tail = bytearray(72)

    def idx(x, y):
        return struct.pack('<H', y * N + x)
    for p in range(1, 7):
        i = p - 1
        co = 2 * i if i < 4 else 16 + 2 * (i - 4)
        ho = 8 + 2 * i if i < 4 else 24 + 2 * (i - 4)
        tail[co:co + 2] = idx(*cameras[p])
        tail[ho:ho + 2] = idx(*helipads[p])
    out += tail
    open(dst, 'wb').write(out)
    counts = {}
    for y in range(N):
        for x in range(N):
            p = parcel[y][x]
            if p and tiles[y][x][2] == HOSP_FLOOR and not (tiles[y][x][7] & 16):
                counts[p] = counts.get(p, 0) + 1
    print('floor tiles per plot', sorted(counts.items()))
    print('cameras', cameras)
    print('helipads', helipads)
    print('wrote', dst, len(out))


def road_centre(tiles, x, y):
    t = tiles[y][x]
    return t[2] == CENTRE and not (t[5] & 1) and t[7] & 16


def on_rim(sq, x, y):
    return x in (sq[0], sq[2]) or y in (sq[1], sq[3])


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
