const std = @import("std");
const util = @import("./util.zig");

const BsdDom = struct {
    lat: u8 = 0,
    pwd: u8 = 0,
    pgs: u4 = 0,
    rls: u2 = 0,
};

var _bsd_dom1: BsdDom = .{};

var _bsd_dom2: BsdDom = .{};

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
        5 => _bsd_dom1.lat = @truncate(value),
        6 => _bsd_dom1.pwd = @truncate(value),
        7 => _bsd_dom1.pgs = @truncate(value),
        8 => _bsd_dom1.rls = @truncate(value),
        9 => _bsd_dom2.lat = @truncate(value),
        10 => _bsd_dom2.pwd = @truncate(value),
        11 => _bsd_dom2.pgs = @truncate(value),
        12 => _bsd_dom2.rls = @truncate(value),
        else => std.debug.panic("TODO: PI register write: {X:05}", .{addr}),
    }
}
