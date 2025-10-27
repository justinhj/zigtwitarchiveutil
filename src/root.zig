//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// Sample tweet-headers.js
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
    ParseError
};

pub fn parseTweetHeaders(buffer: []u8, allocator: std.mem.Allocator) TweetHeaderError![]TweetHeader {
    if(buffer.len == 0) {
        return .ParseError;
    } else {
        _ = allocator;
        return []TweetHeader;
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

    try testing.expectEqual(sample_content.len, 198);  
}
