const std = @import("std");
const clap = @import("clap");

const max_file_size = 1073741824; // 1GiB

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    const parsers = .{
        .path = clap.parsers.string,
    };

    const params = comptime clap.parseParamsComptime(
        \\-h, --help       Display this help and exit.
        \\-p, --pif <path> Path to PIF ROM (usually "pifdata.bin")
        \\<path>
        \\
    );

    var res = try clap.parse(clap.Help, &params, parsers, .{ .allocator = allocator });
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.helpToFile(.stderr(), clap.Help, &params, .{});
    }

    const pif_path = res.args.pif orelse {
        std.debug.print("Error: PIF ROM path must be specified\n\n", .{});
        return clap.helpToFile(.stderr(), clap.Help, &params, .{});
    };

    const rom_path = res.positionals[0] orelse {
        std.debug.print("Error: Cartridge ROM path must be specified\n\n", .{});
        return clap.helpToFile(.stderr(), clap.Help, &params, .{});
    };

    var pif: [2048]u8 align(4) = undefined;

    _ = std.fs.cwd().readFile(pif_path, &pif) catch |err| {
        std.debug.print("Error: Could not read file {s}\n", .{pif_path});
        return err;
    };

    const rom = std.fs.cwd().readFileAllocOptions(allocator, rom_path, max_file_size, null, .@"4", null) catch |err| {
        std.debug.print("Error: Could not read file {s}\n", .{rom_path});
        return err;
    };
    defer allocator.free(rom);

    std.debug.print("PIF: {any}\n", .{pif});
    std.debug.print("ROM: {d}\n", .{rom.len});
}
