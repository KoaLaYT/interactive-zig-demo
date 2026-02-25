const std = @import("std");
const State = @import("game_api.zig").State;
const Api = @import("game_api.zig").Api;

const Game = struct {
    lib: ?std.DynLib,
    inode: std.c.ino_t,
    state: ?State,
    api: *const Api,

    // TODO

    fn init() Game {
        return .{
            .lib = null,
            .inode = 0,
            .state = null,
            .api = undefined,
        };
    }

    fn deinit(self: *Game) void {
        if (self.lib) |*lib| {
            if (self.state) |*s| {
                self.api.finalize(s);
            }
            lib.close();
        }

        self.lib = null;
        self.inode = 0;
        self.state = null;
        self.api = undefined;
    }

    fn load(self: *Game, lib_path: []u8) !void {
        const f = try std.fs.openFileAbsolute(lib_path, .{});
        defer f.close();
        const stat = try f.stat();

        if (stat.inode != self.inode) {
            if (self.lib) |*lib| {
                if (self.state) |*s| {
                    self.api.unload(s);
                }
                lib.close();
            }

            var lib = try std.DynLib.open(lib_path);
            self.api = lib.lookup(*const Api, "api").?;
            self.lib = lib;
            if (self.state == null) {
                self.state = self.api.init();
            }

            if (self.state) |*s| {
                self.api.reload(s);
            }
        }
    }

    fn run(self: *Game) void {
        if (self.state) |*s| {
            self.api.next(s);
        }
    }
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
        g.run();
        std.Thread.sleep(100000000);
    }
}
