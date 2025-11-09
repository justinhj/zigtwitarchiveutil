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

// Take a multiline string and escape the carriage returns so it is a single line
// Returns a new string
fn oneLineIt(allocator: std.mem.Allocator, line: [] const u8) ![]u8 {
    const new_size = line.len * 2;
    var buffer : []u8 = try allocator.alloc(u8, new_size);
    var j:usize = 0;
    for (0..line.len) |i| {
        if (line[i] == '\r') {
            buffer[j] = '\\';
            j += 1;
            buffer[j] = 'r';
            j += 1;
        }
        else if (line[i] == '\n') {
            buffer[j] = '\\';
            j += 1;
            buffer[j] = 'n';
            j += 1;
        } else {
            buffer[j] = line[i];
            j += 1;
        }
    }
    buffer[j] = 0;
    return buffer;
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

    // Example code print the dates
    // for (tweet_headers.value) |tweet| {
    //     const date1 = zdt.Datetime.fromString(tweet.tweet.created_at, "%a %b %d %H:%M:%S %z %Y") catch |err| {
    //         std.debug.print("Parse error {}.\n", .{err});
    //         return;
    //     };
    //     std.debug.print("{d}/{d}/{d}\n", .{date1.day, date1.month, @rem(date1.year, 100)});
    // }

    // Example code print the likes
    for (tweet_headers.value) |tweet| {
        std.debug.print("{s}\n{s}\n", .{ tweet.tweet.id_str, tweet.tweet.full_text });
    }
}

test "one liner" {
    const input1 =
        \\hello
        \\  world
        \\    I have three lines
        ;
    const expected1 = 
        \\hello\r\n  world\r\n I have three lines
        ;

    const output1 = try oneLineIt(std.testing.allocator, input1);
    defer std.testing.allocator.free(output1);
    std.debug.print("output {s}\n", .{output1});
    try std.testing.expect(std.mem.eql(u8, expected1,output1));
} 
