const std = @import("std");
const zigtwitarchiveutil = @import("zigtwitarchiveutil");

const ZigTwitError = error {
    NoFileSupplied,
    FileNotFound
};


fn getInputFileName(allocator: std.mem.Allocator) ZigTwitError![]const u8 {
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();

    // Drop the executable
    _ = it.next();

    const filename = it.next() orelse return ZigTwitError.NoFileSupplied;
    return filename;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const input_file_name = getInputFileName(allocator) catch {
        std.debug.print("Please pass a file name of the Twitter index file,\n", .{});
        return;
    }; 
    std.debug.print("Input file name {s}\n", .{input_file_name});
}
