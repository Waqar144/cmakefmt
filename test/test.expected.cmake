option(IS_TAGGED_RELEASE_BUILD
    "Clears the \"Prelease Version\" project description for tagged release builds. Defaults to `false`" OFF
)

cmake_policy(SET CMP0012 NEW) # needed for require flags down below
if(IUI_ENABLE_BUILD_3RDPARTY)
    set(Runtime_data_BUILD_QT6
        ${IUI_INSTRUMENT_QT6}
        CACHE BOOL "Build against qt6" FORCE
    )
endif()
message(STATUS
    "CMake version: ${CMAKE_VERSION}sssssssssssssss dfaskldfj askdfj slkdfj "
)
add_executable(hello
    hello1.c
    hello2.c
    hello3.c
    hello4.c
    hello5.c
)
add_executable(abc
    abc.1 #[[com]]abc.2
    abc.3 abc.4
)
find_package(PKG
    ${PKG_VERSION}
    REQUIRED
    COMPONENTS
        C1
        C2
        C3
        C4
        C5
    OPTIONAL_COMPONENTS B1 B2
)
find_package(PKG ${PKG_VERSION}
    REQUIRED
    COMPONENTS
        C1
        C2
        C3
        C4
        C5
    OPTIONAL_COMPONENTS B1 B2
)
find_package(PKG ${PKG_VERSION}
    REQUIRED COMPONENTS C1 C2
    OPTIONAL_COMPONENTS B1 B2
)
find_package(FOO
    1.23
    EXACT
    QUIET
    MODULE
    REQUIRED
    COMPONENTS foo bar
    OPTIONAL_COMPONENTS foo bar
    NO_POLICY_SCOPE
)
find_package(FOO
    1.23
    EXACT
    QUIET
    REQUIRED foo bar
    OPTIONAL_COMPONENTS foo bar
    CONFIG
    NO_POLICY_SCOPE
    NAMES foo bar
    CONFIGS foo bar
    HINTS foo bar
    PATHS foo bar
    PATH_SUFFIXES foo bar
    NO_DEFAULT_PATH
    NO_PACKAGE_ROOT_PATH
    NO_CMAKE_PATH
    NO_CMAKE_ENVIRONMENT_PATH
    NO_CMAKE_PACKAGE_REGISTRY
    NO_CMAKE_BUILDS_PATH
    NO_CMAKE_SYSTEM_PATH
    NO_CMAKE_SYSTEM_PACKAGE_REGISTRY
    CMAKE_FIND_ROOT_PATH_BOTH
)
# not great currently, but just hand format it a bit for clarity
if(NOT (-1 EQUAL (${v})) AND (1 EQUAL 1))
endif()

if((AA AND BB) OR
    (CC AND DD) OR (EE AND FF)
)
endif()

set(SOME_FORMATTED_PYTHON_CODE
    [=[
def foo(bar, baz):
    for i, j in zip(bar, baz):
        print(i, j)
    print("DONE")
]=]
)
set(OTHER_FORMATTED_PYTHON_CODE [=[Foo = lambda Bar: Bar.something_to_be_done_on_Bar_object()]=])
build_command(FOO
    CONFIGURATION BAR
    TARGET BAZ
    PROJECT_NAME QUX
)
find_program(FOO
    NAMES name1
    NAMES_PER_DIR
    HINTS path1
    PATHS path1 p2
    PATH_SUFFIXES s1 s2
    NO_CMAKE_FIND_ROOT_PATH
)
target_link_libraries(target
    PUBLIC
        lib1
        lib2
        lib3
        fff
    PRIVATE
        lib4
        lib5
        lib6
        lib7
)
ecm_generate_headers(KTextEditor_CamelCase_HEADERS
    HEADER_NAMES
        AnnotationInterface
        CodeCompletionModelControllerInterface
        MovingCursor
        Range
        LineRange
        TextHintInterface
        Cursor
        InlineNote
        InlineNoteProvider
    PREFIX KTextEditor
    RELATIVE ktexteditor
    REQUIRED_HEADERS KTEXTEDITOR_PUBLIC_HEADERS
)
ecm_generate_export_header(KF6TextEditor
    BASE_NAME KTextEditor
    GROUP_BASE_NAME KF
    VERSION ${KF_VERSION}
    USE_VERSION_HEADER
    DEPRECATED_BASE_VERSION 0
    DEPRECATION_VERSIONS 6.9
    EXCLUDE_DEPRECATED_BEFORE_AND_AT ${EXCLUDE_DEPRECATED_BEFORE_AND_AT}
)
set_target_properties(target PROPERTIES
    VERSION ${MY_VERSION}
    SOVERSION ${MYAPP_SOVERSION}
    EXPORT_NAME "SomeName"
)
set_tests_properties(KF6TextEditor
    DIRECTORY "a/b/c"
    PROPERTIES
    VERSION ${asd}
    SOVERSION ${asdf}
    EXPORT_NAME "asdfg"
)
set_target_properties(target PROPERTIES
    VERSION ${MY_VERSION}
    SOVERSION ${MYAPP_SOVERSION}
    #[[comment]]
    EXPORT_NAME "SomeName"
)
set_target_properties(target PROPERTIES
    VERSION ${MY_VERSION}
    #comment
    SOVERSION ${MYAPP_SOVERSION}
    #[[comment]]
    EXPORT_NAME "SomeName"
)

find_package(PKG ${PKG_VERSION} REQUIRED COMPONENTS
    C1
    C2
    C3
    C4
)
find_package(PKG ${PKG_VERSION} REQUIRED COMPONENTS C1 C2 C3)
add_custom_command(
    OUTPUT
        FOO
        # first line comment
        # second line comment
        some_other_output
        another_output
    COMMAND
        FOO # first line comment
        # second line comment
        some_arg_to_foo_command another_arg_to_foo_command
    COMMAND BAZ
)

add_test(NAME Test1
    COMMAND
        ./run hello world #com
        123 #helo
        blah #helo
    CONFIGURATIONS cfg
    WORKING_DIRECTORY home
)

add_test(NAME Test1
    COMMAND ./run world #world
    CONFIGURATIONS cfg
    WORKING_DIRECTORY home
)

add_test(NAME Test1
    COMMAND ./run #world
        world
    CONFIGURATIONS cfg
    WORKING_DIRECTORY home
)

add_test(NAME Test1
    COMMAND
        ./run #[[com]] hello #[[com]] world
    CONFIGURATIONS cfg
    WORKING_DIRECTORY home
)

if(TRUE) # FOOBAR
    user()
endif() #[comment]

if(TRUE)
    user(
        # comment
    )
endif()
#[comment]
#[=comment]

#[[ Bracketed Comment     0   ]]
#[=[ Bracketed Comment       1   ]=]
#[==[ Bracketed Comment       2   ]==]
#[===[ Bracketed Comment     3   ]===]
#[[
Bracketed Multi


line
]]

Python_add_library(lak
    MODULE
    USE_SABI 3.123 #[[comment]]
    file1
    file2
    file3
)

if(UNIX AND NOT APPLE AND NOT ANDROID AND NOT HAIKU)
    set(MY_VAR ON)
endif()

if(UNIX AND NOT APPLE AND NOT ANDROID AND NOT HAIKU AND ${SOME_LONG_VAR} AND ${ANOTHER_LONG_LONG_VAR} AND
    ${ANOTHER_LONG}
)
    set(MY_VAR ON)
endif()

if(UNIX AND NOT APPLE AND NOT ANDROID
    AND NOT HAIKU AND ${SOME_LONG_VAR}
    AND ${ANOTHER_LONG_LONG_VAR} AND ${ANOTHER_LONG}
)
    set(MY_VAR ON)
endif()

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/LongLongFileAbc.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/VERYVERY_LOng_file_name.cmake"
    "${CMAKE_CURRENT_SOURCE_DIR}/Hello_world_WOlrd_worl_world.cmake"
    DESTINATION "${CMAKECONFIG_INSTALL_DIR}"
    COMPONENT ShotComponent
)
