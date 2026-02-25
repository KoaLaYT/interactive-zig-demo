const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libgame = b.addLibrary(.{
        .name = "game",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/game.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    libgame.root_module.linkSystemLibrary("ncurses", .{
        .preferred_link_mode = .dynamic,
    });
    const install_libgame = b.addInstallArtifact(libgame, .{});

    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // DO NOT LINK HERE, we use dlopen link it at run time.
    // exe.root_module.linkLibrary(libgame);
    const install_exe = b.addInstallArtifact(exe, .{});

    const lib_step = b.step("lib", "Build the game library only");
    lib_step.dependOn(&install_libgame.step);

    const all_step = b.step("all", "Build and install both exe and library");
    all_step.dependOn(&install_libgame.step);
    all_step.dependOn(&install_exe.step);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(all_step);
    run_step.dependOn(&run_cmd.step);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
