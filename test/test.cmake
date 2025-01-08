option(IS_TAGGED_RELEASE_BUILD "Clears the \"Prelease Version\" project description for tagged release builds. Defaults to `false`" OFF)


cmake_policy(SET CMP0012 NEW) # needed for require flags down below
if(IUI_ENABLE_BUILD_3RDPARTY)
set(Runtime_data_BUILD_QT6
        ${IUI_INSTRUMENT_QT6}
            CACHE BOOL "Build against qt6" FORCE)
endif()
message(STATUS
        "CMake version: ${CMAKE_VERSION}sssssssssssssss dfaskldfj askdfj slkdfj ")
add_executable(hello hello1.c hello2.c hello3.c hello4.c hello5.c)
add_executable(abc
    abc.1 abc.2
    abc.3 abc.4
    )
find_package(PKG ${PKG_VERSION} REQUIRED COMPONENTS C1 C2 C3 C4 C5 OPTIONAL_COMPONENTS B1 B2)
find_package(PKG ${PKG_VERSION}
    REQUIRED COMPONENTS C1 C2 C3 C4 C5
    OPTIONAL_COMPONENTS B1 B2)
find_package(PKG ${PKG_VERSION}
    REQUIRED COMPONENTS C1 C2
    OPTIONAL_COMPONENTS B1 B2)
find_package(FOO 1.23 EXACT QUIET MODULE REQUIRED COMPONENTS foo bar OPTIONAL_COMPONENTS foo bar NO_POLICY_SCOPE)
find_package(FOO 1.23 EXACT QUIET REQUIRED foo bar OPTIONAL_COMPONENTS foo bar CONFIG NO_POLICY_SCOPE NAMES foo bar CONFIGS foo bar HINTS foo bar PATHS foo bar PATH_SUFFIXES foo bar NO_DEFAULT_PATH NO_PACKAGE_ROOT_PATH NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_PACKAGE_REGISTRY NO_CMAKE_BUILDS_PATH NO_CMAKE_SYSTEM_PATH NO_CMAKE_SYSTEM_PACKAGE_REGISTRY CMAKE_FIND_ROOT_PATH_BOTH)
# not great currently, but just hand format it a bit for clarity
if(NOT(-1 EQUAL (${v}))AND(1 EQUAL 1))
