const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "gridsim",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const types = b.addModule("types", .{
        .root_source_file = b.path("src/types.zig")
    });

    const power = b.addModule("power", .{
        .root_source_file = b.path("src/power/power.zig")
    });
    power.addImport("types", types);

    const utils = b.addModule("utils", .{
        .root_source_file = b.path("src/utils.zig")
    });
    utils.addImport("types", types);

    const simulation = b.addModule("simulation", .{
        .root_source_file = b.path("src/simulation/simulation.zig")
    });
    simulation.addImport("types", types);
    simulation.addImport("power", power);
    simulation.addImport("utils", utils);

    const log = b.addModule("log", .{
        .root_source_file = b.path("src/log.zig")
    });

    exe.root_module.addImport("log", log);
    exe.root_module.addImport("power", power);
    exe.root_module.addImport("types", types);
    exe.root_module.addImport("utils", utils);
    exe.root_module.addImport("simulation", simulation);

    b.installArtifact(exe);
}