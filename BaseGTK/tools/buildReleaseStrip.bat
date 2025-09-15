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

REM EDIT HER TO YOUR MSYS2 mingw64 PATH
SET msys2_root=D:/workbench/Zig/_msys64/mingw64

SET extra_args= ^
 -I"%CD%" ^
 -I"%CD%\lib\GTK" ^
 -I"%msys2_root%\include\gtk-4.0" ^
 -I"%msys2_root%\include\gtk-4.0\gtk" ^
 -I"%msys2_root%\include\gtk-4.0\gdk" ^
 -I"%msys2_root%\include\gtk-4.0\gsk" ^
 -I"%msys2_root%\include\gdk-pixbuf-2.0" ^
 -I"%msys2_root%\include\graphene-1.0" ^
 -I"%msys2_root%\include\glib-2.0" ^
 -I"%msys2_root%\include\cairo" ^
 -I"%msys2_root%\include\pango-1.0" ^
 -I"%msys2_root%\include\pango-1.0\pango" ^
 -I"%msys2_root%\include\harfbuzz" ^
 -I"%msys2_root%\lib\glib-2.0\include" ^
 -I"%msys2_root%\lib\graphene-1.0\include" ^
 -L"%CD%\lib\GTK" ^
 -L"%msys2_root%\lib" ^
 -L"%msys2_root%\bin" ^
 -llibgtk-4-1 -llibgobject-2.0-0 -llibglib-2.0-0 -llibgio-2.0-0 -llibpango-1.0-0 -llibcairo-2 -llibgdk_pixbuf-2.0-0 -llibintl-8



REM AddCSource
REM ==========
REM If your project use C Source Files, add here the list of files you want to add to your build.
REM 
REM SET addCSourceFile="%CD%\lib\SDL3\glad.c"

SET addCSourceFile=

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

REM --- Generate Launch.bat ---
(
  echo @echo off
  echo SET PATH=%msys2_root%\bin;%%PATH%%
  echo BaseGTK.exe
) >  "%CD%\bin\ReleaseStrip\Launch.bat"

ECHO.
ECHO Done!
REM PAUSE