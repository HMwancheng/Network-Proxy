@echo off
chcp 936 >nul
title Network Proxy Install

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run as Administrator!
    echo Right-click this file - Run as Administrator
    pause
    exit /b 1
)

echo ============================================
echo   Network Proxy Install
echo ============================================
echo.

set "INSTALL_DIR=%~dp0"
set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"
set "SERVICE_NAME=NetworkProxy"
set "EXE_NAME=network-proxy.exe"

echo [1/6] Check program file...

if exist "%INSTALL_DIR%\%EXE_NAME%" (
    echo   Found: %EXE_NAME%
    goto :install_service
)

if exist "%INSTALL_DIR%\network-proxy-amd64.exe" (
    echo   Found 64-bit version, renaming to %EXE_NAME% ...
    ren "%INSTALL_DIR%\network-proxy-amd64.exe" "%EXE_NAME%"
    goto :install_service
)

if exist "%INSTALL_DIR%\network-proxy-386.exe" (
    echo   Found 32-bit version, renaming to %EXE_NAME% ...
    ren "%INSTALL_DIR%\network-proxy-386.exe" "%EXE_NAME%"
    goto :install_service
)

echo [ERROR] No executable found!
echo   Need one of: %EXE_NAME%, network-proxy-amd64.exe, network-proxy-386.exe
pause
exit /b 1

:install_service
echo   Program file ready: %EXE_NAME%

echo.
echo [2/6] Install service...
set "EXE_PATH=%INSTALL_DIR%\%EXE_NAME%"
sc create %SERVICE_NAME% binPath= "%EXE_PATH%" start= auto DisplayName= "Network Proxy Service"
if %errorlevel% neq 0 (
    echo [ERROR] Service create failed. Maybe already exists.
    echo   Run uninstall.bat first to remove old service.
    pause
    exit /b 1
)
echo   Service created.

echo.
echo [3/6] Configure service...
sc description %SERVICE_NAME% "Lightweight proxy service - HTTP and SOCKS5"
sc failure %SERVICE_NAME% actions= restart/60000/restart/60000/restart/60000 reset= 86400
echo   Service configured (auto-restart enabled).

echo.
echo [4/6] Configure firewall...
:: Delete old rules if exist
netsh advfirewall firewall delete rule name="Network Proxy HTTP" >nul 2>&1
netsh advfirewall firewall delete rule name="Network Proxy SOCKS5" >nul 2>&1

:: Add HTTP rule (default port 8080)
netsh advfirewall firewall add rule name="Network Proxy HTTP" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
if %errorlevel% equ 0 (
    echo   Firewall rule added: HTTP port 8080
) else (
    echo   [WARN] HTTP firewall rule failed, please open port 8080 manually
)

:: Add SOCKS5 rule (default port 1080)
netsh advfirewall firewall add rule name="Network Proxy SOCKS5" dir=in action=allow protocol=TCP localport=1080 >nul 2>&1
if %errorlevel% equ 0 (
    echo   Firewall rule added: SOCKS5 port 1080
) else (
    echo   [WARN] SOCKS5 firewall rule failed, please open port 1080 manually
)

echo.
echo [5/6] Start service...
sc start %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo [WARN] Service start failed. Check config.yaml and service.log.
    echo   Run: sc query %SERVICE_NAME%
    goto :done
)
echo   Service started!

echo.
echo [6/6] Verify service...
timeout /t 2 /nobreak >nul
sc query %SERVICE_NAME% | find "RUNNING" >nul
if %errorlevel% equ 0 (
    echo   Service is running.
) else (
    echo [WARN] Service not running. Check:
    echo   1. config.yaml in same folder
    echo   2. Port not in use by other programs
    echo   3. service.log for error details
    echo   Run: sc query %SERVICE_NAME%
)

:done
echo.
echo ============================================
echo   Install Complete!
echo   Service name: %SERVICE_NAME%
echo   Install path: %INSTALL_DIR%
echo.
echo   Check status: sc query %SERVICE_NAME%
echo   Stop service: net stop %SERVICE_NAME%
echo   Start service: net start %SERVICE_NAME%
echo   Uninstall:    run uninstall.bat
echo.
echo   Proxy: YOUR_IP:8080 (HTTP) / YOUR_IP:1080 (SOCKS5)
echo   Config: edit config.yaml then restart service
echo ============================================
echo.
pause