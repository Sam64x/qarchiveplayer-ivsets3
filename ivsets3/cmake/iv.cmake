
macro(iv_version PACKAGE_VERSION )
    # message(STATUS "PACKAGE_VERSION: ${PACKAGE_VERSION}")
    set(BUILD_ID 0)
    if($ENV{BUILD_ID})
        set(BUILD_ID $ENV{BUILD_ID})
    endif()
    set(PROGRAM_VERSION ${PACKAGE_VERSION})
    string(REPLACE "." ";" VERSION_LIST ${PROGRAM_VERSION})
    list(GET VERSION_LIST 0 PROJECT_VERSION_MAJOR)
    list(GET VERSION_LIST 1 PROJECT_VERSION_MINOR)
    list(GET VERSION_LIST 2 PROJECT_VERSION_PATCH)    
    string(TIMESTAMP BUILD_TIME "%Y-%m-%d %H:%M:%S" UTC)
    string(TIMESTAMP BUILD_YEAR "%Y" UTC)
    find_package(Git)
    if(Git_FOUND)
      message(STATUS "${Git_EXECUTABLE} rev-parse --short HEAD")
      message(STATUS "WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}")
      execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT
        RESULT_VARIABLE STATUS
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )
  
      if(STATUS)
        set(GIT_COMMIT "unknown")
        message(STATUS "Failed to retrive git short hash")
      endif()

      execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_BRANCH
        RESULT_VARIABLE STATUS
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      if(STATUS)
        set(GIT_BRANCH "unknown")
        message(STATUS "Failed to retrive git branch")
      endif()

    else()
      set(GIT_COMMIT "unknown")
      message(STATUS "Git not found")
    endif()

    configure_file(cmake/version.h.in iv_version.h @ONLY) 
    if(WIN32)
      configure_file(cmake/version.rc.in iv_version.rc COPYONLY) 
      set(PROJECT_RC iv_version.rc)
    endif()

endmacro()

macro(iv_conan_init)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/conan.cmake")
      include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/conan.cmake)
    elseif(EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
      include(${CMAKE_BINARY_DIR}/conan.cmake)
    else()
        message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
        file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/0.18.1/conan.cmake"
                        "${CMAKE_BINARY_DIR}/conan.cmake"
                        TLS_VERIFY ON)
        include(${CMAKE_BINARY_DIR}/conan.cmake)
    endif()

    if(CONAN_EXPORTED) # in conan local cache
    else() # in user space
        conan_cmake_autodetect(settings)
        conan_cmake_install(PATH_OR_REFERENCE ${CMAKE_CURRENT_SOURCE_DIR} SETTINGS ${settings})
    endif()

    include(${CMAKE_CURRENT_BINARY_DIR}/conanbuildinfo.cmake)
    conan_basic_setup()
endmacro()

macro(iv_lib USER NAME )
  include(FetchContent)

  FetchContent_Declare(
    ${NAME}
    GIT_REPOSITORY https://iv.integra-s.com/git/${USER}/${NAME}.git
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/${NAME}
  )
  
#   add_subdirectory("${USERVER_ROOT_DIR}/${SPDLOG_PATH_SUFFIX}" "${CMAKE_BINARY_DIR}/${SPDLOG_PATH_SUFFIX}")
endmacro()

macro(iv_load DEP_LIST)
  FetchContent_MakeAvailable(${DEP_LIST})
endmacro()
