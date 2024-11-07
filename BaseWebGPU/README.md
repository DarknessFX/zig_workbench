To use and build:
- Download /BaseWebGPU/ folder.
- Install Zig language, v0.13.0, from https://ziglang.org
- Install Emscripten from [https://emscripten.org](https://emscripten.org/docs/getting_started/downloads.html)
- Fix some hard-coded paths (not sorry, I'm lazy. But I tried to expose hard-coded paths as the 1st line of each file. ).
- Go to /BaseWebGPU/ folder and run : **zig build**
- 10secs compiling and done.
- &nbsp;&nbsp;optional: Run **zig build** again to populate /Build/ folder.
- Check your /Build/ or /Bin/Debug/ folders for portable off-line html5 wasm webgpu pages and application binaries with required DLL libraries.  Cheers! 👍🍻

<br/>

> [!WARNING]
> This template is not 100% compatible with [/tools/updateProjectName.bat](https://github.com/DarknessFX/zig_workbench/blob/main/tools/updateProjectName.bat) ,<br/>
> it can be used and it helps, but you will need to replace Build.zig with the original and maybe introduced some bugs.
