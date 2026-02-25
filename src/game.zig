const std = @import("std");

export fn hello() void {
    print() catch unreachable;
}

fn print() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Hello, World!\n", .{});

    try stdout.flush();
}
