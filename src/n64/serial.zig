const std = @import("std");
const util = @import("./util.zig");

const pif_ram_start = 0x7c0;

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

var _pif_rom_locked: bool = false;

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

    if (addr <= pif_ram_start and _pif_rom_locked) {
        std.debug.panic("Read from locked PIF ROM: {X:05}", .{addr});
    }

    return std.mem.readInt(u32, _pif[addr..][0..4], .big);
}

pub fn writePif(addr: u20, value: u32) void {
    if (addr >= _pif.len) {
        std.debug.panic("Unmapped PIF write: {X:05}", .{addr});
    }

    if (addr < pif_ram_start) {
        std.debug.panic("Write to PIF ROM: {X:05}", .{addr});
    }

    std.mem.writeInt(u32, _pif[addr..][0..4], value, .big);

    if (addr != 0x7fc) {
        return;
    }

    const command = _pif[0x7ff];

    if ((command & 0x01) != 0) {
        std.debug.panic("PIF configure joybus frame", .{});
    }

    if ((command & 0x02) != 0) {
        std.debug.panic("PIF challenge/response", .{});
    }

    if ((command & 0x10) != 0) {
        _pif_rom_locked = true;
        std.log.debug("PIF ROM locked", .{});
    }

    if ((command & 0x20) != 0) {
        std.debug.panic("PIF acquire checksum", .{});
    }

    if ((command & 0x40) != 0) {
        std.debug.panic("PIF run checksum", .{});
    }
}
