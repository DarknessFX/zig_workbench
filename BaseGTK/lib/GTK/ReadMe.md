Requirements:
  MSYS2
  GTK4

Setup:
  Install MSYS2 from https://www.msys2.org/
  Run mingw64.exe
  Execute the command:
    pacman -S mingw-w64-x86_64-gtk4 mingw-w64-x86_64-gdk-pixbuf2

  This is enough to have all .DLL and .H include headers.

Hard-coded paths:
  The following files have hard coded paths pointing to msys2_root folder and need to be changed:
    .vscode/Tasks.json
    tools/buildReleaseStrip.bat
    build.zig