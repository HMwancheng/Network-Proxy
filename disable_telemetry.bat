@echo off
chcp 936 >nul
title Disable Windows Telemetry

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run as Administrator!
    echo Right-click this file - Run as Administrator
    pause
    exit /b 1
)

echo ============================================
echo   Disable Windows Telemetry Services
echo ============================================
echo.
echo This tool will disable:
echo   - DiagTrack   (Diagnostics Tracking)
echo   - dmwappushsvc (Device Management WAP Push)
echo   - DoSvc       (Delivery Optimization)
echo   - WSearch     (Windows Search - optional)
echo   - SysMain     (Superfetch - optional)
echo.

set "DISABLED=0"
set "SKIPPED=0"

echo [1] Disabling DiagTrack...
sc query DiagTrack >nul 2>&1
if %errorlevel% equ 0 (
    sc stop DiagTrack >nul 2>&1
    sc config DiagTrack start= disabled >nul 2>&1
    echo   DiagTrack disabled.
    set /a DISABLED+=1
) else (
    echo   DiagTrack not found, skipped.
    set /a SKIPPED+=1
)

echo [2] Disabling dmwappushsvc...
sc query dmwappushsvc >nul 2>&1
if %errorlevel% equ 0 (
    sc stop dmwappushsvc >nul 2>&1
    sc config dmwappushsvc start= disabled >nul 2>&1
    echo   dmwappushsvc disabled.
    set /a DISABLED+=1
) else (
    echo   dmwappushsvc not found, skipped.
    set /a SKIPPED+=1
)

echo [3] Disabling DoSvc...
sc query DoSvc >nul 2>&1
if %errorlevel% equ 0 (
    sc stop DoSvc >nul 2>&1
    sc config DoSvc start= disabled >nul 2>&1
    echo   DoSvc disabled.
    set /a DISABLED+=1
) else (
    echo   DoSvc not found, skipped.
    set /a SKIPPED+=1
)

echo [4] Disabling WSearch...
sc query WSearch >nul 2>&1
if %errorlevel% equ 0 (
    sc stop WSearch >nul 2>&1
    sc config WSearch start= disabled >nul 2>&1
    echo   WSearch disabled.
    set /a DISABLED+=1
) else (
    echo   WSearch not found, skipped.
    set /a SKIPPED+=1
)

echo [5] Disabling SysMain...
sc query SysMain >nul 2>&1
if %errorlevel% equ 0 (
    sc stop SysMain >nul 2>&1
    sc config SysMain start= disabled >nul 2>&1
    echo   SysMain disabled.
    set /a DISABLED+=1
) else (
    echo   SysMain not found, skipped.
    set /a SKIPPED+=1
)

echo.
echo ============================================
echo   Done! Disabled %DISABLED% service(s), skipped %SKIPPED%.
echo.
echo   To restore: sc config [ServiceName] start= auto
echo ============================================
echo.
pause