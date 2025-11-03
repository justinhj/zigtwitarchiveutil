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

// Sample post from tweets.js

// window.YTD.tweets.part0 = [
// {
//   "tweet" : {
//     "edit_info" : {
//       "initial" : {
//         "editTweetIds" : [
//           "1977039067859894552"
//         ],
//         "editableUntil" : "2025-10-11T16:50:20.000Z",
//         "editsRemaining" : "5",
//         "isEditEligible" : false
//       }
//     },
//     "retweeted" : false,
//     "source" : "<a href=\"https://mobile.twitter.com\" rel=\"nofollow\">Twitter Web App</a>",
//     "entities" : {
//       "hashtags" : [ ],
//       "symbols" : [ ],
//       "user_mentions" : [ ],
//       "urls" : [
//         {
//           "url" : "https://t.co/RwFBCwuHS5",
//           "expanded_url" : "https://codeberg.org/ziglings/exercises",
//           "display_url" : "codeberg.org/ziglings/exerc…",
//           "indices" : [
//             "0",
//             "23"
//           ]
//         }
//       ]
//     },
//     "display_text_range" : [
//       "0",
//       "23"
//     ],
//     "favorite_count" : "0",
//     "in_reply_to_status_id_str" : "1977039066895204461",
//     "id_str" : "1977039067859894552",
//     "in_reply_to_user_id" : "29532976",
//     "truncated" : false,
//     "retweet_count" : "0",
//     "id" : "1977039067859894552",
//     "in_reply_to_status_id" : "1977039066895204461",
//     "possibly_sensitive" : false,
//     "created_at" : "Sat Oct 11 15:50:20 +0000 2025",
//     "favorited" : false,
//     "full_text" : "https://t.co/RwFBCwuHS5",
//     "lang" : "zxx",
//     "in_reply_to_screen_name" : "justinhj",
//     "in_reply_to_user_id_str" : "29532976"
//   }
// },

const Tweet = struct {
    tweet : TweetTweet,
};

const TweetTweet = struct {
    retweeted: bool,
    source: []const u8,
    favorite_count: []const u8,
    full_text: []const u8,
    id_str : []const u8,
    possibly_sensitive : bool,
    created_at : []const u8,
    favorited : bool,
    in_reply_to_screen_name : []const u8,
    in_reply_to_user_id_str : []const u8
};

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

pub fn parseTweetHeaders(allocator: std.mem.Allocator, buffer: []const u8) TweetHeaderError![]TweetHeader {
    // Parse begins at the first '[' skipping the non json friendly header
    const start = std.mem.indexOfScalar(u8, buffer, '['); 

    if(start == null) {
        return TweetHeaderError.ParseError;
    } else {
        // Parse the tweets into an ArrayList
        var list = std.ArrayList(TweetHeader).initCapacity(allocator, 128) catch 
            return TweetHeaderError.OutOfMemory;

        const options = std.json.ParseOptions{
                .ignore_unknown_fields = true,
            };
        var parsed = std.json.parseFromSlice([]TweetHeader, allocator, buffer[start.?..], options) catch 
            return TweetHeaderError.ParseError;
        defer parsed.deinit();

        const data = parsed.value;
        for (data) |tweet| {
            try list.append(allocator, tweet);
        }

        return list.toOwnedSlice(allocator);
    }
}

const testing = std.testing;

test "Parse headers" {
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

    const result = try parseTweetHeaders(testing.allocator, sample_content);
    defer testing.allocator.free(result);
    try testing.expectEqualDeep(result, &parsed);
}

test "Parse tweets" {
    const sample_content =
      \\ window.YTD.tweets.part0 = [
      \\ {
      \\   "tweet" : {
      \\     "edit_info" : {
      \\       "initial" : {
      \\         "editTweetIds" : [
      \\           "1977039067859894552"
      \\         ],
      \\         "editableUntil" : "2025-10-11T16:50:20.000Z",
      \\         "editsRemaining" : "5",
      \\         "isEditEligible" : false
      \\       }
      \\     },
      \\     "retweeted" : false,
      \\     "source" : "<a href=\"https:\\mobile.twitter.com\" rel=\"nofollow\">Twitter Web App</a>",
      \\     "entities" : {
      \\       "hashtags" : [ ],
      \\       "symbols" : [ ],
      \\       "user_mentions" : [ ],
      \\       "urls" : [
      \\         {
      \\           "url" : "https:\\t.co/RwFBCwuHS5",
      \\           "expanded_url" : "https:\\codeberg.org/ziglings/exercises",
      \\           "display_url" : "codeberg.org/ziglings/exerc…",
      \\           "indices" : [
      \\             "0",
      \\             "23"
      \\           ]
      \\         }
      \\       ]
      \\     },
      \\     "display_text_range" : [
      \\       "0",
      \\       "23"
      \\     ],
      \\     "favorite_count" : "0",
      \\     "in_reply_to_status_id_str" : "1977039066895204461",
      \\     "id_str" : "1977039067859894552",
      \\     "in_reply_to_user_id" : "29532976",
      \\     "truncated" : false,
      \\     "retweet_count" : "0",
      \\     "id" : "1977039067859894552",
      \\     "in_reply_to_status_id" : "1977039066895204461",
      \\     "possibly_sensitive" : false,
      \\     "created_at" : "Sat Oct 11 15:50:20 +0000 2025",
      \\     "favorited" : false,
      \\     "full_text" : "https:\\t.co/RwFBCwuHS5",
      \\     "lang" : "zxx",
      \\     "in_reply_to_screen_name" : "justinhj",
      \\     "in_reply_to_user_id_str" : "29532976"
      \\   }
      \\   }]
          ;

    const sample_tweet = Tweet {
        .tweet = TweetTweet {
            .retweeted = false,
            .source = "<a href=\"https://mobile.twitter.com\" rel=\"nofollow\">Twitter Web App</a>",
            .favorite_count = "0",
            .full_text = "https://t.co/RwFBCwuHS5",
            .id_str = "1977039067859894552",
            .possibly_sensitive = false,
            .created_at = "Sat Oct 11 15:50:20 +0000 2025",
            .favorited = false,
            .in_reply_to_screen_name = "justinhj",
            .in_reply_to_user_id_str = "29532976"
        }
    };

    try testing.expect(sample_content.len > 0);
    try testing.expect(sample_tweet.tweet.retweeted == false);

    // const parsed: [1]TweetHeader = .{sample_tweet};

    // const result = try parseTweetHeaders(testing.allocator, sample_content);
    // defer testing.allocator.free(result);
    // try testing.expectEqualDeep(result, &parsed);
}
