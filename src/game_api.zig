pub const State = struct {};

pub const Api = extern struct {
    init: *const fn () callconv(.c) State,
    finalize: *const fn (*State) callconv(.c) void,
    reload: *const fn (*State) callconv(.c) void,
    unload: *const fn (*State) callconv(.c) void,
    next: *const fn (*State) callconv(.c) void,
};
