@echo off
echo AS StageFX Package Builder
echo =========================
echo.
echo This script will generate distribution packages for AS StageFX shaders.
echo.

:: Check if running with admin privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges...
) else (
    echo WARNING: Not running with administrator privileges.
    echo Some operations may fail. Consider running as administrator.
    echo.
    pause
)

echo Starting package build process...
echo This will first clean the packages directory and then build new packages.
echo.

:: Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -Command "try { & '%~dp0build-packages.ps1' -ErrorAction Stop; exit $LASTEXITCODE } catch { Write-Error $_; exit 1 }"

echo.
if %errorLevel% == 0 (
    echo Package build completed successfully!
) else (
    echo Package build failed with error code %errorLevel%.
    echo If you're experiencing issues with string formatting, please check the script for proper string handling.
)

echo.
echo Press any key to exit...
pause > nul
