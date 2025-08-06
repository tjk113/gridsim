const std = @import("std");

const Grid = @import("Grid.zig");
const Line = @import("Line.zig");

const Allocator = std.mem.Allocator;
const Self = @This();

var id_index: u64 = 0;

id: u64,
isGenerating: bool,
line: *Line,

pub fn init(line: *Line) Self {
    id_index += 1;
    return .{
        .id = id_index - 1,
        .isGenerating = false,
        .line = line,
    };
}

pub fn startUp(self: *Self) void {
    self.isGenerating = true;
}

pub fn shutDown(self: *Self) void {
    self.isGenerating = false;
}