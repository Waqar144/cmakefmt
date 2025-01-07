const std = @import("std");
const lex = @import("lexer.zig");

var indent: u32 = 0;
const indentWidth = 4;
var currentTokenIndex: *u32 = undefined;
var gtokens: *const std.ArrayList(lex.Token) = undefined;
var g_outFile: *const std.fs.File = undefined;
const gCommandMap = std.StaticStringMapWithEql([]const []const u8, std.static_string_map.eqlAsciiIgnoreCase).initComptime(.{
    .{ "find_package", &.{ "COMPONENTS", "OPTIONAL_COMPONENTS", "NAMES", "CONFIGS", "HINTS", "PATHS", "PATH_SUFFIXES" } },
    .{ "find_library", &.{ "NAMES", "HINTS", "PATHS", "PATH_SUFFIXES" } },
});

fn strequal(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn write(text: []const u8) void {
    _ = g_outFile.write(text) catch |err| {
        std.log.err("Error when writing {s}", .{@errorName(err)});
    };
}

fn writeln() void {
    write("\n");
}

fn writeIndent(indent_level: u32) void {
    for (0..indent_level) |_| {
        for (0..indentWidth) |_| {
            write(" ");
        }
    }
}

fn isControlStructureBegin(text: []const u8) bool {
    const controlStructs = [_][]const u8{ "if", "foreach", "function", "macro", "while", "block" };
    for (controlStructs) |c| {
        if (std.mem.eql(u8, c, text))
            return true;
    }
    return false;
}

fn isControlStructureEnd(text: []const u8) bool {
    const controlStructs = [_][]const u8{ "endif", "endforeach", "endfunction", "endmacro", "endwhile", "endblock" };
    for (controlStructs) |c| {
        if (std.mem.eql(u8, c, text))
            return true;
    }
    return false;
}

fn peekNext() ?lex.Token {
    if (currentTokenIndex.* + 1 < gtokens.items.len)
        return gtokens.items[currentTokenIndex.* + 1];
    return null;
}

fn isElse() bool {
    const nextToken = peekNext();
    return nextToken != null and std.meta.activeTag(nextToken.?) == .Cmd and std.mem.eql(u8, nextToken.?.Cmd.text, "else");
}

fn isNextTokenNewline() bool {
    const nextToken = peekNext();
    return nextToken != null and nextToken.?.isNewLine();
}

fn isNextTokenParenClose() bool {
    const nextToken = peekNext();
    return nextToken != null and std.meta.activeTag(nextToken.?) == .Paren and !nextToken.?.Paren.opener;
}

fn isNextTokenComment() bool {
    const nextToken = peekNext();
    return nextToken != null and std.meta.activeTag(nextToken.?) == .Comment;
}

fn nextArgEquals(text: []const u8) bool {
    var j = currentTokenIndex.* + 1;
    while (j < gtokens.items.len) : (j += 1) {
        switch (gtokens.items[j]) {
            .UnquotedArg, .QuotedArg, .BracketedArg => return std.mem.eql(u8, text, gtokens.items[j].text()),
            .Newline => continue,
            else => return false,
        }
    }
    return false;
}

fn countArgsInLine(fromTokenIndex: u32) u32 {
    var numArgsInLine: u32 = 0;
    var j: u32 = fromTokenIndex;
    while (j < gtokens.items.len) : (j += 1) {
        switch (gtokens.items[j]) {
            .UnquotedArg, .QuotedArg, .BracketedArg => numArgsInLine += 1,
            .Newline => break,
            else => continue,
        }
    }
    return numArgsInLine;
}

fn handleCommand(cmd: lex.Command) void {
    write(cmd.text);

    const emptyArgs: []const []const u8 = &.{};
    const multiArgsList = gCommandMap.get(cmd.text) orelse emptyArgs;

    currentTokenIndex.* += 1;
    var bracketDepth: i32 = 0;
    var prevWasNewline = false;
    indent += 1;
    // number of new lines that will be found in the block
    var newlines: u32 = 0;
    var numArgsInLine: u32 = countArgsInLine(currentTokenIndex.* + 1);
    var argTextLen: usize = 0;

    while (currentTokenIndex.* < gtokens.items.len) {
        switch (gtokens.items[currentTokenIndex.*]) {
            .Cmd => |_| {
                std.log.err("command in unexpected place, probably a bug: {s}\n", .{cmd.text});
                std.process.exit(1);
            },
            .Paren => |p| {
                bracketDepth += if (p.opener) 1 else -1;

                // if the open paren and close isn't on the same line then push it to a newline
                if (bracketDepth == 0 and !prevWasNewline and !p.opener and newlines > 0) {
                    writeln();
                    // indent as needed
                    writeIndent(indent - 1);
                }

                handleParen(p);

                if (bracketDepth == 0) {
                    break;
                }
                prevWasNewline = false;
            },
            .UnquotedArg, .QuotedArg, .BracketedArg => blk: {
                const argText = gtokens.items[currentTokenIndex.*].text();
                var found: bool = false;
                if (multiArgsList.len != 0) {
                    for (multiArgsList) |arg| {
                        if (strequal(arg, argText)) {
                            found = true;
                            break;
                        }
                    }

                    if (found) {
                        var newlinesInserted: bool = false;
                        handleMultiArgs(multiArgsList, &newlinesInserted);
                        prevWasNewline = newlinesInserted;
                        newlines += if (newlinesInserted) 1 else 0;
                        break :blk;
                    }
                }

                write(argText);
                argTextLen += argText.len + 1; // 1 for space
                const nextArgLen = if (currentTokenIndex.* + 1 < gtokens.items.len and !isNextTokenNewline()) peekNext().?.text().len else 0;

                prevWasNewline = false;
                // if there are > 5 args on a line, then split them with newlines
                if ((argTextLen + nextArgLen + (indent * indentWidth) > 120) or (numArgsInLine > 5 and !isNextTokenNewline())) {
                    handleNewline();
                    prevWasNewline = true;
                    newlines += 1;
                    argTextLen = 0;
                } else if (!isNextTokenNewline() and !isNextTokenParenClose()) {
                    write(" ");
                }
            },
            .Comment => |c| {
                prevWasNewline = false;
                handleComment(c);
            },
            .Newline => |_| {
                handleNewline();
                prevWasNewline = true;
                newlines += 1;
                numArgsInLine = countArgsInLine(currentTokenIndex.* + 1);
            },
        }

        currentTokenIndex.* += 1;
    }

    if (bracketDepth != 0) {
        std.log.err("unbalanced brackets when processing: {s}\n", .{cmd.text});
        std.process.exit(1);
    }
    indent -= 1;

    if (isControlStructureBegin(cmd.text)) {
        indent += 1;
    } else if (isControlStructureEnd(cmd.text)) {
        if (indent == 0) {
            std.log.err("unbalanced control structure when processing: {s}\n", .{cmd.text});
            std.process.exit(1);
        }
        indent -= 1;
    }
}

fn handleMultiArgs(multiArgsForCommand: []const []const u8, newlinesInserted: *bool) void {
    var j = currentTokenIndex.*;
    write(gtokens.items[j].text());
    j += 1;

    // count multi args
    var k = j;
    var numArgsForMultiArg: u32 = 0;
    out: while (k < gtokens.items.len) : (k += 1) {
        const arg = gtokens.items[k];
        switch (arg) {
            .UnquotedArg, .QuotedArg, .BracketedArg => {
                for (multiArgsForCommand) |a| {
                    // Break if we reach another multi arg
                    if (strequal(a, arg.text())) {
                        break :out;
                    }
                }
                numArgsForMultiArg += 1;
            },
            .Cmd => break,
            else => continue,
        }
    }

    // separate args with newline if there are more than 3 args
    // TODO: probably account for text length here along with num args
    const seperateWithNewline = (numArgsForMultiArg > 3);

    if (seperateWithNewline) {
        newlinesInserted.* = true;
        write("\n");
        writeIndent(indent + 1);
    } else {
        write(" ");
    }

    var processed: u32 = 0;
    while (processed < numArgsForMultiArg) : (j += 1) {
        const arg = gtokens.items[j];
        switch (arg) {
            .UnquotedArg, .QuotedArg, .BracketedArg => {
                write(arg.text());
                const isLast = processed + 1 == numArgsForMultiArg;
                if (seperateWithNewline) {
                    const increment: u32 = if (isLast) 0 else 1;
                    write("\n");
                    writeIndent(indent + increment);
                } else if (!isLast) {
                    write(" ");
                }
                processed += 1;
            },
            else => continue,
        }
    }

    currentTokenIndex.* = j - 1;

    if (seperateWithNewline and j < gtokens.items.len and gtokens.items[j].isNewLine()) {
        currentTokenIndex.* += 1;
    }
}

fn handleParen(a: lex.Paren) void {
    if (a.opener) {
        write("(");
    } else {
        write(")");

        // add space if
        // - next is not newline
        // - next is not paren
        if (!isNextTokenParenClose() and !isNextTokenNewline() and !isNextTokenComment()) {
            write(" ");
        }
    }
}

fn handleComment(a: lex.Comment) void {
    const atStartOfLine = currentTokenIndex.* == 0 or currentTokenIndex.* > 0 and gtokens.items[currentTokenIndex.* - 1].isNewLine();
    // add a space between prev element and comment if we are not at the start of line
    if (!atStartOfLine) {
        write(" ");
    }
    write(std.mem.trimLeft(u8, a.text, " "));
}

fn handleNewline() void {
    writeln();

    // allow one more newline
    if (currentTokenIndex.* + 1 < gtokens.items.len) {
        var j = currentTokenIndex.*;
        if (gtokens.items[j + 1].isNewLine()) {
            writeln();

            // skip the two processed newlines
            j += 2;

            while (j < gtokens.items.len) : (j += 1) {
                if (!gtokens.items[j].isNewLine())
                    break;
            }
            currentTokenIndex.* = j - 1;
        }
    }

    var toIndent = indent;
    // reduce indent if
    // - the next token is an end block command
    // - the next token is )
    // - the next token is else
    if (indent > 0 and currentTokenIndex.* + 1 < gtokens.items.len) {
        const nextToken = gtokens.items[currentTokenIndex.* + 1];
        const tag = std.meta.activeTag(nextToken);
        if ((tag == lex.Token.Cmd and isControlStructureEnd(nextToken.Cmd.text)) or isNextTokenParenClose() or isElse()) {
            toIndent = indent - 1;
        }
    }

    writeIndent(toIndent);
}

pub fn format(tokens: std.ArrayList(lex.Token)) void {
    var i: u32 = 0;
    currentTokenIndex = &i;
    gtokens = &tokens;

    const stdout = std.io.getStdOut();
    g_outFile = &stdout;

    while (i < tokens.items.len) {
        const token = tokens.items[i];

        switch (token) {
            .Cmd => |c| handleCommand(c),
            .UnquotedArg, .QuotedArg, .BracketedArg, .Paren => {
                std.log.err("Args/Parens should already be handled in handleCommand, this is a bug\n", .{});
                std.debug.assert(false);
            },
            .Comment => |c| handleComment(c),
            .Newline => |_| handleNewline(),
        }

        i += 1;
    }
}
