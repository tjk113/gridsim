const std = @import("std");
const types = @import("types");

const Probabilities = @import("Probabilities.zig");

pub const Profile = enum {
    const Self = @This();

    LowActivity,
    RegularActivity,
    HighActivity,

    pub fn getProbabilities(self: Self) Probabilities {
        return switch (self) {
            .LowActivity => Probabilities.LowActivity,
            .RegularActivity => Probabilities.RegularActivity,
            .HighActivity => Probabilities.HighActivity 
        };
    }
};