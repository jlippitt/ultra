var _rom: []align(4) u8 = undefined;

pub fn init(rom: []align(4) u8) void {
    _rom = rom;
}

pub fn deinit() void {}
