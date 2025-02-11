const std = @import("std");
const mem = std.mem;

pub const Command = struct { text: []const u8 };
pub const Paren = struct { opener: bool };
pub const UnquotedArg = struct { text: []const u8 };
pub const QuotedArg = struct { text: []const u8 };
pub const BracketedArg = struct { text: []const u8 };
pub const Comment = struct { bracketed: bool, text: []const u8 };
pub const Newline = struct {};

pub const Position = struct {
    line: u32,
    col: u32,
};

pub const ParseError = error{
    ExpectedAnotherBracket,
    UnmatchedBrackets,
    InvalidEscapeSequence,
    UnbalancedQuotes,
    InvalidSyntax,
};

pub const Token = union(enum) {
    Cmd: Command,
    Paren: Paren,
    UnquotedArg: UnquotedArg,
    QuotedArg: QuotedArg,
    BracketedArg: BracketedArg,
    Comment: Comment,
    Newline: Newline,

    pub fn text(self: Token) []const u8 {
        return switch (self) {
            .Cmd => |c| c.text,
            .Paren => |p| if (p.opener) "(" else ")",
            .UnquotedArg => |uq| uq.text,
            .QuotedArg => |q| q.text,
            .BracketedArg => |b| b.text,
            .Comment => |c| c.text,
            .Newline => |_| "\n",
        };
    }

    pub fn isNewLine(self: Token) bool {
        return switch (self) {
            .Newline => |_| true,
            else => false,
        };
    }
};

fn countEquals(source: []const u8, from: u32) u32 {
    return @intCast((mem.indexOfNonePos(u8, source, from, "=") orelse from) - from);
}

fn isSpace(source: u8) bool {
    return source == ' ' or source == '\t';
}

fn isCRLF(source: []const u8, i: u32) bool {
    return source[i] == '\r' and i + 1 < source.len and source[i + 1] == '\n';
}

fn isNewline(source: []const u8, i: u32) bool {
    return source[i] == '\n' or isCRLF(source, i);
}

// escape_sequence  ::=  escape_identity | escape_encoded | escape_semicolon
// escape_identity  ::=  '\' <match '[^A-Za-z0-9;]'>
// escape_encoded   ::=  '\t' | '\r' | '\n'
// escape_semicolon ::=  '\;'
fn isEscapeSequence(source: []const u8, i: u32) bool {
    std.debug.assert(source[i] == '\\');
    if (i + 1 < source.len) {
        return switch (source[i + 1]) {
            'r', 't', 'n', ';' => true,
            else => !std.ascii.isAlphanumeric(source[i + 1]),
        };
    }
    return false;
}

fn consumeWhitespace(source: []const u8, tokens: *std.ArrayList(Token), i: u32) !u32 {
    var j = i;
    while (j < source.len and std.ascii.isWhitespace(source[j])) {
        if (isNewline(source, j)) {
            j = try readNewline(source, tokens, j);
        } else {
            j += 1;
        }
    }
    return j;
}

fn readNewline(source: []const u8, tokens: *std.ArrayList(Token), i: u32) !u32 {
    var j = i;
    try tokens.append(Token{ .Newline = .{} });
    if (isCRLF(source, i)) {
        j += 1;
    }
    j += 1;
    return j;
}

fn tryReadBracketedArg(source: []const u8, tokens: *std.ArrayList(Token), i: *u32, errorOffset: *u32) !bool {
    i.* = readBracketedArg(source, tokens, i.*, errorOffset) catch |err| {
        if (err == ParseError.ExpectedAnotherBracket) {
            return false;
        } else {
            return err;
        }
    };
    return true;
}

// comment ::= bracket_comment | line_comment
// bracket_comment ::=  '#' bracket_argument
// line_comment ::=  '#' <any text not starting in a bracket_open
//                        and not containing a newline>
fn readComment(source: []const u8, tokens: *std.ArrayList(Token), i: u32, errorOffset: *u32) !u32 {
    // bracketed comment
    var j = i;
    if (j + 1 < source.len and source[j + 1] == '[') {
        // assume this is a bracket_comment, push the '#'
        try tokens.append(Token{ .Comment = .{ .bracketed = true, .text = source[j .. j + 1] } });
        // check if this is really a bracket_comment
        var k = j + 1;
        if (try tryReadBracketedArg(source, tokens, &k, errorOffset)) {
            return k;
        } else {
            // pop off the '#'
            const commentHash = tokens.pop();
            std.debug.assert(mem.eql(u8, commentHash.Comment.text, "#"));
        }
    }

    // line comment
    while (j < source.len and source[j] != '\n') : (j += 1) {}
    try tokens.append(Token{ .Comment = .{ .bracketed = false, .text = source[i..j] } });
    return j;
}

// bracket_argument ::=  bracket_open bracket_content bracket_close
// bracket_open     ::=  '[' '='* '['
// bracket_content  ::=  <any text not containing a bracket_close with
//                        the same number of '=' as the bracket_open>
// bracket_close    ::=  ']' '='* ']'
fn readBracketedArg(source: []const u8, tokens: *std.ArrayList(Token), i: u32, errorOffset: *u32) !u32 {
    std.debug.assert(source[i] == '[');

    var j = i + 1;
    const numEquals: u32 = countEquals(source, j);
    j += numEquals;

    // expect another [
    if (source[j] != '[') return ParseError.ExpectedAnotherBracket;

    while (j < source.len) : (j += 1) {
        if (source[j] == ']') {
            const equalsCount = countEquals(source, j + 1);
            const a = j + equalsCount + 1;
            if (equalsCount == numEquals and a < source.len and source[a] == ']') {
                j = a + 1;
                try tokens.append(Token{ .BracketedArg = .{ .text = source[i..j] } });
                return j;
            }
        }
    }
    errorOffset.* = j;
    std.debug.print("Unmatched brackets [[ ]]\n", .{});
    return ParseError.UnmatchedBrackets;
}

// quoted_argument     ::=  '"' quoted_element* '"'
// quoted_element      ::=  <any character except '\' or '"'> |
//                          escape_sequence |
//                          quoted_continuation
// quoted_continuation ::=  '\' newline
fn readQuotedArg(source: []const u8, tokens: *std.ArrayList(Token), i: u32, errorOffset: *u32) !u32 {
    std.debug.assert(source[i] == '"');
    var j = i + 1;
    while (j < source.len) : (j += 1) {
        switch (source[j]) {
            '\\' => { // process escape
                if (isEscapeSequence(source, j)) {
                    j += 1;
                    continue;
                }
                return ParseError.InvalidEscapeSequence;
            },
            '"' => {
                // end
                j += 1;
                try tokens.append(Token{ .QuotedArg = .{ .text = source[i..j] } });
                return j;
            },
            else => {},
        }
    }
    errorOffset.* = j;
    return ParseError.UnbalancedQuotes;
}

// unquoted_argument ::=  unquoted_element+ | unquoted_legacy
// unquoted_element  ::=  <any character except whitespace or one of '()#"\'> |
//                        escape_sequence
// unquoted_legacy   ::=  <see note in text> // can contain quotes
fn readUnquotedArg(source: []const u8, tokens: *std.ArrayList(Token), i: u32, errorOffset: *u32) !u32 {
    var j = i;
    var inQuotes: bool = false;

    while (j < source.len) : (j += 1) {
        switch (source[j]) {
            '"' => {
                inQuotes = !inQuotes;
            },
            '\\' => {
                if (isEscapeSequence(source, j)) {
                    j += 1;
                } else {
                    return ParseError.InvalidEscapeSequence;
                }
            },
            '(', '#', ')', ' ', '\t', '\n' => {
                // unquoted_legacy, horizontal whitespace allowed in quotes
                if (inQuotes and (source[j] == ' ' or source[j] == '\t')) {
                    continue;
                }

                try tokens.append(Token{ .UnquotedArg = .{ .text = source[i..j] } });
                if (isNewline(source, j)) {
                    return try readNewline(source, tokens, j);
                } else if (source[j] != '(' and source[j] != ')' and source[j] != '#') {
                    return j + 1;
                }
                break;
            },
            else => {},
        }
    }

    if (inQuotes) {
        errorOffset.* = j;
        return ParseError.UnbalancedQuotes;
    }

    return j;
}

// arguments           ::=  argument? separated_arguments*
// separated_arguments ::=  separation+ argument? |
//                          separation* '(' arguments ')'
// separation          ::=  space | line_ending
fn parseArgs(source: []const u8, tokens: *std.ArrayList(Token), i: u32, errorOffset: *u32) !u32 {
    var j = try consumeWhitespace(source, tokens, i);

    var parenDepth: u32 = 0;
    // argument ::=  bracket_argument | quoted_argument | unquoted_argument
    while (j < source.len) {
        if (std.ascii.isWhitespace(source[j])) {
            if (isNewline(source, j)) {
                j = try readNewline(source, tokens, j);
                continue;
            }
            j += 1;
        }
        // command end
        else if (source[j] == ')') {
            if (parenDepth == 0) {
                break;
            }
            parenDepth -= 1;
            j += 1;
            try tokens.append(Token{ .Paren = .{ .opener = false } });
        } else if (source[j] == '(') {
            parenDepth += 1;
            j += 1;
            try tokens.append(Token{ .Paren = .{ .opener = true } });
        }
        // read quoted arg
        else if (source[j] == '\"') {
            j = try readQuotedArg(source, tokens, j, errorOffset);
        }
        // read bracketed arg
        else if (source[j] == '[' and try tryReadBracketedArg(source, tokens, &j, errorOffset)) {
            //
        }
        // a comment
        else if (source[j] == '#') {
            j = try readComment(source, tokens, j, errorOffset);
        }
        // read unquoted arg
        else {
            j = try readUnquotedArg(source, tokens, j, errorOffset);
        }
    }
    return j;
}

// command_invocation  ::=  space* identifier space* '(' arguments ')'
// identifier          ::=  <match '[A-Za-z_][A-Za-z0-9_]*'>
fn parseCommand(source: []const u8, tokens: *std.ArrayList(Token), i: u32, errorOffset: *u32) !u32 {
    var j = i + 1;
    while (j < source.len) {
        if (std.ascii.isAlphanumeric(source[j]) or source[j] == '_') {
            j += 1;
        } else {
            break;
        }
    }

    try tokens.append(Token{ .Cmd = .{ .text = source[i..j] } });

    j = try consumeWhitespace(source, tokens, j);

    if (source[j] != '(') {
        std.debug.print("Expected a '(' after command: {s}\n", .{tokens.getLast().Cmd.text});
        return ParseError.InvalidSyntax;
    }
    try tokens.append(Token{ .Paren = .{ .opener = true } });
    j += 1;

    j = try parseArgs(source, tokens, j, errorOffset);

    if (source[j] != ')') {
        errorOffset.* = j;
        std.debug.print("Expected a ')' after command\n", .{});
        return ParseError.InvalidSyntax;
    }

    try tokens.append(Token{ .Paren = .{ .opener = false } });
    j += 1;
    return j;
}

fn lexImpl(source: []const u8, allocator: mem.Allocator, errorOffset: *u32) !std.ArrayList(Token) {
    var i: u32 = 0;
    var tokens = std.ArrayList(Token).init(allocator);
    errdefer tokens.deinit();

    while (i < source.len) {
        if (isSpace(source[i])) {
            i += 1;
        } else if (isNewline(source, i)) {
            i = try readNewline(source, &tokens, i);
        } else if (source[i] == '#') {
            i = try readComment(source, &tokens, i, errorOffset);
        } else {
            if (std.ascii.isAlphabetic(source[i]) or source[i] == '_') {
                i = try parseCommand(source, &tokens, i, errorOffset);
            } else {
                if (std.ascii.isPrint(source[i])) {
                    std.debug.print("Expected a command, got '{c}':\n", .{source[i]});
                } else {
                    std.debug.print("Expected a command, got ({d}):\n", .{source[i]});
                }
                errorOffset.* = i;
                return ParseError.InvalidSyntax;
            }
        }
    }

    // debug helper
    if (false) {
        std.debug.print("Tokens count: {d}\n", .{tokens.items.len});
        for (tokens.items) |t| {
            std.debug.print("Token({s}) '{s}'\n", .{ @tagName(t), t.text() });
        }
        //         std.debug.print("{s}", .{source});
    }

    return tokens;
}

fn isParseError(err: anyerror) bool {
    return switch (err) {
        ParseError.ExpectedAnotherBracket, ParseError.UnmatchedBrackets, ParseError.InvalidEscapeSequence, ParseError.UnbalancedQuotes, ParseError.InvalidSyntax => true,
        else => false,
    };
}

pub fn lex(source: []const u8, allocator: mem.Allocator, errorPosition: *?Position) !std.ArrayList(Token) {
    var errorOffset: u32 = 1;
    return lexImpl(source, allocator, &errorOffset) catch |err| {
        if (isParseError(err)) {
            var pos: usize = 0;
            var line: u32 = 0;
            var nextLineStart: usize = 0;

            while (true) {
                const nextNewline = std.mem.indexOfScalarPos(u8, source, pos, '\n');
                if (nextNewline == null or nextNewline.? > errorOffset) {
                    nextLineStart = if (nextNewline == null) source.len else nextNewline.?;
                    break;
                }
                pos = nextNewline.? + 1;
                line += 1;
            }
            const column: u32 = @intCast(errorOffset - pos);
            const lineText = source[pos..nextLineStart];
            std.debug.print("{s}\n", .{lineText});
            for (0..column) |_| {
                std.debug.print(" ", .{});
            }
            std.debug.print("^\n", .{});

            errorPosition.* = .{
                .line = line + 1,
                .col = column + 1,
            };
        }
        return err;
    };
}

test {
    _ = @import("lexer_test.zig");
}
