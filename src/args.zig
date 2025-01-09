const std = @import("std");

pub fn printHelp() !void {
    _ = try std.io.getStdOut().writeAll(
        \\Usage:
        \\
        \\ If no arguments are specified then input is taken from stdin
        \\
        \\Overwrite the given file:
        \\    cmakefmt -i CMakeLists.txt
        \\
        \\Write to stdout:
        \\    cmakefmt CMakeLists.txt
        \\
        \\Options:
        \\ -i   Overwite the given file (inplace formatting)
        \\ -h   Print this help text
        \\
    );
}

pub const Options = struct {
    help: bool,
    inplace: bool,
    filename: []const u8,
};

pub fn parseArgs(args: *std.process.ArgIterator) Options {
    var options: Options = .{ .help = false, .inplace = false, .filename = "" };
    _ = args.next(); // skip first arg
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-i")) {
            options.inplace = true;
        } else if (std.mem.eql(u8, arg, "-h")) {
            options.help = true;
        } else {
            options.filename = arg;
        }
    }
    return options;
}
