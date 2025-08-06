const std = @import("std");
const types = @import("types");

const Line = @import("Line.zig");
const Voltage = types.Voltage;

const Allocator = std.mem.Allocator;
const Self = @This();

var id_index: u64 = 0;

id: u64,
enabled: bool,
in_line: *Line,
out_line: *Line,
/// Negative values indicate a step-down transformer;
/// positive values indicate a step-up transformer.
transformer_delta: Voltage,

pub fn init(in_line: *Line, out_line: *Line) Self {
    id_index += 1;
    return .{
        .id = id_index - 1,
        .enabled = false,
        .in_line = in_line,
        .out_line = out_line,
        .transformer_delta = out_line.voltage - in_line.voltage
    };
}

pub fn enable(self: *Self) void {
    self.enabled = true;
}

pub fn disable(self: *Self) void {
    self.enabled = false;
}