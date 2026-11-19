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

#include "th_packs.h"

#include <zlib.h>

#include <array>

#include "monocypher-ed25519.h"

namespace th::packs {

namespace {

// The public keys of the OpenTH release signing keys. The private key never
// leaves the release maker's computer; a new key is added here (keeping the
// old one while its packs are in use).
constexpr std::array<std::string_view, 1> release_keys{
    "68d71994b3cf106bb3170ebc2c55a00e7e390355e8a19a57442cec384f8a9f16",
};

int hex_digit(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

}  // namespace

bool parse_hex(std::string_view hex, uint8_t* out, std::size_t out_size) {
  if (hex.size() != out_size * 2) return false;
  for (std::size_t i = 0; i < out_size; ++i) {
    int high = hex_digit(hex[2 * i]);
    int low = hex_digit(hex[2 * i + 1]);
    if (high < 0 || low < 0) return false;
    out[i] = static_cast<uint8_t>(high * 16 + low);
  }
  return true;
}

bool signature_valid_for(const uint8_t key[32], const uint8_t* data,
                         std::size_t size, const uint8_t signature[64]) {
  return crypto_ed25519_check(signature, key, data, size) == 0;
}

bool signature_valid(const uint8_t* data, std::size_t size,
                     const uint8_t signature[64]) {
  for (std::string_view hex : release_keys) {
    uint8_t key[32];
    if (parse_hex(hex, key, sizeof(key)) &&
        signature_valid_for(key, data, size, signature)) {
      return true;
    }
  }
  return false;
}

bool inflate(const uint8_t* data, std::size_t size, std::size_t max_size,
             std::vector<uint8_t>& out) {
  out.clear();
  z_stream stream{};
  if (inflateInit(&stream) != Z_OK) return false;
  stream.next_in = const_cast<Bytef*>(data);
  stream.avail_in = static_cast<uInt>(size);
  if (stream.avail_in != size) {  // (more than zlib takes at once)
    inflateEnd(&stream);
    return false;
  }
  std::array<uint8_t, 64 * 1024> buffer{};
  int result = Z_OK;
  while (result == Z_OK) {
    stream.next_out = buffer.data();
    stream.avail_out = static_cast<uInt>(buffer.size());
    result = ::inflate(&stream, Z_NO_FLUSH);
    if (result != Z_OK && result != Z_STREAM_END) break;
    std::size_t produced = buffer.size() - stream.avail_out;
    if (out.size() + produced > max_size) {
      result = Z_MEM_ERROR;
      break;
    }
    out.insert(out.end(), buffer.data(), buffer.data() + produced);
    if (result == Z_OK && produced == 0 && stream.avail_in == 0) {
      result = Z_DATA_ERROR;  // (the data ended before the stream did)
    }
  }
  inflateEnd(&stream);
  if (result != Z_STREAM_END) {
    out.clear();
    return false;
  }
  return true;
}

}  // namespace th::packs
