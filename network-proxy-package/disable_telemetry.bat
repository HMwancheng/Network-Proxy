@echo off
chcp 65001 >nul
title 禁用 Windows 数据收集服务

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 请以管理员身份运行此脚本！
    echo 右键此文件 -> 以管理员身份运行
    pause
    exit /b 1
)

echo ============================================
echo   禁用 Windows 数据收集和遥测服务
echo ============================================
echo.
echo 此工具将禁用以下服务:
echo   - DiagTrack   (诊断跟踪服务)
echo   - dmwappushsvc (设备管理WAP推送)
echo   - DoSvc       (传递优化服务)
echo   - WSearch     (Windows Search - 可选)
echo   - SysMain     (Superfetch - 可选)
echo.

set "DISABLED=0"
set "SKIPPED=0"

:: 禁用诊断跟踪服务 (Connected User Experiences and Telemetry)
echo [1] 禁用 DiagTrack (诊断跟踪)...
sc query DiagTrack >nul 2>&1
if %errorlevel% equ 0 (
    sc stop DiagTrack >nul 2>&1
    sc config DiagTrack start= disabled >nul 2>&1
    echo   已禁用 DiagTrack
    set /a DISABLED+=1
) else (
    echo   DiagTrack 不存在，跳过
    set /a SKIPPED+=1
)

:: 禁用设备管理无线应用协议推送服务
echo [2] 禁用 dmwappushsvc (设备管理推送)...
sc query dmwappushsvc >nul 2>&1
if %errorlevel% equ 0 (
    sc stop dmwappushsvc >nul 2>&1
    sc config dmwappushsvc start= disabled >nul 2>&1
    echo   已禁用 dmwappushsvc
    set /a DISABLED+=1
) else (
    echo   dmwappushsvc 不存在，跳过
    set /a SKIPPED+=1
)

:: 禁用传递优化服务
echo [3] 禁用 DoSvc (传递优化)...
sc query DoSvc >nul 2>&1
if %errorlevel% equ 0 (
    sc stop DoSvc >nul 2>&1
    sc config DoSvc start= disabled >nul 2>&1
    echo   已禁用 DoSvc
    set /a DISABLED+=1
) else (
    echo   DoSvc 不存在，跳过
    set /a SKIPPED+=1
)

:: 禁用 Windows Search (可选，会禁用文件索引)
echo [4] 禁用 WSearch (Windows Search)...
sc query WSearch >nul 2>&1
if %errorlevel% equ 0 (
    sc stop WSearch >nul 2>&1
    sc config WSearch start= disabled >nul 2>&1
    echo   已禁用 WSearch
    set /a DISABLED+=1
) else (
    echo   WSearch 不存在，跳过
    set /a SKIPPED+=1
)

:: 禁用 Superfetch / SysMain
echo [5] 禁用 SysMain (Superfetch)...
sc query SysMain >nul 2>&1
if %errorlevel% equ 0 (
    sc stop SysMain >nul 2>&1
    sc config SysMain start= disabled >nul 2>&1
    echo   已禁用 SysMain
    set /a DISABLED+=1
) else (
    echo   SysMain 不存在，跳过
    set /a SKIPPED+=1
)

echo.
echo ============================================
echo   完成！已禁用 %DISABLED% 个服务，跳过 %SKIPPED% 个
echo.
echo 提示: 如需恢复，可将对应服务启动类型改为"自动"
echo   例如: sc config DiagTrack start= auto
echo ============================================
echo.
pause