@ECHO OFF

REM Check if Tools folder, then go up to parent folder
SET FolderName=
FOR %%* IN (%CD%) DO SET FolderName=%%~n*
IF /I "%FolderName%" == "tools" (
  FOR %%* IN (%CD%\..) DO SET FolderName=%%~n*
  CD ..
)

REM EXTRA ARGS SHORTCUT
REM ===================
REM  Linking system libraries (note: -l and library name all together):
REM   -lSDL2 -lOpenGL32
REM  Adding libraries DLL+LIB folders (note: -L SPACE "Dir"):
REM   -L %CD%\lib\SDL2 
REM  Adding cImport .H include folders (note: -I"Dir", without spaces):
REM    -I%CD%\lib\microui -I%CD%\lib\SDL2\include
REM
REM Full extra_args sample of a project that use SDL3 + OpenGL :
REM  SET extra_args=-lSDL3 -lOpenGL32 -L "%CD%\lib\SDL3" -I"%CD%" -I"%CD%\lib" -I"%CD%\lib\SDL3"

SET extra_args=-I"%CD%" -I"%CD%/lib/freeglut" -I"%CD%/lib/freeglut/include" -lopengl32 -lgdi32 -lwinmm -DFREEGLUT_STATIC -DTARGET_HOST_MS_WINDOWS -DHAVE_SYS_TYPES_H -DHAVE_STDBOOL_H -DHAVE_STDINT_H


REM AddCSource
REM ==========
REM If your project use C Source Files, add here the list of files you want to add to your build.
REM 
REM SET addCSourceFile="%CD%\lib\SDL3\glad.c"

SET addCSourceFile=lib/freeglut/src/fg_callbacks.c lib/freeglut/src/fg_cursor.c lib/freeglut/src/fg_display.c lib/freeglut/src/fg_ext.c lib/freeglut/src/fg_font.c lib/freeglut/src/fg_font_data.c lib/freeglut/src/fg_gamemode.c lib/freeglut/src/fg_geometry.c lib/freeglut/src/fg_gl2.c lib/freeglut/src/fg_init.c lib/freeglut/src/fg_input_devices.c lib/freeglut/src/fg_joystick.c lib/freeglut/src/fg_main.c lib/freeglut/src/fg_menu.c lib/freeglut/src/fg_misc.c lib/freeglut/src/fg_overlay.c lib/freeglut/src/fg_spaceball.c lib/freeglut/src/fg_state.c lib/freeglut/src/fg_stroke_mono_roman.c lib/freeglut/src/fg_stroke_roman.c lib/freeglut/src/fg_structure.c lib/freeglut/src/fg_teapot.c lib/freeglut/src/fg_videoresize.c lib/freeglut/src/fg_window.c lib/freeglut/src/mswin/fg_cmap_mswin.c lib/freeglut/src/mswin/fg_cursor_mswin.c lib/freeglut/src/mswin/fg_display_mswin.c lib/freeglut/src/mswin/fg_ext_mswin.c lib/freeglut/src/mswin/fg_gamemode_mswin.c lib/freeglut/src/mswin/fg_init_mswin.c lib/freeglut/src/mswin/fg_input_devices_mswin.c lib/freeglut/src/mswin/fg_joystick_mswin.c lib/freeglut/src/mswin/fg_main_mswin.c lib/freeglut/src/mswin/fg_menu_mswin.c lib/freeglut/src/mswin/fg_spaceball_mswin.c lib/freeglut/src/mswin/fg_state_mswin.c lib/freeglut/src/mswin/fg_structure_mswin.c lib/freeglut/src/mswin/fg_window_mswin.c lib/freeglut/src/util/xparsegeometry_repl.c

IF NOT EXIST %CD%\bin\ReleaseStrip (
  MKDIR %CD%\bin\ReleaseStrip 
)
IF NOT EXIST %CD%\bin\ReleaseStrip\obj (
  MKDIR %CD%\bin\ReleaseStrip\obj
)

REM GET CURRENT FOLDER NAME
SET ProjectName=%FolderName%

SET rcmd=
IF EXIST "*.rc" (
  SET rcmd=-rcflags /c65001 -- %CD%\%ProjectName%.rc
)

SET singlethread=-fsingle-threaded
SET libc=
FINDSTR /L linkLibC build.zig > NUL && (
  SET libc=-lc
)
SET libcpp=
FINDSTR /L linkLibCpp build.zig > NUL && (
  SET libcpp=-lc++
  SET singlethread=
)

REM OUTPUT TO ZIG_REPORT.TXT
> bin/ReleaseStrip/obj/zig_report.txt (
  zig build-exe -O ReleaseSmall %rcmd% %libc% %libcpp% %singlethread% -fstrip --color off -femit-bin=bin/ReleaseStrip/%ProjectName%.exe -femit-asm=bin/ReleaseStrip/obj/%ProjectName%.s -femit-llvm-ir=bin/ReleaseStrip/obj/%ProjectName%.ll -femit-llvm-bc=bin/ReleaseStrip/obj/%ProjectName%.bc -femit-h=bin/ReleaseStrip/obj/%ProjectName%.h -fstack-report %extra_args% --name %ProjectName% main.zig %addCSourceFile%
) 2>&1 

REM OUTPUT BUILD COMMAND LINE TO ZIG_BUILD_CMD.TXT
> bin/ReleaseStrip/obj/zig_build_cmd.txt (
  ECHO zig build-exe -O ReleaseSmall %rcmd% %libc% %libcpp% %singlethread% -fstrip --color off -femit-bin=bin/ReleaseStrip/%ProjectName%.exe -femit-asm=bin/ReleaseStrip/obj/%ProjectName%.s -femit-llvm-ir=bin/ReleaseStrip/obj/%ProjectName%.ll -femit-llvm-bc=bin/ReleaseStrip/obj/%ProjectName%.bc -femit-h=bin/ReleaseStrip/obj/%ProjectName%.h -fstack-report %extra_args% --name %ProjectName% main.zig %addCSourceFile%
) 2>&1 

IF EXIST "%CD%\bin\ReleaseStrip\%ProjectName%.exe.obj" (
  MOVE %CD%\bin\ReleaseStrip\%ProjectName%.exe.obj %CD%\bin\ReleaseStrip\obj > NUL
)

ECHO.
ECHO Done!
REM PAUSE