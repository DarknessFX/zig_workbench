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
Without webgpu-wasm-zig knowledge the template would not exist.<br/>
- wasm_webgpu from Juj - https://github.com/juj/wasm_webgpu .<br/>
Essential to sync HTML5 WebGPU events and Zig Wasm.<br/>
- zig-wasm-logger from Daneelsan - https://github.com/daneelsan/zig-wasm-logger .<br/>
Where I finally learned how to send strings to HTML5 Wasm. <br/>
- zgpu and wgpu from Zig-Gamedev - https://github.com/zig-gamedev/zig-gamedev/ .<br/>
I didn't use the libraries, but the source code was essential to better understand Zig + WebGPU and helped fix some hard to catch bugs.<br/>
