const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

pub fn lui() void {
    const rt = cpu.rt();
    const imm = cpu.imm();
    std.log.debug("{X:08}: LUI 0x{X:04}", .{ cpu.pc(), imm });
    cpu.set(rt, util.signExtend(u64, @as(u32, imm) << 16));
}
