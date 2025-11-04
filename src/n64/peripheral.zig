const std = @import("std");
const util = @import("./util.zig");

var _rom: []align(4) u8 = undefined;

pub fn init(rom: []align(4) u8) void {
    _rom = rom;
}

pub fn deinit() void {}

pub fn writeInterface(addr: u20, value: u32) void {
    switch (util.bitTruncate(u4, addr >> 2)) {
        4 => if ((value & 2) != 0) {
            std.log.debug("TODO: PI interrupts", .{});
        },
        else => std.debug.panic("TODO: PI register write: {}", .{addr}),
    }
}
