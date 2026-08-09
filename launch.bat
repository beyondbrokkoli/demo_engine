@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

if /I "%~1"=="swarm" (
    set GRAPHICAL_CLIENTS=%~2
    set BOT_CLIENTS=%~3
    goto swarm_exec
)
if /I "%~1"=="host" goto host
if /I "%~1"=="client" goto client
if /I "%~1"=="attach" goto attach
if /I "%~1"=="clean" goto clean
exit /b 1

:clean
taskkill /F /IM boot.exe /IM boot_headless.exe >nul 2>&1
exit /b 0

:host
start "Weaver Host" /B cmd /c "bin\boot.exe host %~2 > logs\host_%RANDOM%.log 2>&1"
exit /b 0

:client
start "Weaver Client" /B cmd /c "bin\boot.exe %~2 %~3 > logs\client_manual_%RANDOM%.log 2>&1"
exit /b 0

:attach
for /L %%i in (1, 1, %~2) do (
    start "Weaver Bot %%i" /B cmd /c "bin\boot_headless.exe %~3 %~4 > logs\bot_attach_%%i_%RANDOM%.log 2>&1"
)
exit /b 0

:swarm_exec
if "%GRAPHICAL_CLIENTS%"=="" set GRAPHICAL_CLIENTS=0
if "%BOT_CLIENTS%"=="" set BOT_CLIENTS=0
set /A TOTAL_PLAYERS=1 + GRAPHICAL_CLIENTS + BOT_CLIENTS

:: Force clean host log for deterministic waiting
if exist "logs\host.log" del /F /Q "logs\host.log"

start "Weaver Host" /B cmd /c "bin\boot.exe host %TOTAL_PLAYERS% > logs\host.log 2>&1"

:wait_lobby
>nul find "LOBBY_ID:" logs\host.log
if errorlevel 1 ( timeout /t 1 /nobreak >nul & goto wait_lobby )

for /f "tokens=2 delims=:" %%A in ('findstr "LOBBY_ID:" logs\host.log') do set RAW_LOBBY=%%A
set LOBBY_ID=%RAW_LOBBY: =%

if %GRAPHICAL_CLIENTS% GTR 0 (
    for /L %%i in (1, 1, %GRAPHICAL_CLIENTS%) do (
        start "Weaver Client %%i" /B cmd /c "bin\boot.exe %LOBBY_ID% %TOTAL_PLAYERS% > logs\client_%%i_%RANDOM%.log 2>&1"
    )
)
if %BOT_CLIENTS% GTR 0 (
    for /L %%i in (1, 1, %BOT_CLIENTS%) do (
        start "Weaver Bot %%i" /B cmd /c "bin\boot_headless.exe %LOBBY_ID% %TOTAL_PLAYERS% > logs\bot_%%i_%RANDOM%.log 2>&1"
    )
)
exit /b 0
