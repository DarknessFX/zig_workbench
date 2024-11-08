*Sales pitch? Is the smallest, fastest, easiest way to get into WebGPU(+DX12+Vulkan+Metal) and create your own Compute+Fragment+Vertex shaders, while able to build and share as OS platform binaries or Web html5 wasm..*

<img src="https://raw.githubusercontent.com/DarknessFX/zig_workbench/refs/heads/main/.git_img/BaseWebGPU_screenshot.png" width="640px" /> <br/>

## About

BaseWebGPU Template is a tiny framework where a single Zig code base using WebGPU Graphics API is able to build platform OS binaries and Web html5. <br/>
- Binaries are grouped with required DLLs to easily deploy or share. <br/>
- HTML5 are build as a single-file package, offline and portable, run as a normal web page and **don't** need webservers (or python -m http.server).
<br/>

This template have 3 main features:
- app.zig = SDL2 Window and WebGPU Dawn renderer (DirectX12 on Windows). Develop, debug, build, deploy for your OS platform.
- web.zig = HTML5 WebGPU Canvas renderer. Develop, debug, build, deploy for Web.
- shared.zig = Module for both App and Web. For convenience Shared is also build as HTML5 package, you can run/test/debug your shared WASM module in an isolated page without WebGPU running.
<br/>

## Requirements
- Zig v0.13.0
- Emscripten SDK v3.1.70 (latest, Nov/2024).
<br/>

## How to build
- Download /BaseWebGPU/ folder.
- Install Zig language, v0.13.0, from https://ziglang.org
- Install Emscripten from [https://emscripten.org](https://emscripten.org/docs/getting_started/downloads.html)
- Fix some hard-coded paths (not sorry, I'm lazy. But I tried to expose hard-coded paths as the 1st line of each file. ).
- Go to /BaseWebGPU/ folder and run : **zig build**
- 10secs compiling and done.
- &nbsp;&nbsp;optional: Run **zig build** again to populate /Build/ folder.
- Check your /Build/ or /Bin/Debug/ folders for portable off-line html5 wasm webgpu pages and application binaries with required DLL libraries.  Cheers! 👍🍻

<br/>

## Notes

> [!WARNING]
> This template is not 100% compatible with [/tools/updateProjectName.bat](https://github.com/DarknessFX/zig_workbench/blob/main/tools/updateProjectName.bat) ,<br/>
> it can be used and it helps, but you will need to replace Build.zig with the original and maybe introduced some bugs.

<br/>

## Credits, References, Acknowledge and Thanks

**BaseWebGPU** Template would not exist without the following:<br/>
- webgpu-wasm-zig from Seyhajin - https://github.com/seyhajin/webgpu-wasm-zig .<br/>
Seyhajin work at webgpu-wasm-zig is the foundation of BaseWebGPU.</br>
Parts of Build and all render code are still the same from webgpu-wasm-zig.</br>
Credits isn't enought, Seyhajin is counted as co-author of this template.<br/>
- wasm_webgpu from Juj - https://github.com/juj/wasm_webgpu .<br/>
Essential to sync HTML5 WebGPU events and Zig Wasm.<br/>
- zig-wasm-logger from Daneelsan - https://github.com/daneelsan/zig-wasm-logger .<br/>
Where I finally learned how to send strings to HTML5 Wasm. <br/>
- zgpu and wgpu from Zig-Gamedev - https://github.com/zig-gamedev/zig-gamedev/ .<br/>
I didn't use the Zig-Gamedev libraries but the source code was essential to better understand Zig + WebGPU and helped fix some hard to catch bugs.<br/>
