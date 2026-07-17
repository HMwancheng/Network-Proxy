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

:: 如果已有 network-proxy.exe 则直接使用
if exist "%INSTALL_DIR%\%EXE_NAME%" (
    echo   Found: %EXE_NAME%
    goto :install_service
)

:: 自动检测系统架构并复制对应版本
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto :copy_64
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" goto :copy_64
goto :copy_32

:copy_64
echo   Detected 64-bit system.
if exist "%INSTALL_DIR%\network-proxy-amd64.exe" (
    echo   Copying network-proxy-amd64.exe to %EXE_NAME% ...
    copy /y "%INSTALL_DIR%\network-proxy-amd64.exe" "%INSTALL_DIR%\%EXE_NAME%" >nul
    goto :install_service
)
echo   [WARN] network-proxy-amd64.exe not found, trying 32-bit version...

:copy_32
echo   Detected 32-bit system.
if exist "%INSTALL_DIR%\network-proxy-386.exe" (
    echo   Copying network-proxy-386.exe to %EXE_NAME% ...
    copy /y "%INSTALL_DIR%\network-proxy-386.exe" "%INSTALL_DIR%\%EXE_NAME%" >nul
    goto :install_service
)

echo [ERROR] No executable found!
echo   Need one of: %EXE_NAME%, network-proxy-amd64.exe, network-proxy-386.exe
pause
exit /b 1

:install_service
echo   Program file ready: %EXE_NAME%

echo.
echo [2/6] Read config...
set "HTTP_PORT=8080"
set "SOCKS5_PORT=1080"
set "FIRST=1"
if exist "%INSTALL_DIR%\config.yaml" (
    for /f "usebackq tokens=2" %%a in (`findstr /c:"  port:" "%INSTALL_DIR%\config.yaml"`) do (
        if defined FIRST (
            set "HTTP_PORT=%%a"
            set "FIRST="
        ) else (
            set "SOCKS5_PORT=%%a"
        )
    )
)
echo   HTTP port: %HTTP_PORT%
echo   SOCKS5 port: %SOCKS5_PORT%

echo.
echo [3/6] Install service...
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
echo [4/6] Configure service...
sc description %SERVICE_NAME% "Lightweight proxy service - HTTP and SOCKS5"
sc failure %SERVICE_NAME% actions= restart/60000/restart/60000/restart/60000 reset= 86400
echo   Service configured (auto-restart enabled).

echo.
echo [5/6] Configure firewall...
:: Delete old rules if exist
netsh advfirewall firewall delete rule name="Network Proxy HTTP" >nul 2>&1
netsh advfirewall firewall delete rule name="Network Proxy SOCKS5" >nul 2>&1

:: Add HTTP rule
netsh advfirewall firewall add rule name="Network Proxy HTTP" dir=in action=allow protocol=TCP localport=%HTTP_PORT% >nul 2>&1
if %errorlevel% equ 0 (
    echo   Firewall rule added: HTTP port %HTTP_PORT%
) else (
    echo   [WARN] HTTP firewall rule failed, please open port %HTTP_PORT% manually
)

:: Add SOCKS5 rule
netsh advfirewall firewall add rule name="Network Proxy SOCKS5" dir=in action=allow protocol=TCP localport=%SOCKS5_PORT% >nul 2>&1
if %errorlevel% equ 0 (
    echo   Firewall rule added: SOCKS5 port %SOCKS5_PORT%
) else (
    echo   [WARN] SOCKS5 firewall rule failed, please open port %SOCKS5_PORT% manually
)

echo.
echo [6/6] Start service...
sc start %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo [WARN] Service start failed. Check config.yaml and service.log.
    echo   Run: sc query %SERVICE_NAME%
    goto :done
)
echo   Service started!

echo.
echo [7/7] Verify service...
timeout /t 2 /nobreak >nul
sc query %SERVICE_NAME% | find "RUNNING" >nul
if %errorlevel% equ 0 (
    echo   Service is running.
) else (
    echo [WARN] Service not running. Check:
    echo   1. config.yaml in same folder
    echo   2. Port not in use by other programs
    echo   3. Set log_enabled: true in config.yaml, reinstall, check service.log
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
echo   Proxy: YOUR_IP:%HTTP_PORT% (HTTP) / YOUR_IP:%SOCKS5_PORT% (SOCKS5)
echo   Config: edit config.yaml then restart service
echo ============================================
echo.
pause