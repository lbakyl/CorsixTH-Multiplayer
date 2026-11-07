#include <catch2/catch_test_macros.hpp>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "lua.hpp"
#include "th_lua.h"
#include "th_map.h"

TEST_CASE("test l_map_setcellflags", "[l_map_setcellflags]") {
  // Prepare lua bindings
  const lua_state_unique_ptr L(luaL_newstate());
  luaL_openlibs(L.get());
  preload_lua_package(L.get(), "TH", luaopen_th);
  luaT_execute(L.get(), "return require \"TH\"");
  lua_settop(L.get(), 1);

  // Create a map
  lua_getfield(L.get(), -1, "map");
  lua_call(L.get(), 0, 1);
  auto* map = static_cast<level_map*>(lua_touserdata(L.get(), -1));

  // Default map is 0,0, increase size so we can set flags
  map->set_size(128, 128);

  lua_getfield(L.get(), -1, "setCellFlags");

  lua_pushvalue(L.get(), -2);  // Copy the map to the top of the stack

  lua_pushinteger(L.get(), 5);   // X
  lua_pushinteger(L.get(), 10);  // Y

  // flags
  lua_newtable(L.get());
  lua_pushstring(L.get(), "buildable");
  lua_pushboolean(L.get(), true);
  lua_settable(L.get(), -3);

  lua_pushstring(L.get(), "doorNorth");
  lua_pushboolean(L.get(), true);
  lua_settable(L.get(), -3);

  lua_pushstring(L.get(), "parcelId");
  lua_pushnumber(L.get(), 3);
  lua_settable(L.get(), -3);

  lua_call(L.get(), 4, 0);

  const map_tile* tile = map->get_tile(4, 9);

  REQUIRE(tile->flags.buildable == true);
  REQUIRE(tile->flags.do_not_idle == false);
  REQUIRE(tile->flags.door_north == true);
  REQUIRE(tile->iParcelId == 3);
}

namespace {

std::vector<uint8_t> save_and_read(level_map& map, const std::string& name) {
  const std::filesystem::path path =
      std::filesystem::temp_directory_path() / name;
  map.save(path.string());
  std::ifstream is(path, std::ios_base::binary);
  std::vector<uint8_t> data((std::istreambuf_iterator<char>(is)),
                            std::istreambuf_iterator<char>());
  is.close();
  std::filesystem::remove(path);
  return data;
}

}  // namespace

TEST_CASE("blank maps of other sizes", "[level_map]") {
  level_map map;

  REQUIRE(map.load_blank());
  REQUIRE(map.get_width() == 128);
  REQUIRE(map.get_height() == 128);

  REQUIRE(map.load_blank(192, 192));
  REQUIRE(map.get_width() == 192);
  REQUIRE(map.get_height() == 192);
  int x = 0;
  int y = 0;
  REQUIRE(map.get_player_camera_tile(0, &x, &y));
  REQUIRE(x == 95);
  REQUIRE(y == 95);

  REQUIRE(map.load_blank(256, 256));
  REQUIRE_FALSE(map.load_blank(257, 257));
  REQUIRE_FALSE(map.load_blank(0, 128));
}

TEST_CASE("an 8 player 192 x 192 map saves and loads", "[level_map]") {
  level_map map;
  REQUIRE(map.load_blank(192, 192));
  map.set_player_count(8);
  map.set_player_camera_tile(0, 10, 20);
  map.set_player_heliport_tile(3, 30, 40);
  map.set_player_camera_tile(5, 150, 170);
  map.set_player_heliport_tile(7, 190, 3);

  const std::vector<uint8_t> data = save_and_read(map, "cth_test_192.map");
  REQUIRE(data.size() > 16);
  REQUIRE(std::memcmp(data.data(), "CTHMAP1", 7) == 0);

  level_map loaded;
  REQUIRE(loaded.load_from_th_file(data.data(), data.size(), nullptr, nullptr));
  REQUIRE(loaded.get_width() == 192);
  REQUIRE(loaded.get_height() == 192);
  REQUIRE(loaded.get_player_count() == 8);
  int x = 0;
  int y = 0;
  REQUIRE(loaded.get_player_camera_tile(0, &x, &y));
  REQUIRE((x == 10 && y == 20));
  REQUIRE(loaded.get_player_heliport_tile(3, &x, &y));
  REQUIRE((x == 30 && y == 40));
  REQUIRE(loaded.get_player_camera_tile(5, &x, &y));
  REQUIRE((x == 150 && y == 170));
  REQUIRE(loaded.get_player_heliport_tile(7, &x, &y));
  REQUIRE((x == 190 && y == 3));
}

TEST_CASE("a 128 x 128 map keeps Theme Hospital's format", "[level_map]") {
  level_map map;
  REQUIRE(map.load_blank());
  map.set_player_count(6);
  map.set_player_camera_tile(1, 12, 34);
  map.set_player_camera_tile(4, 56, 78);

  const std::vector<uint8_t> data = save_and_read(map, "cth_test_128.map");
  REQUIRE(data.size() == 163948);
  REQUIRE(data[0] == 6);

  level_map loaded;
  REQUIRE(loaded.load_from_th_file(data.data(), data.size(), nullptr, nullptr));
  REQUIRE(loaded.get_width() == 128);
  REQUIRE(loaded.get_player_count() == 6);
  int x = 0;
  int y = 0;
  REQUIRE(loaded.get_player_camera_tile(1, &x, &y));
  REQUIRE((x == 12 && y == 34));
  REQUIRE(loaded.get_player_camera_tile(4, &x, &y));
  REQUIRE((x == 56 && y == 78));
}
