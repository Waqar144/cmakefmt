const std = @import("std");
const emptyArgs: []const []const u8 = &.{};

pub const CommandKeywords = struct {
    /// multi value keywords
    multi: []const []const u8,
    /// flag or single value
    keywords: []const []const u8 = &.{},

    pub fn hasMultiArgKeyword(self: CommandKeywords, word: []const u8) bool {
        for (self.multi) |k| if (std.mem.eql(u8, k, word)) return true;
        return false;
    }

    pub fn contains(self: CommandKeywords, word: []const u8) bool {
        for (self.multi) |k| if (std.mem.eql(u8, k, word)) return true;
        for (self.keywords) |k| if (std.mem.eql(u8, k, word)) return true;
        return false;
    }
};

pub const gCommandMap = std.StaticStringMapWithEql(CommandKeywords, std.static_string_map.eqlAsciiIgnoreCase).initComptime(.{
    // find_package
    .{ "find_package", .{
        .multi = &.{ "COMPONENTS", "OPTIONAL_COMPONENTS", "NAMES", "CONFIGS", "HINTS", "PATHS", "PATH_SUFFIXES", "REQUIRED" },
        .keywords = &.{ "EXACT", "QUIET", "MODULE", "CONFIG", "NO_MODULE", "NO_POLICY_SCOPE", "NO_DEFAULT_PATH", "NO_PACKAGE_ROOT_PATH", "NO_CMAKE_PATH", "NO_CMAKE_ENVIRONMENT_PATH", "NO_SYSTEM_ENVIRONMENT_PATH", "NO_CMAKE_PACKAGE_REGISTRY", "NO_CMAKE_BUILDS_PATH", "NO_CMAKE_SYSTEM_PATH", "NO_CMAKE_SYSTEM_PACKAGE_REGISTRY", "CMAKE_FIND_ROOT_PATH_BOTH", "ONLY_CMAKE_FIND_ROOT_PATH", "NO_CMAKE_FIND_ROOT_PATH", "NO_CMAKE_INSTALL_PREFIX", "GLOBAL" },
    } },

    // find_library
    .{ "find_library", .{
        .multi = &.{ "NAMES", "HINTS", "PATHS", "PATH_SUFFIXES", "DOC", "ENV", "VALIDATOR" },
        .keywords = &.{ "NAMES_PER_DIR", "NO_DEFAULT_PATH", "NO_PACKAGE_ROOT_PATH", "NO_CMAKE_PATH", "NO_CMAKE_ENVIRONMENT_PATH", "NO_SYSTEM_ENVIRONMENT_PATH", "NO_CMAKE_SYSTEM_PATH", "CMAKE_FIND_ROOT_PATH_BOTH", "ONLY_CMAKE_FIND_ROOT_PATH", "NO_CMAKE_FIND_ROOT_PATH", "REQUIRED", "NO_CMAKE_INSTALL_PREFIX" },
    } },

    // build_command
    .{ "build_command", .{ .multi = &.{ "CONFIGURATION", "PARALLEL_LEVEL", "TARGET", "PROJECT_NAME" }, .keywords = emptyArgs } },

    // find_program
    .{ "find_program", .{
        .multi = &.{ "NAMES", "NAMES_PER_DIR", "HINTS", "PATHS", "PATH_SUFFIXES", "DOC", "ENV", "VALIDATOR", "REGISTRY_VIEW" },
        .keywords = &.{ "NO_CACHE", "REQUIRED", "NO_DEFAULT_PATH", "NO_PACKAGE_ROOT_PATH", "NO_CMAKE_PATH", "NO_CMAKE_ENVIRONMENT_PATH", "NO_SYSTEM_ENVIRONMENT_PATH", "NO_CMAKE_SYSTEM_PATH", "NO_CMAKE_INSTALL_PREFIX", "CMAKE_FIND_ROOT_PATH_BOTH", "ONLY_CMAKE_FIND_ROOT_PATH", "NO_CMAKE_FIND_ROOT_PATH" },
    } },

    // target_link_libraries
    .{ "target_link_libraries", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE", "LINK_PUBLIC", "LINK_PRIVATE", "LINK_INTERFACE_LIBRARIES" }, .keywords = emptyArgs } },
    // target_compile_definitions
    .{ "target_compile_definitions", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .keywords = emptyArgs } },
    // target_precompile_headers
    .{ "target_precompile_headers", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .keywords = emptyArgs } },
    // target_include_directories
    .{ "target_include_directories", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .keywords = emptyArgs } },
    // target_include_options
    .{ "target_include_options", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .keywords = emptyArgs } },
    // target_compile_features
    .{ "target_compile_features", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .keywords = emptyArgs } },
    // target_compile_options
    .{ "target_compile_options", .{ .multi = &.{ "PRIVATE", "PUBLIC", "INTERFACE" }, .keywords = emptyArgs } },
    // set_target_properties
    .{ "set_target_properties", .{ .multi = &.{"PROPERTIES"}, .keywords = emptyArgs } },
    // set_directory_properties
    .{ "set_directory_properties", .{ .multi = &.{"PROPERTIES"}, .keywords = emptyArgs } },
    // set_tests_properties
    .{ "set_tests_properties", .{ .multi = &.{ "PROPERTIES", "DIRECTORY" }, .keywords = emptyArgs } },
    // set_source_files_properties
    .{ "set_source_files_properties", .{ .multi = &.{ "PROPERTIES", "DIRECTORY", "TARGET_DIRECTORY" }, .keywords = emptyArgs } },
    // add_custom_target
    .{ "add_custom_target", .{
        .multi = &.{ "COMMAND", "DEPENDS", "BYPRODUCTS", "WORKING_DIRECTORY", "COMMENT", "JOB_POOL", "JOB_SERVER_AWARE", "SOURCES" },
        .keywords = &.{ "ALL", "COMMAND_EXPAND_LISTS", "VERBATIM", "USES_TERMINAL" },
    } },
    // add_custom_command
    .{ "add_custom_command", .{
        .multi = &.{ "TARGET", "OUTPUT", "COMMAND", "ARGS", "DEPENDS", "BYPRODUCTS", "IMPLICIT_DEPENDS", "OUTPUT", "MAIN_DEPENDENCY", "WORKING_DIRECTORY", "COMMENT", "DEPFILE", "JOB_POOL", "JOB_SERVER_AWARE" },
        .keywords = &.{ "VERBATIM", "APPEND", "USES_TERMINAL", "COMMAND_EXPAND_LISTS", "DEPENDS_EXPLICIT_ONLY", "CODEGEN", "PRE_BUILD", "PRE_LINK", "POST_BUILD" },
    } },
    // add_test
    .{ "add_test", .{ .multi = &.{ "NAME", "COMMAND", "CONFIGURATIONS", "WORKING_DIRECTORY" }, .keywords = &.{"COMMAND_EXPAND_LISTS"} } },

    // target_sources
    .{ "target_sources", .{ .multi = &.{ "INTERFACE", "PUBLIC", "PRIVATE" }, .keywords = emptyArgs } },

    // BEGIN builtin Modules
    .{ "find_package_check_version", .{ .keywords = &.{ "HANDLE_VERSION_RANGE", "NO_AUTHOR_WARNING_VERSION_RANGE" }, .multi = &.{"RESULT_MESSAGE_VARIABLE"} } },
    .{ "find_package_handle_standard_args", .{ .keywords = &.{ "CONFIG_MODE", "HANDLE_COMPONENTS", "NAME_MISMATCHED", "HANDLE_VERSION_RANGE" }, .multi = &.{ "FAIL_MESSAGE", "REASON_FAILURE_MESSAGE", "VERSION_VAR", "FOUND_VAR", "REQUIRED_VARS" } } },
    .{ "protobuf_generate", .{ .keywords = &.{ "APPEND_PATH", "DESCRIPTORS" }, .multi = &.{ "LANGUAGE", "OUT_VAR", "EXPORT_MACRO", "PROTOC_OUT_DIR", "PLUGIN", "PLUGIN_OPTIONS", "DEPENDENCIES", "PROTOS", "IMPORT_DIRS", "GENERATE_EXTENSIONS", "PROTOC_OPTIONS" } } },
    .{ "protobuf_generate_cpp", .{ .keywords = emptyArgs, .multi = &.{ "EXPORT_MACRO", "DESCRIPTORS" } } },
    .{ "cmake_add_fortran_subdirectory", .{ .keywords = &.{"NO_EXTERNAL_INSTALL"}, .multi = &.{ "PROJECT", "ARCHIVE_DIR", "RUNTIME_DIR", "LIBRARIES", "LINK_LIBRARIES", "CMAKE_COMMAND_LINE" } } },
    .{ "cmake_check_linker_flag", .{ .keywords = emptyArgs, .multi = &.{"OUTPUT_VARIABLE"} } },
    .{ "cmake_check_compiler_flag", .{ .keywords = emptyArgs, .multi = &.{"OUTPUT_VARIABLE"} } },
    .{ "cmake_try_compiler_or_linker_flag", .{ .keywords = emptyArgs, .multi = &.{ "SRC_EXT", "COMMAND_PATTERN", "OUTPUT_VARIABLE", "FAIL_REGEX" } } },
    .{ "cmake_expand_imported_targets", .{ .keywords = emptyArgs, .multi = &.{ "CONFIGURATION", "LIBRARIES" } } },
    .{ "cmake_parse_implicit_link_info2", .{ .keywords = emptyArgs, .multi = &.{ "LANGUAGE", "COMPUTE_IMPLICIT_LIBS", "COMPUTE_IMPLICIT_DIRS", "COMPUTE_IMPLICIT_FWKS", "COMPUTE_IMPLICIT_OBJECTS", "COMPUTE_LINKER" } } },
    .{ "cmake_parse_implicit_link_info", .{ .keywords = emptyArgs, .multi = &.{ "LANGUAGE", "COMPUTE_IMPLICIT_OBJECTS" } } },
    .{ "perl_get_info", .{ .keywords = &.{"IS_PATH"}, .multi = emptyArgs } },
    .{ "externaldata_add_test", .{ .keywords = emptyArgs, .multi = &.{"SHOW_PROGRESS"} } },
    .{ "externaldata_add_target", .{ .keywords = emptyArgs, .multi = &.{"SHOW_PROGRESS"} } },
    .{ "export_jars", .{ .keywords = emptyArgs, .multi = &.{ "FILE", "NAMESPACE", "TARGETS" } } },
    .{ "create_javadoc", .{ .keywords = emptyArgs, .multi = &.{ "TARGET", "GENERATED_FILES", "OUTPUT_NAME", "OUTPUT_DIR", "CLASSES", "CLASSPATH", "DEPENDS" } } },
    .{ "install_jar_exports", .{ .keywords = emptyArgs, .multi = &.{ "FILE", "DESTINATION", "COMPONENT", "NAMESPACE", "TARGETS" } } },
    .{ "add_jar", .{ .keywords = emptyArgs, .multi = &.{ "ENTRY_POINT", "MANIFEST", "OUTPUT_DIR", "", "OUTPUT_NAME", "VERSION", "GENERATE_NATIVE_HEADERS", "INCLUDE_JARS", "RESOURCES", "SOURCES" } } },
    .{ "install_jar", .{ .keywords = emptyArgs, .multi = &.{ "DESTINATION", "COMPONENT" } } },
    .{ "find_jar", .{ .keywords = emptyArgs, .multi = &.{ "TARGET", "GENERATED_FILES", "OUTPUT_NAME", "OUTPUT_DIR", "CLASSES", "CLASSPATH", "DEPENDS" } } },
    .{ "install_jni_symlink", .{ .keywords = emptyArgs, .multi = &.{ "DESTINATION", "COMPONENT" } } },
    .{ "create_javah", .{ .keywords = emptyArgs, .multi = &.{ "TARGET", "GENERATED_FILES", "OUTPUT_NAME", "OUTPUT_DIR", "CLASSES", "CLASSPATH", "DEPENDS" } } },
    .{ "check_ipo_supported", .{ .keywords = emptyArgs, .multi = &.{ "RESULT", "OUTPUT", "LANGUAGES" } } },
    .{ "matlab_get_release_name_from_version", .{ .keywords = emptyArgs, .multi = &.{"REGISTRY_VIEW"} } },
    .{ "matlab_get_all_valid_matlab_roots_from_registry", .{ .keywords = emptyArgs, .multi = &.{"REGISTRY_VIEW"} } },
    .{ "matlab_get_mex_suffix", .{ .keywords = &.{"NO_UNITTEST_FRAMEWORK"}, .multi = &.{ "NAME", "UNITTEST_FILE", "TIMEOUT", "WORKING_DIRECTORY", "UNITTEST_PRECOMMAND", "CUSTOM_TEST_COMMAND", "ADDITIONAL_PATH", "MATLAB_ADDITIONAL_STARTUP_OPTIONS", "TEST_ARGS" } } },
    .{ "matlab_extract_all_installed_versions_from_registry", .{ .keywords = emptyArgs, .multi = &.{"REGISTRY_VIEW"} } },
    .{ "matlab_add_mex", .{ .keywords = &.{ "EXECUTABLE", "MODULE", "SHARED", "R2017b", "R2018a", "EXCLUDE_FROM_ALL", "NO_IMPLICIT_LINK_TO_MATLAB_LIBRARIES" }, .multi = &.{ "NAME", "DOCUMENTATION", "OUTPUT_NAME", "LINK_TO", "SRC" } } },
    .{ "matlab_get_version_from_matlab_run", .{ .keywords = &.{"NO_UNITTEST_FRAMEWORK"}, .multi = &.{ "NAME", "UNITTEST_FILE", "TIMEOUT", "WORKING_DIRECTORY", "UNITTEST_PRECOMMAND", "CUSTOM_TEST_COMMAND", "ADDITIONAL_PATH", "MATLAB_ADDITIONAL_STARTUP_OPTIONS", "TEST_ARGS" } } },
    .{ "matlab_add_unit_test", .{ .keywords = &.{"NO_UNITTEST_FRAMEWORK"}, .multi = &.{ "NAME", "UNITTEST_FILE", "TIMEOUT", "WORKING_DIRECTORY", "UNITTEST_PRECOMMAND", "CUSTOM_TEST_COMMAND", "ADDITIONAL_PATH", "MATLAB_ADDITIONAL_STARTUP_OPTIONS", "TEST_ARGS" } } },
    .{ "write_basic_config_version_file", .{ .keywords = &.{"ARCH_INDEPENDENT"}, .multi = &.{ "VERSION", "COMPATIBILITY" } } },
    .{ "doxygen_quote_value", .{ .keywords = &.{ "ALL", "USE_STAMP_FILE" }, .multi = &.{ "WORKING_DIRECTORY", "COMMENT", "CONFIG_FILE" } } },
    .{ "doxygen_add_docs", .{ .keywords = &.{ "ALL", "USE_STAMP_FILE" }, .multi = &.{ "WORKING_DIRECTORY", "COMMENT", "CONFIG_FILE" } } },
    .{ "doxygen_list_to_quoted_strings", .{ .keywords = &.{ "ALL", "USE_STAMP_FILE" }, .multi = &.{ "WORKING_DIRECTORY", "COMMENT", "CONFIG_FILE" } } },
    .{ "write_compiler_detection_header", .{ .keywords = &.{ "ALLOW_UNKNOWN_COMPILERS", "ALLOW_UNKNOWN_COMPILER_VERSIONS" }, .multi = &.{ "VERSION", "EPILOG", "PROLOG", "OUTPUT_FILES_VAR", "OUTPUT_DIR", "COMPILERS", "FEATURES", "BARE_FEATURES" } } },
    .{ "env_module", .{ .keywords = emptyArgs, .multi = &.{ "OUTPUT_VARIABLE", "RESULT_VARIABLE", "COMMAND" } } },
    .{ "env_module_swap", .{ .keywords = emptyArgs, .multi = &.{ "OUTPUT_VARIABLE", "RESULT_VARIABLE" } } },
    .{ "compiler_id_detection", .{ .keywords = &.{ "ID_STRING", "VERSION_STRINGS", "ID_DEFINE", "PLATFORM_DEFAULT_COMPILER" }, .multi = &.{"PREFIX"} } },
    .{ "generate_apple_architecture_selection_file", .{ .keywords = emptyArgs, .multi = &.{ "INSTALL_DESTINATION", "INSTALL_PREFIX", "UNIVERSAL_INCLUDE_FILE", "ERROR_VARIABLE", "SINGLE_ARCHITECTURES", "SINGLE_ARCHITECTURE_INCLUDE_FILES", "UNIVERSAL_ARCHITECTURES" } } },
    .{ "configure_package_config_file", .{ .keywords = &.{ "NO_SET_AND_CHECK_MACRO", "NO_CHECK_REQUIRED_COMPONENTS_MACRO" }, .multi = &.{ "INSTALL_DESTINATION", "INSTALL_PREFIX", "PATH_VARS" } } },
    .{ "swig_add_source_to_module", .{ .keywords = &.{"NO_PROXY"}, .multi = &.{ "LANGUAGE", "TYPE", "OUTPUT_DIR", "OUTFILE_DIR", "SOURCES" } } },
    .{ "swig_get_extra_output_files", .{ .keywords = &.{"NO_PROXY"}, .multi = &.{ "LANGUAGE", "TYPE", "OUTPUT_DIR", "OUTFILE_DIR", "SOURCES" } } },
    .{ "swig_add_library", .{ .keywords = &.{"NO_PROXY"}, .multi = &.{ "LANGUAGE", "TYPE", "OUTPUT_DIR", "OUTFILE_DIR", "SOURCES" } } },
    .{ "ctest_coverage_collect_gcov", .{ .keywords = &.{ "QUIET", "GLOB", "DELETE" }, .multi = &.{ "TARBALL", "SOURCE", "BUILD", "GCOV_COMMAND", "TARBALL_COMPRESSION", "GCOV_OPTIONS" } } },
    .{ "check_pie_supported", .{ .keywords = emptyArgs, .multi = &.{ "OUTPUT_VARIABLE", "LANGUAGES" } } },
    .{ "execute_adb_command", .{ .keywords = emptyArgs, .multi = &.{ "FILES_DEST", "LIBS_DEST", "DEV_TEST_DIR", "DEV_OBJ_STORE", "FILES", "LIBS" } } },
    .{ "push_and_link", .{ .keywords = emptyArgs, .multi = &.{ "FILES_DEST", "LIBS_DEST", "DEV_TEST_DIR", "DEV_OBJ_STORE", "FILES", "LIBS" } } },
    .{ "android_push_test_files_to_device", .{ .keywords = emptyArgs, .multi = &.{ "FILES_DEST", "LIBS_DEST", "DEV_TEST_DIR", "DEV_OBJ_STORE", "FILES", "LIBS" } } },
    .{ "filename_regex", .{ .keywords = emptyArgs, .multi = &.{ "FILES_DEST", "LIBS_DEST", "DEV_TEST_DIR", "DEV_OBJ_STORE", "FILES", "LIBS" } } },
    .{ "cmake_print_properties", .{ .keywords = emptyArgs, .multi = &.{"PROPERTIES"} } },
    .{ "cmake_print_variables", .{ .keywords = emptyArgs, .multi = &.{"PROPERTIES"} } },
    .{ "fetchcontent_setpopulated", .{ .keywords = emptyArgs, .multi = &.{ "SOURCE_DIR", "BINARY_DIR" } } },
    .{ "fetchcontent_getproperties", .{ .keywords = &.{""}, .multi = &.{ "SOURCE_DIR", "BINARY_DIR", "POPULATED" } } },
    .{ "fetchcontent_declare", .{ .keywords = emptyArgs, .multi = &.{ "GIT_REPOSITORY", "SVN_REPOSITORY", "DOWNLOAD_NO_EXTRACT", "DOWNLOAD_EXTRACT_TIMESTAMP", "BINARY_DIR", "SOURCE_DIR" } } },
    .{ "verify_bundle_prerequisites", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_bundle_keys", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_bundle_main_executable", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_bundle_and_executable", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "link_resolved_item_into_bundle", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_dotapp_dir", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "fixup_bundle", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "copy_resolved_framework_into_bundle", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "clear_bundle_keys", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "verify_bundle_symlinks", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "verify_app", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_item_key", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "copy_resolved_item_into_bundle", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_item_rpaths", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "set_bundle_key_values", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "get_bundle_all_executables", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "copy_and_fixup_bundle", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "fixup_bundle_item", .{ .keywords = emptyArgs, .multi = &.{"IGNORE_ITEM"} } },
    .{ "gtest_discover_tests_impl", .{ .keywords = &.{""}, .multi = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES", "TEST_EXECUTABLE", "TEST_WORKING_DIR", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "CTEST_FILE", "TEST_DISCOVERY_TIMEOUT", "TEST_XML_OUTPUT_DIR", "TEST_FILTER", "TEST_EXTRA_ARGS", "TEST_DISCOVERY_EXTRA_ARGS", "TEST_PROPERTIES", "TEST_EXECUTOR", "" } } },
    .{ "generate_testname_guards", .{ .keywords = &.{""}, .multi = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES", "TEST_EXECUTABLE", "TEST_WORKING_DIR", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "CTEST_FILE", "TEST_DISCOVERY_TIMEOUT", "TEST_XML_OUTPUT_DIR", "TEST_FILTER", "TEST_EXTRA_ARGS", "TEST_DISCOVERY_EXTRA_ARGS", "TEST_PROPERTIES", "TEST_EXECUTOR", "" } } },
    .{ "add_command", .{ .keywords = &.{""}, .multi = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES", "TEST_EXECUTABLE", "TEST_WORKING_DIR", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "CTEST_FILE", "TEST_DISCOVERY_TIMEOUT", "TEST_XML_OUTPUT_DIR", "TEST_FILTER", "TEST_EXTRA_ARGS", "TEST_DISCOVERY_EXTRA_ARGS", "TEST_PROPERTIES", "TEST_EXECUTOR", "" } } },
    .{ "escape_square_brackets", .{ .keywords = &.{""}, .multi = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES", "TEST_EXECUTABLE", "TEST_WORKING_DIR", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "CTEST_FILE", "TEST_DISCOVERY_TIMEOUT", "TEST_XML_OUTPUT_DIR", "TEST_FILTER", "TEST_EXTRA_ARGS", "TEST_DISCOVERY_EXTRA_ARGS", "TEST_PROPERTIES", "TEST_EXECUTOR", "" } } },
    .{ "cpack_append_string_variable_set_command", .{ .keywords = &.{ "HIDDEN", "REQUIRED", "DISABLED", "DOWNLOADED" }, .multi = &.{ "DISPLAY_NAME", "DESCRIPTION", "GROUP", "ARCHIVE_FILE", "PLIST", "DEPENDS", "INSTALL_TYPES" } } },
    .{ "cpack_append_variable_set_command", .{ .keywords = &.{ "HIDDEN", "REQUIRED", "DISABLED", "DOWNLOADED" }, .multi = &.{ "DISPLAY_NAME", "DESCRIPTION", "GROUP", "ARCHIVE_FILE", "PLIST", "DEPENDS", "INSTALL_TYPES" } } },
    .{ "android_add_test_data", .{ .keywords = emptyArgs, .multi = &.{ "FILES_DEST", "LIBS_DEST", "DEVICE_OBJECT_STORE", "DEVICE_TEST_DIR", "FILES", "LIBS", "NO_LINK_REGEX" } } },
    .{ "gtest_add_tests", .{ .keywords = &.{"SKIP_DEPENDENCY"}, .multi = &.{ "TARGET", "WORKING_DIRECTORY", "TEST_PREFIX", "TEST_SUFFIX", "TEST_LIST", "SOURCES", "EXTRA_ARGS" } } },
    .{ "gtest_discover_tests", .{ .keywords = &.{ "NO_PRETTY_TYPES", "NO_PRETTY_VALUES" }, .multi = &.{ "TEST_PREFIX", "TEST_SUFFIX", "WORKING_DIRECTORY", "TEST_LIST", "DISCOVERY_TIMEOUT", "XML_OUTPUT_DIR", "DISCOVERY_MODE", "EXTRA_ARGS", "DISCOVERY_EXTRA_ARGS", "PROPERTIES", "TEST_FILTER" } } },
    .{ "squish_v4_add_test", .{ .keywords = emptyArgs, .multi = &.{ "AUT", "SUITE", "TEST", "SETTINGSGROUP", "PRE_COMMAND", "POST_COMMAND" } } },
    // END

    // 3rdparty stuff

    // ecm_generate_headers
    .{ "ecm_generate_headers", .{
        .multi = &.{ "HEADER_NAMES", "PREFIX", "RELATIVE", "REQUIRED_HEADERS" },
        .keywords = emptyArgs,
    } },

    // ecm_generate_export_header
    .{ "ecm_generate_export_header", .{
        .multi = &.{ "BASE_NAME", "GROUP_BASE_NAME", "VERSION", "DEPRECATED_BASE_VERSION", "DEPRECATION_VERSIONS", "EXCLUDE_DEPRECATED_BEFORE_AND_AT" },
        .keywords = &.{"USE_VERSION_HEADER"},
    } },
});
