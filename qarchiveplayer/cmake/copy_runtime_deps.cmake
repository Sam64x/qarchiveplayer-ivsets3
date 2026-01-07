cmake_minimum_required(VERSION 3.15)

if(NOT DEFINED _TARGET_FILE)
  message(FATAL_ERROR "_TARGET_FILE is required")
endif()
if(NOT DEFINED _OUTPUT_DIR)
  message(FATAL_ERROR "_OUTPUT_DIR is required")
endif()

# Collect runtime dependencies for the plugin and copy them next to the DLL so
# qmlimport can load the module without missing-module errors.
file(GET_RUNTIME_DEPENDENCIES
    RESOLVED_DEPENDENCIES_VAR _resolved_deps
    UNRESOLVED_DEPENDENCIES_VAR _unresolved_deps
    EXECUTABLES "${_TARGET_FILE}"
    DIRECTORIES "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
)

foreach(_dep IN LISTS _resolved_deps)
  file(COPY "${_dep}" DESTINATION "${_OUTPUT_DIR}")
endforeach()

if(_unresolved_deps)
  message(WARNING "Unresolved runtime dependencies: ${_unresolved_deps}")
endif()
