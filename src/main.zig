const std = @import("std");
const zigtwit = @import("zigtwitarchiveutil");
const zdt = @import("zdt");

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
        std.debug.print("Please pass a file path to the Twitter tweets.js file,\n", .{});
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

    const tweet_headers = zigtwit.parseTweets(allocator, file_contents) catch |err| {
        std.debug.print("Failed to parse the Twitter tweets file. Error {}\n", .{err});
        return;
    }; 
    std.debug.print("Parsed headers and found {d} tweets.\n", .{tweet_headers.value.len});

    for (tweet_headers.value) |tweet| {
        const date1 = zdt.Datetime.fromString(tweet.tweet.created_at, "%a %b %d %H:%M:%S %z %Y") catch |err| {
            std.debug.print("Parse error {}.\n", .{err});
            return;
        };
        std.debug.print("{d}/{d}/{d}\n", .{date1.day, date1.month, @rem(date1.year, 100)});
    }
}
