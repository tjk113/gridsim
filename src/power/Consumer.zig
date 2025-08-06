const std = @import("std");
const utils = @import("utils");
const types = @import("types");

const Grid = @import("Grid.zig");
const Line = @import("Line.zig");
const Wattage = types.Wattage; 

const Self = @This();

var id_index: u64 = 0;

id: u64,
line: ?*Line,
power_usage: Wattage,

pub fn init(line: ?*Line) Self {
    id_index += 1;
    return .{
        .id = id_index - 1,
        .line = line,
        .power_usage = 0.0,
    };
}

pub fn isConnected(self: Self) bool {
    return self.line != null;
}

pub fn hasPower(self: Self) bool {
    return self.isConnected() and self.line.?.hasPower();
}

pub fn usePower(self: *Self, watts: Wattage) !void {
    if (self.hasPower()) {
        const amps = utils.convert(
            .Amperage,
            .{
                .watts = watts,
                .volts = self.line.?.voltage
            }
        );
        try self.line.?.addLoad(amps); 
        self.power_usage += watts;
    }
    else {
        return Line.Error.Unpowered;
    }
}

pub fn haltPower(self: *Self, watts: Wattage) void {
    if (self.hasPower()) {
        const amps = utils.convert(
            .Amperage,
            .{
                .watts = watts,
                .volts = self.line.?.voltage
            }
        );
        self.line.?.removeLoad(amps);
        self.power_usage += watts;
    }
}