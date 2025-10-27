//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Sample tweet-headers.js you get from downloading your data on X
// window.YTD.tweet_headers.part0 = [
// {
//   "tweet" : {
//     "tweet_id" : "1979736667021087142",
//     "user_id" : "29532976",
//     "created_at" : "Sun Oct 19 02:29:37 +0000 2025"
//   }
// },

const TweetHeader = struct {
    tweet_id : u64,
    user_id : u64,
    created_at_str : []u8
};

const TweetHeaderError = error {
    ParseError,
    OutOfMemory
};

pub fn parseTweetHeaders(buffer: []const u8, allocator: std.mem.Allocator) TweetHeaderError![]TweetHeader {
    // Parse begins at the first '[' skipping the non json friendly header
    const start = std.mem.indexOfScalar(u8, buffer, '['); 

    if(start == null) {
        return TweetHeaderError.ParseError;
    } else {
        // Parse the tweets into an ArrayList
        var list = std.ArrayList(TweetHeader).initCapacity(allocator, 128) catch 
            return TweetHeaderError.OutOfMemory;
        return list.toOwnedSlice(allocator);
    }
}

const testing = std.testing;

test "Parse test" {
    const sample_content =
      \\window.YTD.tweet_headers.part0 = [
      \\  {
      \\    "tweet" : {
      \\       "tweet_id" : "1979736667021087142",
      \\        "user_id" : "29532976",
      \\        "created_at" : "Sun Oct 19 02:29:37 +0000 2025"
      \\     }
      \\   }]
          ;

    const parsed: [0]TweetHeader = .{};

    try testing.expectEqual(sample_content.len, 198);  

    const result = try parseTweetHeaders(sample_content, testing.allocator);

    try testing.expectEqualSlices([]TweetHeader, result, parsed);
}
