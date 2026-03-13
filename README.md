# Zig LRU Cache

A high-performance, generic, thread-safe Least Recently Used (LRU) cache implementation written in Zig.

## Features
- **Generic:** Uses Zig's `comptime` to support any Key and Value types.
- **Thread-Safe:** Uses `std.Thread.Mutex` for safe concurrent access.
- **Efficient Memory Management:** Utilizes `std.heap.ArenaAllocator` for performant allocation.

## Prerequisites
- Zig 0.15.0 or later

## Usage

```zig
const std = @import("std");
const LRUCache = @import("lru.zig").LRUCache;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Initialize cache with a capacity of 1024 items
    var cache = LRUCache(u32, []const u8).init(allocator, 1024);
    defer cache.deinit();

    try cache.put(1, "data");

    if (cache.get(1)) |value| {
        // Found it!
    }
}
```
## Build and Test
To run the test suite and verify functionality:
```bash
zig build test --verbose
```
## License
MIT

__
