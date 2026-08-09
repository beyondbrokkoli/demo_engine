#!/bin/bash
# launch.sh - Weaver Engine Orchestrator (Linux) - V2 (Dumb Node)

cd "$(dirname "$0")" || exit
BIN_EXT=".elf"

COMMAND=$1

case $COMMAND in
    clean)
        echo "[SWARM] Force sweeping all active Weaver Engine processes..."
        pkill -9 -f "boot.elf" 2>/dev/null
        pkill -9 -f "boot_headless.elf" 2>/dev/null
        ;;
    host)
        echo "[SWARM] Booting Graphical Host Node (Size: $2)..."
        ./bin/boot$BIN_EXT host "$2" > logs/host.log 2>&1 &
        ;;
    client)
        echo "[SWARM] Booting Client joining Lobby $2..."
        ./bin/boot$BIN_EXT "$2" > logs/client_manual_$RANDOM.log 2>&1 &
        ;;
    attach)
        echo "[SWARM] Injecting $2 Headless Bots to Lobby $3..."
        for ((i=1; i<=$2; i++)); do
            ./bin/boot_headless$BIN_EXT "$3" > logs/bot_attach_${i}_$RANDOM.log 2>&1 &
        done
        ;;
    swarm)
        GRAPHICAL_CLIENTS=${2:-0}
        BOT_CLIENTS=${3:-0}
        TOTAL_PLAYERS=$((1 + GRAPHICAL_CLIENTS + BOT_CLIENTS))

        rm -f logs/host.log
        ./bin/boot$BIN_EXT host "$TOTAL_PLAYERS" > logs/host.log 2>&1 &
        
        while ! grep -q "LOBBY_ID:" logs/host.log 2>/dev/null; do sleep 0.1; done
        LOBBY_ID=$(grep "LOBBY_ID:" logs/host.log | awk '{print $NF}')

        for ((i=1; i<=GRAPHICAL_CLIENTS; i++)); do
            ./bin/boot$BIN_EXT "$LOBBY_ID" > logs/client_${i}_$RANDOM.log 2>&1 &
        done
        for ((i=1; i<=BOT_CLIENTS; i++)); do
            ./bin/boot_headless$BIN_EXT "$LOBBY_ID" > logs/bot_${i}_$RANDOM.log 2>&1 &
        done
        ;;
esac
