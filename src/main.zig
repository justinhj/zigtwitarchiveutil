const std = @import("std");
const zigtwitarchiveutil = @import("zigtwitarchiveutil");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("Hello", .{});
}
