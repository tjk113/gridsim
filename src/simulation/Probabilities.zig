const std = @import("std");
const types = @import("types");
const utils = @import("utils");

const Percentage = types.Percentage;
const Probabilities = @import("Probabilities.zig");

const Allocator = std.mem.Allocator;
const Self = @This();

pub const LowActivity: Probabilities = @import("default_probabilities/low_activity.zon");
pub const RegularActivity: Probabilities = @import("default_probabilities/regular_activity.zon");
pub const HighActivity: Probabilities = @import("default_probabilities/high_activity.zon");

plant: struct {
    fail: Percentage
},
substation: struct {
    fail: Percentage
},
line: struct {
    fail: Percentage
},
consumer: struct {
    use_power: Percentage
},