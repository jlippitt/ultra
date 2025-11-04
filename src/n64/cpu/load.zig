const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

const Operator = enum {
    LB,
    LBU,
    LH,
    LHU,
    LW,
    LWU,
    LD,
};

pub fn memory(comptime op: Operator) void {
    const base = cpu.rs();
    const rt = cpu.rt();
    const offset = util.signExtend(u32, cpu.imm());

    std.log.debug("{X:08}: {t} {s}, {d}({s})", .{
        cpu.pc(),
        op,
        cpu.reg_names[rt],
        @as(i32, @bitCast(offset)),
        cpu.reg_names[base],
    });

    const vaddr = util.bitTruncate(u32, cpu.get(base)) +% offset;

    cpu.set(rt, switch (comptime op) {
        .LB => util.signExtend(u64, cpu.readData(u8, vaddr)),
        .LBU => cpu.readData(u8, vaddr),
        .LH => util.signExtend(u64, cpu.readData(u16, vaddr)),
        .LHU => cpu.readData(u16, vaddr),
        .LW => util.signExtend(u64, cpu.readData(u32, vaddr)),
        .LWU => cpu.readData(u32, vaddr),
        .LD => cpu.readData(u64, vaddr),
    });
}
