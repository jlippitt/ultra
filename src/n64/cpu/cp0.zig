const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

const reg_names: [32][]const u8 = .{
    "ZERO", "AT", "V0", "V1", "A0", "A1", "A2", "A3",
    "T0",   "T1", "T2", "T3", "T4", "T5", "T6", "T7",
    "S0",   "S1", "S2", "S3", "S4", "S5", "S6", "S7",
    "T8",   "T9", "K0", "K1", "GP", "SP", "FP", "RA",
};

var _status: packed struct(u32) {
    ie: bool = false,
    exl: bool = false,
    erl: bool = true,
    ksu: u2 = 0,
    ux: bool = false,
    sx: bool = false,
    kx: bool = false,
    im: u8 = 0,
    ds: u9 = 0x40,
    re: bool = false,
    fr: bool = false,
    rp: bool = false,
    cu0: bool = false,
    cu1: bool = false,
    cu2: bool = false,
    cu3: bool = false,
} = .{};

pub fn init() void {}

pub fn deinit() void {}

pub fn set(reg: u5, value: u64) void {
    switch (reg) {
        12 => {
            util.writeWithMask(u32, @ptrCast(&_status), util.bitTruncate(u32, value), 0xfff7_ffff);

            if (_status.ksu != 0) {
                std.log.warn("Unsupported: User and supervisor modes", .{});
            }

            if (_status.kx) {
                std.log.warn("Unsupported: 64-bit addressing", .{});
            }

            if (_status.rp) {
                std.log.warn("Unsupported: Reduced power mode", .{});
            }

            std.log.debug("  Status: {any}", .{_status});
        },
        else => std.debug.panic("Unimplemented: CP0 register write {} <= {X:016}", .{ reg, value }),
    }
}

pub fn dispatch() void {
    const opcode = cpu.rs();

    switch (opcode) {
        0o04 => mtc0(),
        else => std.debug.panic("CP0 opcode {o:02} not yet implemented", .{opcode}),
    }
}

fn mtc0() void {
    const rt = cpu.rt();
    const rd = cpu.rd();
    std.log.debug("{X:08}: MTC0 {s}, {s}", .{ cpu.pc(), cpu.reg_names[rt], reg_names[rd] });
    set(rd, util.signExtend(u64, util.bitTruncate(u32, cpu.get(rt))));
}
