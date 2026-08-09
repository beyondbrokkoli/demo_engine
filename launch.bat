@echo off
setlocal enabledelayedexpansion

:: Force execution context to the script's directory (Project Root)
cd /d "%~dp0"

:: Check if binaries exist
if not exist "bin\boot.exe" (
    echo [ERROR] bin\boot.exe not found. Are you in the root directory?
    exit /b 1
)

if /I "%~1"=="" goto usage
if /I "%~1"=="swarm" goto swarm
if /I "%~1"=="lab" goto lab
if /I "%~1"=="host" goto host
if /I "%~1"=="client" goto client
if /I "%~1"=="attach" goto attach
if /I "%~1"=="clean" goto clean_check
goto usage

:usage
echo =======================================================
echo Weaver Engine Orchestrator (Windows)
echo =======================================================
echo Usage:
echo    launch.bat swarm [graphical_count] [bot_count]  - Spins up a local swarm cluster
echo    launch.bat lab                                  - Spins up 4/4 split (4 graphical, 4 bots)
echo    launch.bat host [size]                          - Boots a graphical host node (default size: 8)
echo    launch.bat client [lobby_id] [size]             - Boots a graphical client to join a lobby
echo    launch.bat attach [bot_count] [lobby_id] [size] - Injects headless bots to an existing lobby
echo    launch.bat clean                                - Force-kills all active boot and bot processes
echo =======================================================
exit /b 1

:clean_check
if not "%~2"=="" (
    echo [ERROR] The 'clean' command must be used independently.
    exit /b 1
)
goto clean

:clean
echo [SWARM] Force sweeping all active Weaver Engine processes...
taskkill /F /IM boot.exe /IM boot_headless.exe >nul 2>&1
echo [SWARM] Clean complete. Sockets released.
exit /b 0

:host
set TARGET_SIZE=%~2
if "%TARGET_SIZE%"=="" set TARGET_SIZE=8
echo [SWARM] Booting Graphical Host Node (Size: %TARGET_SIZE%)...
start "Weaver Host" /B cmd /c "bin\boot.exe host %TARGET_SIZE% > logs\host.log 2>&1"
echo [SWARM] Host running in background.
exit /b 0

:client
if "%~2"=="" echo [ERROR] Usage: launch.bat client [lobby_id] [size] & exit /b 1
set LOBBY_ID=%~2
set TARGET_SIZE=%~3
if "%TARGET_SIZE%"=="" set TARGET_SIZE=8
echo [SWARM] Booting Graphical Client Node joining Lobby %LOBBY_ID% (Size: %TARGET_SIZE%)...
start "Weaver Client" /B cmd /c "bin\boot.exe %LOBBY_ID% %TARGET_SIZE% > logs\client_manual.log 2>&1"
exit /b 0

:attach
if "%~2"=="" echo [ERROR] Usage: launch.bat attach [bot_count] [lobby_id] [size] & exit /b 1
if "%~3"=="" echo [ERROR] Usage: launch.bat attach [bot_count] [lobby_id] [size] & exit /b 1
set BOT_COUNT=%~2
set LOBBY_ID=%~3
set TARGET_SIZE=%~4
if "%TARGET_SIZE%"=="" set TARGET_SIZE=8
echo [SWARM] Injecting %BOT_COUNT% Headless Bots to Lobby %LOBBY_ID% (Size: %TARGET_SIZE%)...
for /L %%i in (1, 1, %BOT_COUNT%) do (
    start "Weaver Bot %%i" /B cmd /c "bin\boot_headless.exe %LOBBY_ID% %TARGET_SIZE% > logs\bot_attach_%%i.log 2>&1"
    echo  ^|- Spun up Chaos Bot %%i
)
exit /b 0

:lab
call :swarm 2 2
exit /b 0

:swarm
set GRAPHICAL_CLIENTS=%~2
set BOT_CLIENTS=%~3
if "%GRAPHICAL_CLIENTS%"=="" set GRAPHICAL_CLIENTS=0
if "%BOT_CLIENTS%"=="" set BOT_CLIENTS=4

set /A TOTAL_PLAYERS=1 + GRAPHICAL_CLIENTS + BOT_CLIENTS

echo [SWARM] Orchestrating %TOTAL_PLAYERS%-Node Match...
echo [SWARM] Booting Graphical Host Node...

start "Weaver Host" /B cmd /c "bin\boot.exe host %TOTAL_PLAYERS% > logs\host.log 2>&1"

echo [SWARM] Waiting for Python Matchmaker to yield Lobby ID...
:wait_lobby
>nul find "LOBBY_ID:" logs\host.log
if errorlevel 1 (
    timeout /t 1 /nobreak >nul
    goto wait_lobby
)

:: Extract the Lobby ID using findstr
for /f "tokens=2 delims=:" %%A in ('findstr "LOBBY_ID:" logs\host.log') do set RAW_LOBBY=%%A
:: Trim whitespace
set LOBBY_ID=%RAW_LOBBY: =%
echo [SWARM] Established Network Lobby: %LOBBY_ID%

set CLIENT_IDX=1

:: Inject Graphical Clients
if %GRAPHICAL_CLIENTS% GTR 0 (
    for /L %%i in (1, 1, %GRAPHICAL_CLIENTS%) do (
        start "Weaver Client %%i" /B cmd /c "bin\boot.exe %LOBBY_ID% %TOTAL_PLAYERS% > logs\client_!CLIENT_IDX!.log 2>&1"
        echo  ^|- Spun up Graphical Client !CLIENT_IDX!
        set /A CLIENT_IDX+=1
    )
)

:: Inject Headless Bots
if %BOT_CLIENTS% GTR 0 (
    for /L %%i in (1, 1, %BOT_CLIENTS%) do (
        start "Weaver Bot %%i" /B cmd /c "bin\boot_headless.exe %LOBBY_ID% %TOTAL_PLAYERS% > logs\bot_!CLIENT_IDX!.log 2>&1"
        echo  ^|- Spun up Chaos Bot !CLIENT_IDX!
        set /A CLIENT_IDX+=1
    )
)

echo [SWARM] All nodes launched and running in the background.
exit /b 0
