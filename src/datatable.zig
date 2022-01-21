const std = @import("std");
const debug = std.debug;
const mem = std.mem;
const ArrayList = std.ArrayList;

const Row = struct {
    pub const Cell = struct {
        column: *Column,
        data: []const u8,
    };

    id: usize,
    cells: ArrayList(Cell),

    pub fn init(allocator: mem.Allocator, id: usize) Row {
        return Row{
            .id = id,
            .cells = ArrayList(Cell).init(allocator),
        };
    }

    pub fn appendCell(self: *Row, new_cell: Cell) !void {
        try self.cells.append(new_cell);
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
    rows: ArrayList(Row),

    pub fn init(allocator: mem.Allocator) !DataTable {
        var self = DataTable{
            .allocator = allocator,
            .columns = ArrayList(Column).init(allocator),
            .rows = ArrayList(Row).init(allocator),
        };
        try self.addSingleColumn(.{ .name = "Id", .allow_empty = false });
        return self;
    }

    pub fn deinit(self: DataTable) void {
        self.columns.deinit();
        for (self.rows.items) |row| {
            row.cells.deinit();
        }
        self.rows.deinit();
    }

    pub fn addSingleColumn(self: *DataTable, column: Column) !void {
        try self.columns.append(column);
    }

    pub fn addManyColumns(self: *DataTable, columns: []const Column) !void {
        for (columns) |column| {
            try self.addSingleColumn(column);
        }
    }

    pub fn totalColumns(self: *DataTable) usize {
        return self.columns.items.len - 1; // without counting "Id" column
    }

    pub fn insertSingleData(self: *DataTable, single_data: []const []const u8) !void {
        var columns_index: usize = 1; // skip first Id column
        var row = Row.init(self.allocator, self.current_id);

        if (single_data.len > self.totalColumns()) return error.TooManyColumns;

        for (single_data) |data| {
            var current_column = &self.columns.items[columns_index];

            if (!current_column.allow_empty and data.len == 0) {
                return error.EmptyData;
            }
            if (data.len > current_column.max_len) {
                return error.TooLongDataLength;
            }
            try row.appendCell(.{ .column = current_column, .data = data });
            columns_index += 1;
        }
        try self.rows.append(row);
        self.current_id += 1;
    }

    pub fn insertManyData(self: *DataTable, many_data: []const []const []const u8) !void {
        for (many_data) |single_data| {
            try self.insertSingleData(single_data[0..]);
        }
    }

    pub fn isDataExistOnColumn(self: *DataTable, which_column: []const u8, which_data: []const u8) bool {
        for (self.rows.items) |row| {
            for (row.cells.items) |cell| {
                if (mem.eql(u8, cell.column.name, which_column) and mem.eql(u8, cell.data, which_data))
                    return true;
            }
        }
        return false;
    }

    pub fn searchData(self: *DataTable, which_column: []const u8, which_data: []const u8) ![][]const u8 {
        var row_index: ?usize = null;

        outer: for (self.rows.items) |row, i| {
            for (row.cells.items) |cell| {
                if (mem.eql(u8, cell.column.name, which_column) and mem.eql(u8, cell.data, which_data)) {
                    row_index = i;
                    break :outer;
                }
            }
        }
        if (row_index) |idx| {
            var found_data = ArrayList([]const u8).init(self.allocator);
            defer found_data.deinit();

            for (self.rows.items[idx].cells.items) |cell| {
                try found_data.append(cell.data);
            }
            return found_data.toOwnedSlice();
        } else {
            return error.DataNotFound;
        }
    }

    pub fn selectColumnByNum(self: *DataTable, which_column_num: usize) ![][]const u8 {
        if (which_column_num > self.totalColumns()) return error.ColumnNotFound;
        if (self.rows.items.len == 0) return error.EmptyData;

        var column_index = which_column_num - 1;
        var data = ArrayList([]const u8).init(self.allocator);
        defer data.deinit();

        for (self.rows.items) |row| {
            try data.append(row.cells.items[column_index].data);
        }
        return data.toOwnedSlice();
    }

    pub fn selectColumnByName(self: *DataTable, which_column: []const u8) ![][]const u8 {
        var column_index: ?usize = null;
        for (self.columns.items) |column, i| {
            if (mem.eql(u8, column.name, which_column)) {
                column_index = i;
                break;
            }
        }

        if (column_index) |idx| {
            return self.selectColumnByNum(idx);
        } else {
            return error.ColumnNotFound;
        }
    }
};
