# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "baydev_hifi")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.baydev.baydev_hifi")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# ==============================================================================
# Auto-Bundle Audio Runtime Shared Libraries (FLAC, Vorbis, Ogg, Opus)
# Guarantees 100% portable, relocatable standalone bundle across all Linux distros
# (Fixes "libFLAC.so.14: cannot open shared object file: No such file or directory")
# ==============================================================================
set(AUDIO_RUNTIME_LIBS "")
set(SEARCH_LIB_DIRS
  "/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}"
  "/lib/${CMAKE_LIBRARY_ARCHITECTURE}"
  "/usr/lib/x86_64-linux-gnu"
  "/lib/x86_64-linux-gnu"
  "/usr/lib/aarch64-linux-gnu"
  "/lib/aarch64-linux-gnu"
  "/usr/lib64"
  "/usr/lib"
  "/lib"
)

foreach(lib_dir ${SEARCH_LIB_DIRS})
  if(EXISTS "${lib_dir}")
    file(GLOB FLAC_FILES "${lib_dir}/libFLAC.so*")
    file(GLOB OPUS_FILES "${lib_dir}/libopus.so*")
    file(GLOB VORBIS_FILES "${lib_dir}/libvorbis.so*")
    file(GLOB VORBISENC_FILES "${lib_dir}/libvorbisenc.so*")
    file(GLOB VORBISFILE_FILES "${lib_dir}/libvorbisfile.so*")
    file(GLOB OGG_FILES "${lib_dir}/libogg.so*")
    
    if(FLAC_FILES)
      list(APPEND AUDIO_RUNTIME_LIBS ${FLAC_FILES})
    endif()
    if(OPUS_FILES)
      list(APPEND AUDIO_RUNTIME_LIBS ${OPUS_FILES})
    endif()
    if(VORBIS_FILES)
      list(APPEND AUDIO_RUNTIME_LIBS ${VORBIS_FILES})
    endif()
    if(VORBISENC_FILES)
      list(APPEND AUDIO_RUNTIME_LIBS ${VORBISENC_FILES})
    endif()
    if(VORBISFILE_FILES)
      list(APPEND AUDIO_RUNTIME_LIBS ${VORBISFILE_FILES})
    endif()
    if(OGG_FILES)
      list(APPEND AUDIO_RUNTIME_LIBS ${OGG_FILES})
    endif()
  endif()
endforeach()

if(AUDIO_RUNTIME_LIBS)
  list(REMOVE_DUPLICATES AUDIO_RUNTIME_LIBS)
  install(FILES ${AUDIO_RUNTIME_LIBS}
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)

  # Normalize absolute symlinks to relative symlinks inside bundle lib directory
  # Ensures 100% portability on target Linux machines without relying on host /usr/lib paths
  install(CODE "
    set(TARGET_LIB_DIR \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/lib\")
    file(GLOB BUNDLED_SO_FILES \"\${TARGET_LIB_DIR}/*.so*\")
    foreach(so_file \${BUNDLED_SO_FILES})
      if(IS_SYMLINK \"\${so_file}\")
        get_filename_component(real_dest \"\${so_file}\" REALPATH)
        if(EXISTS \"\${real_dest}\")
          get_filename_component(real_name \"\${real_dest}\" NAME)
          if(EXISTS \"\${TARGET_LIB_DIR}/\${real_name}\")
            file(REMOVE \"\${so_file}\")
            get_filename_component(link_name \"\${so_file}\" NAME)
            execute_process(
              COMMAND \${CMAKE_COMMAND} -E create_symlink \"\${real_name}\" \"\${link_name}\"
              WORKING_DIRECTORY \"\${TARGET_LIB_DIR}\"
            )
          endif()
        endif()
      endif()
    endforeach()
  " COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
