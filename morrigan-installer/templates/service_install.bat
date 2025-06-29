@echo off
REM Morrigan Service Installation Script

SET SERVICE_NAME=MorriganService
SET SERVICE_DISPLAY_NAME=Morrigan Monitoring Service
SET SERVICE_EXECUTABLE="C:\Path\To\Morrigan\morrigan.exe"
SET SERVICE_DESCRIPTION="Service for monitoring LLM interactions and sending anonymized metadata to the Morrigan API."

REM Check if the service is already installed
sc query "%SERVICE_NAME%" >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo Service "%SERVICE_DISPLAY_NAME%" is already installed.
    exit /b 1
)

REM Install the service
sc create "%SERVICE_NAME%" binPath= %SERVICE_EXECUTABLE% start= auto DisplayName= "%SERVICE_DISPLAY_NAME%" description= "%SERVICE_DESCRIPTION%"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to create service "%SERVICE_DISPLAY_NAME%".
    exit /b 1
)

REM Start the service
sc start "%SERVICE_NAME%"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to start service "%SERVICE_DISPLAY_NAME%".
    exit /b 1
)

echo Service "%SERVICE_DISPLAY_NAME%" installed and started successfully.