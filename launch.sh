#!/bin/bash
# launch.sh - Weaver Engine Orchestrator (Linux) - V2 (Smart Node)

cd "$(dirname "$0")" || exit

BIN_EXT=".elf"

usage() {
    echo "======================================================="
    echo "Weaver Engine Orchestrator (Linux)"
    echo "======================================================="
    echo "Usage:"
    echo "  ./launch.sh swarm [graphical_count] [bot_count]  - Spins up a local swarm cluster"
    echo "  ./launch.sh lab                                  - Spins up 4/4 split (4 graphical, 4 bots)"
    echo "  ./launch.sh host [size]                          - Boots a graphical host node"
    echo "  ./launch.sh client [lobby_id]                    - Boots a graphical client to join a lobby"
    echo "  ./launch.sh attach [bot_count] [lobby_id]        - Injects headless bots to an existing lobby"
    echo "  ./launch.sh clean                                - Force-kills all active boot and bot processes"
    echo "======================================================="
    exit 1
}

if [ "$#" -eq 0 ]; then usage; fi

COMMAND=$1

case $COMMAND in
    clean)
        if [ "$#" -gt 1 ]; then
            echo "[ERROR] The 'clean' command must be used independently."
            exit 1
        fi
        echo "[SWARM] Force sweeping all active Weaver Engine processes..."
        pkill -9 -f "boot.elf" 2>/dev/null
        pkill -9 -f "boot_headless.elf" 2>/dev/null
        echo "[SWARM] Clean complete. Sockets released."
        ;;

    host)
        TARGET_SIZE=${2:-8}
        echo "[SWARM] Booting Graphical Host Node (Size: $TARGET_SIZE)..."
        ./bin/boot$BIN_EXT host "$TARGET_SIZE" > logs/host.log 2>&1 &
        echo "[SWARM] Host running in background."
        ;;

    client)
        if [ -z "$2" ]; then echo "[ERROR] Usage: client [lobby_id]"; exit 1; fi
        LOBBY_ID=$2
        echo "[SWARM] Booting Graphical Client Node joining Lobby $LOBBY_ID..."
        ./bin/boot$BIN_EXT "$LOBBY_ID" > logs/client_manual.log 2>&1 &
        ;;

    attach)
        if [ -z "$2" ] || [ -z "$3" ]; then echo "[ERROR] Usage: attach [bot_count] [lobby_id]"; exit 1; fi
        BOT_COUNT=$2
        LOBBY_ID=$3
        echo "[SWARM] Injecting $BOT_COUNT Headless Bots to Lobby $LOBBY_ID..."
        for ((i=1; i<=BOT_COUNT; i++)); do
            ./bin/boot_headless$BIN_EXT "$LOBBY_ID" > logs/bot_attach_${i}.log 2>&1 &
            echo " |- Spun up Chaos Bot $i"
        done
        ;;

    lab)
        $0 swarm 3 4
        ;;

    swarm)
        GRAPHICAL_CLIENTS=${2:-0}
        BOT_CLIENTS=${3:-7}
        TOTAL_PLAYERS=$((1 + GRAPHICAL_CLIENTS + BOT_CLIENTS))

        echo "[SWARM] Orchestrating $TOTAL_PLAYERS-Node Match..."
        ./bin/boot$BIN_EXT host "$TOTAL_PLAYERS" > logs/host.log 2>&1 &
        HOST_PID=$!
        SWARM_PIDS=($HOST_PID)

        echo "[SWARM] Waiting for Python Matchmaker to yield Lobby ID..."
        while ! grep -q "LOBBY_ID:" logs/host.log; do
            sleep 0.1
        done

        LOBBY_ID=$(grep "LOBBY_ID:" logs/host.log | awk '{print $NF}')
        echo "[SWARM] Established Network Lobby: $LOBBY_ID"

        CLIENT_IDX=1

        # Graphical Clients
        for ((i=1; i<=GRAPHICAL_CLIENTS; i++)); do
            ./bin/boot$BIN_EXT "$LOBBY_ID" "$TOTAL_PLAYERS" > logs/client_${CLIENT_IDX}.log 2>&1 &
            SWARM_PIDS+=($!)
            echo " |- Spun up Graphical Client $CLIENT_IDX"
            ((CLIENT_IDX++))
        done

        # Headless Bots
        for ((i=1; i<=BOT_CLIENTS; i++)); do
            ./bin/boot_headless$BIN_EXT "$LOBBY_ID" "$TOTAL_PLAYERS" > logs/bot_${CLIENT_IDX}.log 2>&1 &
            SWARM_PIDS+=($!)
            echo " |- Spun up Chaos Bot $CLIENT_IDX"
            ((CLIENT_IDX++))
        done

        echo "[SWARM] All nodes launched and running in the background."
        ;;

    *)
        usage
        ;;
esac
