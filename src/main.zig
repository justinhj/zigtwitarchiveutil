const std = @import("std");
const zigtwit = @import("zigtwitarchiveutil");
const zdt = @import("zdt");
const ArrayList = std.ArrayList;

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

// Take a multiline string and escape the carriage returns so it is a single line
// Returns a new string
fn oneLineIt(allocator: std.mem.Allocator, line: [] const u8) ![]u8 {
    var output = try ArrayList(u8).initCapacity(allocator, line.len);
    for (line) |c| {
        if (c == '\r') {
            try output.appendSlice(allocator, "\\r");
        }
        else if (c == '\n') {
            try output.appendSlice(allocator, "\\n");
        }
        else {
            try output.append(allocator, c);
        }
    }
    return output.toOwnedSlice(allocator);
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

    const tweets = zigtwit.parseTweets(allocator, file_contents) catch |err| {
        std.debug.print("Failed to parse the Twitter tweets file. Error {}\n", .{err});
        return;
    }; 
    std.debug.print("Parsed headers and found {d} tweets.\n", .{tweets.value.len});

    // Example code print the likes
    for (tweets.value) |tweet| {
        const oneLiner = try oneLineIt(allocator, tweet.tweet.full_text);
        defer allocator.free(oneLiner);
        std.debug.print("{s}\n{s}\n", .{ tweet.tweet.id_str, oneLiner });
    }
}

test "multi line string becomes 1" {
    const input1 =
        \\hello
        \\  world
        \\    I have three lines
        ;
    const expected1 = 
        \\hello\n  world\n    I have three lines
        ;

    const actual1 = try oneLineIt(std.testing.allocator, input1);
    defer std.testing.allocator.free(actual1);
    try std.testing.expectEqualSlices(u8, expected1, actual1);
} 

test "empty string works" {
    const input1 = "";
    const expected1 = "";

    const actual1 = try oneLineIt(std.testing.allocator, input1);
    defer std.testing.allocator.free(actual1);
    try std.testing.expectEqualSlices(u8, expected1, actual1);
} 

test "string with only NL" {
    const input1 = "\n";
    const expected1 = "\\n";

    const actual1 = try oneLineIt(std.testing.allocator, input1);
    defer std.testing.allocator.free(actual1);
    try std.testing.expectEqualSlices(u8, expected1, actual1);
} 
