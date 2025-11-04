const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

const UnaryOperator = enum {
    BLEZ,
    BGTZ,
    BLTZ,
    BGEZ,
};

const BinaryOperator = enum {
    BEQ,
    BNE,
};

pub fn unary(comptime op: UnaryOperator, comptime params: cpu.BranchParams) void {
    const rs = cpu.rs();
    const offset = util.signExtend(u32, cpu.imm()) << 2;

    std.log.debug("{X:08}: {t}{s}{s} {s}, {d}", .{
        cpu.pc(),
        op,
        if (params.link) "AL" else "",
        if (params.likely) "L" else "",
        cpu.reg_names[rs],
        offset,
    });

    const value = cpu.get(rs);

    const condition = switch (comptime op) {
        .BLEZ => value <= 0,
        .BGTZ => value > 0,
        .BLTZ => value < 0,
        .BGEZ => value >= 0,
    };

    cpu.branchTo(params, condition, offset);
}

pub fn binary(comptime op: BinaryOperator, comptime params: cpu.BranchParams) void {
    const rs = cpu.rs();
    const rt = cpu.rt();
    const offset = util.signExtend(u32, cpu.imm()) << 2;

    std.log.debug("{X:08}: {t}{s} {s}, {s}, {d}", .{
        cpu.pc(),
        op,
        if (params.likely) "L" else "",
        cpu.reg_names[rs],
        cpu.reg_names[rt],
        offset,
    });

    const lhs = cpu.get(rs);
    const rhs = cpu.get(rt);

    const condition = switch (comptime op) {
        .BEQ => lhs == rhs,
        .BNE => lhs != rhs,
    };

    cpu.branchTo(params, condition, offset);
}
