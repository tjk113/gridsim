//! Module containing power grids, plants, lines, and consumers.

/// The Grid oversees Plants, Lines, and Substations.
pub const Grid = @import("Grid.zig");
/// Plants only know about their own Line.
pub const Plant = @import("Plant.zig");
/// Lines hold references to their connections.
pub const Line = @import("Line.zig");
/// Consumers only know about their own Line.
pub const Consumer = @import("Consumer.zig");
/// Substations only know about their own Lines.
pub const Substation = @import("Substation.zig");