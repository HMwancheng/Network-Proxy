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

echo [1/4] 检查程序文件...
if not exist "%INSTALL_DIR%\network-proxy.exe" (
    echo [错误] 未找到 network-proxy.exe，请确保程序文件与脚本在同一目录
    pause
    exit /b 1
)
echo   程序文件已找到: network-proxy.exe

echo.
echo [2/4] 安装服务...
sc create %SERVICE_NAME% binPath= "\"%INSTALL_DIR%\network-proxy.exe\"" start= auto DisplayName= "Network Proxy Service"
if %errorlevel% neq 0 (
    echo [错误] 服务创建失败，可能已存在同名服务
    echo   可先运行 uninstall.bat 卸载旧服务
    pause
    exit /b 1
)
echo   服务创建成功

echo.
echo [3/4] 配置服务...
sc description %SERVICE_NAME% "轻量级本地代理服务 - HTTP & SOCKS5"
sc failure %SERVICE_NAME% actions= restart/60000/restart/60000/restart/60000 reset= 86400
echo   服务配置完成（已启用自动重启）

echo.
echo [4/4] 启动服务...
sc start %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo [警告] 服务启动失败，请检查 config.yaml 配置是否正确
    echo   可运行: sc query %SERVICE_NAME%
) else (
    echo   服务启动成功！
)

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
echo ============================================
echo.
pause