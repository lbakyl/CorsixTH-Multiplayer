/*
Copyright (c) 2026 CorsixTH-Multiplayer contributors

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

#ifndef CORSIX_TH_TH_PACKS_H_
#define CORSIX_TH_TH_PACKS_H_

#include <cstddef>
#include <cstdint>
#include <string_view>
#include <vector>

//! Game packs: the game's scripts and small data files of one build, which a
//! multiplayer server sends to a player of another build so the game can
//! switch to the server's build (CorsixTH/Lua/mp_pack.lua). A pack runs code,
//! so the game takes only packs signed with an OpenTH release key.
namespace th::packs {

//! The engine's level for game packs. A pack names the lowest level it needs;
//! raise this when the scripts come to need something new from the engine.
constexpr int engine_level = 1;

//! Read `out_size` bytes written as hexadecimal digits (2 per byte).
bool parse_hex(std::string_view hex, uint8_t* out, std::size_t out_size);

//! Whether `signature` is the Ed25519 signature of the data by `key`.
bool signature_valid_for(const uint8_t key[32], const uint8_t* data,
                         std::size_t size, const uint8_t signature[64]);

//! Whether `signature` is the signature of the data by an OpenTH release key.
bool signature_valid(const uint8_t* data, std::size_t size,
                     const uint8_t signature[64]);

//! Inflate zlib data into `out`; false if it is not valid zlib data or would
//! be larger than `max_size`.
bool inflate(const uint8_t* data, std::size_t size, std::size_t max_size,
             std::vector<uint8_t>& out);

}  // namespace th::packs

#endif  // CORSIX_TH_TH_PACKS_H_
