#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers.hpp>
#include <catch2/matchers/catch_matchers_string.hpp>
#include <string>

#include "th_strings.h"

TEST_CASE("skip whitespace", "[skip_utf8_whitespace]") {
  const char* str = " \t \n  1234";
  const char* end = str + 10;

  skip_utf8_whitespace(str, end);

  REQUIRE_THAT(str, Catch::Matchers::Equals("1234"));
}

TEST_CASE("leave non-whitespace", "[skip_utf8_whitespace]") {
  const char* str = "1234    ";
  const char* end = str + 8;

  skip_utf8_whitespace(str, end);

  REQUIRE_THAT(str, Catch::Matchers::Equals("1234    "));
}

TEST_CASE("remove entire string of whitespace", "[skip_utf8_whitespace]") {
  const char* str = "   \t  \n   ";
  const char* end = str + 10;

  skip_utf8_whitespace(str, end);

  REQUIRE_THAT(str, Catch::Matchers::Equals(""));
}

TEST_CASE("Russian letters in the Russian game's font", "[unicode_to_codepage_mik]") {
  REQUIRE(unicode_to_codepage_mik('A') == 'A');
  REQUIRE(unicode_to_codepage_mik(0x0410) == 0x80);  // Cyrillic capital A
  REQUIRE(unicode_to_codepage_mik(0x0435) == 0xA5);  // Cyrillic small ye
}

TEST_CASE("letters and signs MIK lacks drawn as the nearest it has",
          "[unicode_to_codepage_mik]") {
  REQUIRE(unicode_to_codepage_mik(0x0401) == 0x85);  // Yo as Ye
  REQUIRE(unicode_to_codepage_mik(0x0451) == 0xA5);  // yo as ye
  REQUIRE(unicode_to_codepage_mik(0x00AB) == '"');   // guillemets
  REQUIRE(unicode_to_codepage_mik(0x00BB) == '"');
  REQUIRE(unicode_to_codepage_mik(0x2014) == '-');  // em dash
  REQUIRE(unicode_to_codepage_mik(0x4E2D) == '?');  // a Chinese letter
}
