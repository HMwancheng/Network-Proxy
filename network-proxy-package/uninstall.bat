@echo off
chcp 65001 >nul
title Network Proxy 卸载

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 请以管理员身份运行此脚本！
    echo 右键此文件 -> 以管理员身份运行
    pause
    exit /b 1
)

echo ============================================
echo   Network Proxy 卸载脚本
echo ============================================
echo.

set "SERVICE_NAME=NetworkProxy"

echo [1/3] 停止服务...
sc stop %SERVICE_NAME% >nul 2>&1
echo   服务已停止

echo.
echo [2/3] 删除服务...
sc delete %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo [信息] 服务可能已不存在
) else (
    echo   服务已删除
)

echo.
echo [3/3] 清理完成

echo.
echo ============================================
echo   卸载完成！
echo.
echo   注意: 程序文件和配置文件未被删除
echo   如需完全清除，请手动删除此文件夹
echo ============================================
echo.
pause