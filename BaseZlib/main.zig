//!zig-autodoc-section: BaseZlib.Main
//! Base\\main.zig :
//!   Template for a program using zlib 1.3.1 .
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================

const std = @import("std");
const zlib = @cImport({
  @cInclude("lib/zlib/zlib.h");
});
const print = std.debug.print;

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================

pub fn main() !void {
  const input_text = 
    \\Hello, Zig and zlib! A sample text to test zlib compress/decompress :
    \\In the quiet of early morning, the town awakens slowly, like a flower unfurling under the first 
    \\light of dawn. The baker, with flour-dusted hands, kneads dough for the day's first loaves, 
    \\while the scent of fresh coffee wafts from the small café on the corner. Birds chirp, announcing 
    \\the new day to the world, their songs a natural symphony. Children with backpacks, full of energy 
    \\and stories, walk to school, their laughter bouncing off the old brick walls. The local bookstore 
    \\owner arranges new arrivals, each book a portal to another world. The postman delivers letters and
    \\packages, connecting lives across distances. Here, time seems to have a gentler rhythm; the rush
    \\of the outside world is felt only faintly. As the sun climbs higher, casting long shadows, the
    \\town square becomes a meeting place, where neighbors exchange greetings, news, and sometimes,
    \\the comfort of shared silence. In this town, life is woven from simple, yet profound moments,
    \\where each day is an opportunity to live, love, and learn.
  ;
  
  print("Original: {s}\n", .{input_text});
  print("Original size: {d} bytes\n\n", .{input_text.len});

  const allocator = std.heap.page_allocator;

  // Compression
  var deflate_stream: zlib.z_stream = std.mem.zeroes(zlib.z_stream);
  try checkZlibError(zlib.deflateInit_(&deflate_stream, zlib.Z_BEST_COMPRESSION, zlib.ZLIB_VERSION, @sizeOf(zlib.z_stream)));
  deflate_stream.avail_in = @intCast(input_text.len);
  deflate_stream.next_in = @as([*c]u8, @constCast(input_text));

  const max_compressed_size = zlib.deflateBound(&deflate_stream, @intCast(input_text.len));
  const compressed = try allocator.alloc(u8, max_compressed_size);
  defer allocator.free(compressed);

  deflate_stream.avail_out = @intCast(max_compressed_size);
  deflate_stream.next_out = compressed.ptr;
  try checkZlibError(zlib.deflate(&deflate_stream, zlib.Z_FINISH));
  const compressed_size = max_compressed_size - deflate_stream.avail_out;
  print("Compressed: {x}\n", .{compressed[0..compressed_size]});
  print("Compressed size: {d} bytes\n\n", .{compressed_size});
  try checkZlibError(zlib.deflateEnd(&deflate_stream));  


  // Decompression
  var inflate_stream: zlib.z_stream = std.mem.zeroes(zlib.z_stream);
  try checkZlibError(zlib.inflateInit_(&inflate_stream, zlib.ZLIB_VERSION, @sizeOf(zlib.z_stream)));
  inflate_stream.avail_in = @intCast(compressed_size);
  inflate_stream.next_in = compressed.ptr;

  const decompressed = try allocator.alloc(u8, input_text.len);
  defer allocator.free(decompressed);

  inflate_stream.avail_out = @intCast(input_text.len);
  inflate_stream.next_out = decompressed.ptr;
  try checkZlibError(zlib.inflate(&inflate_stream, zlib.Z_NO_FLUSH));  
  print("Decompressed: {s}\n", .{decompressed});
  print("Decompressed size: {d} bytes\n\n", .{decompressed.len});
  try checkZlibError(zlib.inflateEnd(&inflate_stream));
}

//#endregion ==================================================================
//#region MARK: UTIL
//=============================================================================

fn checkZlibError(code: c_int) !void {
  if (code != zlib.Z_OK and code != zlib.Z_STREAM_END) {
    const err_msg = switch (code) {
      zlib.Z_STREAM_ERROR => "Stream error",
      zlib.Z_DATA_ERROR => "Data error",
      zlib.Z_MEM_ERROR => "Memory error",
      zlib.Z_BUF_ERROR => "Buffer error",
      zlib.Z_VERSION_ERROR => "Version error",
      else => "Unknown zlib error",
    };
    print("Zlib error: {s}\n", .{err_msg});
    return error.ZlibError;
  }
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " " {

}

//#endregion ==================================================================
//=============================================================================