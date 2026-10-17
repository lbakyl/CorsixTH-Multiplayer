# Experimental multiplayer: Linux runtime baseline

## Status and scope

Baseline commit: `5e8655e2484b24c2776b8b036d55329338e6d121`.
The executable reports `v0.70.1-dev269`, not the official Windows release
`0.70.1` used for the initial manual test. Do not mix these builds in future
multiplayer tests.

This change adds a diagnostic runner and these notes. It does **not** add
networking, deterministic lockstep, multiplayer commands, or new gameplay.
No game assets or generated saves are included. Supply legally obtained Theme
Hospital data locally; do not upload it to GitHub, public CI artifacts, or logs.

## Verified results

Tested on x86-64 Amazon Linux 2023, GCC 11.5, CMake 3.22.2, Lua 5.4.4:

- Unmodified game engine compiled successfully.
- CTest: 8/8 tests passed.
- Busted 2.3.0: 117 successes, 0 failures, 0 errors.
- SDL dummy-video / software-renderer smoke test loaded campaign level 1,
  advanced 600 application callbacks, wrote a nonempty save, reloaded it with
  the same game date, advanced another 120 callbacks, and rendered a frame.
- At 600 callbacks the game date was `1-01-05T00` in the observed run. The
  harness checks date advancement, not this exact date or cross-run equality.
- Rendering changed `math.randomdump()` in the diagnostic. This confirms that
  rendering and gameplay currently share a random stream.

The smoke scenario has no player-built hospital or command script. It is a
startup, time-advancement, rendering and save/load check, not evidence of
long-term stability, realistic hospital workloads or cross-process determinism.
Audio and movies are disabled. Missing/placeholder media in the supplied data
has not been repaired; passing this check does not certify a complete install.

## Reproduce the Linux build

The following commands describe the tested dependency setup. They install
packages on the build machine and build third-party sources into an isolated
prefix, not into the checkout. The source directory names below must be new;
keep existing work intact. Approximately two build workers were used.

```bash
sudo dnf install -y gcc gcc-c++ make cmake ninja-build pkgconf-pkg-config \
  lua lua-devel lua-filesystem lua-lpeg freetype-devel zlib-devel \
  libpng-devel libzstd-devel glib2-devel

# Choose a location outside the CorsixTH checkout.
export RUNTIME_ROOT="$HOME/corsixth-runtime"
mkdir -p "$RUNTIME_ROOT/src" "$RUNTIME_ROOT/prefix"
export PREFIX="$RUNTIME_ROOT/prefix"
export PKG_CONFIG_PATH="$PREFIX/lib64/pkgconfig:$PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
cd "$RUNTIME_ROOT/src"

git clone --depth 1 --branch release-3.4.18 https://github.com/libsdl-org/SDL.git SDL
cmake -S SDL -B SDL/build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" -DSDL_SHARED=ON -DSDL_STATIC=OFF \
  -DSDL_TESTS=OFF -DSDL_UNIX_CONSOLE_BUILD=ON
cmake --build SDL/build -j2
cmake --install SDL/build

git clone --depth 1 --branch v2.4.8 https://github.com/FluidSynth/fluidsynth.git fluidsynth
cmake -S fluidsynth -B fluidsynth/build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -Denable-alsa=OFF -Denable-pulseaudio=OFF -Denable-jack=OFF \
  -Denable-portaudio=OFF -Denable-pipewire=OFF -Denable-dbus=OFF \
  -Denable-ladspa=OFF -Denable-libsndfile=OFF -Denable-readline=OFF \
  -Denable-sdl2=OFF
cmake --build fluidsynth/build -j2
cmake --install fluidsynth/build

git clone --depth 1 --branch release-3.2.4 https://github.com/libsdl-org/SDL_mixer.git SDL_mixer
cmake -S SDL_mixer -B SDL_mixer/build -G Ninja \
  -DCMAKE_PREFIX_PATH="$PREFIX" -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release -DSDLMIXER_TESTS=OFF -DSDLMIXER_EXAMPLES=OFF \
  -DSDLMIXER_FLAC_LIBFLAC=OFF -DSDLMIXER_GME=OFF -DSDLMIXER_MOD=OFF \
  -DSDLMIXER_MP3_MPG123=OFF -DSDLMIXER_OPUS=OFF \
  -DSDLMIXER_VORBIS_VORBISFILE=OFF -DSDLMIXER_WAVPACK=OFF
cmake --build SDL_mixer/build -j2
cmake --install SDL_mixer/build

# The distribution's zstd development package lacks the CMake package config
# required by this checkout, so build upstream zstd without changing game CMake.
git clone --depth 1 --branch v1.5.7 https://github.com/facebook/zstd.git zstd
cmake -S zstd/build/cmake -B zstd/build/local -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF
cmake --build zstd/build/local -j2
cmake --install zstd/build/local
```

From the CorsixTH checkout:

```bash
cmake -S . -B build/linux-runtime -G Ninja \
  -DCMAKE_PREFIX_PATH="$PREFIX" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DUSE_SOURCE_DATADIRS=ON -DENABLE_UNIT_TESTS=ON -DFETCH_CATCH2=ON \
  -DWITH_MOVIES=OFF -DWITH_UPDATE_CHECK=OFF -DWITH_MIDI_DEVICE=OFF
cmake --build build/linux-runtime -j2
ctest --test-dir build/linux-runtime --output-on-failure
```

Catch2 is fetched at the upstream-configured `v3.8.1`. Lua's `lfs` and `lpeg`
modules are loaded at runtime. This is a headless test build, not an interactive
desktop distribution: window-system and audio backends depend on the host's
installed headers/libraries. Movies, update checking, and hardware MIDI output
are intentionally disabled; dependency codec choices above are not production
packaging recommendations.

For Lua tests, install Busted for the same Lua version. In the observed setup,
LuaRocks `v3.12.2` was built from source using `./configure --prefix="$PREFIX"
--lua-version=5.4 --with-lua-include=/usr/include`, then `make` and `make install`.

```bash
"$PREFIX/bin/luarocks" --tree="$RUNTIME_ROOT/rocks" install busted 2.3.0
# Run these commands in the checkout:
eval "$("$PREFIX/bin/luarocks" --tree="$RUNTIME_ROOT/rocks" path)"
"$RUNTIME_ROOT/rocks/bin/busted" --verbose --directory=CorsixTH/Luatest
```

## Run the diagnostic

Requires bash, Python 3, GNU timeout, realpath, the binary and local game data.
The runner uses a new temporary directory by default. An optional third argument
specifies a **new** output directory; an existing directory is refused. Output
must be outside the checkout. Keep the generated save private.

```bash
# Optional font override, if this font exists on the test machine:
export CORSIXTH_SMOKE_FONT=/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf
bash scripts/multiplayer/run_headless_smoke.sh \
  build/linux-runtime/CorsixTH/corsix-th /path/to/ThemeHospital
```

The runner sets dummy video/audio and software rendering, disables game audio
and movies through a private config, and limits execution to 60 seconds. A pass
requires both exit code zero and `SMOKE: PASS` in its log. It supplies a fallback
USER because upstream player-name initialization assumes USER or USERNAME is set.
It deliberately exits the process after the diagnostic rather than entering the
interactive main loop, so it does not test normal shutdown or SDL event polling.

## Architecture findings and next development step

- `Src/lua_sdl.h` and `Src/sdl_core.cpp`: SDL generates timer events at about
  18 ms intervals. The main loop coalesces tick events within an event-drain pass.
  `App:onTick` in `Lua/app.lua` calls `World:onTick` and then UI ticks, except
  during movies. A future network scheduler must define authoritative simulation
  steps explicitly rather than equating wall-clock events on two PCs.
- `Lua/world.lua`: Normal speed advances one game hour per three callbacks;
  pause sets hours-per-tick to zero but leaves UI callbacks running. Modal
  windows and local speed controls can change pause/speed state. These need a
  shared policy and command boundary for co-build.
- `Src/main.cpp` and `Src/random.c`: the engine replaces Lua math.random with
  MT19937. `math.randomdump()` and string-form `math.randomseed()` already export
  and restore its state. `Lua/persistance.lua` saves that state today. We do not
  need to invent RNG-state persistence from scratch.
- `GameUI:draw` in `Lua/game_ui.lua` consumes two shared random values for screen
  shake, even when its intensity is zero. Different rendering schedules can
  therefore change gameplay randomness. Audio also uses this random stream.
- Array traversal is common in the main entity loop, but mutation- and
  RNG-consuming `pairs` loops require targeted auditing. Not every pairs loop
  is harmful or needs rewriting.
- Saves include UI, map, world and RNG. `Src/persist_lua.cpp` traverses tables
  with lua_next, so compressed save bytes are not a canonical gameplay hash.
  Load hooks and UI reconstruction also need examination before using saves
  as network snapshots.
- The next experiment should compare a small ordered gameplay projection and
  RNG state at explicit simulation boundaries across independent processes.
  Start by varying rendering frequency to reproduce the confirmed shared-RNG
  issue, then separate cosmetic randomness without changing gameplay semantics.
  Full lockstep, resync, command conflict handling and cross-platform parity are
  subsequent work, not features of this baseline.

## Windows CI

`.github/workflows/Windows.yml` already builds the default `win-x64-rel` preset,
runs CTest, installs into `artifact/`, and uploads a CorsixTH artifact. It runs on
push and pull request. No workflow modification is needed merely to get a
Windows download. Whether a particular fork run succeeds must be checked on
GitHub; the repository settings screenshot alone is not a successful build.
The asset-dependent smoke runner must not be wired to public CI with private
game data.
