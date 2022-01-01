const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const ArrayList = std.ArrayList;

const Row = struct {
    id: usize,
    cell: ?*Cell = null,

    pub fn init(id: usize) Row {
        return Row{ .id = id };
    }

    pub fn appendData(self: *Row, new_cell: *Cell) void {
        if (self.cell == null) {
            self.cell = new_cell;
            return;
        }
        self.cell.append(new_cell);
    }
};

const Cell = struct {
    column: *Column,
    data: []const u8,
    next: ?*Cell = null,

    pub fn append(self: *Cell, new_cell: *Cell) void {
        var last_cell = blk: {
            var current_cell = self;
            while (true) {
                current_cell = current_cell.next orelse break :blk current_cell;
            }
        };
        last_cell.next = new_cell;
    }
};

pub const Column = struct {
    name: []const u8,
    allow_empty: bool = false,
    max_len: usize = 255,
};

pub const DataTable = struct {
    allocator: mem.Allocator,
    current_id: usize = 0,
    columns: ArrayList(Column),
    table: ArrayList(Row) = undefined,

    pub fn init(allocator: mem.Allocator) !DataTable {
        var self = DataTable{
            .allocator = allocator,
            .columns = ArrayList(Column).init(allocator),
            .table = ArrayList(Row).init(allocator),
        };
        try self.addSingleColumn(.{ .name = "Id", .allow_empty = false });
        return self;
    }

    pub fn deinit(self: DataTable) void {
        self.columns.deinit();
    }

    pub fn addSingleColumn(self: *DataTable, column: Column) !void {
        try self.columns.append(column);
    }

    pub fn addManyColumns(self: *DataTable, columns: []Column) !void {
        for (columns) |column| {
            try self.addColumn(column);
        }
    }

    pub fn countColumns(self: *DataTable) usize {
        return self.columns.items.len - 1; // without counting "Id" column
    }

    pub fn insertSingleData(self: *DataTable, raw_data: [][]const u8) !void {
        var columns_index: usize = 1; // skip first Id column
        var row = Row.init(self.current_id);

        if (raw_data.len > self.countColumns()) return error.TooLongData;

        for (raw_data) |data| {
            var current_column = self.columns.items[columns_index];

            if (!current_column.allow_empty and data.len == 0) {
                return error.EmptyData;
            }
            row.appendData(Cell{ .column = current_column, .data = data });
            columns_index += 1;
        }
        try self.table.append(row);
        self.current_id += 1;
    }
};
