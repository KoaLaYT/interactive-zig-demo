const std = @import("std");

const Game = struct {
    lib: ?std.DynLib,
    inode: std.c.ino_t,
    hello: *const fn () void,

    // TODO

    fn init() Game {
        return .{
            .lib = null,
            .inode = 0,
            .hello = undefined,
        };
    }

    fn deinit(self: *Game) void {
        if (self.lib) |*lib| {
            lib.close();
        }
    }

    fn load(self: *Game, lib_path: []u8) !void {
        const f = try std.fs.openFileAbsolute(lib_path, .{});
        defer f.close();
        const stat = try f.stat();

        if (stat.inode != self.inode) {
            if (self.lib) |*lib| {
                lib.close();
            }

            var lib = try std.DynLib.open(lib_path);
            self.hello = lib.lookup(*const fn () void, "hello").?;
            self.lib = lib;
        }
    }

    fn run() void {}
};

pub fn main() !void {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const exe_dir = try std.fs.selfExeDirPath(&buf);
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const lib_path = try std.fmt.bufPrint(&path_buf, "{s}/../lib/libgame.dylib", .{exe_dir});

    var g = Game.init();
    defer g.deinit();

    while (true) {
        try g.load(lib_path);
        g.hello();
        std.Thread.sleep(100000000);
    }
}
