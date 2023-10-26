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
IF EXIST DIR BaseWin.* ( 
  SET switchproject=BaseWin 
)


REM MAIN
CALL :Main %switchproject%
GOTO :END


:Main
SET "search=%1"
ECHO %_fBlue%***%_ResetColor% Replacing %search% to %_fGreen%%ProjectName%%_ResetColor% %_fBlue%***%_ResetColor%
ECHO.
ECHO Fixing VSCode workspace filename
IF EXIST .vscode\%search%.code-workspace (
  MOVE .vscode\%search%.code-workspace .vscode\%ProjectName%.code-workspace > NUL
)

ECHO Fixing build.zig project name.
CALL :ReplaceInFile build.zig

IF EXIST %search%.rc (
  ECHO Fixing Windows Resource file %search%.rc
  CALL :ReplaceInFile %search%.rc
  ECHO Fixing main.zig
  CALL :ReplaceInFile main.zig
)

ECHO Fixing buildReleaseStrip.bat
IF EXIST Tools\buildReleaseStrip.bat (
  CALL :ReplaceInFile Tools\buildReleaseStrip.bat
)

ECHO Renaming filenames.
IF EXIST %search%.* ( REN %search%.* %ProjectName%.* )
IF EXIST .vscode\%search%.* ( REN .vscode\%search%.* %ProjectName%.* )
IF EXIST .vscode\Base.* ( REN .vscode\Base.* %ProjectName%.* )

REM FIX Tasks.json to add -lc when BaseWin
IF EXIST *.rc (
  SET search=^"run^", ^"main.zig^"
  SET replace=^"run^", ^"-lc^", ^"main.zig^"
  CALL :ReplaceInFile .vscode\tasks.json
  SET search=^"zig^", ^"run^", ^"^${file}^"
  SET replace=^"zig^", ^"run^", ^"-lc^", ^"^${file}^"
  CALL :ReplaceInFile .vscode\tasks.json
)
%_ExitSub%


:ReplaceInFile
SET "textFile=%1"
>"%textFile%.new" (
SETLOCAL DISABLEDELAYEDEXPANSION
FOR /F "tokens=1,* delims=]" %%A IN ('"type %textFile%|find /n /v """') DO (
  SET "line=%%B"
  IF DEFINED line (
    CALL SET "line=echo.%%line:%search%=%replace%%%"
    FOR /F "delims=" %%X IN ('"echo."%%line%%""') DO %%~X
  ) ELSE echo.
)
)
MOVE /y "%textFile%.new" "%textFile%" >NUL
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
