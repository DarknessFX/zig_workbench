@ECHO OFF
REM Check if Tools folder, then go up to parent folder
SET FolderName=
FOR %%* IN (%CD%) DO SET FolderName=%%~n*
IF /I "%FolderName%" == "tools" (
  FOR %%* IN (%CD%\..) DO SET FolderName=%%~n*
  CD ..
)

REM Delete all zig-cache subfolders.
FOR /D /R . %%d IN (zig-cache)  DO @IF EXIST "%%d" RD /S /Q "%%d"
FOR /D /R . %%d IN (.zig-cache) DO @IF EXIST "%%d" RD /S /Q "%%d"