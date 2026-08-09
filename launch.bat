@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

if /I "%~1"=="" exit /b 1

if /I "%~1"=="swarm" (
    call :swarm %~2 %~3
    exit /b 0
)
if /I "%~1"=="host" (
    call :host %~2
    exit /b 0
)
if /I "%~1"=="client" (
    call :client %~2 %~3
    exit /b 0
)
if /I "%~1"=="attach" (
    call :attach %~2 %~3 %~4
    exit /b 0
)
if /I "%~1"=="clean" (
    call :clean
    exit /b 0
)
exit /b 1

:clean
taskkill /F /IM boot.exe /IM boot_headless.exe >nul 2>&1
exit /b 0

:host
start "Weaver Host" /B cmd /c "bin\boot.exe host %~1 > logs\host_%RANDOM%.log 2>&1"
exit /b 0

:client
start "Weaver Client" /B cmd /c "bin\boot.exe %~1 %~2 > logs\client_manual_%RANDOM%.log 2>&1"
exit /b 0

:attach
for /L %%i in (1, 1, %~1) do (
    start "Weaver Bot %%i" /B cmd /c "bin\boot_headless.exe %~2 %~3 > logs\bot_attach_%%i_%RANDOM%.log 2>&1"
)
exit /b 0

:swarm
set GRAPHICAL_CLIENTS=%~1
set BOT_CLIENTS=%~2
if "%GRAPHICAL_CLIENTS%"=="" set GRAPHICAL_CLIENTS=0
if "%BOT_CLIENTS%"=="" set BOT_CLIENTS=0
set /A TOTAL_PLAYERS=1 + GRAPHICAL_CLIENTS + BOT_CLIENTS

:: Note: If you haven't moved to InstanceIDs yet, KEEP this delete for now so the loop doesn't hang on an old ID!
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
