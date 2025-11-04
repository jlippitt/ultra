const std = @import("std");
const cpu = @import("../cpu.zig");
const util = @import("../util.zig");

const reg_names: [32][]const u8 = .{
    "Index",    "Random",   "EntryLo0",    "EntryLo1",
    "Context",  "PageMask", "Wired",       "R7",
    "BadVAddr", "Count",    "EntryHi",     "Compare",
    "Status",   "Cause",    "EPC",         "PRId",
    "Config",   "LLAddr",   "WatchLo",     "WatchHi",
    "XContext", "R21",      "R22",         "R23",
    "R24",      "R25",      "ParityError", "CacheError",
    "TagLo",    "TagHi",    "ErrorEPC",    "R31",
};

var _status: packed struct(u32) {
    ie: bool = false,
    exl: bool = false,
    erl: bool = true,
    ksu: u2 = 0,
    ux: bool = false,
    sx: bool = false,
    kx: bool = false,
    im: u8 = 0,
    ds: u9 = 0b0_0100_0000,
    re: bool = false,
    fr: bool = false,
    rp: bool = false,
    cu0: bool = false,
    cu1: bool = false,
    cu2: bool = false,
    cu3: bool = false,
} = .{};

var _config: packed struct(u32) {
    k0: u3 = 0,
    cu: bool = false,
    _0: u11 = 0b110_0100_0110,
    be: bool = true,
    _1: u8 = 0b0000_0110,
    ep: u4 = 0,
    ec: u3 = 0b111,
    _2: u1 = 0,
} = .{};

pub fn init() void {}

pub fn deinit() void {}

pub fn set(reg: u5, value: u64) void {
    switch (reg) {
        12 => {
            util.writeWithMask(u32, @ptrCast(&_status), util.bitTruncate(u32, value), 0xfff7_ffff);

            if (_status.ksu != 0) {
                std.log.warn("Unsupported: User and supervisor modes", .{});
            }

            if (_status.kx) {
                std.log.warn("Unsupported: 64-bit addressing", .{});
            }

            if (_status.rp) {
                std.log.warn("Unsupported: Reduced power mode", .{});
            }

            std.log.debug("  Status: {any}", .{_status});
        },
        16 => {
            util.writeWithMask(u32, @ptrCast(&_config), util.bitTruncate(u32, value), 0x0f00_800f);

            if (!_config.be) {
                std.log.warn("Unsupported: Little-endian mode", .{});
            }

            if (_config.ep != 0) {
                std.log.warn("Unsupported: Non-default data transfer patterns", .{});
            }

            std.log.debug("  Config: {any}", .{_config});
        },
        else => std.debug.panic("Unimplemented: CP0 register write {} <= {X:016}", .{ reg, value }),
    }
}

pub fn dispatch() void {
    const opcode = cpu.rs();

    switch (opcode) {
        0o04 => mtc0(),
        else => std.debug.panic("CP0 opcode {o:02} not yet implemented", .{opcode}),
    }
}

fn mtc0() void {
    const rt = cpu.rt();
    const rd = cpu.rd();
    std.log.debug("{X:08}: MTC0 {s}, {s}", .{ cpu.pc(), cpu.reg_names[rt], reg_names[rd] });
    set(rd, util.signExtend(u64, util.bitTruncate(u32, cpu.get(rt))));
}
