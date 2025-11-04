const std = @import("std");
const rsp = @import("./rsp.zig");
const pi = @import("./peripheral.zig");
const si = @import("./serial.zig");
const util = @import("./util.zig");
const arithmetic = @import("./cpu/arithmetic.zig");
const branch = @import("./cpu/branch.zig");
const cp0 = @import("./cpu/cp0.zig");
const jump = @import("./cpu/jump.zig");
const load = @import("./cpu/load.zig");
const logic = @import("./cpu/logic.zig");
const store = @import("./cpu/store.zig");

pub const reg_names: [32][]const u8 = .{
    "ZERO", "AT", "V0", "V1", "A0", "A1", "A2", "A3",
    "T0",   "T1", "T2", "T3", "T4", "T5", "T6", "T7",
    "S0",   "S1", "S2", "S3", "S4", "S5", "S6", "S7",
    "T8",   "T9", "K0", "K1", "GP", "SP", "FP", "RA",
};

pub const BranchParams = struct {
    link: bool = false,
    likely: bool = false,
};

pub const JumpParams = struct {
    link: bool = false,
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
var _regs: [32]u64 = @splat(0);

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
    if (reg == 0) {
        return;
    }

    _regs[reg] = value;
    std.log.debug("  {s}: {X:016}", .{ reg_names[reg], value });
}

pub fn branchTo(comptime params: BranchParams, condition: bool, offset: u32) void {
    if (!_delay[0]) {
        @branchHint(.likely);
        _delay[1] = true;

        if (condition) {
            std.log.debug("Branch taken", .{});
            _pc[2] = _pc[0] +% offset +% 4;
        } else {
            std.log.debug("Branch not taken", .{});

            if (comptime params.likely) {
                _word[1] = 0;
            }
        }
    }

    if (comptime params.link) {
        set(31, util.signExtend(u64, _pc[1] +% 4));
    }
}

pub fn jumpTo(target: u32) void {
    if (_delay[0]) {
        @branchHint(.unlikely);
        return;
    }

    _delay[1] = true;
    _pc[2] = target;
}

pub fn readData(comptime T: type, vaddr: u32) T {
    const value = blk: {
        if ((vaddr & 0xc000_0000) == 0x8000_0000) {
            @branchHint(.likely);
            break :blk read(T, @truncate(vaddr));
        }

        std.debug.panic("TLB not yet implemented", .{});
    };

    std.log.debug("  [{X:08} => {s}]", .{ vaddr, util.hexFmt(value) });

    return value;
}

pub fn writeData(comptime T: type, vaddr: u32, value: T) void {
    std.log.debug("  [{X:08} <= {s}]", .{ vaddr, util.hexFmt(value) });

    if ((vaddr & 0xc000_0000) == 0x8000_0000) {
        @branchHint(.likely);
        return write(T, @truncate(vaddr), value);
    }

    std.debug.panic("TLB not yet implemented", .{});
}

fn readInstruction() u32 {
    const vaddr = _pc[1];

    if ((vaddr & 0xc000_0000) == 0x8000_0000) {
        @branchHint(.likely);
        return read(u32, @truncate(vaddr));
    }

    std.debug.panic("TLB not yet implemented", .{});
}

fn read(comptime T: type, paddr: u29) T {
    if (T != u32) {
        std.debug.panic("Unsupported: CPU read from {X:08} must be 32-bit", .{paddr});
    }

    return switch (memory_map[paddr >> 20]) {
        .rsp => rsp.read(@truncate(paddr)),
        .pif => si.readPif(@truncate(paddr)),
        else => std.debug.panic("Unmapped CPU read: {X:08}", .{paddr}),
    };
}

fn write(comptime T: type, paddr: u29, value: T) void {
    if (T != u32) {
        std.debug.panic("Unsupported: CPU write to {X:08} must be 32-bit", .{paddr});
    }

    return switch (memory_map[paddr >> 20]) {
        .rsp => rsp.write(@truncate(paddr), value),
        .video_interface => {}, // Ignore for now
        .audio_interface => {}, // Ignore for now
        .peripheral_interface => pi.writeInterface(@truncate(paddr), value),
        else => std.debug.panic("Unmapped CPU write: {X:08}", .{paddr}),
    };
}

fn dispatch() void {
    const opcode: u6 = @truncate(word() >> 26);

    if (word() == 0) {
        std.log.debug("{X:08}: NOP", .{pc()});
        return;
    }

    switch (opcode) {
        0o00 => dispatchSpecial(),
        0o01 => dispatchRegImm(),
        0o04 => branch.binary(.BEQ, .{}),
        0o05 => branch.binary(.BNE, .{}),
        0o06 => branch.unary(.BLEZ, .{}),
        0o07 => branch.unary(.BGTZ, .{}),
        0o10 => arithmetic.iType(.ADD, .signed),
        0o11 => arithmetic.iType(.ADD, .unsigned),
        0o12 => arithmetic.iType(.SLT, .signed),
        0o13 => arithmetic.iType(.SLT, .unsigned),
        0o14 => logic.iType(.AND),
        0o15 => logic.iType(.OR),
        0o16 => logic.iType(.XOR),
        0o17 => logic.lui(),
        0o20 => cp0.dispatch(),
        0o24 => branch.binary(.BEQ, .{ .likely = true }),
        0o25 => branch.binary(.BNE, .{ .likely = true }),
        0o26 => branch.unary(.BLEZ, .{ .likely = true }),
        0o27 => branch.unary(.BGTZ, .{ .likely = true }),
        0o30 => arithmetic.iType(.DADD, .signed),
        0o31 => arithmetic.iType(.DADD, .unsigned),
        0o40 => load.memory(.LB),
        0o41 => load.memory(.LH),
        0o43 => load.memory(.LW),
        0o44 => load.memory(.LBU),
        0o45 => load.memory(.LHU),
        0o47 => load.memory(.LWU),
        0o50 => store.memory(.SB),
        0o51 => store.memory(.SH),
        0o53 => store.memory(.SW),
        0o67 => load.memory(.LD),
        0o77 => store.memory(.SD),
        else => std.debug.panic("CPU opcode {o:02} not yet implemented", .{opcode}),
    }
}

fn dispatchSpecial() void {
    const func: u6 = @truncate(word());

    switch (func) {
        0o10 => jump.jr(),
        else => std.debug.panic("CPU special function {o:02} not yet implemented", .{func}),
    }
}

fn dispatchRegImm() void {
    const opcode = rt();

    switch (opcode) {
        0o00 => branch.unary(.BLTZ, .{}),
        0o01 => branch.unary(.BGEZ, .{}),
        0o02 => branch.unary(.BLTZ, .{ .likely = true }),
        0o03 => branch.unary(.BGEZ, .{ .likely = true }),
        0o20 => branch.unary(.BLTZ, .{ .link = true }),
        0o21 => branch.unary(.BGEZ, .{ .link = true }),
        0o22 => branch.unary(.BLTZ, .{ .link = true, .likely = true }),
        0o23 => branch.unary(.BGEZ, .{ .link = true, .likely = true }),
        else => std.debug.panic("CPU RegImm opcode {o:02} not yet implemented", .{opcode}),
    }
}
