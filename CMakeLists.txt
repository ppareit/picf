cmake_minimum_required(VERSION 2.6)
cmake_policy(VERSION 2.6)

project(PictureFrame)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.13.0" MINIMUM)
include(ValaPrecompile)
include(GSettings)

vala_precompile(
    VALA_C
        src/picf.vala
    PACKAGES
        gtk+-3.0
    OPTIONS
        -g --save-temps
        --thread
)

add_schema(data/be.ppareit.picf.gschema.xml)

find_package(PkgConfig)

pkg_check_modules(DEPS REQUIRED gtk+-3.0)

set(CFLAGS ${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER})
set(LIB_PATHS ${DEPS_LIBRARY_DIRS})
link_directories(${LIB_PATHS})
add_definitions(${CFLAGS})

add_executable(picf ${VALA_C})

target_link_libraries(picf ${DEPS_LIBRARIES})

install (TARGETS picf DESTINATION "bin")
install (FILES "data/picf.desktop" DESTINATION share/applications)
install (FILES "data/picf.desktop" DESTINATION /etc/xdg/autostart)
