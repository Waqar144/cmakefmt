option(IS_TAGGED_RELEASE_BUILD
    "Clears the \"Prelease Version\" project description for tagged release builds. Defaults to `false`" OFF)


cmake_policy(SET CMP0012 NEW) # needed for require flags down below
if(IUI_ENABLE_BUILD_3RDPARTY)
set(Runtime_data_BUILD_QT6
        ${IUI_INSTRUMENT_QT6}
            CACHE BOOL "Build against qt6" FORCE
    )
endif()
message(STATUS
        "CMake version: ${CMAKE_VERSION}sssssssssssssss dfaskldfj askdfj slkdfj ")
add_executable(hello hello1.c hello2.c hello3.c hello4.c hello5.c)
add_executable(abc
    abc.1 abc.2
    abc.3 abc.4
    )
