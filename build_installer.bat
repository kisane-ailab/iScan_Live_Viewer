@echo off
cd /d "%~dp0"

REM Try common Inno Setup paths
if exist "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" (
    "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" installer.iss
    goto :done
)

if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
    goto :done
)

if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    "C:\Program Files\Inno Setup 6\ISCC.exe" installer.iss
    goto :done
)

REM Try to find ISCC in PATH
where ISCC.exe >nul 2>&1
if %errorlevel% equ 0 (
    ISCC.exe installer.iss
    goto :done
)

echo Inno Setup not found. Please install from https://jrsoftware.org/isdl.php
pause
exit /b 1

:done
echo.
echo Installer created: installer\iScan_Live_Viewer_Setup.exe
pause
