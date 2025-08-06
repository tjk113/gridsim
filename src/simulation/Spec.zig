const std = @import("std");
const types = @import("types");

const Voltage = types.Voltage;
const Ohmage = types.Ohmage;
const Hertz = types.Hertz;
const Vec2f = types.Vec2f;

const Allocator = std.mem.Allocator;
const Self = @This();

pub const NodeKind = enum {
    Plant,
    Substation,
    Consumer
};

pub const Node = struct {
    kind: NodeKind,
    name: []const u8,
    pos: Vec2f
};

pub const Config = struct {
    frequency: Hertz
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

name: []const u8,
config: Config,
nodes: []Node,
lines: []Line,
connections: []Connection,

pub fn loadFromFile(path: []const u8, allocator: Allocator) !Self {
    const src_file = try std.fs.cwd().openFile(path, .{});
    defer src_file.close();

    const src = try src_file.readToEndAlloc(allocator, 4096);
    defer allocator.free(src);

    return try std.zon.parse.fromSlice(Self, allocator, @ptrCast(src), null, .{});
}