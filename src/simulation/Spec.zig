const std = @import("std");
const types = @import("types");
const utils = @import("utils");

const Profile = @import("Profile.zig").Profile;
const Voltage = types.Voltage;
const Ohmage = types.Ohmage;
const Hertz = types.Hertz;
const Vec2f = types.Vec2f;
const Time = types.Time;

const Allocator = std.mem.Allocator;
const Self = @This();

pub const Node = struct {
    pub const Kind = enum {
        Plant,
        Substation,
        Consumer
    };
    
    kind: Kind,
    name: []const u8,
    pos: Vec2f
};

pub const FailureAction = enum {
    None,
    Restart,
    ShutDown
};

pub const Config = struct {
    frequency: Hertz,
    profile: Profile,
    failure_action: FailureAction
};

pub const Line = struct {
    name: []const u8,
    ohms_per_km: Ohmage,
    voltage: Voltage
};

pub const Connection = struct {
    from: []const u8,
    through: []const u8,
    to: []const u8,
};

pub const Event = struct {
    pub const Severity = enum {
        None,
        Low,
        Medium,
        High,
        Extreme
    };

    pub const Kind = enum {
        Failure,
        Disconnect
    };

    severity: Severity,
    time: Time,
    kind: Kind,
    source: []const u8
};

name: []const u8,
config: Config,
nodes: []Node,
lines: []Line,
connections: []Connection,
events: []Event,