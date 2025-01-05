const std = @import("std");
const lexer = @import("lexer.zig");

//     const out = std.io.getStdOut().writer();
//     for (tokens.items, 0..) |tok, idx| {
//         std.debug.print("[{d}] --- ", .{idx});
//         if (std.meta.activeTag(tok) == .Paren) {
//             std.debug.print(".{{ .{s} = .{{ .opener = {s} }} }},\n", .{ @tagName(tok), if (tok.Paren.opener) "true" else "false" });
//         } else if (std.meta.activeTag(tok) == .Newline) {
//             std.debug.print(".{{ .{s} = .{{}} }},\n", .{@tagName(tok)});
//         } else {
//             std.debug.print(".{{ .{s} = .{{ .name = \"{s}\" }} }},\n", .{ @tagName(tok), tok.text() });
//         }
//     }

test "test full file" {
    const alloc = std.testing.allocator;
    const text = std.fs.cwd().readFileAlloc(alloc, "test/CMakeLists.txt", std.math.maxInt(i32)) catch |e| {
        std.debug.print("Failed to read test CMakeLists file, are you running tests from the root of the repo? Error: {s}\n", .{@errorName(e)});
        return;
    };
    defer alloc.free(text);
    var tokens = try lexer.lex(text, alloc);
    defer tokens.clearAndFree();

    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .name = "cmake_minimum_required" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .name = "VERSION" } },
        .{ .UnquotedArg = .{ .name = "3.12" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .name = "project" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .name = "proj" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Comment = .{ .bracketed = true, .name = "#" } },
        .{ .BracketedArg = .{ .name =
        \\[[This is a bracket comment.
        \\It runs until the close bracket.]]
        } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Comment = .{ .bracketed = true, .name = "#" } },
        .{ .BracketedArg = .{ .name = "[[comment big]]" } },
        .{ .Comment = .{ .bracketed = false, .name = "#line" } },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .name = "add_executable" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .name = "my_exe" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .name = "asd.cpp" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .name = "kkk.cpp" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .name = "lll.cpp" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .name = "value.cpp" } },
        .{ .Newline = .{} },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .name = "if" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .name = "WIN32" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .name = "message" } },
        .{ .Paren = .{ .opener = true } },
        .{ .QuotedArg = .{ .name = "\"helo\"" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .name = "endif" } },
        .{ .Paren = .{ .opener = true } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .name = "message" } },
        .{ .Paren = .{ .opener = true } },
        .{ .QuotedArg = .{ .name =
        \\"This is a quoted argument containing multiple lines.
        \\This is always one argument even though it contains a ; character.
        \\Both \\-escape sequences and ${variable} references are evaluated.
        \\The text does not end on an escaped double-quote like \".
        \\It does end in an unescaped double quote.
        \\"
        } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .name = "message" } },
        .{ .Paren = .{ .opener = true } },
        .{ .BracketedArg = .{ .name =
        \\[=[
        \\This is the first line in a bracket argument with bracket length 1.
        \\No \-escape sequences or ${variable} references are evaluated.
        \\This is always one argument even though it contains a ; character.
        \\The text does not end on a closing bracket of length 0 like ]].
        \\It does end in a closing bracket of length 1.
        \\]=]
        } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
    };

    try std.testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}
