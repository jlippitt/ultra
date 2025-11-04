const std = @import("std");
const cpu = @import("../cpu.zig");
const logic = @import("./interpreter/logic.zig");

pub fn dispatch() void {
    const opcode = cpu.opcode();

    if (opcode == 0o00) {
        std.log.debug("{X:08}: NOP", .{cpu.pc()});
        return;
    }

    switch (opcode) {
        0o17 => logic.lui(),
        else => std.debug.panic("CPU opcode {o:02} not yet implemented", .{opcode}),
    }
}
