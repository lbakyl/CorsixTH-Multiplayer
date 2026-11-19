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

#include <zlib.h>

#include <catch2/catch_test_macros.hpp>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "th_packs.h"

namespace {

const uint8_t* bytes(std::string_view text) {
  return reinterpret_cast<const uint8_t*>(text.data());
}

}  // namespace

TEST_CASE("Ed25519 test vector of RFC 8032", "[packs]") {
  uint8_t key[32];
  uint8_t signature[64];
  REQUIRE(th::packs::parse_hex(
      "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c", key,
      sizeof(key)));
  REQUIRE(th::packs::parse_hex(
      "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da"
      "085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00",
      signature, sizeof(signature)));
  const uint8_t message[] = {0x72};
  CHECK(th::packs::signature_valid_for(key, message, 1, signature));
  const uint8_t other[] = {0x73};
  CHECK_FALSE(th::packs::signature_valid_for(key, other, 1, signature));
  signature[10] ^= 1;
  CHECK_FALSE(th::packs::signature_valid_for(key, message, 1, signature));
}

TEST_CASE("the release key's signature is taken, others are not", "[packs]") {
  std::string_view message = "OpenTH game pack test";
  uint8_t signature[64];
  REQUIRE(th::packs::parse_hex(
      "2d6586b6b846474dcbaec827fe7e31f850c995bb0109ff8278632b2507a6ba99"
      "c689258816c8efb156ebffbe3f0a68fa3ce7ab0e2ca06c1187c9513d13f53a0a",
      signature, sizeof(signature)));
  CHECK(th::packs::signature_valid(bytes(message), message.size(), signature));
  std::string_view changed = "OpenTH game pack tesT";
  CHECK_FALSE(
      th::packs::signature_valid(bytes(changed), changed.size(), signature));
}

TEST_CASE("hexadecimal of the wrong length or with other letters", "[packs]") {
  uint8_t out[2];
  CHECK(th::packs::parse_hex("0aFf", out, 2));
  CHECK(out[0] == 0x0a);
  CHECK(out[1] == 0xff);
  CHECK_FALSE(th::packs::parse_hex("0aF", out, 2));
  CHECK_FALSE(th::packs::parse_hex("0aFg", out, 2));
}

TEST_CASE("inflate a pack, within its size limit only", "[packs]") {
  std::string text(100000, 'x');
  for (std::size_t i = 0; i < text.size(); i += 7) text[i] = 'y';
  uLongf packed_size = compressBound(static_cast<uLong>(text.size()));
  std::vector<uint8_t> packed(packed_size);
  REQUIRE(compress(packed.data(), &packed_size, bytes(text),
                   static_cast<uLong>(text.size())) == Z_OK);
  packed.resize(packed_size);

  std::vector<uint8_t> out;
  REQUIRE(th::packs::inflate(packed.data(), packed.size(), text.size(), out));
  CHECK(std::string(out.begin(), out.end()) == text);

  CHECK_FALSE(
      th::packs::inflate(packed.data(), packed.size(), text.size() - 1, out));
  CHECK(out.empty());
  CHECK_FALSE(th::packs::inflate(packed.data(), packed.size() / 2,
                                 text.size(), out));
  CHECK_FALSE(th::packs::inflate(bytes("not zlib"), 8, 100, out));
}
