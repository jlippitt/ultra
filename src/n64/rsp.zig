const std = @import("std");

var _status: packed struct(u32) {
    halted: bool = true,
    broke: bool = false,
    dma_busy: bool = false,
    dma_full: bool = false,
    io_busy: bool = false,
    sstep: bool = false,
    intbreak: bool = false,
    sig: u8 = 0,
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

fn readRegister(addr: u3) u32 {
    return switch (addr) {
        4 => @bitCast(_status),
        else => std.debug.panic("TODO: RSP register read: {}", .{addr}),
    };
}
