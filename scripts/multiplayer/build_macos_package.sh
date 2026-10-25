#!/usr/bin/env bash
# Build a macOS (Apple Silicon) package of CorsixTH multiplayer: a
# self-contained CorsixTH.app, zipped. Built on a macOS 15 runner, so it runs
# on macOS 15 and newer (Tahoe included).
#
# Players need the same Lua runtime as the Windows and Linux builds (Lua 5.5:
# it is part of the multiplayer build id), so Lua 5.5 and the Lua modules the
# game loads (LuaFileSystem, LPeg, LuaSocket) are built here and put into the
# app. The libraries come from Homebrew (SDL3, SDL3_mixer, FluidSynth,
# FreeType, libpng, zstd); CMake's fixup_bundle copies them into the app.
#
# The Lua modules go into Contents/Resources (next to CorsixTH.lua, where the
# game looks for them), not into Resources/Lua: every .lua file there counts
# for the build id, and the Windows and Linux builds keep them elsewhere too.
#
# Needs Homebrew: brew install cmake ninja pkg-config sdl3 sdl3_mixer fluid-synth freetype libpng zstd
# Usage: bash scripts/multiplayer/build_macos_package.sh [VERSION_LABEL]
# Result: dist/CorsixTH.app and dist/CorsixTH-Multiplayer-<label>-macos-arm64.zip
set -euo pipefail
src=$(cd "$(dirname "$0")/../.." && pwd)
label=${1:-$(git -C "$src" rev-parse --short=8 HEAD 2>/dev/null || echo dev)}
work=${WORK_DIR:-$src/build-macos-package}
dist=${DIST_DIR:-$src/dist}
jobs=$(sysctl -n hw.ncpu)
P=$work/prefix
brew_prefix=$(brew --prefix)
export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-15.0}
mkdir -p "$work/src" "$P" "$dist"
cd "$work/src"

# 1. Lua 5.5 (static) with LuaFileSystem, LPeg and LuaSocket as loadable
# bundles; they find the Lua functions in the game program (-force_load below).
if [[ ! -f "$P/lib/liblua.a" ]]; then
  [[ -f lua-5.5.0.tar.gz ]] || curl -fsSLO https://www.lua.org/ftp/lua-5.5.0.tar.gz
  tar xzf lua-5.5.0.tar.gz
  make -C lua-5.5.0 -j"$jobs" macosx
  make -C lua-5.5.0 install INSTALL_TOP="$P"
fi
inc=$P/include
mods=$P/lib/lua/5.5
lmods=$P/share/lua/5.5
mkdir -p "$mods" "$lmods" "$P/include-cmake"
bundle="cc -O2 -fPIC -I$inc -bundle -undefined dynamic_lookup"
# CMake's FindLua cannot read Lua 5.5's version macros: a wrapper header (see
# build_linux_package.sh).
{
  echo '/* Wrapper for CMake FindLua; see scripts/multiplayer/build_macos_package.sh. */'
  echo '#if 0'
  echo '#define LUA_VERSION_MAJOR "5"'
  echo '#define LUA_VERSION_MINOR "4"'
  echo '#define LUA_VERSION_RELEASE "0"'
  echo '#endif'
  echo "#include \"$inc/lua.h\""
} > "$P/include-cmake/lua.h"
for h in luaconf.h lualib.h lauxlib.h lua.hpp; do ln -sfn "$inc/$h" "$P/include-cmake/$h"; done
if [[ ! -f "$mods/lfs.so" ]]; then
  [[ -d luafilesystem ]] || git clone -q --depth 1 --branch v1_9_0 https://github.com/lunarmodules/luafilesystem.git
  $bundle -o "$mods/lfs.so" luafilesystem/src/lfs.c
fi
if [[ ! -f "$mods/lpeg.so" ]]; then
  [[ -d lpeg ]] || git clone -q --depth 1 --branch v1.1.0 https://github.com/roberto-ieru/LPeg.git lpeg
  $bundle -o "$mods/lpeg.so" lpeg/lp*.c
  cp lpeg/re.lua "$lmods/"
fi
if [[ ! -f "$mods/socket/core.so" ]]; then
  [[ -d luasocket ]] || git clone -q --depth 1 --branch v3.1.0 https://github.com/lunarmodules/luasocket.git
  make -C luasocket -j"$jobs" macosx LUAV=5.5 LUAINC_macosx="$inc" \
    MACOSX_VERSION="$MACOSX_DEPLOYMENT_TARGET"
  make -C luasocket install PLAT=macosx LUAV=5.5 prefix="$P" INSTALL_TOP_LDIR="$lmods" INSTALL_TOP_CDIR="$mods"
fi

# 2. CorsixTH, installed as CorsixTH.app (fixup_bundle copies the Homebrew
# libraries into Contents/Frameworks). Lua is linked in whole, so the Lua
# modules find every function they need.
cmake -S "$src" -B "$work/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH="$P;$brew_prefix" -DCMAKE_INSTALL_PREFIX="$work/stage" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DWITH_MOVIES=OFF -DWITH_UPDATE_CHECK=OFF -DWITH_MIDI_DEVICE=OFF -DWITH_LUAROCKS=OFF \
  -DFETCH_SOUNDFONT=ON -DFETCH_UNICODE_FONT=ON \
  -DLUA_INCLUDE_DIR="$P/include-cmake" -DLUA_LIBRARY="$P/lib/liblua.a" \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,-force_load,$P/lib/liblua.a"
cmake --build "$work/build" -j"$jobs"
rm -rf "$work/stage"
cmake --install "$work/build"

# 3. The Lua modules into the app, next to CorsixTH.lua.
app=$work/stage/CorsixTH.app
res=$app/Contents/Resources
cp -R "$mods/." "$res/"
cp -R "$lmods/." "$res/"
cat > "$res/README-MULTIPLAYER.txt" <<EOF
CorsixTH-Multiplayer test build (macOS, Apple Silicon)
Commit $label of https://github.com/lbakyl/CorsixTH-Multiplayer

The first time it asks for your Theme Hospital folder (the game data is not
included). Everybody in a game must use the same build of the same commit,
on Windows, Linux or macOS. Main menu > Multiplayer, server address
(host:port) and your name.
EOF

# 4. Sign it ad hoc (Apple Silicon runs only signed code; fixup_bundle has
# changed the libraries). Not notarized: the first start needs System Settings
# > Privacy & Security > Open Anyway.
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"

rm -rf "$dist/CorsixTH.app"
cp -R "$app" "$dist/CorsixTH.app"
zip_name=CorsixTH-Multiplayer-$label-macos-arm64.zip
rm -f "$dist/$zip_name"
(cd "$dist" && ditto -c -k --sequesterRsrc --keepParent CorsixTH.app "$zip_name")
echo "Package: $dist/$zip_name"
