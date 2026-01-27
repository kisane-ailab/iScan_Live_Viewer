cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# =============================================================================
# Check for Native Video Renderer Dependencies
# =============================================================================
set(TURBOJPEG_DIR "${CMAKE_SOURCE_DIR}/libs/libjpeg-turbo")
set(ZMQ_DIR "${CMAKE_SOURCE_DIR}/libs/libzmq")

set(NATIVE_VIDEO_AVAILABLE FALSE)
if(EXISTS "${TURBOJPEG_DIR}/include/turbojpeg.h" AND EXISTS "${ZMQ_DIR}/include/zmq.h")
  set(NATIVE_VIDEO_AVAILABLE TRUE)
  message(STATUS "Native Video Renderer: ENABLED (libjpeg-turbo and ZeroMQ found)")
else()
  message(WARNING "Native Video Renderer: DISABLED (missing dependencies)")
  if(NOT EXISTS "${TURBOJPEG_DIR}/include/turbojpeg.h")
    message(WARNING "  - libjpeg-turbo not found at ${TURBOJPEG_DIR}")
  endif()
  if(NOT EXISTS "${ZMQ_DIR}/include/zmq.h")
    message(WARNING "  - ZeroMQ not found at ${ZMQ_DIR}")
  endif()
  message(WARNING "  Run windows/libs/setup_libs.ps1 to install dependencies")
endif()

# =============================================================================
# Application Target
# =============================================================================

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
if(NATIVE_VIDEO_AVAILABLE)
  add_executable(${BINARY_NAME} WIN32
    "flutter_window.cpp"
    "main.cpp"
    "utils.cpp"
    "win32_window.cpp"
    "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
    "Runner.rc"
    "runner.exe.manifest"
    # Native Video Renderer (Pigeon + libjpeg-turbo + ZMQ)
    "native_video_api.g.cpp"
    "native_video_handler.cpp"
  )
else()
  add_executable(${BINARY_NAME} WIN32
    "flutter_window.cpp"
    "main.cpp"
    "utils.cpp"
    "win32_window.cpp"
    "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
    "Runner.rc"
    "runner.exe.manifest"
  )
endif()

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Native Video Renderer preprocessor definition
if(NATIVE_VIDEO_AVAILABLE)
  target_compile_definitions(${BINARY_NAME} PRIVATE "NATIVE_VIDEO_ENABLED")
endif()

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
if(NATIVE_VIDEO_AVAILABLE)
  target_link_libraries(${BINARY_NAME} PRIVATE flutter_wrapper_plugin)
endif()
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_link_libraries(${BINARY_NAME} PRIVATE "winhttp.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# =============================================================================
# Native Video Renderer Dependencies (when available)
# =============================================================================
if(NATIVE_VIDEO_AVAILABLE)
  # libjpeg-turbo (JPEG decoding with SIMD acceleration)
  target_include_directories(${BINARY_NAME} PRIVATE "${TURBOJPEG_DIR}/include")
  target_link_libraries(${BINARY_NAME} PRIVATE "${TURBOJPEG_DIR}/lib/turbojpeg.lib")

  # ZeroMQ (messaging library)
  target_include_directories(${BINARY_NAME} PRIVATE "${ZMQ_DIR}/include")
  file(GLOB ZMQ_LIB_FILES "${ZMQ_DIR}/lib/*.lib")
  if(ZMQ_LIB_FILES)
    target_link_libraries(${BINARY_NAME} PRIVATE ${ZMQ_LIB_FILES})
  endif()

  # Copy DLLs to output directory
  set(NATIVE_DLLS
    "${TURBOJPEG_DIR}/bin/turbojpeg.dll"
    "${TURBOJPEG_DIR}/bin/jpeg62.dll"
  )
  file(GLOB ZMQ_DLL_FILES "${ZMQ_DIR}/bin/*.dll")
  list(APPEND NATIVE_DLLS ${ZMQ_DLL_FILES})

  foreach(DLL_FILE ${NATIVE_DLLS})
    if(EXISTS "${DLL_FILE}")
      add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
          "${DLL_FILE}"
          "$<TARGET_FILE_DIR:${BINARY_NAME}>"
        COMMENT "Copying ${DLL_FILE}"
      )
    endif()
  endforeach()
endif()

# =============================================================================

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
