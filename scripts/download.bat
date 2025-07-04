@echo off
REM Auto-download script for Windows

title Morrigan Auto Installer
echo Morrigan LLM Monitor - Auto Installer
echo ====================================

set FILENAME=morrigan-installer-windows-amd64.zip
set URL=https://github.com/john-morrigan/morrigan-releases/releases/latest/download/%FILENAME%

echo Downloading %FILENAME%...
curl -L -o "%FILENAME%" "%URL%"

if %ERRORLEVEL% NEQ 0 (
    echo Error downloading file
    pause
    exit /b 1
)

echo Extracting...
powershell -command "Expand-Archive -Path '%FILENAME%' -DestinationPath '.' -Force"

echo Starting installer...
echo Please run as administrator when prompted...
MorriganInstaller.exe

echo Installation complete!
pause
