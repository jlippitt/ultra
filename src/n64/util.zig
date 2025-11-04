const std = @import("std");

pub fn bitExtend(
    comptime signedness: std.builtin.Signedness,
    comptime T: type,
    value: anytype,
) T {
    const src_bits = comptime @typeInfo(@TypeOf(value)).int.bits;
    const dst_bits = comptime @typeInfo(T).int.bits;
    comptime std.debug.assert(dst_bits >= src_bits);
    const signed: std.meta.Int(signedness, src_bits) = @bitCast(value);
    const extended: std.meta.Int(signedness, dst_bits) = signed;
    return @bitCast(extended);
}

pub fn signExtend(comptime T: type, value: anytype) T {
    return bitExtend(.signed, T, value);
}

pub fn zeroExtend(comptime T: type, value: anytype) T {
    return bitExtend(.unsigned, T, value);
}

pub fn bitTruncate(comptime T: type, value: anytype) T {
    const src_bits = comptime @typeInfo(@TypeOf(value)).int.bits;
    const dst_bits = comptime @typeInfo(T).int.bits;
    const dst_sign = comptime @typeInfo(T).int.signedness;
    comptime std.debug.assert(dst_bits <= src_bits);
    const sign_corrected: std.meta.Int(dst_sign, src_bits) = @bitCast(value);
    const truncated: std.meta.Int(dst_sign, dst_bits) = @truncate(sign_corrected);
    return @bitCast(truncated);
}

pub fn hexFmt(value: anytype) [@typeInfo(@TypeOf(value)).int.bits >> 2]u8 {
    const size = comptime @typeInfo(@TypeOf(value)).int.bits >> 3;
    const bytes: [size]u8 = @bitCast(@byteSwap(value));
    return std.fmt.bytesToHex(bytes, .upper);
}

pub fn toggleBitField(reg: anytype, comptime field: []const u8, value: u32, shift: u5) void {
    switch (@as(u2, @truncate(value >> shift))) {
        1 => @field(reg, field) = false,
        2 => @field(reg, field) = true,
        else => {},
    }
}

pub fn writeWithMask(comptime T: type, reg: *T, mask: T, value: T) void {
    reg.* = (reg.* & ~mask) | (value & mask);
}
