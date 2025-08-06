const std = @import("std");

const logger = std.log.scoped(.GridSim);

pub const err = logger.err;
pub const warn = logger.warn;
pub const info = logger.info;
pub const debug = logger.debug;

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    // Ignore all non-error logging from sources other than
    // .my_project, .nice_library and the default
    const scope_prefix = "[" ++ switch (scope) {
        .GridSim, std.log.default_log_scope => @tagName(scope),
        else => if (@intFromEnum(level) <= @intFromEnum(std.log.Level.err))
            @tagName(scope)
        else
            return,
    } ++ "] ";

    const prefix = scope_prefix ++ comptime level.asText() ++ ":";

    // Print the message to stderr, silently ignoring any errors
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ " " ++ format ++ "\n", args) catch return;
}