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

SET extra_args=-I"%CD%" -I"%CD%\lib"

REM AddCSource
REM ==========
REM If your project use C Source Files, add here the list of files you want to add to your build.
REM
REM SET addCSourceFile="%CD%\lib\SDL3\glad.c"

SET addCSourceFile="%CD%/lib/box3d/src/aabb.c" "%CD%/lib/box3d/src/arena_allocator.c" "%CD%/lib/box3d/src/bitset.c" "%CD%/lib/box3d/src/block_allocator.c" "%CD%/lib/box3d/src/body.c" "%CD%/lib/box3d/src/broad_phase.c" "%CD%/lib/box3d/src/capsule.c" "%CD%/lib/box3d/src/compound.c" "%CD%/lib/box3d/src/constraint_graph.c" "%CD%/lib/box3d/src/contact.c" "%CD%/lib/box3d/src/contact_solver.c" "%CD%/lib/box3d/src/convex_manifold.c" "%CD%/lib/box3d/src/core.c" "%CD%/lib/box3d/src/distance.c" "%CD%/lib/box3d/src/distance_joint.c" "%CD%/lib/box3d/src/dynamic_tree.c" "%CD%/lib/box3d/src/height_field.c" "%CD%/lib/box3d/src/hull.c" "%CD%/lib/box3d/src/id_pool.c" "%CD%/lib/box3d/src/island.c" "%CD%/lib/box3d/src/joint.c" "%CD%/lib/box3d/src/manifold.c" "%CD%/lib/box3d/src/math_functions.c" "%CD%/lib/box3d/src/mesh.c" "%CD%/lib/box3d/src/mesh_contact.c" "%CD%/lib/box3d/src/motor_joint.c" "%CD%/lib/box3d/src/mover.c" "%CD%/lib/box3d/src/parallel_for.c" "%CD%/lib/box3d/src/parallel_joint.c" "%CD%/lib/box3d/src/physics_world.c" "%CD%/lib/box3d/src/prismatic_joint.c" "%CD%/lib/box3d/src/recording.c" "%CD%/lib/box3d/src/recording_replay.c" "%CD%/lib/box3d/src/revolute_joint.c" "%CD%/lib/box3d/src/scheduler.c" "%CD%/lib/box3d/src/sensor.c" "%CD%/lib/box3d/src/shape.c" "%CD%/lib/box3d/src/simd.c" "%CD%/lib/box3d/src/solver.c" "%CD%/lib/box3d/src/solver_set.c" "%CD%/lib/box3d/src/sphere.c" "%CD%/lib/box3d/src/spherical_joint.c" "%CD%/lib/box3d/src/table.c" "%CD%/lib/box3d/src/timer.c" "%CD%/lib/box3d/src/triangle_manifold.c" "%CD%/lib/box3d/src/types.c" "%CD%/lib/box3d/src/weld_joint.c" "%CD%/lib/box3d/src/wheel_joint.c" "%CD%/lib/box3d/src/world_snapshot.c"

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
FINDSTR /L link_libc build.zig > NUL && (
  SET libc=-lc
)
SET libcpp=
FINDSTR /L link_libcpp build.zig > NUL && (
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

ECHO.
ECHO Done!
REM PAUSE
