@echo off
chcp 65001 >nul
title Kemono Mobile Viewer - 构建工具

echo ======================================================
echo           Kemono Mobile Viewer - Android 构建
echo ======================================================

:: 1. 自动配置你本地的 JDK 17 (Zulu 17)
set "JAVA_HOME=D:\MajorGame\PCL\JDKs\zulu17.68.17-ca-jdk17.0.20-win_x64"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "ANDROID_HOME=C:\Users\byuyu\AppData\Local\Android\Sdk"

echo [1/4] 验证 JDK 17 环境...
java -version
if %errorlevel% neq 0 (
    echo ❌ JDK 17 配置失败，请检查路径。
    pause
    exit /b
)
echo ✅ JDK 17 就绪！

echo.
echo [2/4] 检测 Flutter SDK...
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ⚠️ 系统 PATH 中未检测到 flutter 命令。
    echo ----------------------------------------------------
    echo 请先安装 Flutter SDK：
    echo 1. 官网下载：https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip
    echo 2. 解压到 D:\flutter （或其他任意目录）
    echo 3. 将 D:\flutter\bin 添加到系统环境变量 Path 中
    echo ----------------------------------------------------
    pause
    exit /b
)
echo ✅ Flutter SDK 就绪！

echo.
echo [3/4] 正在拉取依赖包...
call flutter pub get

echo.
echo [4/4] 正在编译生成 Android APK (Release 优化版)...
call flutter build apk --release

echo.
echo ======================================================
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo 🎉 构建成功！安装包位置：
    echo    %cd%\build\app\outputs\flutter-apk\app-release.apk
    echo 可直接发送到安卓手机安装使用！
) else (
    echo ⚠️ 构建完成，请查看上方输出信息。
)
echo ======================================================
pause
