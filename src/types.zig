//! Types representing common electrical units.

const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Percentage = u64;
pub const Amperage = f64;
pub const Voltage = f64;
pub const Wattage = f64;
pub const Ohmage = f64;
pub const Hertz = f64;
pub const Unit = f64;

pub const Vec2f = struct {
    x: f64,
    y: f64
};

pub const Time = struct {
    const Self = @This();

    hour: u64,
    minute: u64,

    pub fn addMinute(self: *Self) void {
        self.minute += 1;
        if (self.minute == 60) {
            self.minute = 0;
            self.hour += 1;
        }
    }

    pub fn addHour(self: *Self) void {
        self.hour += 1;
    }

    pub fn allocPrint(self: Self, allocator: Allocator) ![]u8 {
        return try std.fmt.allocPrint(
            allocator,
            "{d:0>2}:{d:0>2}",
            .{self.hour, self.minute}
        );
    }

    pub fn eql(self: Self, other: Self) bool {
        return self.hour == other.hour and self.minute == other.minute;
    }
};