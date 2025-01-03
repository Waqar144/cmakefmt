const std = @import("std");
const lex = @import("lexer.zig");

var indent: u32 = 0;
const indentWidth = 4;
var currentTokenIndex: *u32 = undefined;
var gtokens: *const std.ArrayList(lex.Token) = undefined;

var g_outFile: *const std.fs.File = undefined;

fn write(text: []const u8) void {
    _ = g_outFile.write(text) catch |err| {
        std.log.err("Error when writing {s}", .{@errorName(err)});
    };
}

fn writeln() void {
    write("\n");
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
    return nextToken != null and std.meta.activeTag(nextToken.?) == .Cmd and std.mem.eql(u8, nextToken.?.Cmd.name, "else");
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

fn handleCommand(cmd: lex.Command) void {
    write(cmd.name);

    if (isControlStructureBegin(cmd.name)) {
        indent += 1;
    } else if (isControlStructureEnd(cmd.name)) {
        if (indent == 0) {
            std.log.err("unbalanced control structure when processing: {s}", .{cmd.name});
            std.process.exit(1);
        }
        indent -= 1;
    }
}

fn handleParen(a: lex.Paren) void {
    if (a.opener) {
        write("(");
        indent += 1;
    } else {
        write(")");

        // add space if
        // - next is not newline
        // - next is not paren
        if (!isNextTokenParenClose() and !isNextTokenNewline() and !isNextTokenComment()) {
            write(" ");
        }

        indent -= 1;
    }
}

fn handleUnquotedArg(a: lex.UnquotedArg) void {
    write(a.name);

    if (!isNextTokenNewline() and !isNextTokenParenClose()) {
        write(" ");
    }
}

fn handleQuotedArg(a: lex.QuotedArg) void {
    write(a.name);

    if (!isNextTokenNewline() and !isNextTokenParenClose()) {
        write(" ");
    }
}

fn handleBracketedArg(a: lex.BracketedArg) void {
    write(a.name);

    if (!isNextTokenNewline() and !isNextTokenParenClose()) {
        write(" ");
    }
}

fn handleComment(a: lex.Comment) void {
    const atStartOfLine = currentTokenIndex.* == 0 or currentTokenIndex.* > 0 and gtokens.items[currentTokenIndex.* - 1].isNewLine();
    // add a space between prev element and comment if we are not at the start of line
    if (!atStartOfLine) {
        write(" ");
    }
    write(std.mem.trimLeft(u8, a.name, " "));
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

    // reduce indent if
    // - the next token is an end block command
    // - the next token is )
    // - the next token is else
    if (indent > 0 and currentTokenIndex.* + 1 < gtokens.items.len) {
        const nextToken = gtokens.items[currentTokenIndex.* + 1];
        const tag = std.meta.activeTag(nextToken);
        const toIndent = if ((tag == lex.Token.Cmd and isControlStructureEnd(nextToken.Cmd.name)) or isNextTokenParenClose() or isElse())
            indent - 1
        else
            indent;

        for (0..toIndent) |_| {
            for (0..indentWidth) |_| {
                write(" ");
            }
        }
    }
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
            .Paren => |p| handleParen(p),
            .UnquotedArg => |uq| handleUnquotedArg(uq),
            .QuotedArg => |q| handleQuotedArg(q),
            .BracketedArg => |b| handleBracketedArg(b),
            .Comment => |c| handleComment(c),
            .Newline => |_| handleNewline(),
        }

        i += 1;
    }
}
