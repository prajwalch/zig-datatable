const std = @import("std");
const dt = @import("datatable.zig");

const testing = std.testing;

test "test data table" {
    const columns = [_]dt.Column{
        .{ .name = "Middle Name", .allow_empty = true },
        .{ .name = "Last Name" },
        .{ .name = "Age" },
        .{ .name = "Ph No", .max_len = 10 },
    };

    var user_table = try dt.DataTable.init(std.heap.page_allocator);
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
