const std = @import("std");
const log = @import("log");
const types = @import("types");
const power = @import("power");

const Spec = @import("Spec.zig");
const Hertz = types.Hertz;
const Vec2f = types.Vec2f;
const Time = types.Time;

const Allocator = std.mem.Allocator;
const Self = @This();

const Node = struct {
    name: []const u8,
    pos: Vec2f,
    ptr: union(enum) {
        plant: *power.Plant,
        substation: *power.Substation,
        consumer: *power.Consumer,
    }
};

id: u64,
spec: Spec,
grid: power.Grid,
current_time: Time,
random: std.Random,
log_level: Spec.Event.Severity,
nodes: std.StringHashMap(Node),
lines: std.StringHashMap(*power.Line),
allocator: Allocator,

fn initPlantFromSpec(self: Self, spec_node_name: []const u8, spec: Spec) !*power.Plant {
    var line: ?*power.Line = null;

    // Find the line that the power plant feeds.
    outer: for (spec.connections) |connection| {
        // Power plants should only ever occupy
        // the `from` field of a connection.
        if (std.mem.eql(u8, connection.from, spec_node_name)) {
            for (spec.lines) |spec_line| {
                if (std.mem.eql(u8, spec_line.name, connection.through)) {
                    line = self.lines.get(spec_line.name);
                    break :outer;
                }
            }
        }
    }
    if (line == null) {
        return error.LineNotFound;
    }

    const plant = try self.allocator.create(power.Plant);
    plant.* = power.Plant.init(line.?);
    try line.?.connectToPlant(plant);

    return plant;
}

fn initSubstationFromSpec(self: Self, spec_node_name: []const u8, spec: Spec) !*power.Substation {
    var in_line: ?*power.Line = null;
    var out_line: ?*power.Line = null;

    // Find the in and out lines of the substation.
    for (spec.connections) |connection| {
        if (std.mem.eql(u8, connection.to, spec_node_name)) {
            in_line = self.lines.get(connection.through);
        }
        else if (std.mem.eql(u8, connection.from, spec_node_name)) {
            out_line = self.lines.get(connection.through);
        }
        if (in_line != null and out_line != null) {
            break;
        }
    }
    if (in_line == null or out_line == null) {
        return error.LineNotFound;
    }

    const substation = try self.allocator.create(power.Substation);
    substation.* = power.Substation.init(in_line.?, out_line.?);
    try in_line.?.connectToSubstation(substation);
    try out_line.?.connectToSubstation(substation);

    return substation;
}

fn initConsumerFromSpec(self: Self, spec_node_name: []const u8, spec: Spec) !*power.Consumer {
    var line: ?*power.Line = null;

    // Find the line that feeds the consumer.
    outer: for (spec.connections) |connection| {
        // Consumers should only ever occupy
        // the `to` field of a connection.
        if (std.mem.eql(u8, connection.to, spec_node_name)) {
            for (spec.lines) |spec_line| {
                if (std.mem.eql(u8, spec_line.name, connection.through)) {
                    line = self.lines.get(spec_line.name);
                    break :outer;
                }
            }
        }
    }
    if (line == null) {
        return error.LineNotFound;
    }

    const consumer = try self.allocator.create(power.Consumer);
    consumer.* = power.Consumer.init(line);
    try line.?.connectToConsumer(consumer);

    return consumer;
}

fn initNodeFromSpec(self: *Self, spec_node_name: []const u8, spec: Spec) !Node {
    var node: Node = undefined;
    var spec_node: Spec.Node = undefined;

    for (spec.nodes) |_spec_node| {
        if (std.mem.eql(u8, _spec_node.name, spec_node_name)) {
            spec_node = _spec_node;
            break;
        }
    }

    node.name = spec_node_name;
    node.pos = spec_node.pos;
    switch (spec_node.kind) {
        .Plant => {
            const plant = try self.initPlantFromSpec(spec_node_name, spec);
            node.ptr = .{.plant = plant};
        },
        .Substation => {
            const substation = try self.initSubstationFromSpec(spec_node_name, spec);
            node.ptr = .{.substation = substation};
        },
        .Consumer => {
            const consumer = try self.initConsumerFromSpec(spec_node_name, spec);
            node.ptr = .{.consumer = consumer};
        }
    }

    return node;
}

fn initGridFromSpec(self: *Self, spec: Spec) !void {
    self.grid = power.Grid.init(spec.config.frequency, self.allocator);

    // Lines have to be initialized first, because
    // nodes need lines when being initialized.
    for (spec.lines) |spec_line| {
        const line = try self.allocator.create(power.Line);
        line.* = power.Line.init(spec_line.ohms_per_km, spec_line.voltage, self.allocator);

        try self.lines.put(spec_line.name, line);
        try self.grid.addLine(line);
    }

    for (spec.nodes) |spec_node| {
        const node = try self.initNodeFromSpec(spec_node.name, spec);

        try self.nodes.put(spec_node.name, node);
        switch (spec_node.kind) {
            .Plant => {
                try self.grid.addPlant(node.ptr.plant);
            },
            .Substation => {
                try self.grid.addSubstation(node.ptr.substation);
            },
            else => {}
        }
    }
}

pub fn init(id: u64, seed: u64, spec: Spec, log_level: Spec.Event.Severity, allocator: Allocator) !Self {
    var prng = std.Random.DefaultPrng.init(seed);
    var self = Self {
        .id = id,
        .spec = spec,
        .grid = undefined,
        .random = prng.random(),
        .log_level = log_level,
        .current_time = .{.hour = 0, .minute = 0},
        .nodes = std.StringHashMap(Node).init(allocator),
        .lines = std.StringHashMap(*power.Line).init(allocator),
        .allocator = allocator
    };
    try self.initGridFromSpec(spec);

    return self;
}

pub fn deinit(self: *Self) void {
    self.grid.deinit();

    var node_iter = self.nodes.valueIterator();
    while (node_iter.next()) |node| {
        switch (node.ptr) {
            .plant => |ptr| self.allocator.destroy(ptr),
            .substation => |ptr| self.allocator.destroy(ptr),
            .consumer => |ptr| self.allocator.destroy(ptr)
        }
    }
    self.nodes.deinit();

    var line_iter = self.lines.valueIterator();
    while (line_iter.next()) |line| {
        line.*.deinit();
        self.allocator.destroy(line.*);
    }
    self.lines.deinit();
}

fn runLineFailure(self: *Self, event: Spec.Event) !void {
    var line = self.lines.get(event.source).?;
    line.disable();
}

fn runConsumerDisconnect(self: *Self, event: Spec.Event) !void {
    var consumer = self.nodes.get(event.source).?;
    try consumer.ptr.consumer.disconnect();
}

fn runEvent(self: *Self, event: Spec.Event) !void {
    switch (event.kind) {
        .LineFailure => {
            try self.runLineFailure(event);
        },
        .ConsumerDisconnect => {
            try self.runConsumerDisconnect(event);
        },
        else => { return error.Unimplemented; }
    }
}

fn logEvent(self: Self, event: Spec.Event) void {
    const time = self.current_time.allocPrint(self.allocator) catch unreachable;
    defer self.allocator.free(time);
    switch (event.severity) {
        .None => {
            log.info(
                "at {s}, {s} had an event ({s})",
                .{time, event.source, @tagName(event.kind)}
            );
        },
        else => {
            log.info(
                "at {s}, {s} had an event of {s} severity ({s})",
                .{time, event.source, @tagName(event.severity), @tagName(event.kind)}
            );
        }
    }
}

pub fn step(self: *Self) !void {
    for (self.spec.events) |event| {
        if (event.time.eql(self.current_time)) {
            try self.runEvent(event);
            if (@intFromEnum(event.severity) >= @intFromEnum(self.log_level)) {
                self.logEvent(event);
            }
        }
    }
    self.current_time.addMinute();
}