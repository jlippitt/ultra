const std = @import("std");
const util = @import("./util.zig");

var _status: packed struct(u32) {
    halted: bool = true,
    broke: bool = false,
    dma_busy: bool = false,
    dma_full: bool = false,
    io_busy: bool = false,
    sstep: bool = false,
    intbreak: bool = false,
    sig0: bool = false,
    sig1: bool = false,
    sig2: bool = false,
    sig3: bool = false,
    sig4: bool = false,
    sig5: bool = false,
    sig6: bool = false,
    sig7: bool = false,
    _: u17 = 0,
} = .{};

pub fn init() void {}

pub fn deinit() void {}

pub fn read(addr: u20) u32 {
    if ((addr & 0xc_0000) == 0) {
        std.debug.panic("TODO: RSP DMEM/IMEM reads", .{});
    }

    if ((addr & 0xc_0000) == 0x4_0000) {
        return readRegister(@truncate(addr >> 2));
    }

    if (addr == 0x8_0000) {
        std.debug.panic("TODO: RSP program counter read", .{});
    }

    std.debug.panic("Unmapped RSP read: {X:05}", .{addr});
}

pub fn write(addr: u20, value: u32) void {
    if ((addr & 0xc_0000) == 0) {
        std.debug.panic("TODO: RSP DMEM/IMEM writes", .{});
    }

    if ((addr & 0xc_0000) == 0x4_0000) {
        return writeRegister(@truncate(addr >> 2), value);
    }

    if (addr == 0x8_0000) {
        std.debug.panic("TODO: RSP program counter write", .{});
    }

    std.debug.panic("Unmapped RSP write: {X:05}", .{addr});
}

fn readRegister(addr: u3) u32 {
    return switch (addr) {
        4 => @bitCast(_status),
        else => std.debug.panic("TODO: RSP register read: {}", .{addr}),
    };
}

fn writeRegister(addr: u3, value: u32) void {
    return switch (addr) {
        4 => {
            util.toggleBitField(&_status, "halted", value, 0);
            util.toggleBitField(&_status, "sstep", value, 5);
            util.toggleBitField(&_status, "intbreak", value, 7);
            util.toggleBitField(&_status, "sig0", value, 9);
            util.toggleBitField(&_status, "sig1", value, 11);
            util.toggleBitField(&_status, "sig2", value, 13);
            util.toggleBitField(&_status, "sig3", value, 15);
            util.toggleBitField(&_status, "sig4", value, 17);
            util.toggleBitField(&_status, "sig5", value, 19);
            util.toggleBitField(&_status, "sig6", value, 21);
            util.toggleBitField(&_status, "sig7", value, 23);

            if (value & 0x0000_0004 != 0) {
                _status.broke = false;
            }

            std.log.debug("RSP Status: {any}", .{_status});

            switch (@as(u2, @truncate(value >> 3))) {
                1, 2 => std.log.debug("TODO: RSP interrupts", .{}),
                else => {},
            }
        },
        else => std.debug.panic("TODO: RSP register write: {}", .{addr}),
    };
}
