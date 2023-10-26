REM Delete all zig-cache subfolders.
FOR /D /R . %%d IN (zig-cache) DO @IF EXIST "%%d" RD /S /Q "%%d"