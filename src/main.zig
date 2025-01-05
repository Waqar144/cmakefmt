const std = @import("std");
const lexer = @import("lexer.zig");
const formatter = @import("formatter.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = false }){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var argsIt = try std.process.argsWithAllocator(allocator);
    var args = std.ArrayList([]const u8).init(allocator);
    while (argsIt.next()) |arg| {
        const a: []const u8 = arg;
        try args.append(a);
    }

    if (args.items.len < 2) {
        std.log.err("Please pass path to a cmake file", .{});
        return;
    }

    if (false) {
        for (args.items) |arg| {
            std.debug.print("{s}\n", .{arg});
        }
    }

    const file = std.fs.cwd().openFile(args.items[1], .{ .mode = .read_only }) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return;
    };

    const reader = file.reader();
    const buf = reader.readAllAlloc(arena.allocator(), std.math.maxInt(i32)) catch |err| {
        std.log.err("Failed to read file: {s}", .{@errorName(err)});
        return;
    };

    const tokens = try lexer.lex(buf, allocator);
    formatter.format(tokens);
}

test {
    _ = @import("lexer.zig");
}
