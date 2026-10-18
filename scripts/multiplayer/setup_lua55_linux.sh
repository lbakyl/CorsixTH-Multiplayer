#!/usr/bin/env bash
# Build Lua 5.5 with LuaFileSystem, LPeg and LuaSocket into a prefix, and a
# CorsixTH build against it, on Linux. The Windows builds (vcpkg) use Lua 5.5,
# and players need the same Lua runtime to play together (it is part of the
# multiplayer build id), so this makes a Linux build that can join a Windows
# player. Run after setup_debian13.sh (needs its SDL prefix in $PREFIX).
#
# Usage: . ~/mp-env.sh; bash scripts/multiplayer/setup_lua55_linux.sh
# Result: build-lua55/CorsixTH/corsix-th and $HOME/lua55-env.sh
set -euo pipefail
: "${PREFIX:?run . ~/mp-env.sh first}"
checkout=$(cd "$(dirname "$0")/../.." && pwd)
root=${LUA55_ROOT:-$HOME/corsixth-lua55}
P=$root/prefix
mkdir -p "$root/src" "$P/lib/lua/5.5" "$P/share/lua/5.5"
cd "$root/src"
jobs=$(nproc)

if [[ ! -f "$P/lib/liblua.a" ]]; then
  [[ -f lua-5.5.0.tar.gz ]] || curl -fsSLO https://www.lua.org/ftp/lua-5.5.0.tar.gz
  tar xzf lua-5.5.0.tar.gz
  make -C lua-5.5.0 -j"$jobs" linux MYCFLAGS=-fPIC
  make -C lua-5.5.0 install INSTALL_TOP="$P"
fi
inc=$P/include
cflags="-O2 -fPIC -I$inc"

# CMake 3.31's FindLua cannot read Lua 5.5's version macros and would pick
# the system Lua 5.4 headers instead. Give it a wrapper lua.h whose version
# lines it can read (the compiler skips them; it says 5.4 because FindLua
# rejects any newer version) and which includes the real 5.5 header.
mkdir -p "$P/include-cmake"
{
  echo '/* Wrapper for CMake FindLua; see scripts/multiplayer/setup_lua55_linux.sh. */'
  echo '#if 0'
  echo '#define LUA_VERSION_MAJOR "5"'
  echo '#define LUA_VERSION_MINOR "4"' # FindLua accepts at most 5.4; only a label
  echo '#define LUA_VERSION_RELEASE "0"'
  echo '#endif'
  echo "#include \"$inc/lua.h\""
} > "$P/include-cmake/lua.h"
for h in luaconf.h lualib.h lauxlib.h lua.hpp; do ln -sfn "$inc/$h" "$P/include-cmake/$h"; done

if [[ ! -f "$P/lib/lua/5.5/lfs.so" ]]; then
  [[ -d luafilesystem ]] || git clone -q --depth 1 --branch v1_9_0 https://github.com/lunarmodules/luafilesystem.git
  gcc $cflags -shared -o "$P/lib/lua/5.5/lfs.so" luafilesystem/src/lfs.c
fi
if [[ ! -f "$P/lib/lua/5.5/lpeg.so" ]]; then
  [[ -d lpeg ]] || git clone -q --depth 1 --branch v1.1.0 https://github.com/roberto-ieru/LPeg.git lpeg
  gcc $cflags -shared -o "$P/lib/lua/5.5/lpeg.so" lpeg/lp*.c
  cp lpeg/re.lua "$P/share/lua/5.5/"
fi
if [[ ! -f "$P/lib/lua/5.5/socket/core.so" ]]; then
  [[ -d luasocket ]] || git clone -q --depth 1 --branch v3.1.0 https://github.com/lunarmodules/luasocket.git
  make -C luasocket -j"$jobs" linux LUAV=5.5 LUAINC_linux="$inc" MYCFLAGS=-fPIC
  make -C luasocket install LUAV=5.5 prefix="$P" \
    INSTALL_TOP_LDIR="$P/share/lua/5.5" INSTALL_TOP_CDIR="$P/lib/lua/5.5"
fi

# The game binary links Lua statically and exports its symbols (-Wl,-E) for
# the C modules above.
cd "$checkout"
cmake -S . -B build-lua55 -G Ninja -DCMAKE_PREFIX_PATH="$PREFIX" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DUSE_SOURCE_DATADIRS=ON -DWITH_MOVIES=OFF -DWITH_UPDATE_CHECK=OFF -DWITH_MIDI_DEVICE=OFF \
  -DLUA_INCLUDE_DIR="$P/include-cmake" -DLUA_LIBRARY="$P/lib/liblua.a" \
  -DCMAKE_CXX_STANDARD_LIBRARIES="-lm -ldl" -DCMAKE_EXE_LINKER_FLAGS="-Wl,-E"
cmake --build build-lua55 -j"$jobs"

cat > "$HOME/lua55-env.sh" <<EOF
# Lua 5.5 build of CorsixTH (see scripts/multiplayer/setup_lua55_linux.sh)
export BIN55=$checkout/build-lua55/CorsixTH/corsix-th
export LUA_CPATH_5_5="$P/lib/lua/5.5/?.so;;"
export LUA_PATH_5_5="$P/share/lua/5.5/?.lua;$P/share/lua/5.5/?/init.lua;;"
export LUASOCKET_TREE55=$P
EOF
echo "Built $checkout/build-lua55/CorsixTH/corsix-th; environment in $HOME/lua55-env.sh"
