const std = @import("std");
const lexer = @import("lexer.zig");
const formatter = @import("formatter.zig");
const args = @import("args.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = false }){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var argsIt = try std.process.argsWithAllocator(allocator);
    const options = args.parseArgs(&argsIt);

    if (options.filename.len == 0) {
        std.log.err("Please pass path to a cmake file", .{});
        try args.printHelp();
        return;
    }

    const file = std.fs.cwd().openFile(options.filename, .{ .mode = .read_only }) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return;
    };

    const reader = file.reader();
    const buf = reader.readAllAlloc(arena.allocator(), std.math.maxInt(i32)) catch |err| {
        std.log.err("Failed to read file: {s}", .{@errorName(err)});
        return;
    };

    const tokens = try lexer.lex(buf, allocator);
    formatter.format(tokens, buf.len, options);
}

test {
    _ = @import("lexer.zig");
}
