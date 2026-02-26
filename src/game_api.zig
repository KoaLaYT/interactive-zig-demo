const std = @import("std");
var prng = std.Random.DefaultPrng.init(42);

pub const State = extern struct {
    width: u64,
    height: u64,
    select: bool,
    cells: [*]u8,
    has_init: bool,
    alloc_ptr: *anyopaque,

    const Self = State;

    pub fn init(alloc_ptr: *anyopaque) Self {
        return .{
            .width = 0,
            .height = 0,
            .select = false,
            .cells = undefined,
            .has_init = false,
            .alloc_ptr = alloc_ptr,
        };
    }

    pub fn randomize(s: *Self) void {
        for (0..s.height) |y| {
            for (0..s.width) |x| {
                const v: u8 = if (prng.random().boolean()) 1 else 0;
                s.set(x, y, v);
            }
        }
        s.flip();
    }

    pub fn get(s: *Self, x: u64, y: u64) u8 {
        const v: u64 = if (s.select) 1 else 0;
        return s.cells[v * s.width * s.height + y * s.width + x];
    }

    pub fn iterate(s: *Self) void {
        for (0..s.height) |y| {
            for (0..s.width) |x| {
                const sum = s.count(x, y);
                // sum == 3 || (get(state, x, y) && sum == 2)
                var v: u8 = 0;
                if (sum == 3) v = 1;
                if (s.get(x, y) > 0 and sum == 2) v = 1;
                s.set(x, y, v);
            }
        }
        s.flip();
    }

    pub fn flip(s: *Self) void {
        s.select = !s.select;
    }

    pub fn set(s: *Self, x: u64, y: u64, c: u8) void {
        const v: u64 = if (s.select) 0 else 1;
        s.cells[v * s.width * s.height + y * s.width + x] = c;
    }

    pub fn count(s: *Self, x: u64, y: u64) u64 {
        var sum: u64 = 0;

        // Convert coordinates to signed to allow negative offsets
        const ix: i64 = @intCast(x);
        const iy: i64 = @intCast(y);
        const iw: i64 = @intCast(s.width);
        const ih: i64 = @intCast(s.height);

        var dy: i64 = -1;
        while (dy <= 1) : (dy += 1) {
            var dx: i64 = -1;
            while (dx <= 1) : (dx += 1) {
                if (dx == 0 and dy == 0) continue;

                // Simple C-style arithmetic
                // We add iw/ih to handle the case where (ix + dx) is -1
                const nx = @mod(ix + dx + iw, iw);
                const ny = @mod(iy + dy + ih, ih);

                // Cast back to u64 for the 'get' function
                sum += s.get(@intCast(nx), @intCast(ny));
            }
        }
        return sum;
    }
};

pub const Api = extern struct {
    init: *const fn (*State) callconv(.c) void,
    finalize: *const fn (*State) callconv(.c) void,
    reload: *const fn (*State) callconv(.c) void,
    unload: *const fn (*State) callconv(.c) void,
    step: *const fn (*State) callconv(.c) bool,
};
