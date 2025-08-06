const std = @import("std");
const types = @import("types");

const Substation = @import("Substation.zig");
const Plant = @import("Plant.zig");
const Line = @import("Line.zig");
const Hertz = types.Hertz;

const Allocator = std.mem.Allocator;
const Self = @This();

var id_index: u64 = 0;

id: u64,
frequency: Hertz,
lines: std.ArrayList(*Line),
plants: std.ArrayList(*Plant),
substations: std.ArrayList(*Substation),
allocator: Allocator,

pub fn init(frequency: Hertz, allocator: Allocator) Self {
    id_index += 1;
    return .{
        .id = id_index - 1,
        .frequency = frequency,
        .lines = std.ArrayList(*Line).init(allocator),
        .plants = std.ArrayList(*Plant).init(allocator),
        .substations = std.ArrayList(*Substation).init(allocator),
        .allocator = allocator
    };
}

pub fn deinit(self: *Self) void {
    self.lines.deinit();
    self.plants.deinit();
    self.substations.deinit();
}

pub fn addPlant(self: *Self, plant: *Plant) !void {
    try self.plants.append(plant);
}

pub fn removePlant(self: *Self, plant: *Plant) void {
    for (0.., self.plants.items) |i, item| {
        if (plant == item) {
            _ = self.plants.swapRemove(i);
            break;
        }
    }
}

pub fn addSubstation(self: *Self, substation: *Substation) !void {
    try self.substations.append(substation);
}

pub fn removeSubstation(self: *Self, substation: *Substation) void {
    for (0.., self.substations.items) |i, item| {
        if (substation == item) {
            _ = self.substations.swapRemove(i);
            break;
        }
    }
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