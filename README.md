# Zig LRU Cache

A high-performance, generic, thread-safe Least Recently Used (LRU) cache implementation written in Zig.

## Features
- **Generic:** Uses Zig's `comptime` to support any Key and Value types.
- **Thread-Safe:** Uses `std.Thread.Mutex` for safe concurrent access.
- **Efficient Memory Management:** Utilizes `std.heap.ArenaAllocator` for performant allocation.

## Getting Started

### Prerequisites
- Zig 0.15.0 or later

### Build and Test
To run the test suite and verify functionality:

```bash
zig build test --verbose
Usage
Example initialization:
var cache = LRUCache(u32, []const u8).init(allocator, 1024);
defer cache.deinit();

try cache.put(1, "data");
if (cache.get(1)) |value| {
    // Found it!
}

### License
MIT
---
