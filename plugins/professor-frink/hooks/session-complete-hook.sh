#!/bin/bash
# session-complete-hook.sh - Hook triggered when a Claude session ends
#
# This hook is called by Claude Code when a session ends. It checks if
# Professor Frink is managing the session and handles continuation.
#
# Environment variables set by Claude Code:
#   CLAUDE_SESSION_ID - The session ID
#   CLAUDE_EXIT_CODE - The exit code of the session

set -e

FRINK_DIR=".frink"
STATE_FILE="$FRINK_DIR/state.json"

# Only run if Professor Frink state exists
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Check if we're in a Frink-managed session
EXECUTION_STATE=$(jq -r '.execution_state // "idle"' "$STATE_FILE" 2>/dev/null)

if [[ "$EXECUTION_STATE" != "running" ]]; then
    exit 0
fi

# Get current task info
CURRENT_TASK=$(jq -r '.current_task // "null"' "$STATE_FILE")
SESSION_TYPE=$(jq -r '.current_session_type // "unknown"' "$STATE_FILE")

if [[ "$CURRENT_TASK" == "null" ]]; then
    exit 0
fi

# Log session completion
echo "[Professor Frink] Session complete: $SESSION_TYPE for task $CURRENT_TASK"

# The orchestrator script handles the actual loop logic
# This hook is mainly for logging and cleanup

# Check if there's a completion marker in the session
# The orchestrator reads session logs to determine next steps

exit 0
