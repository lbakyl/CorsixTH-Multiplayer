#include <catch2/catch_test_macros.hpp>

#include <functional>
#include <queue>
#include <random>
#include <vector>

#include "../Src/th_map.h"
#include "../Src/th_pathfind.h"

namespace {

constexpr int size = 128;

// The cheapest cost from (x, y) to every tile, entering a tile costing 128
// when it is to be avoided and 1 otherwise (as the pathfinder counts).
std::vector<int> cheapest_costs(const level_map& map, int x, int y) {
  std::vector<int> cost(size * size, -1);
  using item = std::pair<int, int>;  // cost, tile index
  std::priority_queue<item, std::vector<item>, std::greater<item>> open;
  open.push({0, y * size + x});
  while (!open.empty()) {
    auto [c, i] = open.top();
    open.pop();
    if (cost[i] != -1) continue;
    cost[i] = c;
    const map_tile_flags& f = map.get_tile(i % size, i / size)->flags;
    const int steps[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    const bool can[4] = {f.can_travel_w, f.can_travel_e, f.can_travel_n,
                         f.can_travel_s};
    for (int d = 0; d < 4; ++d) {
      if (!can[d]) continue;
      int j = i + steps[d][1] * size + steps[d][0];
      const map_tile_flags& g = map.get_tile(j % size, j / size)->flags;
      if (!g.passable || cost[j] != -1) continue;
      open.push({c + (g.avoid_tile ? 128 : 1), j});
    }
  }
  return cost;
}

}  // namespace

TEST_CASE("pathfinder with tiles to avoid", "[pathfind]") {
  // Small open areas with tiles to avoid (people a room is being drawn over)
  // and walls of impassable tiles. A tile to avoid that looked cheaper by
  // another way used to be promoted after it had left the open heap, which
  // threw "Invalid open_idx on node" and ended the game.
  std::mt19937 rng(12345);
  level_map map;
  REQUIRE(map.set_size(size, size));
  map.update_pathfinding();
  pathfinder pf;
  pf.set_default_map(&map);
  int checked = 0;
  for (int round = 0; round < 300; ++round) {
    for (int y = 0; y < size; ++y) {
      for (int x = 0; x < size; ++x) {
        map_tile_flags& f = map.get_tile(x, y)->flags;
        bool inside = x >= 2 && y >= 2 && x < 18 && y < 18;
        int r = static_cast<int>(rng() % 100);
        f.passable = inside && r >= 15;
        f.avoid_tile = inside && r < 45 && r >= 15;
        f.hospital = f.passable;
      }
    }
    int sx = 2 + static_cast<int>(rng() % 16), sy = 2 + static_cast<int>(rng() % 16);
    map.get_tile(sx, sy)->flags.passable = true;
    std::vector<int> best = cheapest_costs(map, sx, sy);
    for (int k = 0; k < 20; ++k) {
      int ex = 2 + static_cast<int>(rng() % 16), ey = 2 + static_cast<int>(rng() % 16);
      if (!map.get_tile(ex, ey)->flags.passable) continue;
      bool found = false;
      REQUIRE_NOTHROW(found = pf.find_path(&map, sx, sy, ex, ey));
      int expected = best[ey * size + ex];
      REQUIRE(found == (expected != -1));
      if (found) {
        REQUIRE(pf.destination->cost == expected);
        ++checked;
      }
    }
    REQUIRE_NOTHROW(pf.find_idle_tile(&map, sx, sy, 3, 0));
  }
  REQUIRE(checked > 1000);
}
