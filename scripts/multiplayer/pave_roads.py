"""Pave roads onto a Theme Hospital map (128 x 128, or a CTHMAP1 map of
another size): each rectangle is the walkable middle of a road (tile
coordinates from 0, both ends included, e.g. three tiles wide). The tiles
around everything paved get their pavement edges again.

A tile's floor piece follows which of its four corners touch walkable
pavement (a road's middle, piece 4, or a helipad's H, piece 3): all four
the middle of a road, two the side of one, one an outer corner, three an
inner corner where roads meet. So a new road crossing an old one, or
ending on its side, joins it the way the original maps' roads join.

Only town tiles (plot 0) are paved; a rectangle that would touch a plot,
a wall, a door or an object other than a tree is refused.

Levels/crossroads8.map got its ring road round the four plots in the
middle (so every hospital's roads stay joined when a hospital between them
has nobody) with:
  python3 pave_roads.py crossroads8.map crossroads8.map \\
      38,61,151,63 38,127,151,129 61,61,63,129 127,61,129,129

usage: pave_roads.py in.map out.map x0,y0,x1,y1 [...]
"""
import struct
import sys

CENTRE, H_MARK = 4, 3
GRASS = (1, 2)
# Pieces that may be repaved: grass, the flowers by the middle roads, and
# every road piece.
EDGES = {5, 6, 7, 8, 9, 10, 11, 12, 13, 60, 61, 62}
PAVABLE = {1, 2, 183, 190, CENTRE} | EDGES
DOOR_OBJ = {58, 59}
WALK = (62, 0, 16)    # flags of a road's middle: passable, outside
BORDER = (63, 0, 16)  # of grass and pavement edges: not passable
# Corners paved (top left, top right, bottom left, bottom right) -> piece.
PIECES = {
    (1, 1, 1, 1): CENTRE,
    (1, 1, 0, 0): 10, (0, 0, 1, 1): 6, (0, 1, 0, 1): 12, (1, 0, 1, 0): 8,
    (0, 0, 0, 1): 5, (0, 0, 1, 0): 7, (0, 1, 0, 0): 11, (1, 0, 0, 0): 9,
    (1, 1, 0, 1): 61, (1, 1, 1, 0): 60, (0, 1, 1, 1): 13, (1, 0, 1, 1): 62,
}


def main(argv):
    src, dst, rects = argv[1], argv[2], argv[3:]
    data = bytearray(open(src, 'rb').read())
    if data[:7] == b'CTHMAP1':
        n = struct.unpack_from('<H', data, 8)[0]
        base = 16 + 34
    else:
        n, base = 128, 34
    parcels = base + n * n * 8

    def tile(x, y):
        o = base + (y * n + x) * 8
        return data[o:o + 8], o

    def parcel(x, y):
        return struct.unpack_from('<H', data, parcels + 2 * (y * n + x))[0]

    def paved(x, y):
        if not (0 <= x < n and 0 <= y < n) or parcel(x, y):
            return False
        t, _ = tile(x, y)
        return t[2] in (CENTRE, H_MARK) and not (t[5] & 1)

    touched = set()
    for spec in rects:
        x0, y0, x1, y1 = (int(v) for v in spec.split(','))
        for y in range(y0 - 1, y1 + 2):
            for x in range(x0 - 1, x1 + 2):
                t, o = tile(x, y)
                if parcel(x, y) or t[3] or t[4] or t[1] in DOOR_OBJ or t[2] not in PAVABLE:
                    sys.exit('refused: tile %d,%d (plot %d, piece %d, walls %d/%d, object %d)'
                             % (x, y, parcel(x, y), t[2], t[3], t[4], t[1]))
                touched.add((x, y))
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                _, o = tile(x, y)
                data[o + 1] = 0
                data[o + 2] = CENTRE
                data[o + 5:o + 8] = bytes(WALK)

    # The edges: every touched tile and the ring round it, by its corners.
    ring = {(x + dx, y + dy) for x, y in touched for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
    changed = 0
    for x, y in sorted(ring):
        if not (0 <= x < n and 0 <= y < n) or parcel(x, y):
            continue
        t, o = tile(x, y)
        if t[2] == H_MARK or (t[2] == CENTRE and not (t[5] & 1)):
            continue  # (pavement itself)
        corners = []
        for cx, cy in ((x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)):
            # A corner is paved if a paved tile has it.
            corners.append(int(any(paved(cx - dx, cy - dy) for dx in (0, 1) for dy in (0, 1))))
        key = tuple(corners)
        if key == (0, 0, 0, 0):
            if t[2] in EDGES:  # (an old edge with no pavement left)
                data[o + 2] = GRASS[x % 2]
                changed += 1
            continue
        if key not in PIECES:
            sys.exit('no piece for tile %d,%d: corners %s (roads too close)' % (x, y, key))
        if t[3] or t[4] or t[1] in DOOR_OBJ or (t[2] in EDGES and not (t[5] & 1)):
            sys.exit('refused: edge tile %d,%d has a wall or door, or is walkable' % (x, y))
        piece = PIECES[key]
        if piece != t[2]:
            changed += 1
        data[o + 1] = 0
        data[o + 2] = piece
        data[o + 5:o + 8] = bytes(WALK if piece == CENTRE else BORDER)
    open(dst, 'wb').write(data)
    print('paved %d rectangles; %d tiles changed round them; wrote %s' % (len(rects), changed, dst))


if __name__ == '__main__':
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    main(sys.argv)
