@echo off
chcp 65001 >nul
title Network Proxy 安装

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 请以管理员身份运行此脚本！
    echo 右键此文件 -> 以管理员身份运行
    pause
    exit /b 1
)

echo ============================================
echo   Network Proxy 安装脚本
echo ============================================
echo.

:: 获取脚本所在目录
set "INSTALL_DIR=%~dp0"
set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"
set "SERVICE_NAME=NetworkProxy"

echo [1/6] 检查程序文件...

:: 如果已有 network-proxy.exe 则直接使用
if exist "%INSTALL_DIR%\network-proxy.exe" (
    echo   已找到: network-proxy.exe
    goto :install_service
)

:: 自动检测架构版本并重命名
if exist "%INSTALL_DIR%\network-proxy-amd64.exe" (
    echo   检测到 64位版本，重命名为 network-proxy.exe ...
    ren "%INSTALL_DIR%\network-proxy-amd64.exe" "network-proxy.exe"
    goto :install_service
)

if exist "%INSTALL_DIR%\network-proxy-386.exe" (
    echo   检测到 32位版本，重命名为 network-proxy.exe ...
    ren "%INSTALL_DIR%\network-proxy-386.exe" "network-proxy.exe"
    goto :install_service
)

echo [错误] 未找到任何可执行文件！
echo   需要以下文件之一:
echo     - network-proxy.exe
echo     - network-proxy-amd64.exe
echo     - network-proxy-386.exe
pause
exit /b 1

:install_service
echo   程序文件就绪: network-proxy.exe

echo.
echo [2/6] 安装服务...
sc create %SERVICE_NAME% binPath= "\"%INSTALL_DIR%\network-proxy.exe\"" start= auto DisplayName= "Network Proxy Service"
if %errorlevel% neq 0 (
    echo [错误] 服务创建失败，可能已存在同名服务
    echo   可先运行 uninstall.bat 卸载旧服务
    pause
    exit /b 1
)
echo   服务创建成功

echo.
echo [3/6] 配置服务...
sc description %SERVICE_NAME% "轻量级本地代理服务 - HTTP ^& SOCKS5"
sc failure %SERVICE_NAME% actions= restart/60000/restart/60000/restart/60000 reset= 86400
echo   服务配置完成（已启用异常自动重启）

echo.
echo [4/6] 配置防火墙...
:: 读取配置文件中的端口
set "HTTP_PORT=8080"
set "SOCKS5_PORT=1080"
if exist "%INSTALL_DIR%\config.yaml" (
    for /f "tokens=2" %%a in ('findstr /c:"port:" "%INSTALL_DIR%\config.yaml" ^| findstr /n "1" ^| findstr "^1:"') do set "HTTP_PORT=%%a"
    for /f "tokens=2" %%a in ('findstr /c:"port:" "%INSTALL_DIR%\config.yaml" ^| findstr /n "2" ^| findstr "^2:"') do set "SOCKS5_PORT=%%a"
)

:: 删除旧规则（如果存在）
netsh advfirewall firewall delete rule name="Network Proxy HTTP" >nul 2>&1
netsh advfirewall firewall delete rule name="Network Proxy SOCKS5" >nul 2>&1

:: 添加新规则
netsh advfirewall firewall add rule name="Network Proxy HTTP" dir=in action=allow protocol=TCP localport=%HTTP_PORT% >nul 2>&1
if %errorlevel% equ 0 (
    echo   已添加防火墙规则: HTTP 端口 %HTTP_PORT%
) else (
    echo   [警告] HTTP 防火墙规则添加失败，请手动放行端口 %HTTP_PORT%
)

netsh advfirewall firewall add rule name="Network Proxy SOCKS5" dir=in action=allow protocol=TCP localport=%SOCKS5_PORT% >nul 2>&1
if %errorlevel% equ 0 (
    echo   已添加防火墙规则: SOCKS5 端口 %SOCKS5_PORT%
) else (
    echo   [警告] SOCKS5 防火墙规则添加失败，请手动放行端口 %SOCKS5_PORT%
)

echo.
echo [5/6] 启动服务...
sc start %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo [警告] 服务启动失败，请检查 config.yaml 配置是否正确
    echo   可运行: sc query %SERVICE_NAME%
    goto :done
)
echo   服务启动成功！

echo.
echo [6/6] 验证服务状态...
timeout /t 2 /nobreak >nul
sc query %SERVICE_NAME% | find "RUNNING" >nul
if %errorlevel% equ 0 (
    echo   服务运行正常
) else (
    echo [警告] 服务未在运行，请检查:
    echo   1. config.yaml 配置是否正确
    echo   2. 端口是否被其他程序占用
    echo   可运行: sc query %SERVICE_NAME%
)

:done
echo.
echo ============================================
echo   安装完成！
echo   服务名称: %SERVICE_NAME%
echo   安装目录: %INSTALL_DIR%
echo.
echo   查看状态: sc query %SERVICE_NAME%
echo   停止服务: net stop %SERVICE_NAME%
echo   启动服务: net start %SERVICE_NAME%
echo   卸载服务: 运行 uninstall.bat
echo.
echo   代理地址: 本机IP:%HTTP_PORT% (HTTP) / 本机IP:%SOCKS5_PORT% (SOCKS5)
echo   注意: 请确保局域网其他设备能访问本机
echo ============================================
echo.
pause