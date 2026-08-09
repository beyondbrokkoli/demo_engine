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

:: Route directly to the standardized swarm call
if /I "%~1"=="swarm" (
    call :swarm %~2 %~3
    exit /b 0
)
if /I "%~1"=="lab" (
    :: 1 Graphical + 1 Bot + 1 Host = 3 Total Nodes (Perfect for quick iteration)
    call :swarm 1 1
    exit /b 0
)

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
echo    launch.bat lab                                  - Spins up a 1 graphical / 1 bot split
echo    launch.bat host [size]                          - Boots a graphical host node
echo    launch.bat client [lobby_id]                    - Boots a graphical client to join a lobby
echo    launch.bat attach [bot_count] [lobby_id]        - Injects headless bots to an existing lobby
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
if %TARGET_SIZE% GTR 8 (
    echo [ERROR] Host size cannot exceed 8.
    exit /b 1
)
echo [SWARM] Booting Graphical Host Node (Size: %TARGET_SIZE%)...
start "Weaver Host" /B cmd /c "bin\boot.exe host %TARGET_SIZE% > logs\host.log 2>&1"
echo [SWARM] Host running in background.
exit /b 0

:client
if "%~2"=="" echo [ERROR] Usage: launch.bat client [lobby_id] & exit /b 1
set LOBBY_ID=%~2
echo [SWARM] Booting Graphical Client Node joining Lobby %LOBBY_ID%...
start "Weaver Client" /B cmd /c "bin\boot.exe %LOBBY_ID% > logs\client_manual.log 2>&1"
exit /b 0

:attach
if "%~2"=="" echo [ERROR] Usage: launch.bat attach [bot_count] [lobby_id] & exit /b 1
if "%~3"=="" echo [ERROR] Usage: launch.bat attach [bot_count] [lobby_id] & exit /b 1
set BOT_COUNT=%~2
set LOBBY_ID=%~3
echo [SWARM] Injecting %BOT_COUNT% Headless Bots to Lobby %LOBBY_ID%...
for /L %%i in (1, 1, %BOT_COUNT%) do (
    start "Weaver Bot %%i" /B cmd /c "bin\boot_headless.exe %LOBBY_ID% > logs\bot_attach_%%i.log 2>&1"
    echo  ^|- Spun up Chaos Bot %%i
)
exit /b 0

:swarm
:: Now safely mapping to %~1 and %~2 since this is strictly called via 'call :swarm arg1 arg2'
set GRAPHICAL_CLIENTS=%~1
set BOT_CLIENTS=%~2
if "%GRAPHICAL_CLIENTS%"=="" set GRAPHICAL_CLIENTS=0
if "%BOT_CLIENTS%"=="" set BOT_CLIENTS=4

set /A TOTAL_PLAYERS=1 + GRAPHICAL_CLIENTS + BOT_CLIENTS

:: STRICT BOUNDS CHECK: Cap max players to 8 natively to prevent networking overflow!
if %TOTAL_PLAYERS% GTR 8 (
    echo [ERROR] The swarm is too large! %TOTAL_PLAYERS% exceeds the max 8-player limit.
    exit /b 1
)

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
        start "Weaver Client !CLIENT_IDX!" /B cmd /c "bin\boot.exe %LOBBY_ID% %TOTAL_PLAYERS% > logs\client_!CLIENT_IDX!.log 2>&1"
        echo  ^|- Spun up Graphical Client !CLIENT_IDX!
        set /A CLIENT_IDX+=1
    )
)

:: Inject Headless Bots
if %BOT_CLIENTS% GTR 0 (
    for /L %%i in (1, 1, %BOT_CLIENTS%) do (
        start "Weaver Bot !CLIENT_IDX!" /B cmd /c "bin\boot_headless.exe %LOBBY_ID% %TOTAL_PLAYERS% > logs\bot_!CLIENT_IDX!.log 2>&1"
        echo  ^|- Spun up Chaos Bot !CLIENT_IDX!
        set /A CLIENT_IDX+=1
    )
)

echo [SWARM] All nodes launched and running in the background.
exit /b 0
