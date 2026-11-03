@echo off
chcp 65001 >nul
title AntiFake PC Inspector v3.0.1 ^| by @afigenys

:: 1. Проверка наличия главного скрипта antifake.ps1
if not exist "%~dp0antifake.ps1" (
    color 0C
    echo [!] ОШИБКА: Файл antifake.ps1 не найден в этой папке!
    echo Положите antifake.ps1 рядом с батником и повторите запуск.
    echo.
    pause
    exit /b
)

:: 2. Автоматический запрос прав Администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

:: 3. Переход в текущую папку скрипта
cd /d "%~dp0"

:: 4. Обход 32-битного SysWOW64: Запуск НАСТОЯЩЕГО 64-битного PowerShell
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" (
    set "PS64=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
) else (
    set "PS64=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
)

:: 5. Старт главного скрипта antifake.ps1
"%PS64%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0antifake.ps1"