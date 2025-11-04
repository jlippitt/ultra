const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

const Operator = enum {
    ADD,
    SUB,
    DADD,
    DSUB,
    SLT,

    fn applySigned(comptime self: @This(), lhs: i64, rhs: i64) !i64 {
        return switch (comptime self) {
            .ADD => try std.math.add(i32, @truncate(lhs), @truncate(rhs)),
            .SUB => try std.math.sub(i32, @truncate(lhs), @truncate(rhs)),
            .DADD => std.math.add(i64, lhs, rhs),
            .DSUB => std.math.sub(i64, lhs, rhs),
            .SLT => @intFromBool(lhs < rhs),
        };
    }

    fn applyUnsigned(comptime self: @This(), lhs: u64, rhs: u64) u64 {
        return switch (comptime self) {
            .ADD => util.signExtend(u64, util.bitTruncate(u32, lhs) +% util.bitTruncate(u32, rhs)),
            .SUB => util.signExtend(u64, util.bitTruncate(u32, lhs) -% util.bitTruncate(u32, rhs)),
            .DADD => lhs +% rhs,
            .DSUB => lhs -% rhs,
            .SLT => @intFromBool(lhs < rhs),
        };
    }
};

pub fn iType(comptime op: Operator, comptime sign: std.builtin.Signedness) void {
    const rs = cpu.rs();
    const rt = cpu.rt();
    const rhs = util.signExtend(u64, cpu.imm());

    std.log.debug("{X:08}: {t}I{s} {s}, {s}, {d}", .{
        cpu.pc(),
        op,
        if (sign == .unsigned) "U" else "",
        cpu.reg_names[rt],
        cpu.reg_names[rs],
        rhs,
    });

    const lhs = cpu.get(rs);

    cpu.set(rt, switch (comptime sign) {
        .signed => @bitCast(op.applySigned(@bitCast(lhs), @bitCast(rhs)) catch {
            @branchHint(.unlikely);
            std.debug.panic("TODO: Overflow exceptions", .{});
        }),
        .unsigned => op.applyUnsigned(lhs, rhs),
    });
}
