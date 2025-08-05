const std = @import("std");

const Grid = @import("Grid.zig");
const Line = @import("Line.zig");

const Allocator = std.mem.Allocator;
const Self = @This();

var id_index: u64 = 0;

id: u64,
isGenerating: bool,
lines: std.ArrayList(*Line),
allocator: Allocator,

pub fn init(allocator: Allocator) Self {
    id_index += 1;
    return .{
        .id = id_index - 1,
        .isGenerating = false,
        .lines = std.ArrayList(*Line).init(allocator),
        .allocator = allocator
    };
}

pub fn deinit(self: *Self) void {
    self.lines.deinit();
}

pub fn startUp(self: *Self) void {
    self.isGenerating = true;
}

pub fn shutDown(self: *Self) void {
    self.isGenerating = false;
}

pub fn addLine(self: *Self, line: *Line) !void {
    try self.lines.append(line);
}

pub fn removeLine(self: *Self, line: *Line) void {
    for (0.., self.lines.items) |i, item| {
        if (line == item) {
            _ = self.lines.swapRemove(i);
            break;
        }
    }
}