@IF NOT DEFINED _echo echo off
@TITLE buildReleaseStrip
SETLOCAL ENABLEDELAYEDEXPANSION
CLS
PUSHD "%~dp0"
If %errorlevel% NEQ 0 goto:eof

REM CONSTANTS
SET _ExitSub=EXIT /b

REM COLOR HELPERS
SET _bBlack=[40m
SET _fGreen=[92m
SET _fCyan=[36m
Set _fYellow=[33m
Set _fRed=[31m
Set _fBlue=[94m
SET _ResetColor=[0m

REM VARIABLES
SET ProjectName=
FOR %%* IN (%CD%) DO SET ProjectName=%%~n*
IF "%ProjectName%" == "tools" (
  FOR %%* IN (%CD%\..) DO SET ProjectName=%%~n*
  CD ..
)
SET "replace=%ProjectName%"

SET switchproject=Base
IF EXIST .vscode (
  FOR %%T IN (.vscode\Base*.*) DO SET "templatename=%%~nT" &GOTO :FoundTemplateName
  :FoundTemplateName
  IF /I NOT "%templatename%"=="" (
    IF /I NOT "%templatename%"=="%switchproject%" (
      SET switchproject=%templatename%
    ) ELSE ( ECHO Same name )
  )
)

REM MAIN
CALL :Main %switchproject%
CALL :UpdateCImport
CALL :Shortcut %switchproject%
GOTO :END


:Main
SET "search=%1"
ECHO %_fBlue%***%_ResetColor% Replacing %search% to %_fGreen%%ProjectName%%_ResetColor% %_fBlue%***%_ResetColor%
ECHO.
ECHO Fixing VSCode workspace filename.
IF EXIST .vscode\%search%.code-workspace (
  MOVE .vscode\%search%.code-workspace .vscode\%ProjectName%.code-workspace > NUL
)

ECHO Fixing build.zig project name.
IF EXIST build.zig (
  CALL :ReplaceInFile build.zig
)

IF EXIST %search%.rc (
  ECHO Fixing Windows Resource file %search%.rc
  CALL :ReplaceInFile %search%.rc
  ECHO Fixing main.zig
  CALL :ReplaceInFile main.zig
)

ECHO Fixing buildReleaseStrip.bat .
IF EXIST Tools\buildReleaseStrip.bat (
  CALL :ReplaceInFile Tools\buildReleaseStrip.bat
)

ECHO Renaming filenames.
IF EXIST %search%.* ( REN %search%.* %ProjectName%.* )
IF EXIST .vscode\%search%.* ( REN .vscode\%search%.* %ProjectName%.* )
IF EXIST .vscode\Base.* ( REN .vscode\Base.* %ProjectName%.* )

REM FIX Tasks.json to add -lc when BaseWin or BaseSDL2
IF EXIST *.rc (
  SET search=^"run^", ^"main.zig^"
  SET replace=^"run^", ^"-lc^", ^"main.zig^"
  CALL :ReplaceInFile .vscode\tasks.json
  SET search=^"zig^", ^"run^", ^"^${file}^"
  SET replace=^"zig^", ^"run^", ^"-lc^", ^"^${file}^"
  CALL :ReplaceInFile .vscode\tasks.json
)
%_ExitSub%


:Shortcut
IF NOT EXIST .vscode ( %_ExitSub% )
ECHO Creating shortcut to %ProjectName% VSCode workspace.
FOR /F "DELIMS=" %%F IN ('"WHERE CODE"') DO SET "vscode=%%F" &GOTO :FoundVSCode
:FoundVSCode

IF EXIST "createShortcut.vbs" ( 
  DEL createShortcut.vbs > NUL
)

IF EXIST "..\%ProjectName% VSCode Workspace.lnk" ( 
  DEL ..\%ProjectName% VSCode Workspace.lnk > NUL
)

>"createShortcut.vbs" (
  ECHO Set objShell = WScript.CreateObject("WScript.Shell"^)
  ECHO Set lnk = objShell.CreateShortcut("%CD%\%ProjectName% VSCode Workspace.lnk"^)
  ECHO lnk.TargetPath = "%CD%\.vscode\%ProjectName%.code-workspace"
  ECHO lnk.Arguments = ""
  ECHO lnk.Description = "%ProjectName% VSCode Workspace"
  ECHO lnk.IconLocation = "%vscode:bin\code=%Code.exe"
  ECHO lnk.WindowStyle = "1"
  ECHO lnk.WorkingDirectory = "%CD%\.vscode"
  ECHO lnk.Save
  ECHO Set lnk = Nothing
)
START /WAIT wscript createShortcut.vbs
DEL createShortcut.vbs > NUL
%_ExitSub%


:ReplaceInFile
SET "tmp=%1"
SET textFile=%tmp:"=%
>"%textFile%.new" (
SETLOCAL DISABLEDELAYEDEXPANSION
FOR /F "TOKENS=1,* DELIMS=]" %%A IN ('"TYPE ^^"%textFile%^^" | FIND /n /v """') DO (
  SET "line=%%B"
  IF DEFINED line (
    CALL SET "line=ECHO.%%line:%search%=%replace%%%"
    FOR /F "DELIMS=" %%X IN ('"ECHO."%%line%%""') DO %%~X
  ) ELSE ECHO.
)
)
MOVE /y "%textFile%.new" "%textFile%" >NUL
%_ExitSub%


:UpdateCImport
ECHO Updating cImport Libs folder path.
SET folder=%CD:\=/%/
SET search=cInclude("
SET replace=cInclude("%folder%
FOR /R "%CD%" %%G IN (*.zig) DO (
  CALL :ReplaceInFile "%%G"
)
%_ExitSub%


:END
POPD
ENDLOCAL
ECHO Done!
ECHO.
ECHO This tool is useless after the first use 
ECHO and it will self-delete after this pause.
PAUSE
(goto) 2>nul & del "%~f0"
