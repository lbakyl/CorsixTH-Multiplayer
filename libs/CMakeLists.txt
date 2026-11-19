add_subdirectory(rnc)
add_subdirectory(monocypher)

if(SEARCH_LOCAL_DATADIRS)
  add_subdirectory(whereami)
endif()
