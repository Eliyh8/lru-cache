const std = @import("std");

pub fn LRUCache(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        const Node = struct {
            key: K,
            value: V,
            prev: ?*Node = null,
            next: ?*Node = null,
        };

        capacity: usize,
        size: usize,
        head: ?*Node,
        tail: ?*Node,
        map: std.AutoHashMap(K, *Node),
        mutex: std.Thread.Mutex,
        arena: std.heap.ArenaAllocator,

        pub fn init(child_allocator: std.mem.Allocator, capacity: usize) Self {
            return .{
                .capacity = capacity,
                .size = 0,
                .head = null,
                .tail = null,
                .map = std.AutoHashMap(K, *Node).init(child_allocator),
                .mutex = .{},
                .arena = std.heap.ArenaAllocator.init(child_allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
            self.arena.deinit();
        }

        pub fn get(self: *Self, key: K) ?V {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.map.get(key)) |node| {
                self.moveToHead(node);
                return node.value;
            }
            return null;
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.capacity == 0) return;

            if (self.map.get(key)) |node| {
                node.value = value;
                self.moveToHead(node);
                return;
            }

            var new_node: *Node = undefined;
            if (self.size == self.capacity) {
                const tail = self.tail orelse return;
                _ = self.map.remove(tail.key);
                self.removeNode(tail);
                new_node = tail;
            } else {
                new_node = try self.arena.allocator().create(Node);
                self.size += 1;
            }

            new_node.key = key;
            new_node.value = value;
            new_node.prev = null;
            new_node.next = null;

            try self.map.put(key, new_node);
            self.insertHead(new_node);
        }

        fn moveToHead(self: *Self, node: *Node) void {
            self.removeNode(node);
            self.insertHead(node);
        }

        fn removeNode(self: *Self, node: *Node) void {
            if (node.prev) |p| {
                p.next = node.next;
            } else {
                self.head = node.next;
            }

            if (node.next) |n| {
                n.prev = node.prev;
            } else {
                self.tail = node.prev;
            }
        }

        fn insertHead(self: *Self, node: *Node) void {
            node.next = self.head;
            node.prev = null;

            if (self.head) |h| {
                h.prev = node;
            }
            self.head = node;

            if (self.tail == null) {
                self.tail = node;
            }
        }
    };
}

test "LRUCache functionality and thread safety" {
    std.debug.print("\nRunning LRU Cache tests...\n", .{});
    const testing = std.testing;
    const allocator = testing.allocator;

    var cache = LRUCache(u32, []const u8).init(allocator, 3);
    defer cache.deinit();

    try cache.put(1, "one");
    try cache.put(2, "two");
    try cache.put(3, "three");

    try testing.expectEqualStrings("one", cache.get(1).?);
    try testing.expectEqualStrings("two", cache.get(2).?);
    try testing.expectEqualStrings("three", cache.get(3).?);

    try cache.put(4, "four");

    try testing.expect(cache.get(1) == null);
    try testing.expectEqualStrings("four", cache.get(4).?);

    _ = cache.get(2);
    try cache.put(5, "five");

    try testing.expect(cache.get(3) == null);
    try testing.expectEqualStrings("two", cache.get(2).?);

    const ThreadContext = struct {
        c: *LRUCache(u32, []const u8),

        fn run(ctx: @This()) void {
            ctx.c.put(6, "six") catch unreachable;
            _ = ctx.c.get(5);
            ctx.c.put(7, "seven") catch unreachable;
        }
    };

    var thread = try std.Thread.spawn(.{}, ThreadContext.run, .{ ThreadContext{ .c = &cache } });
    thread.join();

    try testing.expect(cache.get(4) == null);
    try testing.expect(cache.get(2) == null);

    try testing.expectEqualStrings("five", cache.get(5).?);
    try testing.expectEqualStrings("six", cache.get(6).?);
    try testing.expectEqualStrings("seven", cache.get(7).?);
}
