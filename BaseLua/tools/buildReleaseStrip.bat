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

SET extra_args=-I"%CD%" -I"%CD%\lib\lua"


REM AddCSource
REM ==========
REM If your project use C Source Files, add here the list of files you want to add to your build.
REM 
REM SET addCSourceFile="%CD%\lib\SDL3\glad.c"

SET addCSourceFile=lib\lua\lapi.c lib\lua\lauxlib.c lib\lua\lbaselib.c lib\lua\lcode.c lib\lua\lctype.c lib\lua\ldebug.c lib\lua\ldblib.c lib\lua\ldo.c lib\lua\ldump.c lib\lua\lfunc.c lib\lua\lgc.c lib\lua\linit.c lib\lua\liolib.c lib\lua\llex.c lib\lua\lmathlib.c lib\lua\lmem.c lib\lua\loadlib.c lib\lua\lobject.c lib\lua\lopcodes.c lib\lua\loslib.c lib\lua\lparser.c lib\lua\lstate.c lib\lua\lstring.c lib\lua\lstrlib.c lib\lua\ltable.c lib\lua\ltablib.c lib\lua\lutf8lib.c lib\lua\ltm.c lib\lua\lundump.c lib\lua\lvm.c lib\lua\lzio.c lib\lua\lcorolib.c


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
  zig build-exe -O ReleaseSmall %rcmd% %libc% %libcpp% %singlethread% -fstrip --color off -femit-bin=bin/ReleaseStrip/%ProjectName%.exe -femit-asm=bin/ReleaseStrip/obj/%ProjectName%.s -femit-llvm-ir=bin/ReleaseStrip/obj/%ProjectName%.ll -femit-llvm-bc=bin/ReleaseStrip/obj/%ProjectName%.bc -femit-h=bin/ReleaseStrip/obj/%ProjectName%.h -fstack-report %extra_args% --name %ProjectName% main.zig %addCSourceFile%
) 2>&1 

IF EXIST "%CD%\bin\ReleaseStrip\%ProjectName%.exe.obj" (
  MOVE %CD%\bin\ReleaseStrip\%ProjectName%.exe.obj %CD%\bin\ReleaseStrip\obj > NUL
)

IF EXIST "%CD%\script.lua" (
  COPY /Y %CD%\script.lua %CD%\bin\ReleaseStrip\ > NUL
)

ECHO.
ECHO Done!
REM PAUSE