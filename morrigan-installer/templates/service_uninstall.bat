@echo off
REM Morrigan Service Uninstall Script

echo Uninstalling Morrigan Service...

REM Stop the service if it is running
sc stop MorriganService

REM Remove the service
sc delete MorriganService

echo Morrigan Service has been uninstalled successfully.
pause