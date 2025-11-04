const std = @import("std");

var _pif: *align(4) [2048]u8 = undefined;

pub fn init(pif: *align(4) [2048]u8) void {
    _pif = pif;
    _pif[0x7ff] = 0;
}

pub fn deinit() void {}

pub fn readPif(addr: u20) u32 {
    if (addr >= _pif.len) {
        std.debug.panic("Unmapped PIF read: {X:05}", .{addr});
    }

    return std.mem.readInt(u32, _pif[addr..][0..4], .big);
}
