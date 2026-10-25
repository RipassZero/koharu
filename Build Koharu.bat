@echo off
setlocal EnableExtensions
title Build Koharu (Recognize text edition)
cd /d "%~dp0"

echo ============================================================
echo  Koharu with the Recognize text tool - one-click setup
echo ============================================================
echo.
echo This installs the build tools (once), builds Koharu, and puts
echo a "Koharu (Recognize text)" shortcut on your desktop.
echo The first run takes about an hour. Windows may ask for
echo permission a few times; click Yes.
echo.
echo A full log is saved to build-log.txt in this folder.
echo.
pause

set "LOG=%~dp0build-log.txt"
echo Build started %date% %time% > "%LOG%"

where winget >nul 2>&1
if errorlevel 1 (
  echo.
  echo winget is missing. Install "App Installer" from the Microsoft Store, then run this file again.
  goto :fail
)

echo.
echo [1/5] Installing build tools (skipped if already installed)...
call :install Rustlang.Rustup
call :install LLVM.LLVM
call :install Oven-sh.Bun
echo        Microsoft C++ build tools (this one is large)...
winget install -e --id Microsoft.VisualStudio.2022.BuildTools --accept-package-agreements --accept-source-agreements --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" >> "%LOG%" 2>&1

rem Make the freshly installed tools visible without reopening the window.
set "PATH=%USERPROFILE%\.cargo\bin;%USERPROFILE%\.bun\bin;%ProgramFiles%\LLVM\bin;%PATH%"
set "LIBCLANG_PATH=%ProgramFiles%\LLVM\bin"

echo.
echo [2/5] Setting up Rust...
where rustup >nul 2>&1 || (echo Rust did not install correctly. & goto :fail)
call rustup default stable >> "%LOG%" 2>&1 || goto :fail
call rustup target add wasm32-unknown-unknown >> "%LOG%" 2>&1 || goto :fail

where bun >nul 2>&1 || (echo Bun did not install correctly. & goto :fail)

echo.
echo [3/5] Downloading Koharu's parts (10-20 minutes)...
call bun install >> "%LOG%" 2>&1 || goto :fail

echo.
echo [4/5] Building Koharu (the long step - leave this window open)...
call bun run build >> "%LOG%" 2>&1 || goto :fail

set "EXE=%~dp0target\release\koharu.exe"
if not exist "%EXE%" (
  echo The build finished but koharu.exe was not found.
  goto :fail
)

echo.
echo [5/5] Creating the desktop shortcut...
powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\Koharu (Recognize text).lnk'); $s.TargetPath='%EXE%'; $s.WorkingDirectory='%~dp0target\release'; $s.Save()" >> "%LOG%" 2>&1

echo.
echo ============================================================
echo  Done! Close the regular Koharu, then open
echo  "Koharu (Recognize text)" from your desktop.
echo ============================================================
pause
exit /b 0

:install
winget list -e --id %1 >nul 2>&1 && exit /b 0
echo        %1...
winget install -e --id %1 --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
exit /b 0

:fail
echo.
echo ============================================================
echo  Something went wrong. Nothing on your PC was harmed.
echo  Send Claude the file build-log.txt from this folder
echo  (or its last 30 lines) and it will fix the problem.
echo ============================================================
pause
exit /b 1
