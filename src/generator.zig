const std = @import("std");
const lexer = @import("lexer.zig");

const ParseArgKind = enum {
    PARSE_ARGV,
    PREFIX,
};

const Variable = struct {
    name: []const u8,
    values: std.ArrayList([]const u8),
};

const KeywordData = struct {
    one: std.ArrayList([]const u8),
    multi: std.ArrayList([]const u8),
    options: std.ArrayList([]const u8),
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = false }){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len <= 1) {
        std.log.err("Must specify the directory to scan\n", .{});
        std.process.exit(1);
    }

    try generate(allocator, args[1], true);
}

fn generate(allocator: std.mem.Allocator, dirPath: []const u8, skipPrivateFns: bool) !void {
    const dir = std.fs.cwd().openDir(dirPath, .{ .iterate = true }) catch |err| {
        std.log.err("Failed to open dir: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
    var walker = try dir.walk(allocator);
    while (try walker.next()) |d| {
        if (d.kind != .file)
            continue;

        const file = d.dir.openFile(d.basename, .{}) catch |err| {
            std.log.err("Failed to read file: {s}", .{@errorName(err)});
            continue;
        };
        const data = file.reader().readAllAlloc(allocator, std.math.maxInt(i32)) catch |err| {
            std.log.err("Failed to read file: {s}", .{@errorName(err)});
            continue;
        };

        if (!(std.mem.eql(u8, "CMakeLists.txt", d.basename) or std.mem.endsWith(u8, d.basename, ".cmake"))) {
            continue;
        }

        const tokens = lexer.lex(data, allocator) catch |err| {
            std.debug.print("Failed to parse: {s}, file: {s}\n", .{ @errorName(err), try d.dir.realpathAlloc(allocator, d.basename) });
            continue;
        };
        var i: u32 = 0;
        var count: u32 = 0;
        var infunction: bool = false;
        var functionName: []const u8 = "";

        var functionArgData = std.StringHashMap(KeywordData).init(allocator);

        while (i < tokens.items.len) : (i += 1) {
            switch (tokens.items[i]) {
                .Cmd => |c| {
                    if (std.mem.eql(u8, "function", c.text)) {
                        infunction = true;
                        var j = i + 1;
                        while (j < tokens.items.len) : (j += 1) {
                            switch (tokens.items[j]) {
                                .UnquotedArg, .QuotedArg, .BracketedArg => {
                                    functionName = tokens.items[j].text();
                                    break;
                                },
                                .Comment,
                                .Newline,
                                .Paren,
                                => continue,
                                else => break,
                            }
                        }

                        // if it starts with _ we assume its private
                        if (skipPrivateFns and (std.mem.startsWith(u8, functionName, "_") or std.mem.startsWith(u8, functionName, "qt_internal"))) {
                            continue;
                        }

                        i = j;
                        const keywordData = try parseFunction(allocator, tokens, &j);
                        try functionArgData.put(functionName, keywordData);

                        count += 1;
                    }
                },
                else => continue,
            }
        }

        try dump(allocator, functionArgData);
    }
}

pub fn parseFunction(allocator: std.mem.Allocator, tokens: std.ArrayList(lexer.Token), i: *u32) !KeywordData {
    var j = i.*;
    var variables = std.ArrayList(Variable).init(allocator);
    var keywordData: KeywordData = .{
        .options = std.ArrayList([]const u8).init(allocator),
        .multi = std.ArrayList([]const u8).init(allocator),
        .one = std.ArrayList([]const u8).init(allocator),
    };

    while (j < tokens.items.len) : (j += 1) {
        switch (tokens.items[j]) {
            .Cmd => |c| {
                if (std.mem.eql(u8, c.text, "set")) {
                    j += 1;
                    const variable = try parseSet(allocator, tokens, &j);
                    try variables.append(variable);
                } else if (std.mem.eql(u8, c.text, "cmake_parse_arguments")) {
                    // parse it as a variable
                    j += 1;
                    const parseArgs = try parseSet(allocator, tokens, &j);
                    const kind = if (std.mem.eql(u8, parseArgs.name, "PARSE_ARGV")) ParseArgKind.PARSE_ARGV else ParseArgKind.PREFIX;

                    var options: []const u8 = undefined;
                    var oneValue: []const u8 = undefined;
                    var multiValue: []const u8 = undefined;

                    if (kind == .PARSE_ARGV) {
                        // cmake_parse_arguments(PARSE_ARGV <N> <prefix> <options> <one_value_keywords> <multi_value_keywords>)
                        if (parseArgs.values.items.len > 2)
                            options = parseArgs.values.items[2];
                        if (parseArgs.values.items.len > 3)
                            oneValue = parseArgs.values.items[3];
                        if (parseArgs.values.items.len > 4)
                            multiValue = parseArgs.values.items[4];
                    } else {
                        // cmake_parse_arguments(<prefix> <options> <one_value_keywords> <multi_value_keywords> <args>...)
                        if (parseArgs.values.items.len >= 1)
                            options = parseArgs.values.items[0];
                        if (parseArgs.values.items.len >= 2)
                            oneValue = parseArgs.values.items[1];
                        if (parseArgs.values.items.len >= 3)
                            multiValue = parseArgs.values.items[2];
                    }

                    keywordData = try resolveArguments(allocator, variables, options, oneValue, multiValue);
                    // we are done
                    break;
                }
            },
            else => continue,
        }
    }
    i.* = j;
    return keywordData;
}

pub fn parseSet(allocator: std.mem.Allocator, tokens: std.ArrayList(lexer.Token), i: *u32) !Variable {
    const argText = struct {
        fn func(token: lexer.Token) []const u8 {
            switch (token) {
                .UnquotedArg => return token.text(),
                .QuotedArg => {
                    const text = token.text();
                    return text[1 .. text.len - 1];
                },
                .BracketedArg => {
                    // TODO
                    return token.text();
                },
                else => std.debug.panic("unexpected!", .{}),
            }
            return "";
        }
    }.func;

    var j = i.*;
    var parenDepth: i32 = 0;
    var first = true;
    var variableName: []const u8 = "";
    var values = std.ArrayList([]const u8).init(allocator);
    while (j < tokens.items.len) : (j += 1) {
        switch (tokens.items[j]) {
            .Paren => |p| {
                const inc: i32 = if (p.opener) 1 else -1;
                parenDepth += inc;
                if (parenDepth == 0) break;
            },
            .UnquotedArg, .QuotedArg, .BracketedArg => {
                if (first) {
                    first = false;
                    variableName = argText(tokens.items[j]);
                } else {
                    try values.append(argText(tokens.items[j]));
                }
            },
            else => continue,
        }
    }
    i.* = j;
    return .{ .name = variableName, .values = values };
}

pub fn resolveArguments(
    allocator: std.mem.Allocator,
    variables: std.ArrayList(Variable),
    options: []const u8,
    oneValue: []const u8,
    multiValue: []const u8,
) !KeywordData {
    return KeywordData{
        .options = try resolveArgument(allocator, variables, options),
        .multi = try resolveArgument(allocator, variables, multiValue),
        .one = try resolveArgument(allocator, variables, oneValue),
    };
}

pub fn resolveArgument(
    allocator: std.mem.Allocator,
    variables: std.ArrayList(Variable),
    arg: []const u8,
) !std.ArrayList([]const u8) {
    var res = std.ArrayList([]const u8).init(allocator);

    if (std.mem.startsWith(u8, arg, "${") and std.mem.endsWith(u8, arg, "}")) {
        // resolve variable
        const inner = arg[2 .. arg.len - 1];
        for (variables.items) |v| {
            if (std.mem.eql(u8, inner, v.name)) {
                for (v.values.items) |i| {
                    try res.append(i);
                }
                break;
            }
        }
    } else if (arg.len > 0) {
        if (std.mem.indexOf(u8, arg, ";") != null) {
            var splitIt = std.mem.split(u8, arg, ";");
            while (splitIt.next()) |splitted| {
                try res.append(splitted);
            }
        } else {
            try res.append(arg);
        }
    }

    return res;
}

pub fn dump(allocator: std.mem.Allocator, functionArgData: std.StringHashMap(KeywordData)) !void {
    var it = functionArgData.iterator();
    while (it.next()) |kv| {
        const value = kv.value_ptr.*;
        if (value.options.items.len == 0 and value.multi.items.len == 0 and value.one.items.len == 0)
            continue;

        std.debug.print(".{{ \"{s}\", .{{\n    ", .{try std.ascii.allocLowerString(allocator, kv.key_ptr.*)});

        const dumpArray = struct {
            fn dumpArrayFn(comptime name: []const u8, values: std.ArrayList([]const u8), appendComma: bool) void {
                if (values.items.len == 0) {
                    if (appendComma) {
                        std.debug.print(".{s} = emptyArgs,\n    ", .{name});
                    } else {
                        std.debug.print(".{s} = emptyArgs\n    ", .{name});
                    }
                    return;
                }
                std.debug.print(".{s} = &.{{", .{name});
                for (values.items, 0..) |kw, idx| {
                    var splitIt = std.mem.split(u8, kw, ";");
                    while (splitIt.next()) |w| {
                        if (!std.mem.startsWith(u8, w, "\""))
                            std.debug.print("\"", .{});
                        std.debug.print("{s}", .{w});
                        if (!std.mem.endsWith(u8, w, "\""))
                            std.debug.print("\"", .{});
                        if (splitIt.peek() != null) {
                            std.debug.print(", ", .{});
                        }
                    }
                    if (idx + 1 < values.items.len) {
                        std.debug.print(", ", .{});
                    }
                }
                if (appendComma) {
                    std.debug.print("}},\n    ", .{});
                } else {
                    std.debug.print("}}\n    ", .{});
                }
            }
        }.dumpArrayFn;

        dumpArray("options", value.options, true);
        dumpArray("one", value.one, true);
        dumpArray("multi", value.multi, false);

        std.debug.print("}} }},\n", .{});
    }
}
