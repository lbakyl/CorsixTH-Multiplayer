# Monocypher 4.0.2 (https://monocypher.org), BSD-2-Clause or CC0 (LICENCE.md):
# only its Ed25519 signature check is used, for signed game packs
# (CorsixTH/Src/th_packs.cpp).
project(MonocypherLib C)

add_library(
  MonocypherLib
  STATIC
  ${CMAKE_CURRENT_SOURCE_DIR}/monocypher.c
  ${CMAKE_CURRENT_SOURCE_DIR}/monocypher.h
  ${CMAKE_CURRENT_SOURCE_DIR}/monocypher-ed25519.c
  ${CMAKE_CURRENT_SOURCE_DIR}/monocypher-ed25519.h
)

target_include_directories(MonocypherLib INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
