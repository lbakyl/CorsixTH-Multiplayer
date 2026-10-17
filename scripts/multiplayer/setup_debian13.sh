#!/usr/bin/env bash
# Prepare a Debian 13 (trixie) machine to build and test CorsixTH multiplayer
# headlessly. Installs packages with sudo, builds SDL 3.4 and SDL3_mixer into
# $RUNTIME_ROOT/prefix (Debian 13 has SDL 3.2, which SDL3_mixer 3.2.4 cannot
# use), and writes $HOME/mp-env.sh with the variables the probe scripts need.
#
# Usage: bash scripts/multiplayer/setup_debian13.sh [GAME_DATA_DIR]
# Then:  . ~/mp-env.sh && cmake ... (see the end of this script)
set -euo pipefail
RUNTIME_ROOT=${RUNTIME_ROOT:-$HOME/corsixth-runtime}
PREFIX=$RUNTIME_ROOT/prefix
JOBS=$(nproc)

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  build-essential cmake ninja-build git unzip pkg-config \
  libfluidsynth-dev liblua5.4-dev lua5.4 lua-socket lua-filesystem lua-lpeg \
  lua-busted lua-check libzstd-dev libfreetype-dev libpng-dev zlib1g-dev \
  catch2 libcurl4-openssl-dev python3 python3-pytest iproute2

mkdir -p "$RUNTIME_ROOT/src" "$PREFIX"
cd "$RUNTIME_ROOT/src"
if [[ ! -f "$PREFIX/lib/libSDL3.so" ]]; then
  [[ -d SDL ]] || git clone --depth 1 --branch release-3.4.18 https://github.com/libsdl-org/SDL.git SDL
  cmake -S SDL -B SDL/build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" -DSDL_SHARED=ON -DSDL_STATIC=OFF \
    -DSDL_TESTS=OFF -DSDL_UNIX_CONSOLE_BUILD=ON
  cmake --build SDL/build -j"$JOBS"
  cmake --install SDL/build
fi
if [[ ! -f "$PREFIX/lib/libSDL3_mixer.so" ]]; then
  [[ -d SDL_mixer ]] || git clone --depth 1 --branch release-3.2.4 https://github.com/libsdl-org/SDL_mixer.git SDL_mixer
  cmake -S SDL_mixer -B SDL_mixer/build -G Ninja -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DSDLMIXER_TESTS=OFF -DSDLMIXER_EXAMPLES=OFF -DSDLMIXER_FLAC_LIBFLAC=OFF \
    -DSDLMIXER_GME=OFF -DSDLMIXER_MOD=OFF -DSDLMIXER_MP3_MPG123=OFF \
    -DSDLMIXER_OPUS=OFF -DSDLMIXER_VORBIS_VORBISFILE=OFF -DSDLMIXER_WAVPACK=OFF
  cmake --build SDL_mixer/build -j"$JOBS"
  cmake --install SDL_mixer/build
fi

# The probe scripts expect LuaSocket in a LuaRocks-style tree.
mkdir -p "$HOME/luasocket-tree/lib/lua" "$HOME/luasocket-tree/share/lua"
ln -sfn /usr/lib/x86_64-linux-gnu/lua/5.4 "$HOME/luasocket-tree/lib/lua/5.4"
ln -sfn /usr/share/lua/5.4 "$HOME/luasocket-tree/share/lua/5.4"

checkout=$(cd "$(dirname "$0")/../.." && pwd)
cat > "$HOME/mp-env.sh" <<EOF
export PREFIX=$PREFIX
export LD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/lib64
export LUASOCKET_TREE=$HOME/luasocket-tree
export THDATA=${1:-\$HOME/thdata/themehos}
export BIN=$checkout/build/CorsixTH/corsix-th
EOF
echo "Wrote $HOME/mp-env.sh. Build with:"
echo "  . ~/mp-env.sh; cd $checkout"
echo "  cmake -S . -B build -G Ninja -DCMAKE_PREFIX_PATH=\$PREFIX -DCMAKE_BUILD_TYPE=RelWithDebInfo \\"
echo "    -DUSE_SOURCE_DATADIRS=ON -DENABLE_UNIT_TESTS=ON -DWITH_MOVIES=OFF -DWITH_UPDATE_CHECK=OFF -DWITH_MIDI_DEVICE=OFF"
echo "  cmake --build build -j$JOBS"
