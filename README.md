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

Using Windows 10, Zig x86_64 Version : **_0.12.0-dev.1245+a07f288eb_**

> [!NOTE]
> This is a student project, code will run and build without errors (mostly because I just throw away errors), it is not a reference of "*best coding practices*". Suggestions or contributions changing the code to the "*right way and best practices*" are welcome.

## Templates

Zig have a useful built in feature: *zig init-exe* that create a basic project. I customized this basic project to fit my use cases, mostly to output to **bin** folder instead of **zig-out\bin**, have main.zig in the project root instead of src folder and use my [VSCode Setup](#about-vscode-tips-and-tricks).

| Folder | Description | /Subsystem |
| ------------- | ------------- | ------------- |
| **Base** | Template for a console program. | Console |
| **BaseEx** | Template for a console program that hide the console window. | Console |
| **BaseWin** | Template for a Windows program. | Windows |
| **BaseImGui** | Template with [Dear ImGui](https://github.com/ocornut/imgui) via [Dear Bindings](https://github.com/dearimgui/dear_bindings). Renderers: OpenGL3, SDL3 OpenGL3, SDL2 OpenGL2, SDL3_Renderer, SDL2_Renderer | Both |
| **Basemicroui** | Template with [microui](https://github.com/rxi/). Renderers: SDL2, Windows GDI. GUI examples: Minimal, Demo. | Windows |
| **BaseSDL2** | Template with [SDL2](https://libsdl.org/). | Windows |
| **BaseSDL3** | Template with [SDL3](https://libsdl.org/) Preview. | Windows |
| **BaseOpenGL** | Template with [OpenGL](https://www.opengl.org/) (GL.h). | Windows |
| **BaseGLFW** | Template with [GLFW](https://www.glfw.org/) and [GLAD](https://github.com/Dav1dde/glad/). | Console |

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

</details> 
 
 <details>
  <summary><ins>About Dear ImGui</ins></summary>
<pre>Using Dear ImGui Docking 1.90WIP and Dear Bindings (20231029)
All necessary libraries are inside the template.<br/><br/>

Note: When changing renderers, make sure to rename all files (Main.zig, Build.zig, .vscode/Tasks.json).</pre>
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
  <summary><ins>About SDL3 Preview</ins></summary>
<pre>&nbsp;&nbsp;Built from source in 20231102.</pre>
</details>

<details>
  <summary><ins>About GLFW and GLAD</ins></summary>
<pre>GLFW 3.3.8 (Win64 Static).
GLAD 2.0 (OpenGL 3.3 Compatibility).
All necessary libraries are inside the template.</pre>
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

## Libraries

| Folder | Description |
| ------------- | ------------- |
| **dos_color.zig** | Helper to output colors to console (std.debug.print) or debug console (OutputDebugString). |
| **string.zig** | Basic String Type. |

<details>
  <summary><ins>Libraries usage</ins></summary>
<pre>&nbsp;&nbsp;Create a /lib/ folder in your project folder.
&nbsp;&nbsp;Copy the library file to /lib/ .
&nbsp;&nbsp;Add <q>const libname = @Import("lib/lib_name.zig");</q> to your source code.</pre>
</details>

## Programs

| Folder | Description |
| ------------- | ------------- |
| **zTime** | Similar to Linux TIME command, add zTime in front of your command to get the time it took to execute.<br/> Binary version ready to use is available to download at [Releases Page - zTime v1.0](https://github.com/DarknessFX/zig_workbench/releases/tag/zTime_v1.0). (console program) |

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

## Tools
> [!IMPORTANT]
> All tools should be run from **YourProjectFolder\Tools\\** folder, <br/>
> do not run it directly in the main folder.

| Folder | Description |
| ------------- | ------------- |
| **updateProjectName.bat** | Read parent folder name as your ProjectName and replace template references to ProjectName. |
| **buildReleaseStrip.bat** | Call "zig build-exe" with additional options (ReleaseSmall, strip, single-thread), emit assembly (.s), llvm bitcode (.ll, .bc), C header, zig build report. |
| **clean_zig-cache.bat** | Remove zig-cache from **all** sub folders. |
| **zig.ico** | Zig logo Icon file (.ico). (Resolutions 64p, 32p, 16p) |
| **zig_256p.ico** | Zig logo Icon file (.ico) with higher resolutions . (Resolutions 256p, 128p, 64p, 32p, 16p) |
| **zig_icon.reg** | Associate an icon for .Zig files, add Build, Run, Test to Windows Explorer context menu. [Read more details](/tools/zig_icon.reg) in the file comments. |
| **zig_icon_cascade.reg** | Alternative of zig_icon.reg, groups all options inside a Zig submenu. |

<details>
  <summary><ins>zig_icon.reg - screenshot</ins></summary>
     
<pre>After run zig_icon.reg, Windows Explorer will look like:<br/>
<img src="/.git_img/zig_icon_contextmenu.png" width="480" /></pre>
</details>
<details>
  <summary><ins>zig_icon_cascade.reg - screenshot</ins></summary>
     
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

### Ctrl+T, Enter is the new F5

I changed a few VSCode keybindings for better use, mostly because Zig offer multiple options for Build, Run, Test, Generate Docs, and I setup VSCode Tasks.json with all available options.

The more important key binding change is **CTRL+T** to open TASKS menu, because VSCode keep the last task as first menu item, just pressing ENTER will: save current file and run the last ask. 

Zig Build is fast and *Template/.vscode/launch.json* is already setup so VSCode **F5** key (Start with Debugger) will activate Zig Build and start debug, it works great and fast. But even better is **Zig Run Main**, the way zig run compile and start (without debugger) is a lot faster and helps a lot to iterate and productivity. So **CTRL+T, Enter** became my most used keyboard shortcut inside VSCode.<br/>
<sub>(at least until they add a keybiding for "Run Last Task" so I can bind to CTRL+R<sup>un</sup>).</sub>

<details>
  <summary><ins>Task menu screenshot</ins></summary>
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
  }
]
</pre>
</details>

### Copy your libraries DLL to Zig folder

When using libraries that have .DLL (for example SDL2_ttf.dll) the task Zig Run Main will fail because it cannot find the DLL and the exe was built somewhere in zig-cache. The easier way to fix is to copy the library DLL to your Zig folder.

### Personal observation about VSCode

I have a Love/Hate relationship with VSCode, I only used it to code for Arduino and ESP32 with [Platform.io](https://marketplace.visualstudio.com/items?itemName=platformio.platformio-ide) and the hate is always when the editor try to be "smart and helpful". 

Yellow lightbulbs sometimes show up to notify "There are no fix", JSON files organized to easier read key items are reorder because "that is how JSON should be ordered", at least 10% of keys typed are wasted deleting things that VSCode put there to help me.

## Projects

| Folder | Description |
| ------------- | ------------- |
|  soon  |  soon |

## Credits

[Zig Language](https://ziglang.org/) from ZigLang.org .<br/>
[SDL2](https://libsdl.org/) from libSDL.org .<br/>
[GLFW](https://www.glfw.org) from GLFW.org .<br/>
[GLAD](https://github.com/Dav1dde/glad) from Dav1dde .<br/>
[microui](https://github.com/rxi/microui) from rxi .<br/>
[Dear ImGui](https://github.com/ocornut/imgui) from Omar Cornut .<br/>
[Dear Bindings](https://github.com/dearimgui/dear_bindings) from Ben Carter .<br/>

## License
MIT - Free for everyone and any use.

DarknessFX @ https://dfx.lv | Twitter: @DrkFX<br/>
https://github.com/DarknessFX/zig_workbench
