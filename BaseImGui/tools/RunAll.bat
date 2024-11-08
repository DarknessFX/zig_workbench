@ECHO OFF
REM Check if Tools folder, then go up to parent folder
SET FolderName=
FOR %%* IN (%CD%) DO SET FolderName=%%~n*
IF /I "%FolderName%" == "tools" (
  FOR %%* IN (%CD%\..) DO SET FolderName=%%~n*
  CD ..
)

ECHO.
ECHO ===============================================================================
ECHO Zig Run all renderers
ECHO   Useful to test when updating to new Dear ImGui + Dear Bindings.
ECHO ===============================================================================
ECHO.

ECHO. Main - OpenGL2
Zig run -lc++ -lgdi32 -ldwmapi -lopengl32 -I lib/opengl -I lib/imgui main_opengl2.zig lib/imgui/cimgui.cpp lib/imgui/cimgui_impl_opengl2.cpp lib/imgui/cimgui_impl_win32.cpp lib/imgui/cimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_opengl2.cpp

ECHO. Main - OpenGL3
Zig run -lc++ -lgdi32 -ldwmapi -lopengl32 -I lib/opengl -I lib/imgui main_opengl3.zig lib/imgui/cimgui.cpp lib/imgui/cimgui_impl_opengl3.cpp lib/imgui/cimgui_impl_win32.cpp lib/imgui/cimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_opengl3.cpp

ECHO. Main - DirectX11
Zig run -lc++ -lgdi32 -ldwmapi -ld3d11 -ld3dcompiler_47 -I lib/DX11 -I lib/imgui main_directx11.zig lib/imgui/cimgui.cpp lib/imgui/cimgui_impl_win32.cpp lib/imgui/cimgui_impl_dx11.cpp lib/imgui/cimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_dx11.cpp

ECHO. Main - SDL2 OpenGL2
Zig run -lc++ -lgdi32 -ldwmapi -lsdl2 -lopengl32 -L lib/SDL2 -I lib/imgui -I lib/opengl -I lib/SDL2/include main_sdl2_opengl2.zig lib/imgui/cimgui.cpp lib/imgui/cimgui_impl_sdl2.cpp lib/imgui/cimgui_impl_opengl2.cpp lib/imgui/cimgui_impl_win32.cpp lib/imgui/cimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_sdl2.cpp lib/imgui/imgui_impl_opengl2.cpp 

ECHO. Main - SDL2 SDL_Renderer
Zig run -lc++ -lgdi32 -ldwmapi -lsdl2 -L lib/SDL2 -I lib/imgui -I lib/SDL2/include main_sdlrenderer2.zig lib/imgui/cimgui.cpp lib/imgui/cimgui_impl_sdl2.cpp lib/imgui/cimgui_impl_sdlrenderer2.cpp lib/imgui/cimgui_impl_win32.cpp lib/imgui/cimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_sdl2.cpp lib/imgui/imgui_impl_sdlrenderer2.cpp 

ECHO. Main - SDL3 OpenGL3
Zig run -lc++ -lgdi32 -ldwmapi -lopengl32 -lsdl3 -L lib/SDL3 -I lib/imgui -I lib/opengl -I lib/SDL3/include main_sdl3_opengl3.zig lib/imgui/cimgui.cpp lib/imgui/cimgui_impl_sdl3.cpp lib/imgui/cimgui_impl_opengl3.cpp lib/imgui/cimgui_impl_win32.cpp lib/imgui/cimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_sdl3.cpp lib/imgui/imgui_impl_opengl3.cpp 

ECHO. Main - SDL3 SDL_Renderer
Zig run -lc++ -lgdi32 -ldwmapi -lsdl3 -L lib/SDL3 -I lib/imgui -I lib/SDL3/include main_sdlrenderer3.zig lib/imgui/cimgui.cpp lib/imgui/cimgui_impl_sdl3.cpp lib/imgui/cimgui_impl_sdlrenderer3.cpp lib/imgui/cimgui_impl_win32.cpp lib/imgui/cimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_sdl3.cpp lib/imgui/imgui_impl_sdlrenderer3.cpp 

ECHO. Main - SDL3 SDL_Renderer
Zig run -lc++ -lgdi32 -ldwmapi -lsdl3 -L lib/SDL3 -I lib/imgui -I lib/SDL3/include main_sdlrenderer3.zig lib/imgui/cimgui.cpp lib/imgui/cimgui_impl_sdl3.cpp lib/imgui/cimgui_impl_sdlrenderer3.cpp lib/imgui/cimgui_impl_win32.cpp lib/imgui/cimgui_memory_editor.cpp lib/imgui/imgui.cpp lib/imgui/imgui_widgets.cpp lib/imgui/imgui_draw.cpp lib/imgui/imgui_tables.cpp lib/imgui/imgui_demo.cpp lib/imgui/imgui_impl_win32.cpp lib/imgui/imgui_impl_sdl3.cpp lib/imgui/imgui_impl_sdlrenderer3.cpp 

PAUSE