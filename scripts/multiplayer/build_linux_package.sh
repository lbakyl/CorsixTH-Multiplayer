#!/usr/bin/env bash
# Build a portable Linux x86_64 package of CorsixTH multiplayer: a folder
# (and a .tar.gz of it) that runs without installing anything, on the
# distribution it was built on and newer ones (build it on Ubuntu 24.04 for
# Linux Mint 22 and later).
#
# Players need the same Lua runtime as the Windows builds (Lua 5.5: it is
# part of the multiplayer build id), so Lua 5.5 and the Lua modules the game
# loads (LuaFileSystem, LPeg, LuaSocket) are built here and bundled. SDL3,
# SDL3_mixer and the libraries a plain desktop may lack are bundled too; the
# C library, graphics, X11/Wayland, sound servers and GLib come from the
# system (as for an AppImage).
#
# Needs the build packages listed in .github/workflows/LinuxPackage.yml.
# Usage: bash scripts/multiplayer/build_linux_package.sh [VERSION_LABEL]
# Result: dist/CorsixTH-Multiplayer/ and dist/CorsixTH-Multiplayer-<label>-linux-x86_64.tar.gz
set -euo pipefail
src=$(cd "$(dirname "$0")/../.." && pwd)
label=${1:-$(git -C "$src" rev-parse --short=8 HEAD 2>/dev/null || echo dev)}
work=${WORK_DIR:-$src/build-linux-package}
dist=${DIST_DIR:-$src/dist}
jobs=$(nproc)
P=$work/prefix
mkdir -p "$work/src" "$P" "$dist"
cd "$work/src"

# 1. SDL3 and SDL3_mixer (Ubuntu 24.04 has neither).
if [[ ! -f "$P/lib/libSDL3.so" ]]; then
  [[ -d SDL ]] || git clone -q --depth 1 --branch release-3.4.18 https://github.com/libsdl-org/SDL.git SDL
  cmake -S SDL -B SDL/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$P" \
    -DCMAKE_INSTALL_LIBDIR=lib -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF
  cmake --build SDL/build -j"$jobs"
  cmake --install SDL/build
fi
if [[ ! -f "$P/lib/libSDL3_mixer.so" ]]; then
  [[ -d SDL_mixer ]] || git clone -q --depth 1 --branch release-3.2.4 https://github.com/libsdl-org/SDL_mixer.git SDL_mixer
  cmake -S SDL_mixer -B SDL_mixer/build -G Ninja -DCMAKE_PREFIX_PATH="$P" -DCMAKE_INSTALL_PREFIX="$P" \
    -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release -DSDLMIXER_TESTS=OFF -DSDLMIXER_EXAMPLES=OFF \
    -DSDLMIXER_VENDORED=OFF -DSDLMIXER_FLAC_LIBFLAC=OFF -DSDLMIXER_GME=OFF -DSDLMIXER_MOD=OFF \
    -DSDLMIXER_MP3_MPG123=OFF -DSDLMIXER_OPUS=OFF -DSDLMIXER_VORBIS_VORBISFILE=OFF -DSDLMIXER_WAVPACK=OFF
  cmake --build SDL_mixer/build -j"$jobs"
  cmake --install SDL_mixer/build
fi

# 2. Lua 5.5 with LuaFileSystem, LPeg and LuaSocket (as setup_lua55_linux.sh).
if [[ ! -f "$P/lib/liblua.a" ]]; then
  [[ -f lua-5.5.0.tar.gz ]] || curl -fsSLO https://www.lua.org/ftp/lua-5.5.0.tar.gz
  tar xzf lua-5.5.0.tar.gz
  make -C lua-5.5.0 -j"$jobs" linux MYCFLAGS=-fPIC
  make -C lua-5.5.0 install INSTALL_TOP="$P"
fi
inc=$P/include
mods=$P/lib/lua/5.5
lmods=$P/share/lua/5.5
mkdir -p "$mods" "$lmods" "$P/include-cmake"
cflags="-O2 -fPIC -I$inc"
# CMake's FindLua cannot read Lua 5.5's version macros: a wrapper header whose
# version lines it can read (it rejects anything newer than 5.4; only a label).
{
  echo '/* Wrapper for CMake FindLua; see scripts/multiplayer/build_linux_package.sh. */'
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
  gcc $cflags -shared -o "$mods/lfs.so" luafilesystem/src/lfs.c
fi
if [[ ! -f "$mods/lpeg.so" ]]; then
  [[ -d lpeg ]] || git clone -q --depth 1 --branch v1.1.0 https://github.com/roberto-ieru/LPeg.git lpeg
  gcc $cflags -shared -o "$mods/lpeg.so" lpeg/lp*.c
  cp lpeg/re.lua "$lmods/"
fi
if [[ ! -f "$mods/socket/core.so" ]]; then
  [[ -d luasocket ]] || git clone -q --depth 1 --branch v3.1.0 https://github.com/lunarmodules/luasocket.git
  make -C luasocket -j"$jobs" linux LUAV=5.5 LUAINC_linux="$inc" MYCFLAGS=-fPIC
  make -C luasocket install LUAV=5.5 prefix="$P" INSTALL_TOP_LDIR="$lmods" INSTALL_TOP_CDIR="$mods"
fi

# 3. CorsixTH, installed into a staging folder. Lua is linked statically and
# its symbols exported (-Wl,-E) for the Lua modules above.
cmake -S "$src" -B "$work/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_PREFIX_PATH="$P" \
  -DCMAKE_INSTALL_PREFIX="$work/stage" -DWITH_MOVIES=OFF -DWITH_UPDATE_CHECK=OFF -DWITH_MIDI_DEVICE=OFF \
  -DFETCH_SOUNDFONT=ON -DFETCH_UNICODE_FONT=ON -DLUA_INCLUDE_DIR="$P/include-cmake" -DLUA_LIBRARY="$P/lib/liblua.a" \
  -DCMAKE_CXX_STANDARD_LIBRARIES="-lm -ldl" -DCMAKE_EXE_LINKER_FLAGS="-Wl,-E"
cmake --build "$work/build" -j"$jobs"
rm -rf "$work/stage"
cmake --install "$work/build"

# 4. The package: the game's files with the program next to CorsixTH.lua
# (where it looks first), libraries in lib/, Lua modules in lua/.
pkg=$dist/CorsixTH-Multiplayer
rm -rf "$pkg"
mkdir -p "$pkg/lib" "$pkg/lua"
cp -a "$work/stage/share/corsix-th/." "$pkg/"
cp "$work/stage/bin/corsix-th" "$pkg/corsix-th"
cp -a "$mods/." "$pkg/lua/"
cp -a "$lmods/." "$pkg/lua/"
cp "$src/LICENSE.txt" "$pkg/" 2>/dev/null || true

# Libraries: everything the program and the Lua modules load, except what a
# desktop always has (the AppImage idea of an exclude list). A bundled
# libstdc++ or graphics library would break on newer systems.
system_lib() {
  case "$1" in
    linux-vdso* | ld-linux* | libc.so* | libm.so* | libdl.so* | libpthread* | librt.so* | libresolv* |     libutil* | libstdc++* | libgcc_s* | libgomp* | libatomic* | libGL* | libOpenGL* | libEGL* |     libdrm* | libgbm* | libX* | libxcb* | libxkbcommon* | libwayland* | libdecor* | libasound* |     libpulse* | libpipewire* | libjack* | libdbus* | libsystemd* | libudev* | libapparmor* |     libasyncns* | libglib* | libgobject* | libgmodule* | libgio* | libpcre* | libffi* | libz.so* |     libexpat* | libfontconfig* | libfreetype* | libharfbuzz* | libuuid* | libselinux* | libmount* |     libblkid* | libcap* | libgpg-error* | libgcrypt* | liblzma* | liblz4* | libzstd* | libbz2* |     libtinfo* | libreadline* | libbsd* | libmd.so*) return 0 ;;
  esac
  return 1
}
copy_deps() {
  ldd "$1" | awk '/=> \// {print $1, $3}' | while read -r name path; do
    if ! system_lib "$name" && [[ ! -e "$pkg/lib/$name" ]]; then
      cp -L "$path" "$pkg/lib/$name"
      copy_deps "$path"
    fi
  done
}
export LD_LIBRARY_PATH="$P/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
copy_deps "$pkg/corsix-th"
find "$pkg/lua" -name '*.so' | while read -r so; do copy_deps "$so"; done
patchelf --set-rpath '$ORIGIN/lib' "$pkg/corsix-th"
for so in "$pkg"/lib/*.so*; do patchelf --set-rpath '$ORIGIN' "$so" 2>/dev/null || true; done

cat > "$pkg/CorsixTH-Multiplayer.sh" <<'EOF'
#!/bin/sh
# Start CorsixTH multiplayer from this folder, with its own config.txt (and
# saves in a Saves folder here), like "Play multiplayer.bat" on Windows.
here=$(cd "$(dirname "$0")" && pwd)
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LUA_CPATH_5_5="$here/lua/?.so;;"
export LUA_PATH_5_5="$here/lua/?.lua;$here/lua/?/init.lua;;"
cd "$here" || exit 1
exec ./corsix-th --config-file="$here/config.txt" "$@"
EOF
chmod +x "$pkg/CorsixTH-Multiplayer.sh" "$pkg/corsix-th"

cat > "$pkg/README-MULTIPLAYER.txt" <<EOF
CorsixTH-Multiplayer test build (Linux x86_64)
Commit $label of https://github.com/lbakyl/CorsixTH-Multiplayer

Start it with ./CorsixTH-Multiplayer.sh (the first time it asks for your
Theme Hospital folder; the game data is not included). Settings and saves
stay in this folder (config.txt, Saves), so the folder can be copied.

Everybody in a game must use the same build of the same commit, on Windows
or Linux. Main menu > Multiplayer, server address (host:port) and your name.
Keep the game language English.

Full guide: docs/multiplayer/PLAYING.md in the repository.
CorsixTH is MIT licensed (LICENSE.txt). Theme Hospital is a trademark of
Electronic Arts; this build contains none of its data.
EOF

tarball=$dist/CorsixTH-Multiplayer-$label-linux-x86_64.tar.gz
tar -C "$dist" -czf "$tarball" CorsixTH-Multiplayer
echo "Bundled libraries:"; ls "$pkg/lib"
echo "Package: $pkg"
echo "Archive: $tarball"
