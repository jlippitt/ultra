const std = @import("std");

threadlocal var file: std.fs.File = undefined;
threadlocal var writer: std.fs.File.Writer = undefined;
threadlocal var buffer: [65336]u8 = undefined;

pub fn init(comptime name: []const u8) !void {
    const log_dir = try std.fs.cwd().makeOpenPath("log", .{});
    file = try log_dir.createFile(name ++ ".log", .{});
    writer = file.writer(&buffer);
}

pub fn deinit() void {
    writer.interface.flush() catch {};
    file.close();
}

pub fn panic(msg: []const u8, first_trace_addr: ?usize) noreturn {
    deinit();
    std.debug.defaultPanic(msg, first_trace_addr);
}

pub fn write(
    comptime _: std.log.Level,
    comptime _: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    writer.interface.print(format ++ "\n", args) catch {};
}
