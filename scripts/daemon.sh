#!/bin/bash
set -euo pipefail

# Daemon management script for Cowbell (standalone mooR daemon)
# Usage: ./scripts/daemon.sh start|stop|status
# Note: For full stack with web/telnet, use the docker-compose workflow instead

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env.mk if it exists (parse Make-style assignments)
if [[ -f "$PROJECT_DIR/.env.mk" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        # Parse VAR = value or VAR ?= value (only set if not already set)
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\?=[[:space:]]*(.*)$ ]]; then
            var="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            # Only set if not already in environment
            if [[ -z "${!var:-}" ]]; then
                export "$var=$val"
            fi
        elif [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            var="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            export "$var=$val"
        fi
    done < "$PROJECT_DIR/.env.mk"
fi

# Defaults
MOOR_DIR="${MOOR_DIR:-../..}"
BUILD_PROFILE="${BUILD_PROFILE:-debug}"
MOORC_TYPE="${MOORC_TYPE:-cargo}"
DATA_DIR="${DATA_DIR:-local-daemon-data}"
DB_NAME="${DB_NAME:-development.db}"
IPC_DIR="${IPC_DIR:-moor-ipc}"
PID_FILE="${PID_FILE:-.moor-daemon.pid}"

# Resolve relative paths from project directory
cd "$PROJECT_DIR"

# Build the daemon command based on mode
build_daemon_cmd() {
    local daemon_args=(
        "$DATA_DIR"
        "--db=$DB_NAME"
        "--rpc-listen=ipc://$IPC_DIR/rpc.sock"
        "--events-listen=ipc://$IPC_DIR/events.sock"
        "--workers-response-listen=ipc://$IPC_DIR/workers-response.sock"
        "--workers-request-listen=ipc://$IPC_DIR/workers-request.sock"
        "--generate-keypair"
    )

    case "$MOORC_TYPE" in
        cargo)
            echo cargo run --manifest-path "$MOOR_DIR/Cargo.toml" -p moor-daemon -- "${daemon_args[@]}"
            ;;
        direct)
            echo "$MOOR_DIR/target/$BUILD_PROFILE/moor-daemon" "${daemon_args[@]}"
            ;;
        docker)
            echo "Docker mode not yet supported for daemon" >&2
            exit 1
            ;;
        *)
            echo "Unknown MOORC_TYPE: $MOORC_TYPE" >&2
            exit 1
            ;;
    esac
}

cmd_start() {
    # Create IPC directory
    mkdir -p "$IPC_DIR"

    # Check if already running
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Daemon already running (PID $pid)"
            exit 1
        else
            echo "Removing stale PID file"
            rm -f "$PID_FILE"
        fi
    fi

    # Build and run command
    local cmd
    cmd=$(build_daemon_cmd)
    echo "Starting daemon: $cmd"

    # Run in background
    $cmd &
    local pid=$!
    echo "$pid" > "$PID_FILE"

    # Wait briefly to check if it started successfully
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
        echo "Daemon started (PID $pid)"
    else
        echo "Daemon failed to start"
        rm -f "$PID_FILE"
        exit 1
    fi
}

cmd_stop() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "No PID file found"
        exit 1
    fi

    local pid
    pid=$(cat "$PID_FILE")

    if kill "$pid" 2>/dev/null; then
        echo "Daemon stopped (PID $pid)"
        rm -f "$PID_FILE"
    else
        echo "Daemon not running, removing stale PID file"
        rm -f "$PID_FILE"
    fi
}

cmd_status() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "Daemon is not running (no PID file)"
        exit 1
    fi

    local pid
    pid=$(cat "$PID_FILE")

    if kill -0 "$pid" 2>/dev/null; then
        echo "Daemon is running (PID $pid)"
    else
        echo "Daemon is not running (stale PID file)"
        exit 1
    fi
}

cmd_help() {
    cat <<EOF
Usage: $(basename "$0") <command>

Commands:
    start   Start the moor-daemon in the background
    stop    Stop the running daemon
    status  Check if the daemon is running
    help    Show this help message

Note: This starts only the daemon. For full stack with web/telnet,
use the docker-compose workflow (see LOCAL_DEVELOPMENT.md).

Environment variables (can also be set in .env.mk):
    MOOR_DIR        Path to mooR source (default: ../.. for cores/cowbell/)
    BUILD_PROFILE   Build profile: debug or release (default: debug)
    MOORC_TYPE      Build mode: cargo or direct (default: cargo)
    DATA_DIR        Daemon data directory (default: local-daemon-data)
    DB_NAME         Database filename (default: development.db)
    IPC_DIR         IPC socket directory (default: moor-ipc)
    PID_FILE        PID file location (default: .moor-daemon.pid)
EOF
}

# Main
case "${1:-help}" in
    start)  cmd_start ;;
    stop)   cmd_stop ;;
    status) cmd_status ;;
    help|--help|-h) cmd_help ;;
    *)
        echo "Unknown command: $1" >&2
        cmd_help >&2
        exit 1
        ;;
esac
