const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const State = @import("game_api.zig").State;
const Api = @import("game_api.zig").Api;

const Game = struct {
    lib: ?std.DynLib,
    inode: std.c.ino_t,
    state: ?State,
    api: *const Api,

    fn init() Game {
        return .{
            .lib = null,
            .inode = 0,
            .state = null,
            .api = undefined,
        };
    }

    fn deinit(self: *Game, alloc_ptr: *anyopaque) void {
        if (self.lib) |*lib| {
            if (self.state) |*s| {
                self.api.finalize(s, alloc_ptr);
            }
            lib.close();
        }

        self.lib = null;
        self.inode = 0;
        self.state = null;
        self.api = undefined;
    }

    fn load(self: *Game, alloc_ptr: *anyopaque, lib_path: []u8) !void {
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
            self.inode = stat.inode;

            if (self.state == null) {
                self.state = self.api.init(alloc_ptr);
            }

            if (self.state) |*s| {
                self.api.reload(s);
            }
        }
    }

    fn run(self: *Game) bool {
        if (self.state) |*s| {
            return self.api.step(s);
        }
        return false;
    }
};

pub fn main() !void {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const exe_dir = try std.fs.selfExeDirPath(&buf);
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const lib_path = try std.fmt.bufPrint(&path_buf, "{s}/../lib/libgame.dylib", .{exe_dir});

    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();
    const opaque_ptr: *anyopaque = @ptrCast(&allocator);

    var g = Game.init();
    defer g.deinit(opaque_ptr);

    while (true) {
        try g.load(opaque_ptr, lib_path);
        if (!g.run()) {
            break;
        }
        std.Thread.sleep(100 * std.time.ns_per_ms);
    }
}
