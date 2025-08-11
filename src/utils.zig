//! Utility functions for working with common electrical units.

const std = @import("std");
const types = @import("types");

const Amperage = types.Amperage;
const Voltage = types.Voltage;
const Wattage = types.Wattage;
const Ohmage = types.Ohmage;
const Unit = types.Unit;

const Allocator = std.mem.Allocator;

pub const TargetType = enum {
    Ohmage,
    Amperage,
    Voltage,
    Wattage
};

pub const ConversionParameters = struct {
    ohms: ?Ohmage = null,
    amps: ?Amperage = null,
    volts: ?Voltage = null,
    watts: ?Wattage = null
};

pub const ConversionError = error {
    InsufficientParameters
};

fn calculateOhmage(parameters: ConversionParameters) ConversionError!Unit {
    var result: Ohmage = undefined;

    // Resistance in Ohmage
    // R = V / I
    // R = V^2 / P
    // R = P / I^2
    if (parameters.volts != null and parameters.amps != null) {
        result = parameters.volts.? / parameters.amps.?;
    }
    else if (parameters.volts != null and parameters.watts != null) {
        result = (parameters.volts.? * parameters.volts.?) / parameters.watts.?;
    }
    else if (parameters.watts != null and parameters.amps != null) {
        result = parameters.watts.? / (parameters.amps.? * parameters.amps.?);
    }
    else {
        return ConversionError.InsufficientParameters;
    }

    return result;
}

fn calculateAmperage(parameters: ConversionParameters) ConversionError!Unit {
    var result: Amperage = undefined;

    // Current in Amps
    // I = V / R
    // I = P / V
    // I = sqrt(P / R)
    if (parameters.volts != null and parameters.ohms != null) {
        result = parameters.volts.? / parameters.ohms.?;
    }
    else if (parameters.watts != null and parameters.volts != null) {
        result = parameters.watts.? / parameters.volts.?;
    }
    else if (parameters.watts != null and parameters.ohms != null) {
        result = @sqrt(parameters.watts.? / parameters.ohms.?);
    }
    else {
        return ConversionError.InsufficientParameters;
    }

    return result;
}

fn calculateVoltage(parameters: ConversionParameters) ConversionError!Unit {
    var result: Voltage = undefined;

    // Voltage in Volts
    // V = I x R
    // V = P / I
    // V = sqrt(P x R)
    if (parameters.amps != null and parameters.ohms != null) {
        result = parameters.amps.? * parameters.ohms.?;
    }
    else if (parameters.watts != null and parameters.amps != null) {
        result = parameters.watts.? / parameters.amps.?;
    }
    else if (parameters.watts != null and parameters.ohms != null) {
        result = @sqrt(parameters.watts.? * parameters.ohms.?);
    }
    else {
        return ConversionError.InsufficientParameters;
    }

    return result;
}

fn calculateWattage(parameters: ConversionParameters) ConversionError!Unit {
    var result: Wattage = undefined;

    // Power in Watts
    // P = V x I
    // P = V^2 / R
    // P = I^2 x R
    if (parameters.volts != null and parameters.amps != null) {
        result = parameters.volts.? * parameters.amps.?;
    }
    else if (parameters.volts != null and parameters.ohms != null) {
        result = (parameters.volts.? * parameters.volts.?) / parameters.ohms.?;
    }
    else if (parameters.amps != null and parameters.ohms != null) {
        result = (parameters.amps.? * parameters.amps.?) / parameters.ohms.?;
    }
    else {
        return ConversionError.InsufficientParameters;
    }

    return result;
}

/// Convert `parameters` into the `target` unit, if possible.
pub fn convert(target: TargetType, parameters: ConversionParameters) ConversionError!Unit {
    return switch (target) {
        .Ohmage => try calculateOhmage(parameters),
        .Amperage => try calculateAmperage(parameters),
        .Voltage => try calculateVoltage(parameters),
        .Wattage => try calculateWattage(parameters)
    };
}

pub fn loadFromZonFile(T: type, path: []const u8, allocator: Allocator) !T {
    const src_file = try std.fs.cwd().openFile(path, .{});
    defer src_file.close();

    const src = try src_file.readToEndAlloc(allocator, 4096);
    defer allocator.free(src);

    return try std.zon.parse.fromSlice(T, allocator, @ptrCast(src), null, .{});
}

// TODO: Exhaustive tests

test "Convert to Ohms" {
    try std.testing.expectEqual(60.0, try convert(.Ohmage, .{.volts = 120.0, .amps = 2.0}));
}