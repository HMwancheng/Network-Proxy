@echo off
chcp 936 >nul
title Network Proxy Uninstall

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run as Administrator!
    echo Right-click this file - Run as Administrator
    pause
    exit /b 1
)

echo ============================================
echo   Network Proxy Uninstall
echo ============================================
echo.

set "SERVICE_NAME=NetworkProxy"

echo [1/4] Stop service...
sc stop %SERVICE_NAME% >nul 2>&1
echo   Service stopped.

echo.
echo [2/4] Delete service...
sc delete %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo   Service may already be removed.
) else (
    echo   Service deleted.
)

echo.
echo [3/4] Remove firewall rules...
netsh advfirewall firewall delete rule name="Network Proxy HTTP" >nul 2>&1
netsh advfirewall firewall delete rule name="Network Proxy SOCKS5" >nul 2>&1
echo   Firewall rules removed.

echo.
echo [4/4] Cleanup done.

echo.
echo ============================================
echo   Uninstall Complete!
echo.
echo   Note: Program files and config not deleted.
echo   Delete this folder manually if needed.
echo ============================================
echo.
pause