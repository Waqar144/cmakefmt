const std = @import("std");
const mem = std.mem;
const lex = @import("lexer.zig");
const builtin_commands = @import("builtin_commands.zig");
const Options = @import("args.zig").Options;

var indent: u32 = 0;
const indentWidth = 4;
var currentTokenIndex: u32 = 0;
var gTokens: []const lex.Token = undefined;
var gOutBuffer: *std.ArrayList(u8) = undefined;
var prevWasNewline: bool = false;
var useCRLF = false;

fn strequal(a: []const u8, b: []const u8) bool {
    return mem.eql(u8, a, b);
}

fn write(text: []const u8) void {
    _ = gOutBuffer.appendSlice(text) catch |err| {
        std.log.err("Error when writing {s}", .{@errorName(err)});
    };
    if (mem.trim(u8, text, " ").len == 0) return;
    prevWasNewline = mem.endsWith(u8, text, "\n");
}

fn writeln() void {
    write(if (useCRLF) "\r\n" else "\n");
    prevWasNewline = true;
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
        if (strequal(c, text))
            return true;
    }
    return false;
}

fn isControlStructureEnd(text: []const u8) bool {
    const controlStructs = [_][]const u8{ "endif", "endforeach", "endfunction", "endmacro", "endwhile", "endblock" };
    for (controlStructs) |c| {
        if (strequal(c, text))
            return true;
    }
    return false;
}

fn peekNext() ?lex.Token {
    if (currentTokenIndex + 1 < gTokens.len)
        return gTokens[currentTokenIndex + 1];
    return null;
}

fn isElse() bool {
    const nextToken = peekNext();
    return nextToken != null and std.meta.activeTag(nextToken.?) == .Cmd and strequal(nextToken.?.Cmd.text, "else");
}

fn isNextTokenNewline() bool {
    const nextToken = peekNext();
    return nextToken != null and nextToken.?.isNewLine();
}

fn isNextTokenParen() bool {
    const nextToken = peekNext();
    return nextToken != null and std.meta.activeTag(nextToken.?) == .Paren;
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
    var j = currentTokenIndex + 1;
    while (j < gTokens.len) : (j += 1) {
        switch (gTokens[j]) {
            .UnquotedArg, .QuotedArg, .BracketedArg => return strequal(text, gTokens[j].text()),
            .Newline => continue,
            else => return false,
        }
    }
    return false;
}

fn countArgsInLine(fromTokenIndex: u32) u32 {
    var numArgsInLine: u32 = 0;
    var j: u32 = fromTokenIndex;
    while (j < gTokens.len) : (j += 1) {
        switch (gTokens[j]) {
            .UnquotedArg, .QuotedArg, .BracketedArg => numArgsInLine += 1,
            .Newline => break,
            else => continue,
        }
    }
    return numArgsInLine;
}

// compoundArg := ( arg+ )
fn handleCompoundArg() void {
    std.debug.assert(std.meta.activeTag(gTokens[currentTokenIndex]) == .Paren);
    currentTokenIndex += 1;
    var parenDepth: i32 = 1;

    // This function atm is too simple
    // it just keeps all the args on a single line

    while (currentTokenIndex < gTokens.len) {
        switch (gTokens[currentTokenIndex]) {
            .Cmd => |c| std.debug.panic("Command in unexpected position {s}", .{c.text}),
            .Paren => |p| {
                parenDepth += if (p.opener) 1 else -1;

                handleParen(p);

                if (parenDepth == 0) {
                    return;
                } else if (p.opener) {
                    handleCompoundArg();

                    std.debug.assert(std.meta.activeTag(gTokens[currentTokenIndex]) == .Paren and
                        gTokens[currentTokenIndex].Paren.opener == false);
                    parenDepth -= 1;
                }
            },
            .UnquotedArg, .QuotedArg, .BracketedArg => {
                const a = gTokens[currentTokenIndex];
                write(a.text());

                if (!isNextTokenParenClose()) {
                    write(" ");
                }
            },
            .Comment => |c| handleComment(c),
            .Newline => |_| {},
        }
        currentTokenIndex += 1;
    }
}

fn handleCommand(cmd: lex.Command) void {
    write(cmd.text);

    const maybeCommandKeywords = builtin_commands.gCommandMap.get(cmd.text);

    currentTokenIndex += 1;
    var bracketDepth: i32 = 0;
    indent += 1;
    // number of new lines that will be found in the block
    var newlines: u32 = 0;
    var numArgsInLine: u32 = countArgsInLine(currentTokenIndex + 1);
    var argTextLen: usize = 0;

    while (currentTokenIndex < gTokens.len) {
        switch (gTokens[currentTokenIndex]) {
            .Cmd => |c| {
                std.log.err("command in unexpected place, probably a bug: {s} {s}\n", .{ cmd.text, c.text });
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
                } else if (bracketDepth > 1 and p.opener) {
                    handleCompoundArg();

                    std.debug.assert(std.meta.activeTag(gTokens[currentTokenIndex]) == .Paren and
                        gTokens[currentTokenIndex].Paren.opener == false);
                    bracketDepth -= 1;
                }
            },
            .UnquotedArg, .QuotedArg, .BracketedArg => blk: {
                const argText = gTokens[currentTokenIndex].text();
                if (maybeCommandKeywords) |commandKeywords| {
                    if (commandKeywords.hasArgWithValueKeyword(argText)) {
                        var newlinesInserted: bool = false;
                        const argOnSameLineAsCmd = newlines == 0;
                        if (handleMultiArgs(commandKeywords, argOnSameLineAsCmd, &newlinesInserted, bracketDepth)) {
                            newlines += if (newlinesInserted) 1 else 0;
                            break :blk;
                        }
                    }
                }

                write(argText);
                argTextLen += argText.len + 1; // 1 for space
                const nextArgLen = if (currentTokenIndex + 1 < gTokens.len and !isNextTokenNewline()) peekNext().?.text().len else 0;

                // if there are > 5 args on a line, then split them with newlines
                if ((argTextLen + nextArgLen + (indent * indentWidth) > 120 or numArgsInLine > 5) and !isNextTokenNewline() and !isNextTokenParen()) {
                    handleNewline();
                    newlines += 1;
                    argTextLen = 0;
                } else if (!isNextTokenNewline() and !isNextTokenParenClose()) {
                    write(" ");
                }
            },
            .Comment => |c| {
                handleComment(c);
            },
            .Newline => |_| blk: {
                // if there is only 1 newline and the next token is ')', then skip this newline
                // and move the paren to prev
                if (newlines == 0 and isNextTokenParenClose() and bracketDepth - 1 == 0)
                    break :blk;
                handleNewline();
                newlines += 1;
                numArgsInLine = countArgsInLine(currentTokenIndex + 1);
                argTextLen = 0;
            },
        }

        currentTokenIndex += 1;
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

fn handleMultiArgs(commandKeywords: builtin_commands.CommandKeywords, argOnSameLineAsCmd: bool, newlinesInserted: *bool, currentBracketDepth: i32) bool {
    // count multi args
    const isOneValueArg = commandKeywords.isOneValueArg(gTokens[currentTokenIndex].text());

    var k = currentTokenIndex + 1;
    var bracketDepth = currentBracketDepth;
    var numArgsForMultiArg: u32 = 0;
    while (k < gTokens.len) : (k += 1) {
        const arg = gTokens[k];
        switch (arg) {
            .UnquotedArg, .QuotedArg, .BracketedArg => {
                if (commandKeywords.contains(arg.text()))
                    break;
                numArgsForMultiArg += 1;
                if (isOneValueArg) {
                    if (k + 1 < gTokens.len) {
                        const next = gTokens[k + 1];
                        if (std.meta.activeTag(next) == .Comment) {
                            numArgsForMultiArg += 1;
                            if (next.Comment.bracketed) numArgsForMultiArg += 1;
                        }
                    }
                    break;
                }
            },
            .Paren => |p| {
                bracketDepth += if (p.opener) 1 else -1;
                if (bracketDepth == 0)
                    break;
            },
            .Comment => |c| {
                numArgsForMultiArg += 1;
                if (c.bracketed) {
                    k += 1;
                    numArgsForMultiArg += 1;
                }
            },
            .Cmd => {
                std.log.err("Command in unexpected place, this is a bug", .{});
                std.process.exit(1);
            },
            else => continue,
        }
    }

    // there are no values, return now and let the generic handler handle this arg
    if (numArgsForMultiArg == 0) {
        return false;
    }

    var j = currentTokenIndex;
    write(gTokens[j].text());
    const isPROPERTIES = strequal(gTokens[j].text(), "PROPERTIES");
    const isCOMMAND = strequal(gTokens[j].text(), "COMMAND");
    j += 1;

    // separate args with newline if there are more than 3 args
    // TODO: probably account for text length here along with num args
    var seperateWithNewline = (numArgsForMultiArg > 3) and !isOneValueArg;

    if (seperateWithNewline) {
        newlinesInserted.* = true;
        writeln();
        const inc: u32 = if (isPROPERTIES) 0 else if (argOnSameLineAsCmd) 0 else 1;
        writeIndent(indent + inc);
    } else {
        write(" ");
    }

    // we try to put the command on the next line, not separate all the args on one line each
    if (isCOMMAND) {
        seperateWithNewline = false;
    }

    var isKey = true;
    var processed: u32 = 0;
    while (processed < numArgsForMultiArg) : (j += 1) {
        const arg = gTokens[j];
        switch (arg) {
            .UnquotedArg, .QuotedArg, .BracketedArg => {
                const isLast = processed + 1 == numArgsForMultiArg;
                write(arg.text());

                if (isPROPERTIES) {
                    // key value\n
                    if (!isLast) {
                        if (!isKey) {
                            writeln();
                            writeIndent(indent);
                        } else {
                            write(" ");
                        }
                        isKey = !isKey;
                    }
                } else {
                    if (!isLast and seperateWithNewline) {
                        writeln();
                        const inc: u32 = if (argOnSameLineAsCmd) 0 else 1;
                        writeIndent(indent + inc);
                    } else if (!isLast) {
                        write(" ");
                    }
                }
                processed += 1;
            },
            .Comment => |c| {
                processed += 1;
                if (c.bracketed) {
                    write(c.text);
                    j += 1;
                    processed += 1;
                    const isLast = processed == numArgsForMultiArg;
                    std.debug.assert(std.meta.activeTag(gTokens[j]) == .BracketedArg);
                    write(gTokens[j].text());
                    if (!isLast and seperateWithNewline) {
                        writeln();
                        const inc: u32 = if (argOnSameLineAsCmd) 0 else 1;
                        writeIndent(indent + inc);
                    } else if (!isLast) {
                        write(" ");
                    }
                } else {
                    const isLast = processed == numArgsForMultiArg;
                    write(c.text);
                    if (!isLast) {
                        writeln();
                        const inc: u32 = if (isPROPERTIES) 0 else 1;
                        writeIndent(indent + inc);
                    }
                }
            },
            else => continue,
        }
    }

    currentTokenIndex = j - 1;

    if (!isNextTokenNewline() and !isNextTokenParenClose()) {
        newlinesInserted.* = true;
        writeln();
        writeIndent(indent);
    }
    return true;
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
    //     const atStartOfLine = currentTokenIndex == 0 or currentTokenIndex > 0 and gtokens[currentTokenIndex - 1].isNewLine();
    // add a space between prev element and comment if we are not at the start of line
    if (!prevWasNewline and (gOutBuffer.items.len > 0 and gOutBuffer.getLast() != ' ')) {
        write(" ");
    }
    write(mem.trimLeft(u8, a.text, " "));

    if (a.bracketed) {
        currentTokenIndex += 1;
        write(gTokens[currentTokenIndex].text());
    }
}

fn handleNewline() void {
    writeln();

    // allow one more newline
    if (currentTokenIndex + 1 < gTokens.len) {
        var j = currentTokenIndex;
        if (gTokens[j + 1].isNewLine()) {
            writeln();

            // skip the two processed newlines
            j += 2;

            while (j < gTokens.len) : (j += 1) {
                if (!gTokens[j].isNewLine())
                    break;
            }
            currentTokenIndex = j - 1;
        }
    }

    var toIndent = indent;
    // reduce indent if
    // - the next token is an end block command
    // - the next token is )
    // - the next token is else
    if (indent > 0 and currentTokenIndex + 1 < gTokens.len) {
        const nextToken = gTokens[currentTokenIndex + 1];
        const tag = std.meta.activeTag(nextToken);
        if ((tag == lex.Token.Cmd and isControlStructureEnd(nextToken.Cmd.text)) or isNextTokenParenClose() or isElse()) {
            toIndent = indent - 1;
        }
    } else if (currentTokenIndex + 1 >= gTokens.len) {
        return;
    }

    writeIndent(toIndent);
}

pub fn format(tokens: std.ArrayList(lex.Token), inFileSize: usize, options: Options, sourceHasCRLF: bool) void {
    currentTokenIndex = 0;
    gTokens = tokens.items;
    useCRLF = sourceHasCRLF;

    // Write formatted text to a buffer
    var formattedText = std.ArrayList(u8).initCapacity(tokens.allocator, inFileSize + (inFileSize / 2)) catch |err| {
        std.log.err("Failed to allocate buffer. Error: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
    defer formattedText.deinit();
    gOutBuffer = &formattedText;

    while (currentTokenIndex < gTokens.len) {
        const token = gTokens[currentTokenIndex];

        switch (token) {
            .Cmd => |c| handleCommand(c),
            .UnquotedArg, .QuotedArg, .BracketedArg, .Paren => {
                std.log.err("Args/Parens should already be handled in handleCommand, this is a bug\n", .{});
                std.debug.assert(false);
            },
            .Comment => |c| handleComment(c),
            .Newline => |_| handleNewline(),
        }

        currentTokenIndex += 1;
    }

    if (!options.inplace) {
        // Write out to stdout
        _ = std.io.getStdOut().writeAll(formattedText.items) catch |e| {
            std.log.err("Failed to write. Error: {s}\n", .{@errorName(e)});
        };
    } else {
        // Write to given file
        const file = std.fs.cwd().createFile(options.filename, .{}) catch |e| {
            std.log.err("Failed to open file for writing. Error: {s}\n", .{@errorName(e)});
            std.process.exit(1);
        };
        _ = file.writeAll(formattedText.items) catch |e| {
            std.log.err("Failed to write. Error: {s}\n", .{@errorName(e)});
            std.process.exit(1);
        };
    }
}
