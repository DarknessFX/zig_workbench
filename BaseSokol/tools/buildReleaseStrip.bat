@ECHO OFF
CD ..

REM EXTRA ARGS SHORTCUT
REM ===================
REM  Linking system libraries (note: -l and library name all together):
REM   -lSDL2 -lOpenGL32
REM  Adding libraries DLL+LIB folders (note: -L SPACE Folder path):
REM   -L %CD%\lib\SDL2 
REM  Adding cImport .H include folders (note: -I SPACE Folder path):
REM    -I %CD%\lib\microui -I %CD%\lib\SDL2\include
REM
REM Full extra_args sample of a project that use SDL2 + OpenGL + microui :
REM  SET extra_args=-lSDL2 -lOpenGL32 -L "%CD%\lib\SDL2" -I "%CD%\lib\microui" -I "%CD%\lib\SDL2\include"

SET extra_args=-lgdi32 -Ilib/sokol -Ilib/nuklear

REM AddCSource
REM ==========
REM If your project use C Source Files, add here the list of files you want to add to your build.
REM 
REM SET addCSourceFile="%CD%\lib\microui\microui.c"

SET addCSourceFile="%CD%/lib/sokol/sokol_nuklear.c" "%CD%/lib/nuklear/nuklear.c"


IF NOT EXIST %CD%\bin\ReleaseStrip (
  MKDIR %CD%\bin\ReleaseStrip 
)
IF NOT EXIST %CD%\bin\ReleaseStrip\obj (
  MKDIR %CD%\bin\ReleaseStrip\obj
)

REM GET CURRENT FOLDER NAME
for %%* in (%CD%) do SET ProjectName=%%~n*

SET rcmd=
IF EXIST "*.rc" (
  SET rcmd=-rcflags /c65001 -- %CD%\%ProjectName%.rc
)

SET libc=
FINDSTR /L linkLibC build.zig > NUL && (
  SET libc=-lc
)

REM OUTPUT TO ZIG_REPORT.EXE
> bin/ReleaseStrip/obj/zig_report.txt (
  zig build-exe -O ReleaseSmall %rcmd% %libc% -fstrip -fsingle-threaded --color off -femit-bin=bin/ReleaseStrip/%ProjectName%.exe -femit-asm=bin/ReleaseStrip/obj/%ProjectName%.s -femit-llvm-ir=bin/ReleaseStrip/obj/%ProjectName%.ll -femit-llvm-bc=bin/ReleaseStrip/obj/%ProjectName%.bc -femit-h=bin/ReleaseStrip/obj/%ProjectName%.h -ftime-report -fstack-report %extra_args% --name %ProjectName% main.zig %addCSourceFile% 
) 2>&1 

IF EXIST "%CD%\bin\ReleaseStrip\%ProjectName%.exe.obj" (
  MOVE %CD%\bin\ReleaseStrip\%ProjectName%.exe.obj %CD%\bin\ReleaseStrip\obj > NUL
)

ECHO.
ECHO Done!
