"""Scale a 128x128 Theme Hospital map (CorsixTH multiplayer layout, 8 players)
to NxN by repeating rows and columns that can repeat without breaking
anything (no borders across them, no doors, no diagonal pieces), spread so
that every old row lands near 1.5x its place. Window pairs are repaired
afterwards, grass re-alternated. Then a helipad by each hospital.

Levels/crossroads8.map (192 x 192) was made from the 128 x 128 one of
commit c1417fe6 (Matroftt's 128-8p-v2.map with heliports on the paths):
  python3 scale_map.py crossroads8_128.map crossroads8.map 192
The plots come out fair: the repeated lines are searched for so that every
hospital's floor, and every plot in the middle, is the same size (within 1%).

usage: scale_map.py in.map out.map [size]
"""
import struct, sys, collections

src, dst = sys.argv[1], sys.argv[2]
N = int(sys.argv[3]) if len(sys.argv) > 3 else 192
d = open(src, 'rb').read()
W = 128
assert len(d) == 163948, len(d)
HEAD = d[:34]
tiles = [[bytearray(d[34 + (y * W + x) * 8:34 + (y * W + x) * 8 + 8]) for x in range(W)] for y in range(W)]
P = 34 + W * W * 8
parcels = [[struct.unpack_from('<H', d, P + 2 * (y * W + x))[0] for x in range(W)] for y in range(W)]
CAM = P + W * W * 2 + 2
between = d[P + W * W * 2:CAM]
tail = d[CAM:CAM + 72]

def idx(o):
    v = struct.unpack_from('<H', tail, o)[0]
    return v % W, v // W
# cameras 1-4 at 0, heliports 1-4 at 8, cameras 5-8 at 16, heliports 5-8 at 24
cams = [idx(2 * i) for i in range(4)] + [idx(16 + 2 * i) for i in range(4)]

GRASS = {1, 2}
# Floor pieces that are a horizontal border (cannot repeat a row) / vertical.
CORNERS = {5, 7, 9, 11, 13, 60, 61, 62, 187}
H_EDGE = {6, 10} | CORNERS
V_EDGE = {8, 12} | CORNERS
DOOR_OBJ = {58, 59}
N_DOOR = set(range(212, 220, 2))   # door frames, north layer
W_DOOR = set(range(213, 220, 2))   # west layer
# Window halves: north (left, right) and west (top, bottom), two wall sets.
N_WIN = [(122, 124, 120), (114, 116, 112)]
W_WIN = [(123, 125, 121), (115, 117, 113)]

def row_safe(y):
    for x in range(W):
        t = tiles[y][x]
        if t[2] in H_EDGE or t[1] in DOOR_OBJ or t[4] in W_DOOR:
            return False
        # (A door below: its frame piece sits in the row after it.)
        if y + 1 < W and tiles[y + 1][x][4] in W_DOOR:
            return False
    return True

def col_safe(x):
    for y in range(W):
        t = tiles[y][x]
        if t[2] in V_EDGE or t[1] in DOOR_OBJ or t[3] in N_DOOR:
            return False
        if x + 1 < W and tiles[y][x + 1][3] in N_DOOR:
            return False
    return True

def plan(safe):
    """How many times each old line appears (sum N), near 1.5x spacing."""
    count, total = [1] * W, W
    extra = N - W
    for r in range(W):
        want = round((r + 1) * N / W)
        have = sum(count[:r + 1])
        if safe[r] and want > have:
            count[r] += want - have
    short = N - sum(count)
    r = W - 1
    while short > 0:   # (unsafe lines at the end: the last safe ones)
        if safe[r]:
            count[r] += 1
            short -= 1
        r = (r - 1) % W
    assert sum(count) == N, sum(count)
    return count

rs = [row_safe(y) for y in range(W)]
cs = [col_safe(x) for x in range(W)]
rows, cols = plan(rs), plan(cs)

# Fair plots: the repeated lines are chosen so that every hospital's plot
# (1-8) has the same floor, and the shared plots (9-12) too, staying near
# the 1.5x places (a local search over which safe lines repeat).
import random
random.seed(7)
cells = collections.defaultdict(list)
for y in range(W):
    for x in range(W):
        t = tiles[y][x]
        if parcels[y][x] and not (t[5] & 1) and not (t[7] & 16):
            cells[parcels[y][x]].append((y, x))

def spread(rc, cc, group):
    a = [sum(rc[y] * cc[x] for y, x in cells[p]) for p in group]
    return max(a) - min(a), a

def disp(count):
    pos, worst = 0, 0
    for r in range(W):
        worst = max(worst, abs(pos - r * N / W))
        pos += count[r]
    return worst

def score(rc, cc):
    return (spread(rc, cc, range(1, 9))[0] * 10 + spread(rc, cc, range(9, 13))[0] * 10 +
            max(disp(rc), disp(cc)))

best = score(rows, cols)
for it in range(6000):
    which = rows if random.random() < 0.5 else cols
    safe = rs if which is rows else cs
    dup = [r for r in range(W) if which[r] > 1]
    one = [r for r in range(W) if which[r] == 1 and safe[r]]
    a, b = random.choice(dup), random.choice(one)
    which[a] -= 1; which[b] += 1
    s = score(rows, cols)
    if s <= best:
        best = s
    else:
        which[a] += 1; which[b] -= 1
print('fairness score', best, 'hospitals', spread(rows, cols, range(1, 9))[1],
      'shared', spread(rows, cols, range(9, 13))[1], 'shift', disp(rows), disp(cols))
print('safe rows', sum(rs), 'safe cols', sum(cs))
ymap, xmap = [], []   # old -> first new
ny_of, nx_of = [], []  # new -> (old, is a copy)
for r, c in enumerate(rows):
    ymap.append(len(ny_of))
    ny_of += [(r, k > 0) for k in range(c)]
for r, c in enumerate(cols):
    xmap.append(len(nx_of))
    nx_of += [(r, k > 0) for k in range(c)]
# Worst displacement from the 1.5x place.
print('max row shift', max(abs(ymap[r] - r * N / W) for r in range(W)),
      'max col shift', max(abs(xmap[r] - r * N / W) for r in range(W)))

new = [[None] * N for _ in range(N)]
npar = [[0] * N for _ in range(N)]
for ny in range(N):
    oy, ycopy = ny_of[ny]
    for nx in range(N):
        ox, xcopy = nx_of[nx]
        t = bytearray(tiles[oy][ox])
        # A repeated row has no north wall (it is inside); a repeated column
        # no west wall.
        if ycopy:
            t[3] = 0
        if xcopy:
            t[4] = 0
        new[ny][nx] = t
        npar[ny][nx] = parcels[oy][ox]

# Repair window pairs along wall runs.
def fix_run(get, put, length, sets):
    for first, second, plain in sets:
        i = 0
        while i < length:
            p = get(i)
            if p == first:
                if i + 1 < length and get(i + 1) in (first, second):
                    put(i + 1, second)
                    i += 2
                    continue
                put(i, plain)
            elif p == second:
                put(i, plain)
            i += 1

for ny in range(N):
    fix_run(lambda i: new[ny][i][3], lambda i, v: new[ny][i].__setitem__(3, v), N, N_WIN)
for nx in range(N):
    fix_run(lambda i: new[i][nx][4], lambda i, v: new[i][nx].__setitem__(4, v), N, W_WIN)
# Grass alternates by column.
for ny in range(N):
    for nx in range(N):
        if new[ny][nx][2] in GRASS:
            new[ny][nx][2] = 1 + nx % 2

ncams = [(xmap[x], ymap[y]) for x, y in cams]

# Helipads: a 7x7 pad with an H on impassable grass, its opening onto the
# road it touches (finisham.map's pad).
PAD = [
    [5, 6, 6, 6, 6, 6, 7],
    [12, 4, 4, 4, 4, 4, 8],
    [12, 4, 3, 4, 3, 4, 8],
    [12, 4, 3, 3, 3, 4, 8],
    [12, 4, 3, 4, 3, 4, 8],
    [12, 4, 4, 4, 4, 4, 8],
    [11, 10, 10, 10, 10, 10, 9],
]
WALK = (62, 0, 16)  # passable, outside the hospital (road tiles)
used = set()

def free(x0, y0, below):
    # (The pad and a grass tile round it, but the road's border on its open side.)
    for y in (range(y0 - 1, y0 + 7) if below else range(y0, y0 + 8)):
        for x in range(x0 - 1, x0 + 8):
            if not (0 <= x < N and 0 <= y < N) or (x, y) in used:
                return False
            t = new[y][x]
            if npar[y][x] != 0 or not (t[5] & 1) or t[3] or t[4] or t[1]:
                return False
            if t[2] not in (1, 2, 183, 190):
                return False
    return True

def road_below(x0, y0):
    """The pad's bottom middle tile sits on a road's top border: border
    row y0+7 (piece 6), road y0+8 (4)."""
    c = x0 + 3
    return (y0 + 8 < N and new[y0 + 7][c][2] == 6 and new[y0 + 8][c][2] == 4 and
            new[y0 + 7][c - 1][2] == 6 and new[y0 + 7][c + 1][2] == 6)

def road_above(x0, y0):
    c = x0 + 3
    return (y0 - 2 >= 0 and new[y0 - 1][c][2] == 10 and new[y0 - 2][c][2] == 4 and
            new[y0 - 1][c - 1][2] == 10 and new[y0 - 1][c + 1][2] == 10)

def place(x0, y0, below):
    for j, row in enumerate(PAD):
        for i, f in enumerate(row):
            t = new[y0 + j][x0 + i]
            t[2] = f
            t[5], t[6], t[7] = WALK
            used.add((x0 + i, y0 + j))
    c = x0 + 3
    if below:   # opening at the bottom, into the road's top border
        new[y0 + 6][c - 1][2], new[y0 + 6][c][2], new[y0 + 6][c + 1][2] = 61, 4, 60
        b = new[y0 + 7]
        b[c - 1][2], b[c][2], b[c + 1][2] = 13, 4, 62
        b[c][5], b[c][6], b[c][7] = WALK
    else:       # opening at the top, into the road's bottom border
        new[y0][c - 1][2], new[y0][c][2], new[y0][c + 1][2] = 13, 4, 62
        b = new[y0 - 1]
        b[c - 1][2], b[c][2], b[c + 1][2] = 61, 4, 60
        b[c][5], b[c][6], b[c][7] = WALK
    for y in range(y0 - 1, y0 + 8):
        for x in range(x0 - 1, x0 + 8):
            used.add((x, y))

helis = []
for i, (cx, cy) in enumerate(ncams):
    best = None
    for y0 in range(1, N - 8):
        for x0 in range(1, N - 8):
            below, above = road_below(x0, y0), road_above(x0, y0)
            if not (below or above) or not free(x0, y0, below):
                continue
            mx, my = x0 + 3, y0 + 3
            dist = abs(mx - cx) + abs(my - cy)
            # (Its own hospital the nearest.)
            others = min(abs(mx - ox) + abs(my - oy) for j, (ox, oy) in enumerate(ncams) if j != i)
            if dist >= others:
                continue
            if best is None or dist < best[0]:
                best = (dist, x0, y0, below)
    if not best:
        print('NO PAD for player', i + 1); helis.append(ncams[i]); continue
    _, x0, y0, below = best
    place(x0, y0, below)
    helis.append((x0 + 3, y0 + 3))
    print('player', i + 1, 'camera', ncams[i], 'helipad', helis[-1], 'road', 'below' if below else 'above')

def tidx(x, y):
    return struct.pack('<H', y * N + x)

out = bytearray(b'CTHMAP1\0' + struct.pack('<HH', N, N) + b'\0' * 4)
out += HEAD
for ny in range(N):
    for nx in range(N):
        out += new[ny][nx]
for ny in range(N):
    for nx in range(N):
        out += struct.pack('<H', npar[ny][nx])
out += between
t = bytearray(tail)
for i in range(8):
    co = 2 * i if i < 4 else 16 + 2 * (i - 4)
    ho = 8 + 2 * i if i < 4 else 24 + 2 * (i - 4)
    t[co:co + 2] = tidx(*ncams[i])
    t[ho:ho + 2] = tidx(*helis[i])
out += t
open(dst, 'wb').write(out)
sizes = collections.Counter(p for row in npar for p in row)
print('plots', sorted(sizes.items()))
print('wrote', dst, len(out))
