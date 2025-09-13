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
REM  Adding libraries DLL+LIB folders (note: -L SPACE Folder path):
REM   -L %CD%\lib\SDL2 
REM  Adding cImport .H include folders (note: -I SPACE Folder path):
REM    -I %CD%\lib\microui -I %CD%\lib\SDL2\include
REM
REM Full extra_args sample of a project that use SDL2 + OpenGL + microui :
REM  SET extra_args=-lSDL2 -lOpenGL32 -L "%CD%\lib\SDL2" -I "%CD%\lib\microui" -I "%CD%\lib\SDL2\include"

SET extra_args=-lgdi32 -ldwmapi -lopengl32 -Ilib/opengl -Ilib/imgui 


REM AddCSource
REM ==========
REM If your project use C Source Files, add here the list of files you want to add to your build.
REM 
REM SET addCSourceFile="%CD%\lib\microui\microui.c"

SET addCSourceFile=lib/imgui/dcimgui.cpp lib/imgui/dcimgui_impl_opengl2.cpp lib/imgui/dcimgui_impl_win32.cpp lib/imgui/dcimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_opengl2.cpp 

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

REM OUTPUT TO ZIG_REPORT.EXE
> bin/ReleaseStrip/obj/zig_report.txt (
  zig build-exe -O ReleaseSmall %rcmd% %libc% %libcpp% %singlethread% -fstrip --color off -femit-bin=bin/ReleaseStrip/%ProjectName%.exe -femit-asm=bin/ReleaseStrip/obj/%ProjectName%.s -femit-llvm-ir=bin/ReleaseStrip/obj/%ProjectName%.ll -femit-llvm-bc=bin/ReleaseStrip/obj/%ProjectName%.bc -femit-h=bin/ReleaseStrip/obj/%ProjectName%.h -fstack-report %extra_args% --name %ProjectName% main.zig %addCSourceFile%
) 2>&1 

IF EXIST "%CD%\bin\ReleaseStrip\%ProjectName%.exe.obj" (
  MOVE %CD%\bin\ReleaseStrip\%ProjectName%.exe.obj %CD%\bin\ReleaseStrip\obj > NUL
)
IF EXIST "%CD%\bin\ReleaseStrip\%ProjectName%.lib" (
  MOVE %CD%\bin\ReleaseStrip\%ProjectName%.lib %CD%\bin\ReleaseStrip\obj > NUL
)

ECHO.
ECHO Done!
REM PAUSE