const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

pub fn jr() void {
    const rs = cpu.rs();
    std.log.debug("{X:08}: JR {s}", .{ cpu.pc(), cpu.reg_names[rs] });
    cpu.jumpTo(@truncate(cpu.get(rs)));
}
