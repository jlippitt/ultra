const std = @import("std");
const cpu = @import("./n64/cpu.zig");
const rsp = @import("./n64/rsp.zig");
const pi = @import("./n64/peripheral.zig");
const si = @import("./n64/serial.zig");

pub fn init(allocator: std.mem.Allocator, pif: *align(4) [2048]u8, rom: []align(4) u8) !void {
    cpu.init();
    try rsp.init(allocator);
    pi.init(rom);
    si.init(pif);
}

pub fn deinit(allocator: std.mem.Allocator) void {
    cpu.deinit();
    rsp.deinit(allocator);
    pi.deinit();
    si.deinit();
}

pub fn step() void {
    cpu.step();
}
