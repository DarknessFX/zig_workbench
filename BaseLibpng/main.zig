//!zig-autodoc-section: BaseLibpng.Main
//! BaseLibpng\\main.zig :
//!   Template for a program using libpng 1.6.50 .
// Build using Zig 0.16.0

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");
const png = @cImport({
  @cInclude("lib/libpng/png.h");
});
const print = std.debug.print;
var main_io: std.Io = undefined;
var output_file: std.Io.File = undefined;


//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main(init: std.process.Init) !void {
  main_io = init.io;
  const allocator = init.gpa;

  const output_file_name = "output.png";
  std.Io.Dir.cwd().deleteFile(main_io, output_file_name) catch {};
  output_file = try std.Io.Dir.cwd().createFile(main_io, output_file_name, .{
    .exclusive = true,
    .permissions = .default_file,
  });
  defer output_file.close(main_io);  

  // Write a 64x64 RGB PNG with vertical color gradients (R, G, B from 0 to 255)
  var png_ptr = png.png_create_write_struct(png.PNG_LIBPNG_VER_STRING, null, &checkPngError, null);
  if (png_ptr == null) return error.PngCreateWriteStructFailed;
  defer png.png_destroy_write_struct(&png_ptr, null);

  var info_ptr = png.png_create_info_struct(png_ptr);
  if (info_ptr == null) return error.PngCreateInfoStructFailed;
  defer png.png_destroy_info_struct(png_ptr, &info_ptr);


  const width: c_int = 64;
  const height: c_int = 64;
  //png.png_init_io(png_ptr, cfile);
  png.png_set_write_fn(png_ptr, &output_file, writeData, flushData);  
  png.png_set_IHDR(png_ptr, info_ptr, width, height, 8, png.PNG_COLOR_TYPE_RGB, png.PNG_INTERLACE_NONE, png.PNG_COMPRESSION_TYPE_DEFAULT, png.PNG_FILTER_TYPE_DEFAULT);
  png.png_write_info(png_ptr, info_ptr);

  // Create row data: vertical gradients for R, G, B (0 to 1 across height)
  const rowbytes = width * 3; // 3 bytes per pixel (RGB)
  const image_data = try allocator.alloc(u8, @intCast(rowbytes * height));
  defer allocator.free(image_data);

  for (0..@intCast(height)) |y| {
    const row = image_data[y * @as(u32, @intCast(rowbytes))..(y + 1) * @as(u32, @intCast(rowbytes))];
    const t = @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(height - 1)); // 0 to 1
    for (0..@intCast(width)) |x| {
      const idx = x * 3;
      // Three vertical stripes: R (left), G (middle), B (right)
      if (x < width / 3) {
        row[idx] = @intFromFloat(t * 255.0); // R gradient
        row[idx + 1] = 0; // G
        row[idx + 2] = 0; // B
      } else if (x < 2 * width / 3) {
        row[idx] = 0; // R
        row[idx + 1] = @intFromFloat(t * 255.0); // G gradient
        row[idx + 2] = 0; // B
      } else {
        row[idx] = 0; // R
        row[idx + 1] = 0; // G
        row[idx + 2] = @intFromFloat(t * 255.0); // B gradient
      }
    }
  }

  var row_pointers = try allocator.alloc([*c]u8, @intCast(height));
  defer allocator.free(row_pointers);
  for (0..@intCast(height)) |i| {
    row_pointers[i] = @as([*c]u8, @ptrCast(image_data.ptr + (i * rowbytes)));
  }

  //png.png_write_image(png_ptr, @as([*c]png.png_bytep, @ptrCast(row_pointers.ptr)));
  png.png_write_image(png_ptr, row_pointers.ptr);
  png.png_write_end(png_ptr, info_ptr);

  print("Created 64x64 PNG with vertical RGB gradients: {s}\n", .{output_file_name});
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================
fn writeData(png_ptr: ?*png.png_struct, data: [*c]u8, length: usize) callconv(.c) void {
  _ = png_ptr;
  const slice = data[0..length];
  output_file.writeStreamingAll(main_io, slice) catch |err| {
    std.debug.print("write failed: {}\n", .{err});
    @panic("png write failed");
  };
}

fn flushData(png_ptr: ?*png.png_struct) callconv(.c) void {
  _ = png_ptr;
  var buf: [128]u8 = @splat(0);
  var buffered = output_file.writer(main_io, &buf);
  const writer = &buffered.interface;
  _ = writer.flush() catch {};
}

fn checkPngError(png_ptr: ?*png.png_struct, msg: [*c]const u8) callconv(.c) void {
  _ = png_ptr;
  print("PNG error: {s}\n", .{msg});
  @panic("PNG error occurred");
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================
test " " {

}

//#endregion ==================================================================
//=============================================================================