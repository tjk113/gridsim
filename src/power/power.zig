//! Module containing power grids, plants, lines, and consumers.

/// A Grid owns all of the Lines used by Plants and Consumers.
pub const Grid = @import("Grid.zig");
/// A Plant doesn't own any Lines , but it can use them.
pub const Plant = @import("Plant.zig");
/// A Line is owned by the Grid it operates within.
pub const Line = @import("Line.zig");
/// Consumers only interact with Grids.
pub const Consumer = @import("Consumer.zig");