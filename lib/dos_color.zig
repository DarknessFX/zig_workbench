//! DOS_COLOR: Helper functions to change foreground, background or 
//! text decoration in Windows Terminal CMD for std.debug.print messages.
const print = @import("std").debug.print;

/// unicode Escape char used to initialize a color command.
pub const ColorOptions_EscapeChar:u16 = '';
/// Single escape command instruction format to apply a color command.
pub const ColorOptions_EscapeCmd = "{u}[{d}m";
/// Full escape command instructions format to apply foreground, background and text decoration.
pub const ColorOptions_EscapeCmdFull = "{u}[{d}m{u}[{d}m{u}[{d}m";

/// List of available colors.
pub const ColorOptions_Color = enum(u8) {
  BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, DARK_WHITE,
  BLACK_LIGHT, RED_LIGHT, GREEN_LIGHT, YELLOW_LIGHT, BLUE_LIGHT, MAGENTA_LIGHT, CYAN_LIGHT,
  WHITE,
};

/// List of text decorations.
pub const ColorOptions_Text = enum(u8) {
  BOLD, UNDERLINE, NOUNDERLINE, REVERSE, NOREVERSE, 
};

pub const ColorOptions_Type = union(enum) {
  fgcolor: ColorOptions_Color,
  bgcolor: ColorOptions_Color,
  text: ColorOptions_Text
};

/// Return comands code for foreground color.
pub fn ColorOptions_GetForegroundCmd( fg:ColorOptions_Color ) u8 { 
  switch (@intFromEnum(fg)) {
    0...7 => |i| return i + 30,
    else  => |i| return (i - 8) + 90
  }
}

/// Return comands code for background color.
pub fn ColorOptions_GetBackgroundCmd( bg:ColorOptions_Color ) u8 {
  switch (@intFromEnum(bg)) {
    0...7 => |i| return i + 40,
    else  => |i| return (i - 8) + 100
  }
}

/// Return comands code for text decoration.
pub fn ColorOptions_GetTextDecorationCmd( tx:ColorOptions_Text ) u8 {
  switch (@intFromEnum(tx)) {
    0 => return 1,
    1 => return 4,
    2 => return 24,
    3 => return 7,
    else => return 27
  }
}

/// Options for foreground + background colors and text decorations.
/// Default: Foreground White, Background Black, TextDecoration NoReverse.
pub const ColorOptions = struct {
  foreground: ColorOptions_Color = .WHITE, 
  background: ColorOptions_Color = .BLACK,
  text: ColorOptions_Text = .NOREVERSE,
};

/// Call this function before your std.debug.print to apply options to foreground, brackground and text decoration.
/// Usage: printColor( .{ .foreground = .CYAN, .background = .RED_LIGHT, .text = .BOLD } );
/// Optional: printColor( .{} ); to reset options to default settings.
pub fn printColor( Options: ColorOptions ) void {
  print(
    ColorOptions_EscapeCmdFull, .{ 
    ColorOptions_EscapeChar, ColorOptions_GetForegroundCmd(Options.foreground),
    ColorOptions_EscapeChar, ColorOptions_GetBackgroundCmd(Options.background),
    ColorOptions_EscapeChar, ColorOptions_GetTextDecorationCmd(Options.text)
  });
}

/// Like print color but output a single command.
/// Useful if you need text decoration BOLD + UNDERLINE + REVERSE.
/// Usage: printColorCmd( .{ .fgcolor = .RED });
pub fn printColorCmd( Option: ColorOptions_Type ) void {
  switch (Option) {
    .fgcolor => |fg| print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, ColorOptions_GetForegroundCmd(fg) }),
    .bgcolor => |bg| print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, ColorOptions_GetBackgroundCmd(bg) }),
    .text    => |tx| print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, ColorOptions_GetTextDecorationCmd(tx) }),
  }
}

/// Shortcut to reset colors to default state.
pub fn printColorReset() void {
  const Options: ColorOptions = .{};
  //Reset color
  print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, ColorOptions_GetForegroundCmd(Options.foreground) });
  print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, ColorOptions_GetBackgroundCmd(Options.background) });
  print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, 0 });
}

//
// TESTS ======================================================================
//
test " Default values To Escape commands" {
  const Options: ColorOptions = .{};
  print("\n", .{});
  print("Default options: \n", .{});
  print("Enum : {} {} {}\n", .{ 
    @intFromEnum(Options.foreground),
    @intFromEnum(Options.background),
    @intFromEnum(Options.text)
  });
  print("Cmd  : {} {} {}\n", .{
    ColorOptions_GetForegroundCmd(Options.foreground),
    ColorOptions_GetBackgroundCmd(Options.background),
    ColorOptions_GetTextDecorationCmd(Options.text)
  });
  print("\n", .{});
}

test " Display all combinations" {
  // Inspired by SS64 EchoANSI.cmd
  // https://ss64.com/nt/syntax-ansi.html
  const std = @import("std");
  print("\n", .{});

  const colors = @typeInfo(ColorOptions_Color).Enum.fields;
  comptime var ifg = 0;
  comptime var ibg = 0;
  var fgcolor:u8 = 0;
  var bgcolor:u8 = 0;

  // For each Foreground color
  inline while (ifg < colors.len) : (ifg += 1) {
    //Get fg color cmd from Enum name
    fgcolor = ColorOptions_GetForegroundCmd(
      std.meta.stringToEnum(ColorOptions_Color, colors[ifg].name) 
      orelse ColorOptions_Color.WHITE);

    //Print current color name, FG and color command
    print("foreground: {s} {}\n", .{ colors[ifg].name, fgcolor });

    // For each Background color
    ibg = 0;
    inline while (ibg < colors.len) : (ibg += 1) {

      //Get bg color cmd from Enum name
      bgcolor = ColorOptions_GetBackgroundCmd(
        std.meta.stringToEnum(ColorOptions_Color, colors[ibg].name) 
        orelse ColorOptions_Color.BLACK); 

      //Print current BG color name
      print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, fgcolor });
      print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, bgcolor });
      print("{s:^10}", .{ if (colors[ibg].name.len > 10) colors[ibg].name[0..10] else colors[ibg].name} );

      // Reset color and breakline at groups of 8 colors
      if ((ibg + 1) % 8 == 0) {
        printColorReset();
        print("\n", .{});
      }
    }
  }

  print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, 0 });

  print("Text decorations: \n", .{ });
  const textdec = @typeInfo(ColorOptions_Text).Enum.fields;
  comptime var itx = 0;
  var txcmd:u8 = 0;
  // For each text decoration
  inline while (itx < textdec.len) : (itx += 1) {
    txcmd = ColorOptions_GetTextDecorationCmd(
      std.meta.stringToEnum(ColorOptions_Text, textdec[itx].name) 
      orelse ColorOptions_Text.NOREVERSE); 

    print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, txcmd });
    print("{s:^10}", .{ textdec[itx].name } );

    // Keep BOLD (cmd 0) to make Underline visible
    if (itx > 0) print( ColorOptions_EscapeCmd, .{ ColorOptions_EscapeChar, 0 });
  }
  print("\n", .{});
}