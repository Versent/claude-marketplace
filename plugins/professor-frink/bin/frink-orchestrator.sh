#!/bin/bash
# frink-orchestrator.sh - Main orchestrator for Professor Frink
#
# This script runs OUTSIDE of Claude Code and manages the multi-session
# task execution loop. It spawns fresh Claude sessions for each task.
#
# Usage:
#   ./frink-orchestrator.sh run             - Run task execution loop
#   ./frink-orchestrator.sh run --from X.Y  - Start from specific task
#   ./frink-orchestrator.sh status          - Show current status
#   ./frink-orchestrator.sh init [tasks.md] - Initialize state

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Import library functions
source_lib() {
    local lib="$1"
    if [[ -f "$LIB_DIR/$lib" ]]; then
        source "$LIB_DIR/$lib"
    else
        echo "Error: Library not found: $lib" >&2
        exit 1
    fi
}

# Configuration
FRINK_DIR=".frink"
STATE_FILE="$FRINK_DIR/state.json"
MAX_FIXER_ATTEMPTS=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    echo "=========================================="
    echo "  $1"
    echo "=========================================="
    echo ""
}

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v claude &> /dev/null; then
        missing+=("claude (Claude Code CLI)")
    fi

    if ! command -v jq &> /dev/null; then
        missing+=("jq (JSON processor)")
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies:" >&2
        for dep in "${missing[@]}"; do
            echo "  - $dep" >&2
        done
        exit 1
    fi
}

# Initialize state
init() {
    local tasks_file="${1:-}"

    print_header "Professor Frink Initialization"

    # Check for Agent-OS
    if [[ -d "agent-os" ]]; then
        echo "Agent-OS detected."

        # Find tasks.md files
        local task_files=($(find agent-os/specs -name "tasks.md" 2>/dev/null))

        if [[ ${#task_files[@]} -gt 0 ]]; then
            echo "Found ${#task_files[@]} tasks.md file(s):"
            for f in "${task_files[@]}"; do
                echo "  - $f"
            done
            echo ""

            # Use first one if not specified
            if [[ -z "$tasks_file" ]]; then
                tasks_file="${task_files[0]}"
                echo "Using: $tasks_file"
            fi
        fi
    fi

    # Initialize state
    "$LIB_DIR/progress-tracker.sh" init "$tasks_file"

    # Initialize checkpoints
    "$LIB_DIR/checkpoint-manager.sh" init

    # Initialize credentials
    "$LIB_DIR/credential-validator.sh" init

    # Create context directory
    mkdir -p "$FRINK_DIR/context" "$FRINK_DIR/logs" "$FRINK_DIR/prompts"

    # Validate credentials
    echo ""
    if ! "$LIB_DIR/credential-validator.sh" validate; then
        print_status "$YELLOW" "Warning: Some credentials are missing."
        echo "You may need to set them before certain tasks can run."
    fi

    print_header "Initialization Complete"
    echo "Run './frink-orchestrator.sh run' to start execution."
}

# Run a single task (executor + validator)
run_task() {
    local task_id="$1"
    local fixer_attempts=0

    print_status "$BLUE" "[TASK $task_id] Starting execution..."

    # Update state
    "$LIB_DIR/progress-tracker.sh" set-current "$task_id" "executor"
    "$LIB_DIR/progress-tracker.sh" set-state "running"

    # Phase 1: Run executor
    while true; do
        print_status "$BLUE" "[EXECUTOR] Spawning session for task $task_id..."
        "$LIB_DIR/progress-tracker.sh" increment-sessions "executor"

        # Run executor session
        local exit_code=0
        "$LIB_DIR/session-spawner.sh" --task "$task_id" --mode executor || exit_code=$?

        case $exit_code in
            0)
                # Success - move to validation
                print_status "$GREEN" "[EXECUTOR] Task implementation complete."
                break
                ;;
            10)
                # Environment unhealthy - need fixer
                ((fixer_attempts++))
                if [[ $fixer_attempts -gt $MAX_FIXER_ATTEMPTS ]]; then
                    print_status "$RED" "[ERROR] Max fixer attempts reached. Manual intervention needed."
                    "$LIB_DIR/progress-tracker.sh" fail "$task_id" "Environment unfixable after $MAX_FIXER_ATTEMPTS attempts"
                    return 1
                fi

                print_status "$YELLOW" "[FIXER] Environment unhealthy. Spawning fixer session (attempt $fixer_attempts)..."
                "$LIB_DIR/progress-tracker.sh" increment-sessions "fixer"
                "$LIB_DIR/session-spawner.sh" --task "$task_id" --mode fixer || true

                # Retry executor after fix
                continue
                ;;
            20)
                # Blocked - need human intervention
                print_status "$RED" "[BLOCKED] Task execution blocked. Check logs for details."
                "$LIB_DIR/progress-tracker.sh" fail "$task_id" "Execution blocked"
                return 1
                ;;
            *)
                # Unknown error
                print_status "$RED" "[ERROR] Executor session failed with code $exit_code"
                "$LIB_DIR/progress-tracker.sh" fail "$task_id" "Executor failed: exit code $exit_code"
                return 1
                ;;
        esac
    done

    # Phase 2: Run validator
    print_status "$BLUE" "[VALIDATOR] Spawning validation session..."
    "$LIB_DIR/progress-tracker.sh" set-current "$task_id" "validator"
    "$LIB_DIR/progress-tracker.sh" increment-sessions "validator"

    local validator_exit=0
    "$LIB_DIR/session-spawner.sh" --task "$task_id" --mode validator || validator_exit=$?

    if [[ $validator_exit -eq 0 ]]; then
        print_status "$GREEN" "[VALIDATOR] Validation PASSED."

        # Check if validator made fixes
        if grep -q "Self-Healing Applied" "$FRINK_DIR/logs/"*"$task_id"*validator* 2>/dev/null; then
            "$LIB_DIR/progress-tracker.sh" increment-fixes
        fi
    else
        print_status "$RED" "[VALIDATOR] Validation failed. Check logs."
        "$LIB_DIR/progress-tracker.sh" fail "$task_id" "Validation failed"
        return 1
    fi

    # Mark task complete
    "$LIB_DIR/progress-tracker.sh" complete "$task_id"
    print_status "$GREEN" "[COMPLETE] Task $task_id finished successfully."

    return 0
}

# Main execution loop
run() {
    local start_from="${1:-}"

    check_dependencies

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "Error: State file not found. Run 'init' first." >&2
        exit 1
    fi

    print_header "Professor Frink Execution"

    # Validate credentials
    if ! "$LIB_DIR/credential-validator.sh" validate; then
        print_status "$RED" "Credential validation failed. Please set required credentials."
        exit 1
    fi

    # Check for pending checkpoint
    local pending=$(jq -r '.pending_checkpoint.id // ""' "$STATE_FILE")
    if [[ -n "$pending" && "$pending" != "null" ]]; then
        print_status "$YELLOW" "Pending checkpoint: $pending"
        echo "Run '/frink-approve' or '/frink-amend' to continue."
        exit 0
    fi

    # Set state to running
    "$LIB_DIR/progress-tracker.sh" set-state "running"

    # Main loop
    while true; do
        # Get next task
        local next_task
        if [[ -n "$start_from" ]]; then
            next_task="$start_from"
            start_from=""  # Only use once
        else
            next_task=$("$LIB_DIR/progress-tracker.sh" get-next)
        fi

        if [[ -z "$next_task" || "$next_task" == "null" ]]; then
            print_header "Execution Complete"
            "$LIB_DIR/progress-tracker.sh" status
            "$LIB_DIR/progress-tracker.sh" set-state "completed"
            break
        fi

        # Check for checkpoint BEFORE task
        local checkpoint=$("$LIB_DIR/checkpoint-manager.sh" check "$next_task" 2>/dev/null || echo "")
        if [[ -n "$checkpoint" ]]; then
            "$LIB_DIR/checkpoint-manager.sh" trigger "$checkpoint"
            echo ""
            echo "Execution paused at checkpoint."
            exit 0
        fi

        # Run the task
        if ! run_task "$next_task"; then
            print_status "$RED" "Task $next_task failed. Stopping execution."
            "$LIB_DIR/progress-tracker.sh" set-state "paused"
            exit 1
        fi

        # Check for checkpoint AFTER task
        checkpoint=$("$LIB_DIR/checkpoint-manager.sh" check-after "$next_task" 2>/dev/null || echo "")
        if [[ -n "$checkpoint" ]]; then
            "$LIB_DIR/checkpoint-manager.sh" trigger "$checkpoint"
            echo ""
            echo "Execution paused at checkpoint."
            exit 0
        fi

        echo ""
        echo "---"
        echo ""
    done
}

# Show status
status() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "No state file found. Run 'init' first."
        exit 1
    fi

    "$LIB_DIR/progress-tracker.sh" status
}

# Print help
print_help() {
    echo "Professor Frink - Autonomous Multi-Session Task Orchestrator"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init [tasks.md]    Initialize state from tasks.md file"
    echo "  run                Run task execution loop"
    echo "  run --from X.Y     Start from specific task"
    echo "  status             Show current execution status"
    echo "  help               Show this help"
    echo ""
    echo "Related Claude commands:"
    echo "  /frink-init        Initialize (interactive)"
    echo "  /frink-run         Run execution (interactive)"
    echo "  /frink-status      Show status"
    echo "  /frink-approve     Approve HITL checkpoint"
    echo "  /frink-amend       Amend checkpoint with feedback"
    echo "  /frink-cancel      Cancel execution"
}

# Main dispatch
case "${1:-}" in
    init)
        init "$2"
        ;;
    run)
        if [[ "$2" == "--from" && -n "$3" ]]; then
            run "$3"
        else
            run
        fi
        ;;
    status)
        status
        ;;
    help|--help|-h)
        print_help
        ;;
    *)
        print_help
        exit 1
        ;;
esac
