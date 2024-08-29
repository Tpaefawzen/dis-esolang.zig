const std = @import("std");

var arg0: [:0]const u8 = undefined;

fn usage(succeed: bool) noreturn {
    // std.debug.print("Usage: {s} [-Ev] [-k steps] [-O level] FILE\n", .{arg0});
    std.debug.print("Usage: {s} FILE\n", .{arg0});
    std.process.exit(if ( succeed ) 0 else 1);
}

pub fn main() !void {
    var args = std.process.args(); 
    defer args.deinit();

    arg0 = args.next() orelse "dis-esolang";

    const filename = args.next() orelse usage(false);

    _ = filename;

    std.process.exit(0);
}
