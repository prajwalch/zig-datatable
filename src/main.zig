const std = @import("std");
const dt = @import("datatable.zig");

const testing = std.testing;

test "test data table" {
    var columns = [_]dt.Column{
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

    var data = [_][]const u8{ "Prajwal", "", "Chapagain", "20", "9815009744" };
    try user_table.insertSingleData(data[0..]);

    try testing.expect(user_table.isDataExistOnColumn("First Name", "Rmaesh") == false);
    try testing.expect(user_table.isDataExistOnColumn("First Name", "Prajwal") == true);

    var searched_data = try user_table.searchData("Ph No", "9815009744");
    try testing.expect(searched_data.len == 5);
    std.debug.print("\n{s}\n", .{searched_data});

    //var many_data = [_][5][]const u8{
    //    .{ "Prajwal", "", "Chapagain", "20", "9815009744" },
    //};
    //try user_table.insertManyData(many_data[0..]);
    //try testing.expect(user_table.insertSingleData(data[0..]), error.TooManyColumns);
    //
    //user_table.findBy("First Name", "prajwal");
    //
    //user_table.selectColumnByNum(2);
    //user_table.selectColumnByName("First Name");
    //
    //user_table.deleteColumnByNum(2);
    //user_table.deleteColumnByName("Date");
}
