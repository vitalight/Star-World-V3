@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem Repository task entry point; all paths are independent of the caller's cwd.
for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
set "PRESET=Windows Desktop"
set "OUTPUT=%PROJECT_ROOT%\builds\StarWorld.exe"
set "PACK=%PROJECT_ROOT%\builds\StarWorld.pck"

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
if not exist "%PROJECT_ROOT%\temp\build" mkdir "%PROJECT_ROOT%\temp\build"
if not exist "%PROJECT_ROOT%\builds" mkdir "%PROJECT_ROOT%\builds"

rem Remove previous artifacts so a failed export cannot leave a stale executable.
del /q "%OUTPUT%" "%PACK%" 2>nul

echo [Import] temp/build/import.log
"%GODOT_PATH%" --headless --path "%PROJECT_ROOT%" --editor --import --quit > "%PROJECT_ROOT%\temp\build\import.log" 2>&1
if errorlevel 1 (
    type "%PROJECT_ROOT%\temp\build\import.log"
    echo [ERROR] Resource import failed.
    exit /b 1
)

echo [Export] temp/build/export.log
"%GODOT_PATH%" --headless --path "%PROJECT_ROOT%" --export-release "%PRESET%" "%OUTPUT%" > "%PROJECT_ROOT%\temp\build\export.log" 2>&1
set "EXPORT_RESULT=%ERRORLEVEL%"
if not "%EXPORT_RESULT%"=="0" goto :failed
if not exist "%OUTPUT%" goto :failed
if not exist "%PACK%" goto :failed

echo [Done] %OUTPUT%
echo [Done] %PACK%
exit /b 0

:failed
type "%PROJECT_ROOT%\temp\build\export.log"
findstr /i /c:"export template" "%PROJECT_ROOT%\temp\build\export.log" >nul
if not errorlevel 1 (
    echo [HINT] Install the export templates matching this Godot version:
    echo        Editor ^> Manage Export Templates, or unpack them under
    echo        %%APPDATA%%\Godot\export_templates\^<version^>\
)
echo [ERROR] Packaging failed. See temp/build/export.log
exit /b 1
