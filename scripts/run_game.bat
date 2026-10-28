@echo off
setlocal EnableExtensions DisableDelayedExpansion
for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
set "GAME_ARGS="
if not "%~1"=="" (
    if /i not "%~1"=="-d" (
        echo Usage: run_game.bat [-d]
        exit /b 1
    )
    if not "%~2"=="" (
        echo Usage: run_game.bat [-d]
        exit /b 1
    )
    set "GAME_ARGS=-- --developer-mode"
)
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
if not exist "%PROJECT_ROOT%\temp\game" mkdir "%PROJECT_ROOT%\temp\game"
if not exist "%PROJECT_ROOT%\temp\game" (
    echo [ERROR] Cannot create temp/game.
    exit /b 1
)
echo [Import] temp/game/import.log
"%GODOT_PATH%" --headless --path "%PROJECT_ROOT%" --editor --import --quit > "%PROJECT_ROOT%\temp\game\import.log" 2>&1
if errorlevel 1 (
    type "%PROJECT_ROOT%\temp\game\import.log"
    echo [ERROR] Resource import failed.
    exit /b 1
)
echo [Run] Player Mode
"%GODOT_PATH%" --path "%PROJECT_ROOT%" %GAME_ARGS%
set "RUN_RESULT=%ERRORLEVEL%"
if not "%RUN_RESULT%"=="0" echo [ERROR] Godot exited with code %RUN_RESULT%.
exit /b %RUN_RESULT%
