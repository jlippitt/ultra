const std = @import("std");
const util = @import("./util.zig");

var _status: packed struct(u32) {
    dma_busy: bool = false,
    io_busy: bool = false,
    read_pending: bool = false,
    dma_error: bool = false,
    pch_state: u4 = 0,
    dma_state: u4 = 0,
    interrupt: bool = false,
    _: u19 = 0,
} = .{};

var _pif: *align(4) [2048]u8 = undefined;

pub fn init(pif: *align(4) [2048]u8) void {
    _pif = pif;
    _pif[0x7ff] = 0;
}

pub fn deinit() void {}

pub fn readInterface(addr: u20) u32 {
    return switch (util.bitTruncate(u4, addr >> 2)) {
        6 => blk: {
            // TODO: SI interrupts
            break :blk @bitCast(_status);
        },
        else => std.debug.panic("TODO: SI register read: {}", .{addr}),
    };
}

pub fn readPif(addr: u20) u32 {
    if (addr >= _pif.len) {
        std.debug.panic("Unmapped PIF read: {X:05}", .{addr});
    }

    return std.mem.readInt(u32, _pif[addr..][0..4], .big);
}
