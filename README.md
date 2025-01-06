     .----------------.  .----------------.  .----------------. 
    | .--------------. || .--------------. || .--------------. |
    | |  ________    | || |  _________   | || |  ____  ____  | |
    | | |_   ___ `.  | || | |_   ___  |  | || | |_  _||_  _| | |
    | |   | |   `. \ | || |   | |_  \_|  | || |   \ \  / /   | |
    | |   | |    | | | || |   |  _|      | || |    > `' <    | |
    | |  _| |___.' / | || |  _| |_       | || |  _/ /'`\ \_  | |
    | | |________.'  | || | |_____|      | || | |____||____| | |
    | |              | || |              | || |              | |
    | '--------------' || '--------------' || '--------------' |
     '----------------'  '----------------'  '----------------' 

           DarknessFX @ https://dfx.lv | Twitter: @DrkFX

## About
I'm studying and learning [Zig Language](https://ziglearn.org/chapter-0/) (started Nov 19, 2023), sharing here my Zig projects, templates, libs and tools.

Using Windows 10, Zig x86_64 Version : **0.13.0**

> [!NOTE]
> This is a student project, code will run and build without errors (mostly because I just throw away errors), it is not a reference of "*best coding practices*". Suggestions or contributions changing the code to the "*right way and best practices*" are welcome.

## Templates

| Folder | Description | /Subsystem |
| ------------- | ------------- | ------------- |
| **[Base](/Base/)** | Template for a console program. | Console |
| **[BaseEx](/BaseEx/)** | Template for a console program that hide the console window. | Console |
| **[BaseWin](/BaseWin/)** | Template for a Windows program. | Windows |
| **[BaseWinEx](/BaseWinEx/)** | Template for a Windows program, Windows API as submodule. | Windows |
| **[BaseImGui](/BaseImGui/)** | Template with [Dear ImGui](https://github.com/ocornut/imgui) via [Dear Bindings](https://github.com/dearimgui/dear_bindings). Extra: [ImGui_Memory_Editor](https://github.com/ocornut/imgui_club/tree/main#imgui_memory_editor). Renderers: OpenGL2, OpenGL3, DirectX11, SDL3 OpenGL3, SDL2 OpenGL2, SDL3_Renderer, SDL2_Renderer | Both |
| **[BaseRayLib](/BaseRayLib/)** | Template with [RayLib](https://www.raylib.com/) and [RayGUI](https://github.com/raysan5/raygui). | Console |
| **[BaseSDL2](/BaseSDL2/)** | Template with [SDL2](https://libsdl.org/). | Windows |
| **[BaseSDL3](/BaseSDL3/)** | Template with [SDL3](https://libsdl.org/). | Windows |
| **[BaseSFML2](/BaseSFML2/)** | Template with [SFML2](https://www.sfml-dev.org/) via [CSFML2](https://www.sfml-dev.org/download/csfml/) C bindings. | Console |
| **[BaseSokol](/BaseSokol/)** | Template with [Sokol](https://github.com/floooh/sokol/). Extras UI: [Dear ImGui](https://github.com/ocornut/imgui) via [cimgui](https://github.com/cimgui/cimgui), [Nuklear](https://github.com/Immediate-Mode-UI/Nuklear). | Windows |
| **[BaseAllegro](/BaseAllegro/)** | Template with [Allegro5](https://liballeg.org/). | Console |
| **[BaseNanoVG](/BaseNanoVG/)** | Template with [NanoVG](https://github.com/memononen/nanovg) using GLFW3 OpenGL3. | Console |
| **[BaseLVGL](/BaseLVGL/)** | Template with [LVGL](https://lvgl.io/) UI. | Console |
| **[BaseMicroui](/Basemicroui/)** | Template with [microui](https://github.com/rxi/). Renderers: SDL2, Windows GDI. | Windows |
| **[BaseNuklear](/BaseNuklear/)** | Template with [Nuklear](https://github.com/Immediate-Mode-UI/Nuklear) UI using Windows GDI native. | Windows |
| **[BaseWebview](/BaseWebview/)** | Template with [Webview](https://github.com/webview/webview). | Console |
| **[BaseOpenGL](/BaseOpenGL/)** | Template with [OpenGL](https://www.opengl.org/) (GL.h). | Windows |
| **[BaseGLFW](/BaseGLFW/)** | Template with [GLFW](https://www.glfw.org/) and [GLAD](https://github.com/Dav1dde/glad/). | Console |
| **[BaseDX11](/BaseDX11/)** | Template with [DirectX Direct3D 11](https://learn.microsoft.com/en-us/windows/win32/direct3d11/atoc-dx-graphics-direct3d-11). | Windows |
| **[BaseWebGPU](/BaseWebGPU/)** | Template with [WebGPU](https://www.w3.org/TR/webgpu/). | Windows + Web |
| **[BaseLua](/BaseLua/)** | Template with [Lua](https://www.lua.org/home.html) scripting language. | Console |
| **[BaseSQLite](/BaseSQLite/)** | Template with [SQLite](https://www.sqlite.org/index.html) database. | Console |
| **[BaseLMDB](/BaseLMDB/)** | Template with [LMDB](https://www.symas.com/mdb) database. | Console |
| **[BaseDuckDB](/BaseDuckDB/)** | Template with [DuckDB](https://duckdb.org/) database. | Console |
| **[BaseODE](/BaseODE/)** | Template with [ODE](https://www.ode.org/) Open Dynamics Engine physics. | Console |
| **[BaseChipmunk2D](/BaseChipmunk2D/)** | Template with [Chipmunk2D](https://chipmunk-physics.net/) physics. | Console |
| **[BaseClay](/failed_BaseClay/)** | FAILED: Template with [Clay](https://github.com/nicbarker/clay/) UI using [RayLib](https://www.raylib.com/) renderer. | Windows |

<details>
   <summary><ins>Usage</ins></summary>
     
| Steps | Path example |
| ------------- | ------------- |
| Duplicate the template folder. | C:\zig_workbench\BaseWin Copy\ |
| Rename copy folder to your project name.  | C:\zig_workbench\MyZigProgram\ |
| Copy *tools/updateProjectName.bat* to your project Tools folder. | C:\zig_workbench\MyZigProgram\Tools\ |
| Run *updateProjectName.bat*. | C:\zig_workbench\MyZigProgram\Tools\updateProjectName.bat |
| Open *YourProject VSCode Workspace*. | C:\zig_workbench\MyZigProgram\MyZigProgram VSCode Workspace.lnk |

> [!WARNING]  
> Current VSCode + ZLS extension do not accept **@cInclude** relative to project folder and will break builds.<br/>
> After open your new project, remember to edit **.zig** files **@cInclude** including your full path and using / folder separator.

Zig have a useful built in feature: *zig init* that creates a basic project. I customized this basic project to fit my use cases, mostly to output to **bin** folder instead of **zig-out\bin**, have main.zig in the project root instead of src folder and use my [VSCode Setup](#about-vscode-tips-and-tricks).

</details> 
 
 <details>
  <summary><ins>About Dear ImGui</ins></summary>
<pre>Using Dear ImGui Docking 1.91.5 and Dear Bindings (20241108)
All necessary libraries are inside the template.<br/>

Note:
- When changing renderers, make sure to rename all files (Main.zig, Build.zig, .vscode/Tasks.json).
- Check tools/RunAll.bat to get a list of **Zig Run** commands to launch rendereres without renaming files.

ImGui_Memory_Editor: Edited from Dear Bindings output. Sample inside all ImGui templates and usage details at <a href="BaseImGui/lib/imgui/cimgui_memory_editor.h" target="_blank">cimgui_memory_editor.h</a></pre>
</details>

 <details>
  <summary><ins>About LVGL</ins></summary>
<pre>Using <a href="https://github.com/lvgl/lvgl" target="_blank">LVGL from source</a> (20231105, 9.0 Preview).
Used parts of code from <a href="https://github.com/lvgl/lv_port_pc_visual_studio" target="_blank">lv_port_pc_visual_studio</a> (lv_conf and main source).
All necessary libraries are inside the template.
Download Demos and Examples folders from the GitHub source<br/>
(and don't forget to add all .C files necessary to build).</pre>
</details>

<details>
  <summary><ins>About microui</ins></summary>
<pre>microui.c and microui.h are inside the project folder.
Normally I would recommend to download from the official repository 
but sadly microui is outdated (last update 3 years ago) and I applied 
<a href="https://github.com/rxi/microui/pulls" target="_blank">community pull requests</a> to the source code.
It was necessary because the original code crashed with <i>runtime 
error: member access within misaligned address</i> and without the 
<a href="https://github.com/rxi/microui/issues/19#issuecomment-979063923" target="_blank">fix</a> this project would not work.</pre>
</details>

 <details>
  <summary><ins>About Nuklear</ins></summary>
<pre>Using Nuklear from source (20241231).
I had to make some changes to the nuklear_gdi.h header to fix cImport errors, it failed with duplicate symbols (added inline) and later missing functions (removed static).</pre>
</details>

<details>
  <summary><ins>About RayLib</ins></summary>
<pre>Using <a href="https://github.com/raysan5/raylib" target="_blank">RayLib from source</a> (v5.0 from 20250102).</pre>
</details>

<details>
  <summary><ins>About Allegro</ins></summary>
<pre>Using <a href="https://github.com/liballeg/allegro5" target="_blank">Allegro5 from nuget package</a> (v5.2.10 from 20241127).</pre>
</details>

<details>
  <summary><ins>About SDL2</ins></summary>
<pre>&nbsp;&nbsp;Using SDL2 v2.28.4.
&nbsp;&nbsp;Download SDL2 from: <a href="https://github.com/libsdl-org/SDL/releases/tag/release-2.28.4" target="_blank">GitHub SDL2 Releases Page</a>.
&nbsp;&nbsp;For Windows devs: <a href="https://github.com/libsdl-org/SDL/releases/download/release-2.28.4/SDL2-devel-2.28.4-VC.zip" target="_blank">SDL2-devel-2.28.4-VC.zip 2.57 MB</a>.
&nbsp;&nbsp;Check <a href="https://github.com/DarknessFX/zig_workbench/blob/main/BaseSDL2/lib/SDL2/filelist.txt" target="_blank">BaseSDL2/lib/SDL2/filelist.txt</a> for a description 
&nbsp;&nbsp;of the folder structure and expected files path location.</pre>
</details>

<details>
  <summary><ins>About SDL3</ins></summary>
<pre>&nbsp;&nbsp;Built from source in 20241216, version 3.1.6.</pre>
</details>

<details>
  <summary><ins>About SFML2</ins></summary>
<pre>&nbsp;&nbsp;Using CSFML2 v2.6.1 from https://www.sfml-dev.org/download/csfml/ .</pre>
</details>


<details>
  <summary><ins>About GLFW and GLAD</ins></summary>
<pre>GLFW 3.3.8 (Win64 Static).
GLAD 2.0 (OpenGL 3.3 Compatibility).
All necessary libraries are inside the template.</pre>
</details>

<details>
  <summary><ins>About WebGPU</ins></summary>
<pre>SDL2 and Dawn Native.
All necessary libraries are inside the template.
&nbsp;
Requirements:
. [Emscripten](https://emscripten.org/) installed.
. Change a few hard-coded paths to reflect your local emscripten paths.
</pre>
</details>

<details>
  <summary><ins>About Clay</ins></summary>
<pre>Everything is working from the code/template part, but Zig's cImport fails to import Clay's macros with variadic arguments (...) .<br/>
Sharing here for anyone interested.</pre>
</details>


## Programs

| Folder | Description | /Subsystem |
| ------------- | ------------- | ------------- |
| **ToSystray** | Give other Windows programs ability to "Minimize to Systray". | Windows
| **zTime** | Similar to Linux TIME command, add zTime in front of your command to get the time it took to execute.<br/> Binary version ready to use is available to download at [Releases Page - zTime v1.0.1](https://github.com/DarknessFX/zig_workbench/releases/tag/zTime_v1.0.1). | Console

<details>
  <summary><ins>ToSystray Usage</ins></summary>
<pre>Usage:
ToSystray.exe "Application.exe" "Application Name"
&nbsp;&nbsp;<br/>
Example:
ToSystray.exe "C:\Windows\System32\Notepad.exe" "Notepad"</pre>
</details>

<details>
  <summary><ins>zTime Usage</ins></summary>
<pre>&nbsp;&nbsp;Examples, run in your Command Prompt, Windows Terminal or Powershell:
&nbsp;&nbsp;&nbsp;&nbsp;C:\>zTime zig build
&nbsp;&nbsp;&nbsp;&nbsp;C:\>zTime dir
&nbsp;&nbsp;&nbsp;&nbsp;C:\>zTime bin\ReleaseFast\YourProject.exe<br/>
&nbsp;&nbsp;Suggestion:
&nbsp;&nbsp;Copy zTime.exe to your Zig folder, this way the application will 
&nbsp;&nbsp;share the Environment Path and can be executed from anywhere.</pre>
</details>

## Projects

| Folder | Description |
| ------------- | ------------- |
|  **ModernOpenGL**  |  [Mike Shah](https://github.com/MikeShah) [ModernOpenGL](https://www.youtube.com/playlist?list=PLvv0ScY6vfd9zlZkIIqGDeG5TUWswkMox) Youtube Tutorials ported to Zig + SDL3.1.2 OpenGL 4.6. |

<details>
  <summary><ins>ModernOpenGL Info</ins></summary>
<pre>All files at Lib/SDL3 are the original ones from SDL Github, 
GLAD generated for 4.6 Core. For this project I did not use any 
zig binds or wrappers, just plain cImport.
A copy of SDL.h and glad.h exist at Lib root just replacing &lt;&gt; with "",
this change made easier for VSCode and ZLS display auto-complete.
I tried to @cImport GLM OpenGL Mathematics "C" version cGML, @import ziglm
and glm-zig, but each have their own quirks and styles while I'm wanted to 
keep the source code similar to the episodes, for this reason I built my 
own GLM.ZIG library with just a handful of used functions.
There are some small changes implemented from the original tutorial code, 
mostly adding full Translate, Rotate, Scale, Keyboard and Mouse Movement.
The Window Caption have a brief instruction of the keyboard settings and 
also, as my default, I used SHIFT+ESC to close the program.</pre>
</details>

## Libraries

| Folder | Description |
| ------------- | ------------- |
| **dos_color.zig** | Helper to output colors to console (std.debug.print) or debug console (OutputDebugString). |
| **string.zig** | WIP String Type. |

<details>
  <summary><ins>Libraries usage</ins></summary>
<pre>&nbsp;&nbsp;Create a /lib/ folder in your project folder.
&nbsp;&nbsp;Copy the library file to /lib/ .
&nbsp;&nbsp;Add <q>const libname = @Import("lib/lib_name.zig");</q> to your source code.</pre>
</details>

## Tools
> [!IMPORTANT]
> All tools should be run from **YourProjectFolder\Tools\\** folder, <br/>
> do not run it directly in the main folder.

| Folder | Description |
| ------------- | ------------- |
| **updateProjectName.bat** | Read parent folder name as your ProjectName and replace template references to ProjectName. |
| **buildReleaseStrip.bat** | Call "zig build-exe" with additional options (ReleaseSmall, strip, single-thread), emit assembly (.s), llvm bitcode (.ll, .bc), C header, zig build report. |
| **clean_zig-cache.bat** | Remove zig-cache from **all** sub folders. |


## Tools_ContextMenu
| Folder | Description |
| ------------- | ------------- |
| **zig.ico** | Zig logo Icon file (.ico). (Resolutions 64p, 32p, 16p) |
| **zig_256p.ico** | Zig logo Icon file (.ico) with higher resolutions . (Resolutions 256p, 128p, 64p, 32p, 16p) |
| **zig_contextmenu.bat** | Launcher used by Windows Explorer context menu, copy to Zig folder PATH. |
| **zig_icon.reg** | Associate an icon for .Zig files, add Build, Run, Test to Windows Explorer context menu. [Read more details](/tools/zig_icon.reg) in the file comments. |
| **zig_icon_cascade.reg** | Alternative of zig_icon.reg, groups all options inside a Zig submenu. [Read more details](/tools/zig_icon_cascade.reg) in the file comments. |

Tools to help setup Windows Explorer to apply icons to .ZIG files and add context menu short-cuts to Build, Run and Test.
<details>
  <summary>📷<ins>zig_icon.reg - screenshot</ins></summary>
     
<pre>After run zig_icon.reg, Windows Explorer will look like:<br/>
<img src="/.git_img/zig_icon_contextmenu.png" width="480" /></pre>
</details>
<details>
  <summary>📷<ins>zig_icon_cascade.reg - screenshot</ins></summary>
     
<pre>After run zig_icon_cascade.reg, Windows Explorer will look like:<br/>
<img src="/.git_img/zig_icon_cascade_contextmenu.png" width="480" /></pre>
</details>

## About VSCode (Tips and Tricks)

I'm using [VSCode](https://code.visualstudio.com/download) to program in Zig and using [Zig Language](https://marketplace.visualstudio.com/items?itemName=ziglang.vscode-zig) extension from [ZLS - Zig Language Server](https://github.com/zigtools/zls).

<details>
  <summary><ins>Extensions that I use and recommend</ins></summary>
<pre>&nbsp;&nbsp;<a href="https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools" target="_blank">C/C++</a> from Microsoft. (**essential to enable Debug mode**.)
&nbsp;&nbsp;<a href="https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools-extension-pack" target="_blank">C/C++ Extension Pack</a> from Microsoft. (non-essential)
&nbsp;&nbsp;<a href="https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools-themes" target="_blank">C/C++ Themes</a>. (non-essential)
&nbsp;&nbsp;<a href="https://marketplace.visualstudio.com/items?itemName=ms-vscode.hexeditor" target="_blank">Hex Editor</a> from Microsoft. (**essential in Debug mode**)
&nbsp;&nbsp;<a href="https://marketplace.visualstudio.com/items?itemName=DrMerfy.overtype" target="_blank">OverType</a> from DrMerfy. (non-essential? Add Insert key mode)
&nbsp;&nbsp;<a href="https://marketplace.visualstudio.com/items?itemName=PKief.material-icon-theme" target="_blank">Material Icon Theme</a> from Philipp Kief. (non-essential, but make VSCode looks better)</pre>
</details>

### Ctrl+R is the new F5

I changed a few VSCode keybindings for better use, mostly because Zig offer multiple options for Build, Run, Test, Generate Docs, and I setup VSCode Tasks.json with all available options.

The most important key binding change is **CTRL+T** to open TASKS menu, because VSCode keep the last task as first menu item, just pressing ENTER will: save current file and run the last ask. 

Zig Build is fast and *Template/.vscode/launch.json* is already setup so VSCode **F5** key (Start with Debugger) will activate Zig Build and start debug, it works great and fast. But even better is **Zig Run Main**, the way zig run compile and start (without debugger) is a lot faster and helps a lot to iterate and productivity. **CTRL+T, Enter** became one of my most used keyboard shortcut inside VSCode and **CTRL+R** to repeat the last task.<br/>

<details>
  <summary>📷<ins>Task menu screenshot</ins></summary>
<img src="/.git_img/vscode_tasks_menu.png" width="480" />
</details>


<details>
  <summary><ins>VSCode Keybindings details</ins></summary>
<br/>VSCode Keybindings file location at %APPDATA%\Code\User\keybindings.json<br/><br/>

CTRL+T : Removed showAllSymbols and added runTask.<br/>
Reason : Easy access to Tasks menu and repeatable action to run last action.<br/>

CTRL+R : Removed all bindings.<br/>
Reason: Because this key binding try to reload the current document or display a different menu that also will try to close the current document... If I need I can go to menu File > Open Recent File instead of this shortcut that risk to close what I'm working.<br/>

<pre>
[
  {
    "key": "ctrl+t",
    "command": "-workbench.action.showAllSymbols"
  },
  {
    "key": "ctrl+t",
    "command": "workbench.action.tasks.runTask"
  }
  {
    "key": "ctrl+r",
    "command": "-workbench.action.reloadWindow",
    "when": "isDevelopment"
  },
  {
    "key": "ctrl+r",
    "command": "-workbench.action.quickOpenNavigateNextInRecentFilesPicker",
    "when": "inQuickOpen && inRecentFilesPicker"
  },
  {
    "key": "ctrl+r",
    "command": "-workbench.action.openRecent"
  },
  {
    "key": "ctrl+t",
    "command": "workbench.action.tasks.runTask"
  },
  {
    "key": "ctrl+r",
    "command": "workbench.action.tasks.reRunTask"
  }
]
</pre>
</details>

### Copy your libraries DLL to Zig folder

When using libraries that have .DLL (for example SDL2_ttf.dll) the task Zig Run Main will fail because it cannot find the DLL and the exe was built somewhere in zig-cache, the error is "The terminal process ... terminated with exit code: 53.". The easier way to fix this error is to copy the library DLL to your Zig folder.

### Personal observation about VSCode

I have a Love/Hate relationship with VSCode, I only used it to code for Arduino and ESP32 with [Platform.io](https://marketplace.visualstudio.com/items?itemName=platformio.platformio-ide) and the hate is always when the editor try to be "smart and helpful". 

Yellow lightbulbs sometimes show up to notify "There are no fix", JSON files organized to easier read key items are reorder because "that is how JSON should be ordered", at least 10% of keys typed are wasted deleting things that VSCode put there to help me. And my favorite gripe: You select a function name in the Intellisense combo, it prints at your source code "YourFunction([cursor here])" BUT it don't display the arguments list, you need to backspace to delete the ( opening parenthesis, type ( and now the tooltip show up with the arguments list.

## Credits

[Zig Language](https://ziglang.org/) from ZigLang.org.<br/>
[SDL2, SDL3](https://libsdl.org/) from libSDL.org.<br/>
[GLFW](https://www.glfw.org) from GLFW.org.<br/>
[GLAD](https://github.com/Dav1dde/glad) from Dav1dde.<br/>
[microui](https://github.com/rxi/microui) from rxi.<br/>
[Dear ImGui](https://github.com/ocornut/imgui) from Omar Cornut.<br/>
[Dear Bindings](https://github.com/dearimgui/dear_bindings) from Ben Carter.<br/>
[LVGL](https://github.com/lvgl/lvgl) from LVGL Kft.<br/>
[ModernOpenGL](https://www.youtube.com/playlist?list=PLvv0ScY6vfd9zlZkIIqGDeG5TUWswkMox) from Mike Shah.<br/>
[RayLib](https://github.com/raysan5/raylib) and [RayGUI](https://github.com/raysan5/raygui) from Ramon Santamaria (@raysan5).<br/>
[WebGPU](https://www.w3.org/TR/webgpu/) from World Wide Web Consortium.<br/>
[Dawn](https://dawn.googlesource.com/dawn) from Google.<br/>
[Sokol](https://github.com/floooh/sokol/) from Floooh.<br/>
[cimgui](https://github.com/cimgui/cimgui) from Sonoro1234.<br/>
[Nuklear](https://github.com/Immediate-Mode-UI/Nuklear) from Micha Mettke.<br/>
[Clay](https://github.com/nicbarker/clay) from Nic Barker.<br/>
[Allegro5](https://liballeg.org/) from Allegro 5 Development Team.<br/>
[NanoVG](https://github.com/memononen/nanovg) from Memononen.<br/>
[SFML2](https://www.sfml-dev.org/) from Laurent Gomila.<br/>
[Webview](https://github.com/webview/webview/) from Webview Team.<br/>
[Lua](https://www.lua.org/home.html) from PUC-Rio.<br/>
[SQLite](https://www.sqlite.org/index.html) from SQLite Consortium.<br/>
[LMDB](https://www.symas.com/mdb) from Symas Corporation.<br/>
[DuckDB](https://duckdb.org/) from DuckDB Foundation.<br/>
[ODE](https://www.ode.org/) from Russ Smith.<br/>
[Chipmunk2D](https://chipmunk-physics.net/) from Howling Moon Software.<br/>
<br/>

## License
MIT - Free for everyone and any use.

DarknessFX @ https://dfx.lv | Twitter: @DrkFX<br/>
https://github.com/DarknessFX/zig_workbench

<details>
  <summary><sub><sub>SEO Helper</sub></sub></summary>
<pre>Giving Google a little help pairing Zig + LIB words, because it find my twitter posts easier than this repo:
BaseWinEx   = Zig Windows program template with Windows API as submodule.
BaseImGui   = Zig ImGui Windows program template with renderers: OpenGL3, DirectX11, SDL3 OpenGL3, SDL2 OpenGL2, SDL3_Renderer, SDL2_Renderer.
BaseLVGL    = Zig LVGL Windows program template.
Basemicroui = Zig microui Windows program template with renderers: SDL2, Windows GDI.
BaseRayLib  = Zig RayLib and RayGUI Windows program template.
BaseSDL2    = Zig SDL2 Windows program template.
BaseSDL3    = Zig SDL3 Windows program template.
BaseOpenGL  = Zig OpenGL GL.h Windows program template.
BaseGLFW    = Zig GLFW GLAD Windows program template.
BaseDX11    = Zig DirectX Direct3D 11 DX11 Windows program template.
BaseWebGPU  = Zig WebGPU WASM program template.
BaseSokol   = Zig Sokol Dear ImGui Nuklear UI program template.
BaseNuklear = Zig Nuklear UI program template.
BaseClay    = Zig Clay UI program template.
BaseAllegro = Zig Allegro5 program template.
BaseNanoVG  = Zig NanoVG program template.
BaseWebview = Zig Webview program template.
BaseLua     = Zig Lua scripting language program template.
BaseSQLite  = Zig SQLite database program template.
BaseLMDB    = Zig LMDB transactional database program template.
BaseODE     = Zig ODE Open Dynamics Engine physics program template.
Chipmunk2D  = Zig Chipmunk2D physics program template.
</pre>
</details>