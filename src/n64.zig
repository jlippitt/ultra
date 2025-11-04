const cpu = @import("./n64/cpu.zig");
const pi = @import("./n64/peripheral.zig");
const si = @import("./n64/serial.zig");

pub fn init(pif: *align(4) [2048]u8, rom: []align(4) u8) void {
    cpu.init();
    pi.init(rom);
    si.init(pif);
}

pub fn deinit() void {
    cpu.deinit();
    pi.deinit();
    si.deinit();
}

pub fn step() void {
    cpu.step();
}
