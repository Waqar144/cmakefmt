const std = @import("std");
const lexer = @import("lexer.zig");
const testing = std.testing;

test "test full file" {
    const alloc = std.testing.allocator;
    const text = std.fs.cwd().readFileAlloc(alloc, "test/CMakeLists.txt", std.math.maxInt(i32)) catch |e| {
        std.debug.print("Failed to read test CMakeLists file, are you running tests from the root of the repo? Error: {s}\n", .{@errorName(e)});
        return;
    };
    defer alloc.free(text);
    var tokens = try lexer.lex(text, alloc);
    defer tokens.deinit();

    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "cmake_minimum_required" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "VERSION" } },
        .{ .UnquotedArg = .{ .text = "3.12" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .text = "project" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "proj" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Comment = .{ .bracketed = true, .text = "#" } },
        .{ .BracketedArg = .{ .text =
        \\[[This is a bracket comment.
        \\It runs until the close bracket.]]
        } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Comment = .{ .bracketed = true, .text = "#" } },
        .{ .BracketedArg = .{ .text = "[[comment big]]" } },
        .{ .Comment = .{ .bracketed = false, .text = "#line" } },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .text = "add_executable" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "my_exe" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .text = "asd.cpp" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .text = "kkk.cpp" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .text = "lll.cpp" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .text = "value.cpp" } },
        .{ .Newline = .{} },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .text = "if" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "WIN32" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .text = "message" } },
        .{ .Paren = .{ .opener = true } },
        .{ .QuotedArg = .{ .text = "\"helo\"" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .text = "endif" } },
        .{ .Paren = .{ .opener = true } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
        .{ .Newline = .{} },
        .{ .Cmd = .{ .text = "message" } },
        .{ .Paren = .{ .opener = true } },
        .{ .QuotedArg = .{ .text =
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
        .{ .Cmd = .{ .text = "message" } },
        .{ .Paren = .{ .opener = true } },
        .{ .BracketedArg = .{ .text =
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

test "empty" {
    var tokens = try lexer.lex("", testing.allocator);
    defer tokens.deinit();
    try testing.expect(tokens.items.len == 0);
}

test "test multiple in command" {
    var tokens = try lexer.lex("cmake_minimum_required(VERSION 3.16 FATAL_ERROR)", testing.allocator);
    defer tokens.deinit();
    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "cmake_minimum_required" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "VERSION" } },
        .{ .UnquotedArg = .{ .text = "3.16" } },
        .{ .UnquotedArg = .{ .text = "FATAL_ERROR" } },
        .{ .Paren = .{ .opener = false } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "test multiple parens in command" {
    var tokens = try lexer.lex("if((CMAKE_CXX_COMPILER_ID STREQUAL \"GNU\") AND (${CMAKE_SYSTEM_NAME} MATCHES \"Linux\"))", testing.allocator);
    defer tokens.deinit();

    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "if" } },
        .{ .Paren = .{ .opener = true } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "CMAKE_CXX_COMPILER_ID" } },
        .{ .UnquotedArg = .{ .text = "STREQUAL" } },
        .{ .QuotedArg = .{ .text = "\"GNU\"" } },
        .{ .Paren = .{ .opener = false } },
        .{ .UnquotedArg = .{ .text = "AND" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "${CMAKE_SYSTEM_NAME}" } },
        .{ .UnquotedArg = .{ .text = "MATCHES" } },
        .{ .QuotedArg = .{ .text = "\"Linux\"" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Paren = .{ .opener = false } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "test escaped unquoted arg" {
    var tokens = try lexer.lex("set(VAR \\\"\\\")", testing.allocator);
    defer tokens.deinit();
    //     std.debug.print("{any}\n", .{tokens});
    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "set" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "VAR" } },
        .{ .UnquotedArg = .{ .text = "\\\"\\\"" } },
        .{ .Paren = .{ .opener = false } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "comment in args" {
    const source =
        \\if(VarA
        \\   AND VARB
        \\   AND VARC # Some comment
        \\)
    ;

    var tokens = try lexer.lex(source, std.testing.allocator);
    defer tokens.deinit();
    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "if" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "VarA" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .text = "AND" } },
        .{ .UnquotedArg = .{ .text = "VARB" } },
        .{ .Newline = .{} },
        .{ .UnquotedArg = .{ .text = "AND" } },
        .{ .UnquotedArg = .{ .text = "VARC" } },
        .{ .Comment = .{ .bracketed = false, .text = "# Some comment" } },
        .{ .Newline = .{} },
        .{ .Paren = .{ .opener = false } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "unquoted arg containing quotes" {
    const source = "execute_process(COMMAND git log -1 --format=%cd --date=format:\"%Y-%m-%d %H:%M:%S\")";
    var tokens = try lexer.lex(source, std.testing.allocator);
    defer tokens.deinit();
    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "execute_process" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "COMMAND" } },
        .{ .UnquotedArg = .{ .text = "git" } },
        .{ .UnquotedArg = .{ .text = "log" } },
        .{ .UnquotedArg = .{ .text = "-1" } },
        .{ .UnquotedArg = .{ .text = "--format=%cd" } },
        .{ .UnquotedArg = .{ .text = "--date=format:\"%Y-%m-%d %H:%M:%S\"" } },
        .{ .Paren = .{ .opener = false } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "open paren after unquoted arg" {
    const source = "if(NOT(-1 EQUAL (${v})))";
    var tokens = try lexer.lex(source, std.testing.allocator);
    defer tokens.deinit();
    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "if" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "NOT" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "-1" } },
        .{ .UnquotedArg = .{ .text = "EQUAL" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "${v}" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Paren = .{ .opener = false } },
        .{ .Paren = .{ .opener = false } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "comment after unquoted arg" {
    const source = "if(VAR#comment\n)";
    var tokens = try lexer.lex(source, std.testing.allocator);
    defer tokens.deinit();
    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "if" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "VAR" } },
        .{ .Comment = .{ .bracketed = false, .text = "#comment" } },
        .{ .Newline = .{} },
        .{ .Paren = .{ .opener = false } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "not bracketed comment" {
    const source = "#[comment]\n#[=comment]";
    var tokens = try lexer.lex(source, std.testing.allocator);
    defer tokens.deinit();
    const expectedTokens = [_]lexer.Token{
        .{ .Comment = .{ .bracketed = false, .text = "#[comment]" } },
        .{ .Newline = .{} },
        .{ .Comment = .{ .bracketed = false, .text = "#[=comment]" } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "bad bracketed comment" {
    const source = "#[[comment]";
    try std.testing.expectError(error.UnmatchedBrackets, lexer.lex(source, std.testing.allocator));
}

test "not bracketed arg" {
    const source = "cmd([arg])";
    var tokens = try lexer.lex(source, std.testing.allocator);
    defer tokens.deinit();
    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "cmd" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "[arg]" } },
        .{ .Paren = .{ .opener = false } },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "crlf" {
    const source = "cmd([arg])\r\n";
    var tokens = try lexer.lex(source, std.testing.allocator);
    defer tokens.deinit();
    const expectedTokens = [_]lexer.Token{
        .{ .Cmd = .{ .text = "cmd" } },
        .{ .Paren = .{ .opener = true } },
        .{ .UnquotedArg = .{ .text = "[arg]" } },
        .{ .Paren = .{ .opener = false } },
        .{ .Newline = .{} },
    };
    try testing.expectEqualDeep(expectedTokens[0..], tokens.items[0..]);
}

test "bad quoted arg" {
    const source = "hello(\"asd)";
    try std.testing.expectError(error.UnbalancedQuotes, lexer.lex(source, std.testing.allocator));
}
