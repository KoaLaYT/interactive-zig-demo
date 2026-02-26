const std = @import("std");
const Allocator = @import("std").mem.Allocator;

const Api = @import("game_api.zig").Api;
const State = @import("game_api.zig").State;

const c = @cImport({
    @cInclude("ncurses.h");
});

fn init(s: *State) callconv(.c) void {
    const alloc: *std.mem.Allocator = @ptrCast(@alignCast(s.alloc_ptr));

    _ = c.initscr(); // peek at terminal size
    const width: u64 = @intCast(c.getmaxx(c.stdscr));
    const height: u64 = @intCast(c.getmaxy(c.stdscr));
    _ = c.endwin();

    const cells = alloc.alloc(u8, width * height * 2) catch unreachable;

    s.width = width;
    s.height = height;
    s.select = false;
    s.cells = cells.ptr;
    s.has_init = true;
    s.randomize();
}

fn finalize(s: *State) callconv(.c) void {
    const alloc: *std.mem.Allocator = @ptrCast(@alignCast(s.alloc_ptr));
    alloc.free(s.cells[0 .. s.width * s.height * 2]);
}

fn reload(s: *State) callconv(.c) void {
    _ = s;
    _ = c.initscr();
    _ = c.raw();
    c.timeout(0);
    _ = c.noecho();
    _ = c.curs_set(0);
    _ = c.keypad(c.stdscr, true);
    _ = c.erase();
    _ = c.refresh();
}

fn unload(s: *State) callconv(.c) void {
    _ = s;
    _ = c.endwin();
}

fn step(s: *State) callconv(.c) bool {
    switch (c.getch()) {
        'r' => s.randomize(),
        'q' => {
            return false;
        },
        else => {
            // do nothing
        },
    }
    s.iterate();
    draw(s);
    return true;
}

fn draw(s: *State) void {
    _ = c.move(0, 0);
    for (0..s.height) |y| {
        for (0..s.width) |x| {
            const ch = if (s.get(x, y) > 0) ' ' | c.A_REVERSE else ' ';
            _ = c.addch(ch);
        }
    }
    _ = c.refresh();
}

export const api: Api = .{
    .init = init,
    .finalize = finalize,
    .reload = reload,
    .unload = unload,
    .step = step,
};
