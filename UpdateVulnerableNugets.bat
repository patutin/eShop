@echo off
setlocal enabledelayedexpansion

REM UpdateVulnerableNugets.bat
REM Batch wrapper for UpdateVulnerableNugets.ps1
REM This provides a convenient way to run the PowerShell script on Windows

echo eShop Vulnerable NuGet Package Updater (Batch Wrapper)
echo ======================================================

REM Check if PowerShell is available
where pwsh >nul 2>nul
if !errorlevel! equ 0 (
    echo Using PowerShell Core (pwsh)
    pwsh -ExecutionPolicy Bypass -File "%~dp0UpdateVulnerableNugets.ps1" %*
    goto :end
)

where powershell >nul 2>nul
if !errorlevel! equ 0 (
    echo Using Windows PowerShell
    powershell -ExecutionPolicy Bypass -File "%~dp0UpdateVulnerableNugets.ps1" %*
    goto :end
)

echo ERROR: PowerShell not found. Please install PowerShell Core or Windows PowerShell.
echo You can download PowerShell Core from: https://github.com/PowerShell/PowerShell/releases
exit /b 1

:end
exit /b %errorlevel%