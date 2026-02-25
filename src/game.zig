const std = @import("std");
const Api = @import("game_api.zig").Api;
const State = @import("game_api.zig").State;

fn init() callconv(.c) State {
    return .{};
}

fn finalize(s: *State) callconv(.c) void {
    _ = s;
}

fn reload(s: *State) callconv(.c) void {
    _ = s;
}

fn unload(s: *State) callconv(.c) void {
    _ = s;
}

fn next(s: *State) callconv(.c) void {
    _ = s;
    std.debug.print("Hello, KoaLaYT!\n", .{});
}

export const api: Api = .{
    .init = init,
    .finalize = finalize,
    .reload = reload,
    .unload = unload,
    .next = next,
};
