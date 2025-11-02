const std = @import("std");
const zigtwit = @import("zigtwitarchiveutil");

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
    std.debug.print("Processing file name {s}\n", .{input_file_name});

    const open_flags = std.fs.File.OpenFlags {.mode = .read_only};
    const file = std.fs.cwd().openFile(input_file_name, open_flags) catch {
        return ZigTwitError.FileNotFound;
    };
    defer file.close();

    const max_file_size = 1 * 1024 * 1024 * 1024; // 1 GB
    const file_contents = try file.readToEndAlloc(allocator, max_file_size);
    defer allocator.free(file_contents);

    const parsed = try zigtwit.parseTweetHeaders(allocator, file_contents);
    std.debug.print("Parsed headers and found {d} tweets.\n", .{parsed.len});
}
