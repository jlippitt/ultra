const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

const Operator = enum {
    AND,
    OR,
    XOR,
    NOR,

    fn apply(comptime self: @This(), lhs: u64, rhs: u64) u64 {
        return switch (comptime self) {
            .AND => lhs & rhs,
            .OR => lhs | rhs,
            .XOR => lhs ^ rhs,
            .NOR => ~(lhs | rhs),
        };
    }
};

pub fn lui() void {
    const rt = cpu.rt();
    const imm = cpu.imm();
    std.log.debug("{X:08}: LUI {s}, 0x{X:04}", .{ cpu.pc(), cpu.reg_names[rt], imm });
    cpu.set(rt, util.signExtend(u64, @as(u32, imm) << 16));
}

pub fn iType(comptime op: Operator) void {
    const rs = cpu.rs();
    const rt = cpu.rt();
    const imm = cpu.imm();

    std.log.debug("{X:08}: {t}I {s}, {s}, 0x{X:04}", .{
        cpu.pc(),
        op,
        cpu.reg_names[rt],
        cpu.reg_names[rs],
        imm,
    });

    cpu.set(rt, op.apply(cpu.get(rs), imm));
}
