#!/usr/bin/env bash
# Build a self-contained macOS app of CorsixTH multiplayer for Apple Silicon
# (arm64), macOS 26 Tahoe or newer: CorsixTH.app, and a zip of it.
#
# Players need the same Lua runtime as the Windows and Linux builds (Lua 5.5:
# it is part of the multiplayer build id), so Lua 5.5 and the Lua modules the
# game loads (LuaFileSystem, LPeg, LuaSocket) are built here and bundled, as
# in build_linux_package.sh. SDL3 and SDL3_mixer are built from source (the
# same versions as on Linux), and a small FFmpeg for the videos; FreeType,
# libpng, zstd and FluidSynth come from
# Homebrew and are copied into the app with dylibbundler (CMake's
# fixup_bundle cannot follow Homebrew's @rpath references). The modules go
# into Contents/Resources next to CorsixTH.lua, not into its Lua folder: the
# build id is a checksum of that folder.
#
# The app is signed ad hoc (Apple Silicon runs only signed code); it is not
# notarized, so the first start needs System Settings > Privacy & Security >
# Open Anyway (docs/multiplayer/PLAYING.md).
#
# Needs Xcode command line tools and the Homebrew packages listed in
# .github/workflows/macOS.yml.
# Usage: bash scripts/multiplayer/build_macos_app.sh [VERSION_LABEL]
# Result: dist/CorsixTH-Multiplayer/CorsixTH.app and
#         dist/CorsixTH-Multiplayer-<label>-macos-arm64.zip
set -euo pipefail
src=$(cd "$(dirname "$0")/../.." && pwd)
label=${1:-$(git -C "$src" rev-parse --short=8 HEAD 2>/dev/null || echo dev)}
work=${WORK_DIR:-$src/build-macos-app}
dist=${DIST_DIR:-$src/dist}
jobs=$(sysctl -n hw.ncpu)
export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-26.0}
brew_prefix=$(brew --prefix)
P=$work/prefix
mkdir -p "$work/src" "$P" "$dist"
cd "$work/src"

# 1. SDL3 and SDL3_mixer.
if [[ ! -f "$P/lib/libSDL3.dylib" ]]; then
  [[ -d SDL ]] || git clone -q --depth 1 --branch release-3.4.18 https://github.com/libsdl-org/SDL.git SDL
  cmake -S SDL -B SDL/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$P" \
    -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF
  cmake --build SDL/build -j"$jobs"
  cmake --install SDL/build
fi
if [[ ! -f "$P/lib/libSDL3_mixer.dylib" ]]; then
  [[ -d SDL_mixer ]] || git clone -q --depth 1 --branch release-3.2.4 https://github.com/libsdl-org/SDL_mixer.git SDL_mixer
  cmake -S SDL_mixer -B SDL_mixer/build -G Ninja -DCMAKE_PREFIX_PATH="$P" -DCMAKE_INSTALL_PREFIX="$P" \
    -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DSDLMIXER_TESTS=OFF -DSDLMIXER_EXAMPLES=OFF \
    -DSDLMIXER_VENDORED=OFF -DSDLMIXER_FLAC_LIBFLAC=OFF -DSDLMIXER_GME=OFF -DSDLMIXER_MOD=OFF \
    -DSDLMIXER_MP3_MPG123=OFF -DSDLMIXER_OPUS=OFF -DSDLMIXER_VORBIS_VORBISFILE=OFF -DSDLMIXER_WAVPACK=OFF
  cmake --build SDL_mixer/build -j"$jobs"
  cmake --install SDL_mixer/build
fi

# FFmpeg for the game's videos (intro, level won or lost, the end of a
# multiplayer game): only what Theme Hospital's Smacker videos need (the same
# major version as the Windows build, avcodec 62), shared, nothing taken from
# Homebrew; bundled with the other libraries below.
if [[ ! -f "$P/lib/libavcodec.dylib" ]]; then
  [[ -d ffmpeg ]] || git clone -q --depth 1 --branch n8.0 https://github.com/FFmpeg/FFmpeg.git ffmpeg
  (cd ffmpeg && ./configure --prefix="$P" --arch=arm64 --target-os=darwin --cc=clang \
    --extra-cflags="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET" \
    --extra-ldflags="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET" \
    --enable-shared --disable-static --disable-programs --disable-doc --disable-network \
    --disable-autodetect --disable-everything \
    --enable-demuxer=smacker --enable-decoder=smackvid,smackaud --enable-protocol=file \
    --enable-swscale --enable-swresample \
    && make -j"$jobs" && make install)
fi

# 2. Lua 5.5 with LuaFileSystem, LPeg and LuaSocket.
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
cflags="-O2 -fPIC -I$inc"
module_flags="-bundle -undefined dynamic_lookup"
# CMake's FindLua cannot read Lua 5.5's version macros: a wrapper header whose
# version lines it can read (as in build_linux_package.sh).
{
  echo '/* Wrapper for CMake FindLua; see scripts/multiplayer/build_macos_app.sh. */'
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
  cc $cflags $module_flags -o "$mods/lfs.so" luafilesystem/src/lfs.c
fi
if [[ ! -f "$mods/lpeg.so" ]]; then
  [[ -d lpeg ]] || git clone -q --depth 1 --branch v1.1.0 https://github.com/roberto-ieru/LPeg.git lpeg
  cc $cflags $module_flags -o "$mods/lpeg.so" lpeg/lp*.c
  cp lpeg/re.lua "$lmods/"
fi
if [[ ! -f "$mods/socket/core.so" ]]; then
  [[ -d luasocket ]] || git clone -q --depth 1 --branch v3.1.0 https://github.com/lunarmodules/luasocket.git
  make -C luasocket -j"$jobs" macosx LUAV=5.5 LUAINC_macosx="$inc" \
    MACOSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET"
  make -C luasocket install PLAT=macosx LUAV=5.5 prefix="$P" INSTALL_TOP_LDIR="$lmods" INSTALL_TOP_CDIR="$mods"
fi

# 3. CorsixTH, installed as an app bundle. Lua is linked statically, all of it
# (force_load), so the Lua modules above find every function they use in the
# program.
cmake -S "$src" -B "$work/build" -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH="$P;$brew_prefix" -DCMAKE_INSTALL_PREFIX="$work/stage" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DWITH_FIXUP_BUNDLE=OFF -DWITH_MOVIES=ON -DWITH_UPDATE_CHECK=OFF -DWITH_MIDI_DEVICE=OFF -DWITH_LUAROCKS=OFF \
  -DFETCH_SOUNDFONT=ON -DFETCH_UNICODE_FONT=ON -DWITH_FONT="" \
  -DLUA_INCLUDE_DIR="$P/include-cmake" -DLUA_LIBRARY="$P/lib/liblua.a" \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,-force_load,$P/lib/liblua.a"
cmake --build "$work/build" -j"$jobs"
rm -rf "$work/stage"
cmake --install "$work/build"

# 4. The app: libraries in Contents/Frameworks, Lua modules next to
# CorsixTH.lua, everything signed ad hoc.
pkg=$dist/CorsixTH-Multiplayer
app=$pkg/CorsixTH.app
rm -rf "$pkg"
mkdir -p "$pkg"
cp -R "$work/stage/CorsixTH.app" "$app"
res=$app/Contents/Resources
cp -R "$mods/." "$res/"
cp -R "$lmods/." "$res/"
dylibbundler -cd -of -b -x "$app/Contents/MacOS/CorsixTH" -d "$app/Contents/Frameworks/" \
  -p @executable_path/../Frameworks/ -s "$P/lib" -s "$brew_prefix/lib" < /dev/null
# Only the app's own library folder stays on the search path.
for rp in $(otool -l "$app/Contents/MacOS/CorsixTH" | awk '/LC_RPATH/ {getline; getline; print $2}'); do
  case "$rp" in @*) ;; *) install_name_tool -delete_rpath "$rp" "$app/Contents/MacOS/CorsixTH" ;; esac
done
# Nothing may point outside the app (except the system's own libraries).
leaks=$(find "$app" -type f \( -perm -u+x -o -name '*.dylib' -o -name '*.so' \) -print0 |
  xargs -0 otool -L 2>/dev/null | grep -E "$brew_prefix|$P|/usr/local" || true)
if [[ -n "$leaks" ]]; then
  echo "Libraries outside the app:"; echo "$leaks"; exit 1
fi
find "$app" -type f \( -name '*.dylib' -o -name '*.so' \) -print0 |
  xargs -0 -n1 codesign --force --sign - --timestamp=none
codesign --force --sign - --timestamp=none "$app"
codesign --verify --strict --verbose=2 "$app"

cat > "$pkg/README-MULTIPLAYER.txt" <<EOF
CorsixTH-Multiplayer test build (macOS, Apple Silicon, macOS 26 Tahoe or newer)
Commit $label of https://github.com/lbakyl/CorsixTH-Multiplayer

Move CorsixTH.app to Applications (or anywhere) and open it. The app is not
notarized by Apple: the first time macOS refuses to open it. Then open
System Settings > Privacy & Security, scroll down to the note about
CorsixTH and click Open Anyway (once). Alternatively, in Terminal:
  xattr -dr com.apple.quarantine /Applications/CorsixTH.app

The first start asks for your Theme Hospital folder (the game data is not
included). Settings and saves are in the hidden folder ~/.config/CorsixTH.

Everybody in a game must use a build of the same commit, on Windows, Linux
or macOS. Main menu > Multiplayer, server address (host:port) and your name.
Keep the game language English.

Full guide: docs/multiplayer/PLAYING.md in the repository.
CorsixTH is MIT licensed (LICENSE.txt). Theme Hospital is a trademark of
Electronic Arts; this build contains none of its data.
EOF
cp "$src/LICENSE.txt" "$pkg/" 2>/dev/null || true

zip=$dist/CorsixTH-Multiplayer-$label-macos-arm64.zip
rm -f "$zip"
(cd "$dist" && ditto -c -k --keepParent CorsixTH-Multiplayer "$zip")
echo "Bundled libraries:"; ls "$app/Contents/Frameworks" 2>/dev/null || true
echo "App: $app"
echo "Archive: $zip"
