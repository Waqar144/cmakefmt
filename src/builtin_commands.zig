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

    // BEGIN Modules
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
