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
    tweet : TweetHeaderTweet
};

const TweetHeaderTweet = struct {
    tweet_id : []const u8,
    user_id : []const u8,
    created_at : []const u8
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

        const options = std.json.ParseOptions {
        };
        var parsed = std.json.parseFromSlice([]TweetHeader, allocator, buffer[start.?..], options) catch 
            return TweetHeaderError.ParseError;

        const data = parsed.value;
        for (data) |tweet| {
            try list.append(allocator, tweet);
        }
        parsed.deinit();

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

    const sample_tweet = TweetHeader {
        .tweet = TweetHeaderTweet {
            .tweet_id = "1979736667021087142",
            .user_id = "29532976",
            .created_at = "Sun Oct 19 02:29:37 +0000 2025"
        }
    };

    const parsed: [1]TweetHeader = .{sample_tweet};

    const result = try parseTweetHeaders(sample_content, testing.allocator);
    defer testing.allocator.free(result);
    try testing.expectEqualDeep(result, &parsed);
}
