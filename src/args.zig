const std = @import("std");

pub const Options = struct {
    inplace: bool,
    filename: []const u8,
};

pub fn parseArgs(args: *std.process.ArgIterator) Options {
    var options: Options = .{ .inplace = false, .filename = "" };
    _ = args.next(); // skip first arg
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-i")) {
            options.inplace = true;
        } else {
            options.filename = arg;
        }
    }
    return options;
}
