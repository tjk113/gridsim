const std = @import("std");
const utils = @import("utils");
const types = @import("types");

const Substation = @import("Substation.zig");
const Consumer = @import("Consumer.zig");
const Plant = @import("Plant.zig");
const Amperage = types.Amperage;
const Voltage = types.Voltage;
const Ohmage = types.Ohmage;

const Allocator = std.mem.Allocator;
const Self = @This();

var id_index: u64 = 0;

id: u64,
enabled: bool,
had_failure: bool,
voltage: Voltage,
ohms_per_km: Ohmage,
current_load: Amperage,
plants: std.ArrayList(*Plant),
substations: std.ArrayList(*Substation),
consumers: std.ArrayList(*Consumer),
allocator: Allocator,

pub const Error = error {
    Unpowered,
    Overloaded
};

pub fn init(ohms_per_km: Ohmage, voltage: Voltage, allocator: Allocator) Self {
    id_index += 1;
    return .{
        .id = id_index - 1,
        .enabled = true,
        .had_failure = false,
        .voltage = voltage,
        .ohms_per_km = ohms_per_km,
        .current_load = 0.0,
        .plants = std.ArrayList(*Plant).init(allocator),
        .substations = std.ArrayList(*Substation).init(allocator),
        .consumers = std.ArrayList(*Consumer).init(allocator),
        .allocator = allocator
    };
}

pub fn deinit(self: *Self) void {
    self.plants.deinit();
    self.substations.deinit();
    self.consumers.deinit();
}

pub fn fail(self: *Self) void {
    self.had_failure = true;
}

pub fn connectToPlant(self: *Self, plant: *Plant) !void {
    try self.plants.append(plant);
}

pub fn disconnectFromPlant(self: *Self, plant: *Plant) void {
    for (0.., self.plants.items) |i, item| {
        if (plant == item) {
            _ = self.plants.swapRemove(i);
            break;
        }
    }
}

pub fn connectToSubstation(self: *Self, substation: *Substation) !void {
    try self.substations.append(substation);
}

pub fn disconnectFromSubstation(self: *Self, substation: *Substation) void {
    for (0.., self.substations.items) |i, item| {
        if (substation == item) {
            _ = self.substations.swapRemove(i);
            break;
        }
    }
}

pub fn connectToConsumer(self: *Self, consumer: *Consumer) !void {
    try self.consumers.append(consumer);
}

pub fn disconnectFromConsumer(self: *Self, consumer: *Consumer) void {
    for (0.., self.consumers.items) |i, item| {
        if (consumer == item) {
            _ = self.consumers.swapRemove(i);
            break;
        }
    }
}

pub fn enable(self: *Self) void {
    self.enabled = true;
}

pub fn disable(self: *Self) void {
    self.enabled = false;
}

pub fn hasPower(self: Self) bool {
    const hasGeneratingPlant = blk: {
        for (self.plants.items) |plant| {
            if (plant.isGenerating) {
                break :blk true;
            }
        }
        break :blk false;
    };
    return self.enabled and hasGeneratingPlant;
}

pub fn addLoad(self: *Self, load: Amperage) !void {
    const max_load = try utils.convert(
        .Amperage,
        .{
            .volts = self.voltage,
            .ohms = self.ohms_per_km
        }
    );

    if (self.current_load + load > max_load) {
        return Error.Overloaded;
    }

    self.current_load += load;
}

pub fn removeLoad(self: *Self, load: Amperage) void {
    self.current_load = @min(self.current_load - load, 0);
}