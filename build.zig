const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "powergrid",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const types = b.addModule("types", .{
        .root_source_file = b.path("src/types.zig")
    });
    exe.root_module.addImport("types", types);

    const power = b.addModule("power", .{
        .root_source_file = b.path("src/power/power.zig")
    });
    exe.root_module.addImport("power", power);
    power.addImport("types", types);

    const utils = b.addModule("utils", .{
        .root_source_file = b.path("src/utils.zig")
    });
    utils.addImport("types", types);
    exe.root_module.addImport("utils", utils);

    b.installArtifact(exe);
}