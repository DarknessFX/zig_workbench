//!zig-autodoc-section: BaseZstd.Main
//! BaseZstd\\main.zig :
//!   Template for a console program.
// Build using Zig 0.15.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/zig_workbench/BaseZstd/lib/zstd/zstd.h");
const zst = @cImport({
  @cInclude("lib/zstd/zstd.h");
});

//#endregion ==================================================================
//#region MARK: MAIN
//=============================================================================
pub fn main() !void {

  // Allocate memory for the source data
  // Long text to be compressed as sample
  const src = 
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

  std.debug.print("Original size: {d}\n\n", .{ src.len });

  const srcSize = src.len;

  // Compress the data
  const compressedSize = zst.ZSTD_compressBound(srcSize);
  const compressed = try std.heap.c_allocator.alloc(u8, compressedSize);
  defer std.heap.c_allocator.free(compressed);

  const compressedLen = zst.ZSTD_compress(compressed.ptr, compressedSize, src.ptr, srcSize, 10);
  if (zst.ZSTD_isError(compressedLen) != 0) {
    std.debug.print("Compression error: {s}\n", .{zst.ZSTD_getErrorName(compressedLen)});
    return error.CompressionFailed;
  }
  //std.debug.print("Compression successful,\nSize \t: {d}\nValue \t : \n", .{ compressedLen });
  // for (compressed[0..compressedLen]) |byte| {
  //   std.debug.print("{x:0>2}", .{byte});
  // }
  std.debug.print("Compression successful,\nSize \t: {d}\n", .{ compressedLen });
  std.debug.print("\n", .{});

  // Decompress the data
  var decompressed = try std.heap.c_allocator.alloc(u8, srcSize);
  defer std.heap.c_allocator.free(decompressed);

  const decompressedLen = zst.ZSTD_decompress(decompressed.ptr, srcSize, compressed.ptr, compressedLen);
  if (zst.ZSTD_isError(decompressedLen) != 0) {
    std.debug.print("Decompression error: {s}\n", .{zst.ZSTD_getErrorName(decompressedLen)});
    return error.DecompressionFailed;
  }

  // Confirm the decompressed data matches the original
  if (std.mem.eql(u8, src, decompressed[0..srcSize])) {
    std.debug.print("Decompression successful,\nSize\t: {d}\n\n", .{src.len});
    //std.debug.print("Decompression successful,\nSize\t: {d}\nOriginal: \n{s}\n", .{src.len, src});
    // for (src[0..src.len]) |byte| {
    //   std.debug.print("{x:0>2}", .{byte});
    // }

  } else {
    std.debug.print("Decompression failed to match original data.\n", .{});
    return error.DataMismatch;
  }
}

//#endregion ==================================================================
//#region MARK: TEST
//=============================================================================

test " empty" {
  try std.testing.expect(true);
}

//#endregion ==================================================================
//=============================================================================