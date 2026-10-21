@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem Repository task entry point; all paths are independent of the caller's cwd.
for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
if not defined GODOT_PATH (
    echo [ERROR] Godot not found. Set GODOT_PATH to the full executable path.
    exit /b 1
)
if not exist "%GODOT_PATH%" (
    echo [ERROR] GODOT_PATH does not exist: "%GODOT_PATH%"
    exit /b 1
)
if not exist "%PROJECT_ROOT%\temp" mkdir "%PROJECT_ROOT%\temp"
if not exist "%PROJECT_ROOT%\temp\.gdignore" type nul > "%PROJECT_ROOT%\temp\.gdignore"
if not exist "%PROJECT_ROOT%\temp\devtools\user" mkdir "%PROJECT_ROOT%\temp\devtools\user"
if not exist "%PROJECT_ROOT%\temp\devtools\user" (
    echo [ERROR] Cannot create temp/devtools/user.
    exit /b 1
)
rem Scope the user-data override to this BAT and its Godot child processes.
set "APPDATA=%PROJECT_ROOT%\temp\devtools\user"
echo [Godot] "%GODOT_PATH%"
echo [Import] temp/devtools/import.log
"%GODOT_PATH%" --headless --path "%PROJECT_ROOT%" --editor --import --quit > "%PROJECT_ROOT%\temp\devtools\import.log" 2>&1
if errorlevel 1 (
    type "%PROJECT_ROOT%\temp\devtools\import.log"
    echo [ERROR] Resource import failed. See docs/troubleshooting.md.
    exit /b 1
)
echo [Run] Developer Hub
"%GODOT_PATH%" --path "%PROJECT_ROOT%" res://devtools/hub/developer_hub.tscn %*
set "RUN_RESULT=%ERRORLEVEL%"
if not "%RUN_RESULT%"=="0" echo [ERROR] Godot exited with code %RUN_RESULT%. See docs/troubleshooting.md.
exit /b %RUN_RESULT%
