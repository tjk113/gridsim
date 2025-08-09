const std = @import("std");
const log = @import("log");
const power = @import("power");
const types = @import("types");
const utils = @import("utils");
const simulation = @import("simulation");

const Voltage = types.Voltage;
const Ohmage = types.Ohmage;
const Hertz = types.Hertz;
const Vec2f = types.Vec2f;

pub const std_options: std.Options = .{
    .log_level = .info,
    .logFn = log.logFn,
};

pub fn main() !void {
    var dbg = std.heap.DebugAllocator(.{}).init;
    const allocator = dbg.allocator();
    defer _ = dbg.deinit();

    const spec_path = "examples/small_spec.zon";
    log.info("Loading specification from \"{s}\"", .{spec_path});
    const spec = try simulation.Spec.loadFromFile(spec_path, allocator);
    defer std.zon.parse.free(allocator, spec);
    log.info("Loaded specification \"{s}\"", .{spec.name});

    log.info("Building simulation", .{});
    var sim = try simulation.Engine.init(0, spec, .None, 5, allocator);
    defer sim.deinit();

    log.info("Starting simulation", .{});
    const duration_in_minutes = 24 * 60;
    for (0..duration_in_minutes) |_| {
        try sim.step();
    }
    log.info("Simulation complete", .{});

    // const result = try utils.convert(.Amperage, .{.volts = 1.0, .watts = 100.0});
    // std.debug.print("{d:.2}\n", .{result});
}