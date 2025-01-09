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

    if (options.inplace and options.filename.len == 0) {
        std.log.err("Please pass path to a cmake file", .{});
        try args.printHelp();
        return;
    }

    const buf = blk: {
        if (options.filename.len != 0) {
            // Read from given file
            const file = std.fs.cwd().openFile(options.filename, .{ .mode = .read_only }) catch |err| {
                std.log.err("Error opening file: {s}", .{@errorName(err)});
                std.process.exit(1);
                return;
            };

            const reader = file.reader();
            const data = reader.readAllAlloc(arena.allocator(), std.math.maxInt(i32)) catch |err| {
                std.log.err("Failed to read file: {s}", .{@errorName(err)});
                std.process.exit(1);
                return;
            };
            break :blk data;
        } else {
            // Read from stdin
            const data = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(i32));
            break :blk data;
        }
    };

    const tokens = try lexer.lex(buf, allocator);
    formatter.format(tokens, buf.len, options);
}

test {
    _ = @import("lexer.zig");
}
