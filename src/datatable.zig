const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const ArrayList = std.ArrayList;
const SinglyLinkedList = std.SinglyLinkedList;

pub const Column = struct {
    name: []const u8,
    allow_empty: bool = false,
    max_len: usize = 255,
};

// Actual data of LinkedList
const Cell = struct {
    column: *Column,
    data: []const u8,
};

pub const DataTable = struct {
    const Self = @This();

    allocator: mem.Allocator,
    current_id: usize = 0,
    columns: ArrayList(Column),
    table: []SinglyLinkedList(Cell) = undefined,

    pub fn init(allocator: mem.Allocator) !Self {
        var self = Self{
            .allocator = allocator,
            .columns = ArrayList(Column).init(allocator),
        };
        try self.addColumn(.{ .name = "Id", .allow_empty = false });
        return self;
    }

    pub fn deinit(self: Self) void {
        self.columns.deinit();
    }

    pub fn addColumn(self: *Self, column: Column) !void {
        try self.columns.append(column);
    }

    pub fn addColumns(self: *Self, columns: []Column) !void {
        for (columns) |column| {
            try self.addColumn(column);
        }
    }

    pub fn countColumns(self: *Self) usize {
        return self.columns.items.len - 1; // without counting "Id" column
    }
};
