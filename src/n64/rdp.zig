const std = @import("std");
const util = @import("./util.zig");

var _status: packed struct(u32) {
    xbus: bool = false,
    freeze: bool = false,
    flush: bool = false,
    gclk: bool = false,
    tmem_busy: bool = false,
    pipe_busy: bool = false,
    cmd_busy: bool = false,
    cbuf_ready: bool = false,
    dma_busy: bool = false,
    end_pending: bool = false,
    start_pending: bool = false,
    _: u21 = 0,
} = .{};

pub fn init() void {}

pub fn deinit() void {}

pub fn readCommand(addr: u20) u32 {
    return switch (util.bitTruncate(u3, addr >> 2)) {
        3 => @bitCast(_status),
        else => std.debug.panic("TODO: RDP command register read: {X:05}", .{addr}),
    };
}
