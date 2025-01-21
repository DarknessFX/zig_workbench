@ECHO OFF 
TITLE ZIG %1 %2
CD /D "%~dp2"
IF /I "%1"=="build" (
  zig.exe %1
) ELSE (
  zig.exe %1 "%~nx2"
)
PAUSE