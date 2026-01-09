cmake_minimum_required(VERSION 3.15)

project(ivsets3 LANGUAGES CXX)
include(cmake/iv.cmake)
iv_conan_init()
file(READ "version.txt" PROJECT_VERSION)

iv_version(${PROJECT_VERSION})
set(IVOUTPUT_RELATIVE_DIRECTORY qtplugins/iv/sets/sets3)


file(GLOB_RECURSE PROJECT_SRC 
    src/*.h
    src/*.cpp
)
file (GLOB_RECURSE QML_SRC
    ActiveExportsButton.qml
    qml/*.qml
    qml/client/*.qml
    qmldir
)
set(FILETOCOPY ${QML_SRC})

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
#set(CMAKE_AUTORCC ON)
#set(CMAKE_AUTOUIC ON)

add_library(${PROJECT_NAME} SHARED ${PROJECT_SRC} ${QML_SRC} ${PROJECT_RC})
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

target_include_directories(${PROJECT_NAME} PRIVATE
    src
    qml
)

set_target_properties(${PROJECT_NAME} PROPERTIES
  POSITION_INDEPENDENT_CODE ON
  INSTALL_RPATH "\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/lib"
)

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_17)
target_compile_definitions(${PROJECT_NAME} PRIVATE 
    BUILD_DLL BUILD_PLUGIN
    $<$<CXX_COMPILER_ID:MSVC>:_CRT_SECURE_NO_WARNINGS;NOMINMAX>
)
target_compile_options(${PROJECT_NAME} PRIVATE 
    $<$<CXX_COMPILER_ID:MSVC>:/MP;/Z7>
    $<$<CXX_COMPILER_ID:GNU>:-fvisibility=hidden;-fno-gnu-unique>
)
find_package(Qt5 COMPONENTS Widgets Qml Quick REQUIRED)
target_link_libraries(${PROJECT_NAME} PUBLIC 
    ${CONAN_LIBS} 
	Qt5::Core 
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::Widgets
    $<$<CXX_COMPILER_ID:GNU>:-Wno-unused-variable>
    $<$<CXX_COMPILER_ID:GNU>:-Wreturn-type>
    $<$<CXX_COMPILER_ID:GNU>:pthread>
    $<$<CXX_COMPILER_ID:GNU>:dl>
    $<$<CXX_COMPILER_ID:GNU>:rt>
    $<$<CXX_COMPILER_ID:GNU>:-Wl,-E,--no-undefined>
)

message("Copying qmldir, *.js and *.qml to build directory....")
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -E copy ${FILETOCOPY} $<TARGET_FILE_DIR:${PROJECT_NAME}>)
if (NOT CMAKE_INSTALL_BINDIR)
  set(CMAKE_INSTALL_BINDIR ${CMAKE_INSTALL_PREFIX})
endif()

install(TARGETS ${PROJECT_NAME} 
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}/${IVOUTPUT_RELATIVE_DIRECTORY}
    LIBRARY DESTINATION ${CMAKE_INSTALL_BINDIR}/${IVOUTPUT_RELATIVE_DIRECTORY}
)
install(FILES ${FILETOCOPY} DESTINATION ${CMAKE_INSTALL_BINDIR}/${IVOUTPUT_RELATIVE_DIRECTORY})
