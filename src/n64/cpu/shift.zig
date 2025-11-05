const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

pub const Operator = enum {
    SLL,
    SRL,
    SRA,
    DSLL,
    DSRL,
    DSRA,

    fn apply(comptime self: @This(), value: i64, amount: u6) i64 {
        return switch (comptime self) {
            .SLL => @as(i32, @truncate(value)) << @truncate(amount),
            .SRL => util.signExtend(i64, util.bitTruncate(u32, value) >> @truncate(amount)),
            .SRA => @as(i32, @truncate(value >> @as(u5, @truncate(amount)))),
            .DSLL => value << amount,
            .DSRL => @bitCast(@as(u64, @bitCast(value)) >> amount),
            .DSRA => value >> amount,
        };
    }
};

pub fn fixed(comptime op: Operator) void {
    const rt = cpu.rt();
    const rd = cpu.rd();
    const sa = cpu.sa();

    std.log.debug("{X:08}: {t} {s}, {s}, {d}", .{
        cpu.pc(),
        op,
        cpu.reg_names[rd],
        cpu.reg_names[rt],
        sa,
    });

    cpu.set(rd, @bitCast(op.apply(@bitCast(cpu.get(rt)), sa)));
}

pub fn fixed32(comptime op: Operator) void {
    const rt = cpu.rt();
    const rd = cpu.rd();
    const sa = cpu.sa();

    std.log.debug("{X:08}: {t}32 {s}, {s}, {d}", .{
        cpu.pc(),
        op,
        cpu.reg_names[rd],
        cpu.reg_names[rt],
        sa,
    });

    cpu.set(rd, @bitCast(op.apply(@bitCast(cpu.get(rt)), @as(u6, sa) + 32)));
}

pub fn variable(comptime op: Operator) void {
    const rs = cpu.rs();
    const rt = cpu.rt();
    const rd = cpu.rd();

    std.log.debug("{X:08}: {t} {s}, {s}, {s}", .{
        cpu.pc(),
        op,
        cpu.reg_names[rd],
        cpu.reg_names[rt],
        cpu.reg_names[rs],
    });

    cpu.set(rd, @bitCast(op.apply(@bitCast(cpu.get(rt)), @truncate(cpu.get(rs)))));
}
