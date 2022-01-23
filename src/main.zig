const std = @import("std");
const dt = @import("datatable.zig");

const testing = std.testing;

test "table without using id" {
    const columns = [_]dt.Column{
        .{ .name = "Middle Name", .allow_empty = true },
        .{ .name = "Last Name" },
        .{ .name = "Age" },
        .{ .name = "Ph No", .max_len = 10 },
    };

    var user_table = dt.DataTable.init(std.heap.page_allocator);
    defer user_table.deinit();

    try user_table.addSingleColumn(dt.Column{ .name = "First Name" });
    try user_table.addManyColumns(columns[0..]);
    try testing.expect(user_table.totalColumns() == 5);

    try user_table.insertSingleData(&[_][]const u8{
        "Prajwal", "", "Chapagain", "20", "9815009744",
    });
    try user_table.insertManyData(&[_][]const []const u8{
        &.{ "Samyam", "", "Timsina", "18", "1234567890" },
        &.{ "Ramesh", "", "Dhungana", "19", "9800000900" },
    });

    try testing.expect(user_table.isDataExistOnColumn("Last Name", "Ramesh") == false);
    try testing.expect(user_table.isDataExistOnColumn("First Name", "Prajwal") == true);

    var searched_data = try user_table.searchData("Ph No", "9815009744");
    try testing.expect(searched_data.len == 5);

    var col1_data = try user_table.selectColumnByNum(1);
    try testing.expect(col1_data.len == 3 and std.mem.eql(u8, col1_data[2], "Ramesh"));

    var col4_data = try user_table.selectColumnByName("Ph No");
    try testing.expect(col4_data.len == 3 and std.mem.eql(u8, col4_data[1], "1234567890"));
    //user_table.deleteColumnByNum(2);
    //user_table.deleteColumnByName("Date");
}

test "table with using id" {
    var books_table = try dt.DataTable.initWithIdColumn(std.heap.page_allocator);
    defer books_table.deinit();

    try books_table.addManyColumns(&[_]dt.Column{
        .{ .name = "Book name" },
        .{ .name = "Author" },
    });
    try testing.expect(books_table.totalColumns() == 3);

    try books_table.insertManyData(&[_][]const []const u8{
        &.{ "Book 1", "person 1" },
        &.{ "Book 2", "person 2" },
        &.{ "Book 3", "person 3" },
        &.{ "Book 4", "person 4" },
    });
    try testing.expect(books_table.isDataExistOnColumn("Author", "person 3") == true);

    var book1_data = try books_table.searchData("Book name", "Book 1");
    try testing.expect(book1_data.len == 2);

    var col1_data = try books_table.selectColumnByNum(1);
    try testing.expect(col1_data.len == 4);
    try testing.expect(std.mem.eql(u8, col1_data[0], "Book 1"));
    try testing.expect(std.mem.eql(u8, col1_data[1], "Book 2"));
    try testing.expect(std.mem.eql(u8, col1_data[2], "Book 3"));
    try testing.expect(std.mem.eql(u8, col1_data[3], "Book 4"));

    var col1_data_searched_by_name = try books_table.selectColumnByName("Book name");
    try testing.expect(col1_data_searched_by_name.len == 4);
    try testing.expect(std.mem.eql(u8, col1_data_searched_by_name[0], "Book 1"));
    try testing.expect(std.mem.eql(u8, col1_data_searched_by_name[1], "Book 2"));
    try testing.expect(std.mem.eql(u8, col1_data_searched_by_name[2], "Book 3"));
    try testing.expect(std.mem.eql(u8, col1_data_searched_by_name[3], "Book 4"));
}
