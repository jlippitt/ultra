const std = @import("std");
const si = @import("./serial.zig");
const cp0 = @import("./cpu/cp0.zig");
const logic = @import("./cpu/logic.zig");

pub const reg_names: [32][]const u8 = .{
    "ZERO", "AT", "V0", "V1", "A0", "A1", "A2", "A3",
    "T0",   "T1", "T2", "T3", "T4", "T5", "T6", "T7",
    "S0",   "S1", "S2", "S3", "S4", "S5", "S6", "S7",
    "T8",   "T9", "K0", "K1", "GP", "SP", "FP", "RA",
};

const cold_reset_vector = 0xbfc0_0000;

const Device = enum(u8) {
    rdram_data,
    rdram_registers,
    rsp,
    rdp_command,
    rdp_span,
    mips_interface,
    video_interface,
    audio_interface,
    peripheral_interface,
    rdram_interface,
    serial_interface,
    cartridge_rom,
    pif,
    open_bus,
};

const memory_map: [512]Device = blk: {
    var map: [512]Device = @splat(.open_bus);
    @memset(map[0x000..0x008], .rdram_data);
    map[0x03f] = .rdram_registers;
    map[0x040] = .rsp;
    map[0x041] = .rdp_command;
    map[0x042] = .rdp_span;
    map[0x043] = .mips_interface;
    map[0x044] = .video_interface;
    map[0x045] = .audio_interface;
    map[0x046] = .peripheral_interface;
    map[0x047] = .rdram_interface;
    map[0x048] = .serial_interface;
    @memset(map[0x100..0x1fc], .cartridge_rom);
    map[0x1fc] = .pif;
    break :blk map;
};

var _pc: [3]u32 = @splat(cold_reset_vector);
var _delay: [2]bool = @splat(false);
var _word: [2]u32 = @splat(0);
var _regs: [32]u64 = undefined;

pub fn init() void {
    cp0.init();
}

pub fn deinit() void {
    cp0.deinit();
}

pub fn step() void {
    dispatch();

    _pc[0] = _pc[1];
    _pc[1] = _pc[2];
    _pc[2] +%= 4;

    _delay[0] = _delay[1];
    _delay[1] = false;

    _word[0] = _word[1];
    _word[1] = readInstruction();
}

pub fn pc() u32 {
    return _pc[0];
}

pub fn word() u32 {
    return _word[0];
}

pub fn rs() u5 {
    return @truncate(word() >> 21);
}

pub fn rt() u5 {
    return @truncate(word() >> 16);
}

pub fn rd() u5 {
    return @truncate(word() >> 11);
}

pub fn sa() u5 {
    return @truncate(word() >> 6);
}

pub fn imm() u16 {
    return @truncate(word());
}

pub fn get(reg: u5) u64 {
    return _regs[reg];
}

pub fn set(reg: u5, value: u64) void {
    _regs[reg] = value;
    std.log.debug("  {s}: {X:016}", .{ reg_names[reg], value });
}

fn readInstruction() u32 {
    const vaddr = _pc[1];

    if ((vaddr & 0xc000_0000) == 0x8000_0000) {
        return read(u32, @truncate(vaddr));
    }

    std.debug.panic("TLB not yet implemented", .{});
}

fn read(comptime T: type, paddr: u29) T {
    if (T != u32) {
        std.debug.panic("Unsupported: CPU read from {X:08} must be 32-bit", .{paddr});
    }

    return switch (memory_map[paddr >> 20]) {
        .pif => si.readPif(@truncate(paddr)),
        else => std.debug.panic("Unmapped CPU read: {X:08}", .{paddr}),
    };
}

fn dispatch() void {
    const opcode: u6 = @truncate(word() >> 26);

    if (opcode == 0o00) {
        std.log.debug("{X:08}: NOP", .{pc()});
        return;
    }

    switch (opcode) {
        0o14 => logic.iType(.AND),
        0o15 => logic.iType(.OR),
        0o16 => logic.iType(.XOR),
        0o17 => logic.lui(),
        0o20 => cp0.dispatch(),
        else => std.debug.panic("CPU opcode {o:02} not yet implemented", .{opcode}),
    }
}
