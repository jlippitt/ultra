const std = @import("std");
const cpu = @import("../../cpu.zig");
const util = @import("../../util.zig");

pub fn lui() void {
    const op = cpu.iType();
    std.log.debug("{X:08}: LUI 0x{X:04}", .{ cpu.pc(), op.imm });
    cpu.set(op.rt, util.signExtend(u64, @as(u32, op.imm) << 16));
}
