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

    if (options.help) {
        try args.printHelp();
        return;
    }

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
            defer file.close();

            const reader = file.reader();
            const data = reader.readAllAlloc(arena.allocator(), std.math.maxInt(i32)) catch |err| {
                std.log.err("Failed to read file '{s}': {s}", .{ options.filename, @errorName(err) });
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

    var errorPosition: ?lexer.Position = null;
    const tokens = lexer.lex(buf, allocator, &errorPosition) catch |err| handleParseError(err, options, errorPosition);
    const hasCRLF = std.mem.indexOf(u8, buf, "\r\n") != null;
    formatter.format(tokens, buf.len, options, hasCRLF);
}

fn handleParseError(err: anyerror, options: args.Options, errorPosition: ?lexer.Position) noreturn {
    const filename = blk: {
        if (options.filename.len != 0) {
            var outBuf: [1024]u8 = undefined;
            break :blk std.fs.cwd().realpath(options.filename, outBuf[0..]) catch |e| {
                std.log.err("Unknown error: {s}", .{@errorName(e)});
                std.process.exit(1);
            };
        } else {
            break :blk "<stdin>";
        }
    };
    if (err == error.ParseError) {
        if (errorPosition) |ep| {
            std.log.err("Failed to parse: {s}:{d}:{d}: {s}", .{ filename, ep.line, ep.col, @errorName(err) });
        }
    } else {
        std.log.err("Failed to parse: {s}: {s}", .{ filename, @errorName(err) });
    }
    std.process.exit(1);
}

test {
    _ = @import("lexer.zig");
}
