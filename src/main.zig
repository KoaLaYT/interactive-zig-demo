const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const State = @import("game_api.zig").State;
const Api = @import("game_api.zig").Api;

const Game = struct {
    lib: ?std.DynLib,
    inode: std.c.ino_t,
    state: State,
    api: *const Api,

    fn init(alloc_ptr: *anyopaque) Game {
        return .{
            .lib = null,
            .inode = 0,
            .state = State.init(alloc_ptr),
            .api = undefined,
        };
    }

    fn deinit(self: *Game) void {
        if (self.lib) |*lib| {
            self.api.finalize(&self.state);
            lib.close();
        }
    }

    fn load(self: *Game, lib_path: []u8) !void {
        const f = try std.fs.openFileAbsolute(lib_path, .{});
        defer f.close();
        const stat = try f.stat();

        if (stat.inode != self.inode) {
            if (self.lib) |*lib| {
                self.api.unload(&self.state);
                lib.close();
            }

            var lib = try std.DynLib.open(lib_path);
            self.api = lib.lookup(*const Api, "api").?;
            self.lib = lib;
            self.inode = stat.inode;

            if (!self.state.has_init) {
                self.api.init(&self.state);
            }

            self.api.reload(&self.state);
        }
    }

    fn run(self: *Game) bool {
        return self.api.step(&self.state);
    }
};

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();

    const lib_path = try find_lib_path(alloc);
    defer alloc.free(lib_path);

    var g = Game.init(@ptrCast(&alloc));
    defer g.deinit();

    while (true) {
        try g.load(lib_path);
        if (!g.run()) {
            break;
        }
        std.Thread.sleep(100 * std.time.ns_per_ms);
    }
}

fn find_lib_path(alloc: Allocator) ![]u8 {
    const exe_dir = try std.fs.selfExeDirPathAlloc(alloc);
    defer alloc.free(exe_dir);
    return try std.fmt.allocPrint(alloc, "{s}/../lib/libgame.dylib", .{exe_dir});
}
