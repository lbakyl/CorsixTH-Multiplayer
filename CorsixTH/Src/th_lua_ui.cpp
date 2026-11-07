/*
Copyright (c) 2010 Peter "Corsix" Cawley

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include "th_lua_ui.h"

#include "config.h"

#include <algorithm>

#ifdef WITH_TRACY
#include <tracy/Tracy.hpp>
#endif

#include <list>

#include "lua.hpp"
#include "th_gfx_sdl.h"
#include "th_lua.h"
#include "th_lua_internal.h"
#include "th_map.h"

class abstract_window {};

namespace {

int l_abstract_window_new(lua_State* L) {
  return luaL_error(L,
                    "windowBase can only be used a base class - "
                    " do not create a windowBase directly.");
}

inline bool is_wall(uint16_t blk) {
  return 82 <= (blk & 0xFF) && (blk & 0xFF) <= 164;
}

inline bool is_wall_drawn(const level_map& map, const map_tile& node,
                          const map_tile& original_node, tile_layer n) {
  return map.get_tile_owner(&node) != 0 ? is_wall(node.tile_layers[n])
                                        : is_wall(original_node.tile_layers[n]);
}

int l_town_map_draw(lua_State* L) {
  ZoneScoped;

  luaL_checktype(L, 1, LUA_TTABLE);
  level_map* pMap = luaT_testuserdata<level_map>(L, 2);
  render_target* pCanvas = luaT_testuserdata<render_target>(L, 3);
  int iCanvasXBase = static_cast<int>(luaL_checkinteger(L, 4));
  int iCanvasYBase = static_cast<int>(luaL_checkinteger(L, 5));
  bool bShowHeat = lua_toboolean(L, 6) != 0;
  int scale = static_cast<int>(luaL_optinteger(L, 7, 1));
  // Multiplayer: whose map this is (the plots they may buy are red), and
  // optionally {others = {[player] = {r, g, b}}, for_sale = {r, g, b}}:
  // other players' land in their colour, plots this player cannot buy
  // (yet) in stripes of for_sale's. Without them as in the original game.
  int iPlayer = static_cast<int>(luaL_optinteger(L, 8, 1));
  bool bOptions = lua_istable(L, 9);

  uint32_t iColourMyHosp = render_target::map_colour(0, 0, 70);
  uint32_t iColourWall = render_target::map_colour(255, 255, 255);
  uint32_t iColourDoor = render_target::map_colour(200, 200, 200);
  uint32_t iColourPurchasable = render_target::map_colour(255, 0, 0);

  auto read_rgb = [L](int iTable, uint32_t* pColour) {
    if (!lua_istable(L, iTable)) return false;
    int c[3];
    for (int i = 0; i < 3; ++i) {
      lua_rawgeti(L, iTable, i + 1);
      c[i] = static_cast<int>(lua_tointeger(L, -1));
      lua_pop(L, 1);
    }
    *pColour = render_target::map_colour(static_cast<uint8_t>(c[0]),
                                         static_cast<uint8_t>(c[1]),
                                         static_cast<uint8_t>(c[2]));
    return true;
  };
  uint32_t aOthers[level_map::max_players + 1];
  bool aHasOther[level_map::max_players + 1] = {};
  uint32_t iColourForSale = 0;
  bool bForSale = false;
  if (bOptions) {
    lua_getfield(L, 9, "others");
    if (lua_istable(L, -1)) {
      for (int p = 1; p <= level_map::max_players; ++p) {
        lua_rawgeti(L, -1, p);
        aHasOther[p] = read_rgb(lua_gettop(L), &aOthers[p]);
        lua_pop(L, 1);
      }
    }
    lua_pop(L, 1);
    lua_getfield(L, 9, "for_sale");
    bForSale = read_rgb(lua_gettop(L), &iColourForSale);
    lua_pop(L, 1);
  }

  const map_tile* pNode = pMap->get_tile_unchecked(0, 0);
  const map_tile* pOriginalNode = pMap->get_original_tile_unchecked(0, 0);
  int iMapWidth = pMap->get_width();
  // Pixels per tile (times the UI scale): 3 on Theme Hospital's 128 x 128
  // maps, fewer on bigger ones (2 at 192, 1 at 256), so the map keeps its
  // 384 pixels; doors and walls in proportion.
  const int tile = std::max(1, 384 / std::max(iMapWidth, pMap->get_height()));
  const int t = tile * scale;
  // How far the entrance doors stick out of the hospital, in whole pixels.
  const int door_shift = (2 * t) / 3;
  int iCanvasY = iCanvasYBase + t;
  for (int iY = 0; iY < pMap->get_height(); ++iY, iCanvasY += t) {
    int iCanvasX = iCanvasXBase;
    for (int iX = 0; iX < iMapWidth;
         ++iX, ++pNode, ++pOriginalNode, iCanvasX += t) {
      if (pOriginalNode->flags.hospital) {
        uint32_t iColour = iColourMyHosp;
        int iOwner = pMap->get_parcel_owner(pNode->iParcelId);
        if (!(pNode->flags.hospital)) {
          if (pMap->is_parcel_purchasable(pNode->iParcelId, iPlayer))
            iColour = iColourPurchasable;
          else if (bForSale && iOwner == 0 && (iX + iY) % 3 == 0)
            iColour = iColourForSale;  // (stripes: for sale, not for them)
          else
            goto dont_paint_tile;
        } else if (iOwner != iPlayer && iOwner >= 1 &&
                   iOwner <= level_map::max_players && aHasOther[iOwner]) {
          iColour = aOthers[iOwner];
        } else if (bShowHeat) {
          uint16_t iTemp = pMap->get_tile_temperature(pNode);
          if (iTemp < 5200)  // Less than 4 degrees
            iTemp = 0;
          else if (iTemp > 32767)  // More than 25 degrees
            iTemp = 255;
          else  // NB: 108 == (32767 - 5200) / 255
            iTemp = static_cast<uint16_t>((iTemp - 5200) / 108);

          constexpr uint16_t minOkTemp = 140;
          constexpr uint16_t maxOkTemp = 180;

          uint8_t iR = 0;
          uint8_t iG = 0;
          uint8_t iB = 0;
          switch (pMap->get_temperature_display()) {
            case temperature_theme::multi_colour:
              iB = 70;
              if (iTemp < minOkTemp) {
                iB = map_color_channel(0, minOkTemp - 1, iTemp, 200, 60);
              } else if (iTemp < maxOkTemp) {
                iG = map_color_channel(minOkTemp, maxOkTemp - 1, iTemp, 140,
                                       224);
              } else {
                iR = map_color_channel(maxOkTemp, 255, iTemp, 224, 255);
              }
              break;
            case temperature_theme::yellow_red:
              if (iTemp < minOkTemp) {  // Below 11 degrees
                iR = map_color_channel(0, minOkTemp - 1, iTemp, 100, 213);
                iG = map_color_channel(0, minOkTemp - 1, iTemp, 80, 180);
              } else {
                iR = map_color_channel(minOkTemp, 255, iTemp, 223, 235);
                iG = map_color_channel(minOkTemp, 255, iTemp, 184, 104);
                iB = map_color_channel(minOkTemp, 255, iTemp, 0, 53);
              }
              break;
            case temperature_theme::red:
              iR = static_cast<uint8_t>(iTemp);
              iB = 70;
              break;
          }

          iColour = render_target::map_colour(iR, iG, iB);
        }
        pCanvas->fill_rect(iColour, iCanvasX, iCanvasY, t, t);
      }
    dont_paint_tile:
      if (is_wall_drawn(*pMap, *pNode, *pOriginalNode,
                        tile_layer::north_wall)) {
        pCanvas->fill_rect(iColourWall, iCanvasX, iCanvasY, t, scale);

        // Draw entrance door
        auto l = (pNode - 1)->objects;
        if (!l.empty() && l.front() == object_type::entrance_right_door) {
          if (pNode->flags.hospital) {
            pCanvas->fill_rect(iColourDoor, iCanvasX - 2 * t,
                               iCanvasY - door_shift, 3 * t, t);
          } else {
            pCanvas->fill_rect(iColourDoor, iCanvasX - 2 * t, iCanvasY, 3 * t,
                               t);
          }
        }
      }
      if (is_wall_drawn(*pMap, *pNode, *pOriginalNode, tile_layer::west_wall)) {
        pCanvas->fill_rect(iColourWall, iCanvasX, iCanvasY, scale, t);

        // Draw entrance door
        auto l = (pNode - iMapWidth)->objects;
        if (!l.empty() && l.front() == object_type::entrance_right_door) {
          if (pNode->flags.hospital) {
            pCanvas->fill_rect(iColourDoor, iCanvasX - door_shift,
                               iCanvasY - 2 * t, t, 3 * t);
          } else {
            pCanvas->fill_rect(iColourDoor, iCanvasX, iCanvasY - 2 * t, t,
                               3 * t);
          }
        }
      }
    }
  }

  return 0;
}

}  // namespace

void lua_register_ui(const lua_register_state* pState) {
  // WindowBase
  lua_class_binding<abstract_window> lcb(pState, "windowHelpers",
                                         l_abstract_window_new,
                                         lua_metatable::window_base);
  lcb.add_function(l_town_map_draw, "townMapDraw", lua_metatable::map,
                   lua_metatable::surface);
}
