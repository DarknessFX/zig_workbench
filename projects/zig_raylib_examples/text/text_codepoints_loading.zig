//!zig-autodoc-section: text_codepoints_loading.Main
//! raylib_examples/text_codepoints_loading.zig
//!   Example - codepoints loading.
//!
//! raylib Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
//! Zig port created by DarknessFX | https://dfx.lv | X @DrkFX

// /*******************************************************************************************
// *
// *   raylib [text] example - Codepoints loading
// *
// *   Example originally created with raylib 4.2, last time updated with raylib 2.5
// *
// *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
// *   BSD-like license that allows static linking with closed source software
// *
// *   Copyright (c) 2022-2024 Ramon Santamaria (@raysan5)
// *
// ********************************************************************************************/

const std = @import("std");

// NOTE ABOUT VSCODE + ZLS:
// Use full path for all cIncludes:
//   @cInclude("C:/raylib_examples/lib/raylib.h"); 
const ray = @cImport({ 
  @cInclude("raylib.h"); 
});

// Text to be displayed, must be UTF-8 (save this code file as UTF-8)
// NOTE: It can contain all the required text for the game,
// this text will be scanned to get all the required codepoints
const text = 
"いろはにほへと　ちりぬるを\n" ++
"わかよたれそ　つねならむ\n" ++
"うゐのくやま　けふこえて\n" ++
"あさきゆめみし　ゑひもせす";

// Remove codepoint duplicates if requested
// WARNING: This process could be a bit slow if the text to process is very long
fn CodepointRemoveDuplicates(codepoints: []i32, allocator: std.mem.Allocator) ![]i32 {
  var codepointsNoDups = try allocator.alloc(i32, codepoints.len);
  defer allocator.free(codepointsNoDups);

  @memcpy(codepointsNoDups, codepoints);

  var i: usize = 0;
  while (i < codepointsNoDups.len) : (i += 1) {
    var j = i + 1;
    while (j < codepointsNoDups.len) {
      if (codepointsNoDups[i] == codepointsNoDups[j]) {
        std.mem.copyForwards(i32, codepointsNoDups[j..], codepointsNoDups[j + 1..]);
        codepointsNoDups = codepointsNoDups[0..codepointsNoDups.len - 1];
        j -= 1;
      }
      j += 1;
    }
  }

  const result = try allocator.alloc(i32, codepointsNoDups.len);
  @memcpy(result, codepointsNoDups);

  return result;
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() !u8 {
  // Initialization
  //--------------------------------------------------------------------------------------
  const screenWidth = 800;
  const screenHeight = 450;

  ray.InitWindow(screenWidth, screenHeight, "raylib [text] example - codepoints loading");

  // Get codepoints from text
  var codepointCount: i32 = 0;
  var codepoints = ray.LoadCodepoints(text, &codepointCount);

  // Removed duplicate codepoints to generate smaller font atlas
  // const codepointsNoDupsCount: i32 = 0;
  const codepointsNoDups = try CodepointRemoveDuplicates(codepoints[0..@intCast(codepointCount)], std.heap.page_allocator);
  defer std.heap.page_allocator.free(codepointsNoDups);

  // Load font containing all the provided codepoint glyphs
  // A texture font atlas is automatically generated
  const font = ray.LoadFontEx(getPath("text", "resources/DotGothic16-Regular.ttf"), 36, codepointsNoDups.ptr, @intCast(codepointsNoDups.len));

  // Set bilinear scale filter for better font scaling
  ray.SetTextureFilter(font.texture, ray.TEXTURE_FILTER_BILINEAR);

  ray.SetTextLineSpacing(20);         // Set line spacing for multiline text (when line breaks are included '\n')

  var ptr: [*c]const u8 = text.ptr;    // Pointer to the text for testing
  var codepointSize: c_int = 0;        // Size of the current codepoint

  ray.SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!ray.WindowShouldClose()) {    // Detect window close button or ESC key
    // Update
    //----------------------------------------------------------------------------------
    if (ray.IsKeyPressed(ray.KEY_RIGHT)) {
      // Get next codepoint in string and move pointer
      _ = ray.GetCodepointNext(ptr, &codepointSize);
      ptr += @as(usize, @intCast(codepointSize));
    } else if (ray.IsKeyPressed(ray.KEY_LEFT)) {
      // Get previous codepoint in string and move pointer
      _ = ray.GetCodepointPrevious(ptr, &codepointSize);
      ptr -= @as(usize, @intCast(codepointSize));
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    ray.BeginDrawing();

      ray.ClearBackground(ray.RAYWHITE);

      ray.DrawRectangle(0, 0, ray.GetScreenWidth(), 70, ray.BLACK);
      ray.DrawText(ray.TextFormat("Total codepoints contained in provided text: %i", codepointCount), 10, 10, 20, ray.GREEN);
      ray.DrawText(ray.TextFormat("Total codepoints required for font atlas (duplicates excluded): %i", codepointsNoDups.len), 10, 40, 20, ray.GREEN);

      ray.DrawTextEx(font, text, ray.Vector2{ .x = 20.0, .y = 80.0 }, 36.0, 2.0, ray.BLACK);

      ray.DrawRectangle(0, screenHeight - 70, screenWidth, 70, ray.BLACK);
      ray.DrawText("Press [RIGHT] or [LEFT] to move text cursor...", 30, screenHeight - 40, 20, ray.GRAY);
      ray.DrawText(ray.TextFormat("Current codepoint: 0x%x  (%d)", ray.GetCodepoint(ptr, &codepointSize), codepointSize), 30, toInt(screenHeight) - 20, 20, ray.MAROON);

    ray.EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  ray.UnloadCodepoints(codepoints);
  ray.UnloadFont(font);

  ray.CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}


//------------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------------
inline fn toFloat(value: i32) f32 { return @as(f32, @floatFromInt(value));}
inline fn toInt(value: f32) i32 { return @as(i32, @intFromFloat(value));}
inline fn toU8(value: c_int) u8 { return @as(u8, @intCast(value));}

inline fn fmt(comptime format: []const u8, args: anytype) []u8 {  return std.fmt.allocPrint(std.heap.page_allocator, format, args) catch unreachable; }
var cwd: []u8 = undefined;
inline fn getCwd() []u8 { return std.process.getCwdAlloc(std.heap.page_allocator) catch unreachable; }
inline fn getPath(folder: []const u8, file: []const u8) [*]const u8 { 
  if (cwd.len == 0) cwd = getCwd();
  std.fs.cwd().access(folder, .{ .mode = std.fs.File.OpenMode.read_only }) catch {
    return fmt("{s}/{s}", .{ cwd, file} ).ptr; 
  };
  return fmt("{s}/{s}/{s}", .{ cwd, folder, file} ).ptr; 
}