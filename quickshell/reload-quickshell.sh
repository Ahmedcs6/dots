#!/bin/bash
set -euo pipefail
# Reload QuickShell

# Kill existing instance gracefully first, then force if needed.
# -x matches the exact process name so we never kill prefix-matched
# lookalikes (guards below use pgrep -x; kills must match).
if pgrep -x quickshell > /dev/null; then
    echo "Stopping QuickShell..."
    pkill -x quickshell
    # Wait up to 5 seconds
    for i in {1..50}; do
        if ! pgrep -x quickshell > /dev/null; then
            break
        fi
        sleep 0.1
    done
    # Force kill if still running
    if pgrep -x quickshell > /dev/null; then
        pkill -x -9 quickshell
    fi
fi

# Start new instance (log to file instead of /dev/null for debugging)
echo "Starting QuickShell..."
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
mkdir -p "$LOG_DIR"
nohup quickshell > "$LOG_DIR/quickshell.log" 2>&1 &

echo "Done."
