const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

const Operator = enum {
    SB,
    SH,
    SW,
    SD,
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
    const value = cpu.get(rt);

    switch (comptime op) {
        .SB => cpu.writeData(u8, vaddr, @truncate(value)),
        .SH => cpu.writeData(u16, vaddr, @truncate(value)),
        .SW => cpu.writeData(u32, vaddr, @truncate(value)),
        .SD => cpu.writeData(u64, vaddr, value),
    }
}
