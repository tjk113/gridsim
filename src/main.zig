const std = @import("std");
const power = @import("power");
const utils = @import("utils");

pub fn main() !void {
    var dbg = std.heap.DebugAllocator(.{}).init;
    const allocator = dbg.allocator();
    defer _ = dbg.deinit();
    
    var grid = power.Grid.init(60.0, allocator);
    defer grid.deinit();
    std.debug.print("grid id: {d}\n", .{grid.id});

    const result = try utils.convert(.Amperage, .{.volts = 1.0, .watts = 100.0});
    std.debug.print("{d:.2}\n", .{result});
}