cmake_minimum_required(VERSION 3.15)

project(qarchiveplayer LANGUAGES CXX)

include(cmake/iv.cmake)
iv_conan_init()
file(READ "version.txt" PROJECT_VERSION)
iv_version(${PROJECT_VERSION})

set(IVOUTPUT_RELATIVE_DIRECTORY qtplugins/iv/viewers/archiveplayer)
set(FILETOCOPY
    "${CMAKE_SOURCE_DIR}/other/qmldir"
    "${CMAKE_SOURCE_DIR}/qml/ArchiveMarker.qml"
    "${CMAKE_SOURCE_DIR}/qml/EventButtons.qml"
    "${CMAKE_SOURCE_DIR}/qml/ExportSettingsButton.qml"
    "${CMAKE_SOURCE_DIR}/qml/FrameRewindButtons.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVArchivePlayer.qml"
    "${CMAKE_SOURCE_DIR}/qml/qmainexport.qml"
    "${CMAKE_SOURCE_DIR}/qml/FillRect.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVButtonPaneArc.qml"
    "${CMAKE_SOURCE_DIR}/qml/FillRect2.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVArchiveContextMenu.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVArcSliderControl.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVButtonTopPanel.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVArchivePlayerMin.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVArc_slider_new2.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVSeparator.qml"
    "${CMAKE_SOURCE_DIR}/qml/IVSourceListView.qml"
    "${CMAKE_SOURCE_DIR}/qml/SettingsButton.qml"
    "${CMAKE_SOURCE_DIR}/qml/FrameTimeButton.qml"
    "${CMAKE_SOURCE_DIR}/qml/IntervalScaleButton.qml"
    "${CMAKE_SOURCE_DIR}/qml/LabeledCalendarButton.qml"
    "${CMAKE_SOURCE_DIR}/qml/CursorRect.qml"
    "${CMAKE_SOURCE_DIR}/qml/ScreenshotButton.qml"
    "${CMAKE_SOURCE_DIR}/qml/SyncUploader.qml"
    "${CMAKE_SOURCE_DIR}/qml/SoundSlider.qml"
    "${CMAKE_SOURCE_DIR}/qml/PlayerControls.qml"
    "${CMAKE_SOURCE_DIR}/other/dataloader.js"
    "${CMAKE_SOURCE_DIR}/other/pause.svg"
    "${CMAKE_SOURCE_DIR}/other/play.svg"
    "${CMAKE_SOURCE_DIR}/other/menu171107.png"
    "${CMAKE_SOURCE_DIR}/other/stop.svg"
)

file(GLOB_RECURSE PROJECT_SRC
    src/*.h
    src/*.cpp
    qml/*.qml
    other/*.js
    other/qmldir
)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

add_library(${PROJECT_NAME} SHARED ${PROJECT_SRC})
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/qml
    ${CMAKE_SOURCE_DIR}/other
)

set_target_properties(${PROJECT_NAME} PROPERTIES
  POSITION_INDEPENDENT_CODE ON
  INSTALL_RPATH "\$ORIGIN:\$ORIGIN/../lib:\$ORIGIN/lib:\$ORIGIN/../../../../qt:\$ORIGIN/../../../../qt/lib"
)

# set(FFMPEG_DIR "C:/ffmpeg")
# set(FFMPEG_INCLUDE_DIR "${FFMPEG_DIR}/include")
# set(FFMPEG_LIB_DIR     "${FFMPEG_DIR}/lib")
# set(FFMPEG_BIN_DIR     "${FFMPEG_DIR}/bin")

# find_library(AVCODEC_LIB  NAMES avcodec  avcodec-61 avcodec-60 avcodec-59 HINTS "${FFMPEG_LIB_DIR}")
# find_library(AVFORMAT_LIB NAMES avformat avformat-61 avformat-60 avformat-59 HINTS "${FFMPEG_LIB_DIR}")
# find_library(AVUTIL_LIB   NAMES avutil   avutil-59   avutil-58   avutil-57   HINTS "${FFMPEG_LIB_DIR}")
# find_library(SWSCALE_LIB  NAMES swscale  swscale-8   swscale-7   swscale-6   HINTS "${FFMPEG_LIB_DIR}")

# foreach(_lib AVCODEC_LIB AVFORMAT_LIB AVUTIL_LIB SWSCALE_LIB)
#   if(NOT ${_lib})
#     message(FATAL_ERROR "FFmpeg library ${_lib} not found. Expected in: ${FFMPEG_LIB_DIR}")
#   endif()
# endforeach()

# if(NOT EXISTS "${FFMPEG_INCLUDE_DIR}")
#   message(FATAL_ERROR "FFmpeg include dir not found: ${FFMPEG_INCLUDE_DIR}")
# endif()

# target_include_directories(${PROJECT_NAME} PRIVATE "${FFMPEG_INCLUDE_DIR}")
# link_directories("${FFMPEG_LIB_DIR}")

find_package(Qt5 COMPONENTS Widgets Qml Quick WebSockets Concurrent Gui Core Sql REQUIRED)


target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_17)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    BUILD_DLL BUILD_PLUGIN
    $<$<CXX_COMPILER_ID:MSVC>:_CRT_SECURE_NO_WARNINGS;NOMINMAX>
)

target_compile_options(${PROJECT_NAME} PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/MP;/Z7>
    $<$<CXX_COMPILER_ID:GNU>:-fvisibility=hidden;-fno-gnu-unique>
)

target_link_libraries(${PROJECT_NAME} PRIVATE
#    ${AVFORMAT_LIB}
#    ${AVCODEC_LIB}
#    ${SWSCALE_LIB}
#    ${AVUTIL_LIB}
${CONAN_LIBS}
    Qt5::WebSockets
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::Widgets
    Qt5::Concurrent
    Qt5::Sql
    $<$<AND:$<CXX_COMPILER_ID:GNU>,$<NOT:$<PLATFORM_ID:Windows>>>:-Wno-unused-variable>
    $<$<AND:$<CXX_COMPILER_ID:GNU>,$<NOT:$<PLATFORM_ID:Windows>>>:-Wreturn-type>
    $<$<AND:$<CXX_COMPILER_ID:GNU>,$<NOT:$<PLATFORM_ID:Windows>>>:pthread>
    $<$<AND:$<CXX_COMPILER_ID:GNU>,$<NOT:$<PLATFORM_ID:Windows>>>:dl>
    $<$<AND:$<CXX_COMPILER_ID:GNU>,$<NOT:$<PLATFORM_ID:Windows>>>:rt>
    $<$<AND:$<CXX_COMPILER_ID:GNU>,$<NOT:$<PLATFORM_ID:Windows>>>:-Wl,-E,--no-undefined>
    $<$<PLATFORM_ID:Windows>:ws2_32>
    $<$<PLATFORM_ID:Windows>:bcrypt>
)


message("Copying qmldir, *.js and *.qml to build directory....")
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${FILETOCOPY} $<TARGET_FILE_DIR:${PROJECT_NAME}>
)

if(WIN32 AND EXISTS "${FFMPEG_BIN_DIR}")
  add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E echo "Copying FFmpeg DLLs from ${FFMPEG_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:${PROJECT_NAME}>/../lib"
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${FFMPEG_BIN_DIR}" "$<TARGET_FILE_DIR:${PROJECT_NAME}>/../lib"
  )
endif()

if (NOT CMAKE_INSTALL_BINDIR)
  set(CMAKE_INSTALL_BINDIR ${CMAKE_INSTALL_PREFIX})
endif()

install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}/qtplugins/iv/viewers/archiveplayer
    LIBRARY DESTINATION ${CMAKE_INSTALL_BINDIR}/qtplugins/iv/viewers/archiveplayer
)

install(FILES ${FILETOCOPY}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/${IVOUTPUT_RELATIVE_DIRECTORY}
)
