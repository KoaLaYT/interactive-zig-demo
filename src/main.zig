const std = @import("std");

extern fn bufferedPrint() void;

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    bufferedPrint();
}
