const std = @import("std");
const log = @import("log");
const types = @import("types");
const power = @import("power");

const Probabilities = @import("Probabilities.zig");
const Percentage = types.Percentage;
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
    },

    pub fn isActive(self: Node) bool {
        return switch (self.ptr) {
            .plant => |ptr| ptr.isGenerating,
            .substation => |ptr| ptr.enabled,
            .consumer => |ptr| ptr.hasPower()
        };
    }
};

id: u64,
spec: Spec,
grid: power.Grid,
current_time: Time = .{.hour = 0, .minute = 0},
prng: std.Random.DefaultPrng,
probabilities: Probabilities,
log_level: Spec.Event.Severity,
nodes: std.StringHashMap(Node),
lines: std.StringHashMap(*power.Line),
events: std.ArrayList(Spec.Event),
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

pub fn init(id: u64,
            seed: u64,
            spec: Spec,
            log_level: Spec.Event.Severity,
            start_time: ?Time,
            allocator: Allocator
) !Self {
    var self = Self {
        .id = id,
        .spec = spec,
        .grid = undefined,
        .prng = std.Random.DefaultPrng.init(seed),
        .log_level = log_level,
        .probabilities = spec.config.profile.getProbabilities(),
        .nodes = std.StringHashMap(Node).init(allocator),
        .lines = std.StringHashMap(*power.Line).init(allocator),
        .events = std.ArrayList(Spec.Event).init(allocator),
        .allocator = allocator
    };

    try self.initGridFromSpec(spec);

    for (spec.events) |event| {
        try self.events.append(event);
    }

    if (start_time) |start_time_val| {
        self.current_time = start_time_val;
    }

    return self;
}

pub fn deinit(self: *Self) void {
    self.grid.deinit();
    self.events.deinit();

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

fn runFailure(self: *Self, event: Spec.Event) !void {
    const line = self.lines.get(event.source);
    const node = self.nodes.get(event.source);

    var plant_fail_fn: ?*const fn(*power.Plant) void = null;
    var substation_fail_fn: ?*const fn(*power.Substation) void = null;
    var line_fail_fn: ?*const fn(*power.Line) void = null;

    switch (self.spec.config.failure_action) {
        .None => {},
        .Restart => {
            plant_fail_fn = power.Plant.startUp;
            substation_fail_fn = power.Substation.enable;
            line_fail_fn = power.Line.enable;
        },
        .ShutDown => {
            plant_fail_fn = power.Plant.shutDown;
            substation_fail_fn = power.Substation.disable;
            line_fail_fn = power.Line.disable;
        }
    }

    if (line) |line_val| {
        if (line_fail_fn != null) {
            line_fail_fn.?(line_val);
        }
        line_val.fail();
    }
    else if (node) |node_val| {
        switch (node_val.ptr) {
            .plant => |ptr| {
                if (plant_fail_fn != null) {
                    plant_fail_fn.?(ptr);
                }
                ptr.fail();
            },
            .substation => |ptr| {
                if (substation_fail_fn != null) {
                    substation_fail_fn.?(ptr);
                }
                ptr.fail();
            },
            .consumer => {}
        }
    }
}

fn runDisconnect(self: *Self, event: Spec.Event) !void {
    var consumer = self.nodes.get(event.source).?;
    try consumer.ptr.consumer.disconnect();
}

fn runEvent(self: *Self, event: Spec.Event) !void {
    switch (event.kind) {
        .Failure => try self.runFailure(event),
        .Disconnect => try self.runDisconnect(event)
    }
}

fn logEvent(self: Self, event: Spec.Event) void {
    const time = self.current_time.allocPrint(self.allocator) catch unreachable;
    defer self.allocator.free(time);
    switch (event.severity) {
        .None => {
            log.info(
                "at {s}, \"{s}\" had an event ({s})",
                .{time, event.source, @tagName(event.kind)}
            );
        },
        else => {
            log.warn(
                "at {s}, \"{s}\" had an event of {s} severity ({s})",
                .{time, event.source, @tagName(event.severity), @tagName(event.kind)}
            );
        }
    }
}

fn percentageToSeverity(val: Percentage) Spec.Event.Severity {
    return 
        if (val < 20)
            .Low
        else if (val < 50)
            .Medium
        else if (val < 80)
            .High
        else
            .Extreme;
}

fn checkNodeFailures(self: *Self) !void {
    var node_iter = self.nodes.valueIterator();
    while (node_iter.next()) |node| {
        const fail_probability = switch (node.ptr) {
            .plant => self.probabilities.plant.fail,
            .substation => self.probabilities.substation.fail,
            .consumer => { continue; }
        };
        // Check if a node has failed.
        const fail = self.prng.random().uintAtMost(Percentage, 100);
        if (fail < fail_probability) {
            // Store the failure event.
            const severity = self.prng.random().uintAtMost(Percentage, 100);
            try self.events.append(.{
                .severity = percentageToSeverity(severity),
                .time = self.current_time,
                .kind = .Failure,
                .source = node.name
            });
        }
    }
}

fn checkLineFailures(self: *Self) !void {
    var line_iter = self.lines.keyIterator();
    while (line_iter.next()) |line_name| {
        const fail_probability = self.probabilities.line.fail;
        // Check if a line has failed.
        const fail = self.prng.random().uintAtMost(Percentage, 100);
        if (fail < fail_probability) {
            // Store the failure event.
            const severity = self.prng.random().uintAtMost(Percentage, 100);
            try self.events.append(.{
                .severity = percentageToSeverity(severity),
                .time = self.current_time,
                .kind = .Failure,
                .source = line_name.*
            });
        }
    }
}

fn updateState(self: *Self) !void {
    // Only check for node failure every hour.
    // TODO: This should happen every minute,
    // but percentages would have to be floats
    // instead of integers.
    if (self.current_time.minute == 0) {
        try self.checkNodeFailures();
        try self.checkLineFailures();
    }
}

pub fn printState(self: Self) void {
    var nodes_inactive: u32 = 0;
    var node_iter = self.nodes.iterator();
    while (node_iter.next()) |node| {
        if (!node.value_ptr.isActive()) {
            nodes_inactive += 1;
        }
    }

    var lines_inactive: u32 = 0;
    var line_iter = self.lines.valueIterator();
    while (line_iter.next()) |line| {
        if (!line.*.enabled) {
            lines_inactive += 1;
        }
    }

    log.info(
        "engine state:\n" ++
        "nodes down: {d}/{d}\n" ++
        "lines down: {d}/{d}",
        .{
            nodes_inactive,
            self.nodes.count(),
            lines_inactive,
            self.lines.count()
        }
    );
}

pub fn step(self: *Self) !void {
    try self.updateState();
    // Run any events.
    for (self.events.items) |event| {
        if (event.time.eql(self.current_time)) {
            try self.runEvent(event);
            if (@intFromEnum(event.severity) >= @intFromEnum(self.log_level)) {
                self.logEvent(event);
            }
        }
    }
    self.current_time.addMinute();
}