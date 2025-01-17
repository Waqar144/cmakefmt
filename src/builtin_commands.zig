const std = @import("std");
const emptyArgs: []const []const u8 = &.{};

pub const CommandKeywords = struct {
    /// one value keywords
    one: []const []const u8,
    /// multi value keywords
    multi: []const []const u8,
    /// flag
    options: []const []const u8 = &.{},

    pub fn hasArgWithValueKeyword(self: CommandKeywords, word: []const u8) bool {
        for (self.multi) |k| if (std.mem.eql(u8, k, word)) return true;
        for (self.one) |k| if (std.mem.eql(u8, k, word)) return true;
        return false;
    }

    pub fn isOneValueArg(self: CommandKeywords, word: []const u8) bool {
        for (self.one) |k| if (std.mem.eql(u8, k, word)) return true;
        return false;
    }

    pub fn contains(self: CommandKeywords, word: []const u8) bool {
        for (self.multi) |k| if (std.mem.eql(u8, k, word)) return true;
        for (self.options) |k| if (std.mem.eql(u8, k, word)) return true;
        for (self.one) |k| if (std.mem.eql(u8, k, word)) return true;
        return false;
    }
};

pub const gCommandMap = std.StaticStringMapWithEql(CommandKeywords, std.static_string_map.eqlAsciiIgnoreCase).initComptime(.{
    // find_package
    .{ "find_package", .{
        .multi = &.{ "COMPONENTS", "OPTIONAL_COMPONENTS", "NAMES", "CONFIGS", "HINTS", "PATHS", "PATH_SUFFIXES", "REQUIRED" },
        .options = &.{ "EXACT", "QUIET", "MODULE", "CONFIG", "NO_MODULE", "NO_POLICY_SCOPE", "NO_DEFAULT_PATH", "NO_PACKAGE_ROOT_PATH", "NO_CMAKE_PATH", "NO_CMAKE_ENVIRONMENT_PATH", "NO_SYSTEM_ENVIRONMENT_PATH", "NO_CMAKE_PACKAGE_REGISTRY", "NO_CMAKE_BUILDS_PATH", "NO_CMAKE_SYSTEM_PATH", "NO_CMAKE_SYSTEM_PACKAGE_REGISTRY", "CMAKE_FIND_ROOT_PATH_BOTH", "ONLY_CMAKE_FIND_ROOT_PATH", "NO_CMAKE_FIND_ROOT_PATH", "NO_CMAKE_INSTALL_PREFIX", "GLOBAL" },
        .one = emptyArgs,
    } },

    // find_library
    .{ "find_library", .{
        .one = &.{ "DOC", "ENV", "VALIDATOR" },
        .multi = &.{ "NAMES", "HINTS", "PATHS", "PATH_SUFFIXES" },
        .options = &.{ "NAMES_PER_DIR", "NO_DEFAULT_PATH", "NO_PACKAGE_ROOT_PATH", "NO_CMAKE_PATH", "NO_CMAKE_ENVIRONMENT_PATH", "NO_SYSTEM_ENVIRONMENT_PATH", "NO_CMAKE_SYSTEM_PATH", "CMAKE_FIND_ROOT_PATH_BOTH", "ONLY_CMAKE_FIND_ROOT_PATH", "NO_CMAKE_FIND_ROOT_PATH", "REQUIRED", "NO_CMAKE_INSTALL_PREFIX" },
    } },

    // build_command
    .{ "build_command", .{ .one = &.{ "CONFIGURATION", "PARALLEL_LEVEL", "TARGET", "PROJECT_NAME" }, .multi = emptyArgs, .options = emptyArgs } },

    // find_program
    .{ "find_program", .{
        .one = &.{ "DOC", "ENV", "VALIDATOR" },
        .multi = &.{ "NAMES", "NAMES_PER_DIR", "HINTS", "PATHS", "PATH_SUFFIXES", "REGISTRY_VIEW" },
        .options = &.{ "NO_CACHE", "REQUIRED", "NO_DEFAULT_PATH", "NO_PACKAGE_ROOT_PATH", "NO_CMAKE_PATH", "NO_CMAKE_ENVIRONMENT_PATH", "NO_SYSTEM_ENVIRONMENT_PATH", "NO_CMAKE_SYSTEM_PATH", "NO_CMAKE_INSTALL_PREFIX", "CMAKE_FIND_ROOT_PATH_BOTH", "ONLY_CMAKE_FIND_ROOT_PATH", "NO_CMAKE_FIND_ROOT_PATH" },
    } },

    // target_link_libraries
    .{ "target_link_libraries", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE", "LINK_PUBLIC", "LINK_PRIVATE", "LINK_INTERFACE_LIBRARIES" }, .options = emptyArgs, .one = emptyArgs } },
    // target_compile_definitions
    .{ "target_compile_definitions", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .options = emptyArgs, .one = emptyArgs } },
    // target_precompile_headers
    .{ "target_precompile_headers", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .options = emptyArgs, .one = &.{"REUSE_FROM"} } },
    // target_include_directories
    .{ "target_include_directories", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .options = &.{ "BEFORE", "SYSTEM", "AFTER" }, .one = emptyArgs } },
    // target_include_options
    .{ "target_include_options", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .options = emptyArgs, .one = emptyArgs } },
    // target_compile_features
    .{ "target_compile_features", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .options = emptyArgs, .one = emptyArgs } },
    // target_compile_options
    .{ "target_compile_options", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .options = &.{"BEFORE"}, .one = emptyArgs } },
    // set_target_properties
    .{ "set_target_properties", .{ .multi = &.{"PROPERTIES"}, .options = emptyArgs, .one = emptyArgs } },
    // set_directory_properties
    .{ "set_directory_properties", .{ .multi = &.{"PROPERTIES"}, .options = emptyArgs, .one = emptyArgs } },
    // set_tests_properties
    .{ "set_tests_properties", .{ .multi = &.{"PROPERTIES"}, .one = &.{"DIRECTORY"}, .options = emptyArgs } },
    // set_source_files_properties
    .{ "set_source_files_properties", .{ .multi = &.{ "PROPERTIES", "DIRECTORY", "TARGET_DIRECTORY" }, .options = emptyArgs, .one = emptyArgs } },
    // add_custom_target
    .{ "add_custom_target", .{
        .multi = &.{ "COMMAND", "DEPENDS", "BYPRODUCTS", "SOURCES" },
        .options = &.{ "ALL", "COMMAND_EXPAND_LISTS", "VERBATIM", "USES_TERMINAL" },
        .one = &.{ "WORKING_DIRECTORY", "COMMENT", "JOB_POOL", "JOB_SERVER_AWARE" },
    } },
    // add_custom_command
    .{ "add_custom_command", .{
        .multi = &.{ "TARGET", "OUTPUT", "COMMAND", "ARGS", "DEPENDS", "BYPRODUCTS", "IMPLICIT_DEPENDS" },
        .options = &.{ "VERBATIM", "APPEND", "USES_TERMINAL", "COMMAND_EXPAND_LISTS", "DEPENDS_EXPLICIT_ONLY", "CODEGEN", "PRE_BUILD", "PRE_LINK", "POST_BUILD" },
        .one = &.{ "MAIN_DEPENDENCY", "WORKING_DIRECTORY", "COMMENT", "DEPFILE", "JOB_POOL", "JOB_SERVER_AWARE" },
    } },
    // add_test
    .{ "add_test", .{ .multi = &.{ "COMMAND", "CONFIGURATIONS" }, .options = &.{"COMMAND_EXPAND_LISTS"}, .one = &.{ "NAME", "WORKING_DIRECTORY" } } },
    // target_sources
    .{ "target_sources", .{ .multi = &.{ "INTERFACE", "PUBLIC", "PRIVATE" }, .options = emptyArgs, .one = emptyArgs } },

    // BEGIN builtin Modules
    .{ "find_package_check_version", .{ .options = &.{ "HANDLE_VERSION_RANGE", "NO_AUTHOR_WARNING_VERSION_RANGE" }, .one = &.{"RESULT_MESSAGE_VARIABLE"}, .multi = emptyArgs } },
    .{ "find_package_handle_standard_args", .{ .options = &.{ "CONFIG_MODE", "HANDLE_COMPONENTS", "NAME_MISMATCHED", "HANDLE_VERSION_RANGE" }, .one = &.{ "FAIL_MESSAGE", "REASON_FAILURE_MESSAGE", "VERSION_VAR", "FOUND_VAR" }, .multi = &.{"REQUIRED_VARS"} } },
    .{ "protobuf_generate", .{ .options = &.{ "APPEND_PATH", "DESCRIPTORS" }, .one = &.{ "LANGUAGE", "OUT_VAR", "EXPORT_MACRO", "PROTOC_OUT_DIR", "PLUGIN", "PLUGIN_OPTIONS", "DEPENDENCIES" }, .multi = &.{ "PROTOS", "IMPORT_DIRS", "GENERATE_EXTENSIONS", "PROTOC_OPTIONS" } } },
    .{ "protobuf_generate_cpp", .{ .options = emptyArgs, .one = &.{ "EXPORT_MACRO", "DESCRIPTORS" }, .multi = emptyArgs } },
    .{ "cmake_add_fortran_subdirectory", .{ .options = &.{"NO_EXTERNAL_INSTALL"}, .one = &.{ "PROJECT", "ARCHIVE_DIR", "RUNTIME_DIR" }, .multi = &.{ "LIBRARIES", "LINK_LIBRARIES", "CMAKE_COMMAND_LINE" } } },
    .{ "cmake_check_linker_flag", .{ .options = emptyArgs, .one = &.{"OUTPUT_VARIABLE"}, .multi = emptyArgs } },
    .{ "cmake_check_compiler_flag", .{ .options = emptyArgs, .one = &.{"OUTPUT_VARIABLE"}, .multi = emptyArgs } },
    .{ "cmake_try_compiler_or_linker_flag", .{ .options = emptyArgs, .one = &.{ "SRC_EXT", "COMMAND_PATTERN", "OUTPUT_VARIABLE" }, .multi = &.{"FAIL_REGEX"} } },
    .{ "cmake_expand_imported_targets", .{ .options = emptyArgs, .one = &.{"CONFIGURATION"}, .multi = &.{"LIBRARIES"} } },
    .{ "cmake_parse_implicit_link_info2", .{ .options = emptyArgs, .one = &.{ "LANGUAGE", "COMPUTE_IMPLICIT_LIBS", "COMPUTE_IMPLICIT_DIRS", "COMPUTE_IMPLICIT_FWKS", "COMPUTE_IMPLICIT_OBJECTS", "COMPUTE_LINKER" }, .multi = emptyArgs } },
    .{ "cmake_parse_implicit_link_info", .{ .options = emptyArgs, .one = &.{ "LANGUAGE", "COMPUTE_IMPLICIT_OBJECTS" }, .multi = emptyArgs } },
    .{ "perl_get_info", .{ .options = &.{"IS_PATH"}, .one = emptyArgs, .multi = emptyArgs } },
    .{ "externaldata_add_test", .{ .options = emptyArgs, .one = &.{"SHOW_PROGRESS"}, .multi = emptyArgs } },
    .{ "externaldata_add_target", .{ .options = emptyArgs, .one = &.{"SHOW_PROGRESS"}, .multi = emptyArgs } },
    .{ "export_jars", .{ .options = emptyArgs, .one = &.{ "FILE", "NAMESPACE" }, .multi = &.{"TARGETS"} } },
    .{ "install_jar_exports", .{ .options = emptyArgs, .one = &.{ "FILE", "DESTINATION", "COMPONENT", "NAMESPACE" }, .multi = &.{"TARGETS"} } },
    .{ "create_javadoc", .{ .options = emptyArgs, .one = &.{ "TARGET", "GENERATED_FILES", "OUTPUT_NAME", "OUTPUT_DIR" }, .multi = &.{ "CLASSES", "CLASSPATH", "DEPENDS" } } },
    .{ "add_jar", .{ .options = emptyArgs, .one = &.{ "ENTRY_POINT", "MANIFEST", "OUTPUT_DIR", "", "OUTPUT_NAME", "VERSION" }, .multi = &.{ "GENERATE_NATIVE_HEADERS", "INCLUDE_JARS", "RESOURCES", "SOURCES" } } },
    .{ "install_jar", .{ .options = emptyArgs, .one = &.{ "DESTINATION", "COMPONENT" }, .multi = emptyArgs } },
    .{ "find_jar", .{ .options = emptyArgs, .one = &.{ "TARGET", "GENERATED_FILES", "OUTPUT_NAME", "OUTPUT_DIR" }, .multi = &.{ "CLASSES", "CLASSPATH", "DEPENDS" } } },
    .{ "install_jni_symlink", .{ .options = emptyArgs, .one = &.{ "DESTINATION", "COMPONENT" }, .multi = emptyArgs } },
    .{ "create_javah", .{ .options = emptyArgs, .one = &.{ "TARGET", "GENERATED_FILES", "OUTPUT_NAME", "OUTPUT_DIR" }, .multi = &.{ "CLASSES", "CLASSPATH", "DEPENDS" } } },
    .{ "check_ipo_supported", .{ .options = emptyArgs, .one = &.{ "RESULT", "OUTPUT" }, .multi = &.{"LANGUAGES"} } },
    .{ "matlab_get_release_name_from_version", .{ .options = emptyArgs, .one = &.{"REGISTRY_VIEW"}, .multi = emptyArgs } },
    .{ "matlab_add_mex", .{ .options = &.{ "EXECUTABLE", "MODULE", "SHARED", "R2017b", "R2018a", "EXCLUDE_FROM_ALL", "NO_IMPLICIT_LINK_TO_MATLAB_LIBRARIES" }, .one = &.{ "NAME", "DOCUMENTATION", "OUTPUT_NAME" }, .multi = &.{ "LINK_TO", "SRC" } } },
    .{ "matlab_get_all_valid_matlab_roots_from_registry", .{ .options = emptyArgs, .one = &.{"REGISTRY_VIEW"}, .multi = emptyArgs } },
    .{ "matlab_get_mex_suffix", .{ .options = &.{"NO_UNITTEST_FRAMEWORK"}, .one = &.{ "NAME", "UNITTEST_FILE", "TIMEOUT", "WORKING_DIRECTORY", "UNITTEST_PRECOMMAND", "CUSTOM_TEST_COMMAND" }, .multi = &.{ "ADDITIONAL_PATH", "MATLAB_ADDITIONAL_STARTUP_OPTIONS", "TEST_ARGS" } } },
    .{ "matlab_get_version_from_matlab_run", .{ .options = &.{"NO_UNITTEST_FRAMEWORK"}, .one = &.{ "NAME", "UNITTEST_FILE", "TIMEOUT", "WORKING_DIRECTORY", "UNITTEST_PRECOMMAND", "CUSTOM_TEST_COMMAND" }, .multi = &.{ "ADDITIONAL_PATH", "MATLAB_ADDITIONAL_STARTUP_OPTIONS", "TEST_ARGS" } } },
    .{ "matlab_add_unit_test", .{ .options = &.{"NO_UNITTEST_FRAMEWORK"}, .one = &.{ "NAME", "UNITTEST_FILE", "TIMEOUT", "WORKING_DIRECTORY", "UNITTEST_PRECOMMAND", "CUSTOM_TEST_COMMAND" }, .multi = &.{ "ADDITIONAL_PATH", "MATLAB_ADDITIONAL_STARTUP_OPTIONS", "TEST_ARGS" } } },
    .{ "matlab_extract_all_installed_versions_from_registry", .{ .options = emptyArgs, .one = &.{"REGISTRY_VIEW"}, .multi = emptyArgs } },
    .{ "write_basic_config_version_file", .{ .options = &.{"ARCH_INDEPENDENT"}, .one = &.{ "VERSION", "COMPATIBILITY" }, .multi = emptyArgs } },
    .{ "doxygen_quote_value", .{ .options = &.{ "ALL", "USE_STAMP_FILE" }, .one = &.{ "WORKING_DIRECTORY", "COMMENT", "CONFIG_FILE" }, .multi = emptyArgs } },
    .{ "doxygen_add_docs", .{ .options = &.{ "ALL", "USE_STAMP_FILE" }, .one = &.{ "WORKING_DIRECTORY", "COMMENT", "CONFIG_FILE" }, .multi = emptyArgs } },
    .{ "doxygen_list_to_quoted_strings", .{ .options = &.{ "ALL", "USE_STAMP_FILE" }, .one = &.{ "WORKING_DIRECTORY", "COMMENT", "CONFIG_FILE" }, .multi = emptyArgs } },
    .{ "write_compiler_detection_header", .{ .options = &.{ "ALLOW_UNKNOWN_COMPILERS", "ALLOW_UNKNOWN_COMPILER_VERSIONS" }, .one = &.{ "VERSION", "EPILOG", "PROLOG", "OUTPUT_FILES_VAR", "OUTPUT_DIR" }, .multi = &.{ "COMPILERS", "FEATURES", "BARE_FEATURES" } } },
    .{ "env_module", .{ .options = emptyArgs, .one = &.{ "OUTPUT_VARIABLE", "RESULT_VARIABLE" }, .multi = &.{"COMMAND"} } },
    .{ "env_module_swap", .{ .options = emptyArgs, .one = &.{ "OUTPUT_VARIABLE", "RESULT_VARIABLE" }, .multi = emptyArgs } },
    .{ "compiler_id_detection", .{ .options = &.{ "ID_STRING", "VERSION_STRINGS", "ID_DEFINE", "PLATFORM_DEFAULT_COMPILER" }, .one = &.{"PREFIX"}, .multi = emptyArgs } },
    .{ "generate_apple_architecture_selection_file", .{ .options = emptyArgs, .one = &.{ "INSTALL_DESTINATION", "INSTALL_PREFIX", "UNIVERSAL_INCLUDE_FILE", "ERROR_VARIABLE" }, .multi = &.{ "SINGLE_ARCHITECTURES", "SINGLE_ARCHITECTURE_INCLUDE_FILES", "UNIVERSAL_ARCHITECTURES" } } },
    .{ "generate_apple_platform_selection_file", .{ .options = emptyArgs, .multi = emptyArgs, .one = &.{ "INSTALL_DESTINATION", "INSTALL_PREFIX", "INSTALL_PREFIX", "MACOS_INCLUDE_FILE", "IOS_INCLUDE_FILE", "IOS_SIMULATOR_INCLUDE_FILE", "IOS_CATALYST_INCLUDE_FILE", "TVOS_INCLUDE_FILE", "TVOS_SIMULATOR_INCLUDE_FILE", "WATCHOS_INCLUDE_FILE", "WATCHOS_SIMULATOR_INCLUDE_FILE", "VISIONOS_INCLUDE_FILE", "VISIONOS_SIMULATOR_INCLUDE_FILE", "ERROR_VARIABLE" } } },
    .{ "configure_package_config_file", .{ .options = &.{ "NO_SET_AND_CHECK_MACRO", "NO_CHECK_REQUIRED_COMPONENTS_MACRO" }, .one = &.{ "INSTALL_DESTINATION", "INSTALL_PREFIX" }, .multi = &.{"PATH_VARS"} } },
    .{ "swig_add_source_to_module", .{ .options = &.{"NO_PROXY"}, .one = &.{ "LANGUAGE", "TYPE", "OUTPUT_DIR", "OUTFILE_DIR" }, .multi = &.{"SOURCES"} } },
    .{ "swig_get_extra_output_files", .{ .options = &.{"NO_PROXY"}, .one = &.{ "LANGUAGE", "TYPE", "OUTPUT_DIR", "OUTFILE_DIR" }, .multi = &.{"SOURCES"} } },
    .{ "swig_add_library", .{ .options = &.{"NO_PROXY"}, .one = &.{ "LANGUAGE", "TYPE", "OUTPUT_DIR", "OUTFILE_DIR" }, .multi = &.{"SOURCES"} } },
    .{ "ctest_coverage_collect_gcov", .{ .options = &.{ "QUIET", "GLOB", "DELETE" }, .one = &.{ "TARBALL", "SOURCE", "BUILD", "GCOV_COMMAND", "TARBALL_COMPRESSION" }, .multi = &.{"GCOV_OPTIONS"} } },
    .{ "check_pie_supported", .{ .options = emptyArgs, .one = &.{"OUTPUT_VARIABLE"}, .multi = &.{"LANGUAGES"} } },
    .{ "execute_adb_command", .{ .options = emptyArgs, .one = &.{ "FILES_DEST", "LIBS_DEST", "DEV_TEST_DIR", "DEV_OBJ_STORE" }, .multi = &.{ "FILES", "LIBS" } } },
    .{ "push_and_link", .{ .options = emptyArgs, .one = &.{ "FILES_DEST", "LIBS_DEST", "DEV_TEST_DIR", "DEV_OBJ_STORE" }, .multi = &.{ "FILES", "LIBS" } } },
    .{ "android_push_test_files_to_device", .{ .options = emptyArgs, .one = &.{ "FILES_DEST", "LIBS_DEST", "DEV_TEST_DIR", "DEV_OBJ_STORE" }, .multi = &.{ "FILES", "LIBS" } } },
    .{ "filename_regex", .{ .options = emptyArgs, .one = &.{ "FILES_DEST", "LIBS_DEST", "DEV_TEST_DIR", "DEV_OBJ_STORE" }, .multi = &.{ "FILES", "LIBS" } } },
    .{ "cmake_print_properties", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"PROPERTIES"} } },
    .{ "cmake_print_variables", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"PROPERTIES"} } },
    .{ "fetchcontent_declare", .{ .options = emptyArgs, .one = &.{ "GIT_REPOSITORY", "SVN_REPOSITORY", "DOWNLOAD_NO_EXTRACT", "DOWNLOAD_EXTRACT_TIMESTAMP", "BINARY_DIR", "SOURCE_DIR" }, .multi = emptyArgs } },
    .{ "fetchcontent_getproperties", .{ .options = &.{""}, .one = &.{ "SOURCE_DIR", "BINARY_DIR", "POPULATED" }, .multi = &.{""} } },
    .{ "fetchcontent_setpopulated", .{ .options = emptyArgs, .one = &.{ "SOURCE_DIR", "BINARY_DIR" }, .multi = emptyArgs } },
    .{ "verify_bundle_prerequisites", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_bundle_keys", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_bundle_main_executable", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_bundle_and_executable", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "link_resolved_item_into_bundle", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_dotapp_dir", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "fixup_bundle", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "copy_resolved_framework_into_bundle", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "clear_bundle_keys", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "verify_bundle_symlinks", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "verify_app", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_item_key", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "copy_resolved_item_into_bundle", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_item_rpaths", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "set_bundle_key_values", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_bundle_all_executables", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "copy_and_fixup_bundle", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "fixup_bundle_item", .{ .options = emptyArgs, .one = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "gtest_discover_tests_impl", .{ .options = &.{""}, .one = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES", "TEST_EXECUTABLE", "TEST_WORKING_DIR", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "CTEST_FILE", "TEST_DISCOVERY_TIMEOUT", "TEST_XML_OUTPUT_DIR", "TEST_FILTER", "TEST_EXTRA_ARGS", "TEST_DISCOVERY_EXTRA_ARGS", "TEST_PROPERTIES", "TEST_EXECUTOR" }, .multi = &.{""} } },
    .{ "generate_testname_guards", .{ .options = &.{""}, .one = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES", "TEST_EXECUTABLE", "TEST_WORKING_DIR", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "CTEST_FILE", "TEST_DISCOVERY_TIMEOUT", "TEST_XML_OUTPUT_DIR", "TEST_FILTER", "TEST_EXTRA_ARGS", "TEST_DISCOVERY_EXTRA_ARGS", "TEST_PROPERTIES", "TEST_EXECUTOR" }, .multi = &.{""} } },
    .{ "add_command", .{ .options = &.{""}, .one = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES", "TEST_EXECUTABLE", "TEST_WORKING_DIR", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "CTEST_FILE", "TEST_DISCOVERY_TIMEOUT", "TEST_XML_OUTPUT_DIR", "TEST_FILTER", "TEST_EXTRA_ARGS", "TEST_DISCOVERY_EXTRA_ARGS", "TEST_PROPERTIES", "TEST_EXECUTOR" }, .multi = &.{""} } },
    .{ "escape_square_brackets", .{ .options = &.{""}, .one = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES", "TEST_EXECUTABLE", "TEST_WORKING_DIR", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "CTEST_FILE", "TEST_DISCOVERY_TIMEOUT", "TEST_XML_OUTPUT_DIR", "TEST_FILTER", "TEST_EXTRA_ARGS", "TEST_DISCOVERY_EXTRA_ARGS", "TEST_PROPERTIES", "TEST_EXECUTOR" }, .multi = &.{""} } },
    .{ "cpack_append_string_variable_set_command", .{ .options = &.{ "HIDDEN", "REQUIRED", "DISABLED", "DOWNLOADED" }, .one = &.{ "DISPLAY_NAME", "DESCRIPTION", "GROUP", "ARCHIVE_FILE", "PLIST" }, .multi = &.{ "DEPENDS", "INSTALL_TYPES" } } },
    .{ "cpack_append_variable_set_command", .{ .options = &.{ "HIDDEN", "REQUIRED", "DISABLED", "DOWNLOADED" }, .one = &.{ "DISPLAY_NAME", "DESCRIPTION", "GROUP", "ARCHIVE_FILE", "PLIST" }, .multi = &.{ "DEPENDS", "INSTALL_TYPES" } } },
    .{ "android_add_test_data", .{ .options = emptyArgs, .one = &.{ "FILES_DEST", "LIBS_DEST", "DEVICE_OBJECT_STORE", "DEVICE_TEST_DIR" }, .multi = &.{ "FILES", "LIBS", "NO_LINK_REGEX" } } },
    .{ "gtest_add_tests", .{ .options = &.{"SKIP_DEPENDENCY"}, .one = &.{ "TARGET", "WORKING_DIRECTORY", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST" }, .multi = &.{ "SOURCES", "EXTRA_ARGS" } } },
    .{ "gtest_discover_tests", .{ .options = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES" }, .one = &.{ "TEST_PREFIX", "TEST_SUFFIX", "WORKING_DIRECTORY", "TEST_LIST", "DISCOVERY_TIMEOUT", "XML_OUTPUT_DIR", "DISCOVERY_MODE" }, .multi = &.{ "EXTRA_ARGS", "DISCOVERY_EXTRA_ARGS", "PROPERTIES", "TEST_FILTER" } } },
    .{ "squish_v4_add_test", .{ .options = emptyArgs, .one = &.{ "AUT", "SUITE", "TEST", "SETTINGSGROUP", "PRE_COMMAND", "POST_COMMAND" }, .multi = emptyArgs } },
    .{ "Python_add_library", .{ .options = &.{ "STATIC", "SHARED", "MODULE", "WITH_SOABI" }, .one = &.{"USE_SABI"}, .multi = emptyArgs } },
    // END

    // 3rdparty stuff

    // ecm_generate_headers
    .{ "ecm_generate_headers", .{
        .multi = &.{"HEADER_NAMES"},
        .options = emptyArgs,
        .one = &.{ "ORIGINAL", "HEADER_EXTENSION", "OUTPUT_DIR", "PREFIX", "REQUIRED_HEADERS", "COMMON_HEADER", "RELATIVE" },
    } },

    // ecm_generate_export_header
    .{ "ecm_generate_export_header", .{
        .multi = &.{ "BASE_NAME", "GROUP_BASE_NAME", "VERSION", "DEPRECATED_BASE_VERSION", "DEPRECATION_VERSIONS", "EXCLUDE_DEPRECATED_BEFORE_AND_AT" },
        .options = &.{"USE_VERSION_HEADER"},
        .one = emptyArgs,
    } },
});
