#!/bin/bash
# progress-tracker.sh - Manage Professor Frink state in .frink/state.json
#
# Usage:
#   ./progress-tracker.sh init                    - Initialize state file
#   ./progress-tracker.sh get-current             - Get current task
#   ./progress-tracker.sh get-next                - Get next incomplete task
#   ./progress-tracker.sh complete <task_id>      - Mark task as complete
#   ./progress-tracker.sh set-state <state>       - Set execution state
#   ./progress-tracker.sh status                  - Show current status

set -e

FRINK_DIR=".frink"
STATE_FILE="$FRINK_DIR/state.json"

# Ensure jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

# Initialize state file
init_state() {
    local tasks_file="${1:-}"

    mkdir -p "$FRINK_DIR"

    # Parse tasks if file provided
    local tasks="[]"
    local total_tasks=0

    if [[ -n "$tasks_file" && -f "$tasks_file" ]]; then
        # Use task-parser to get tasks
        local parser_dir="$(dirname "$0")"
        if [[ -f "$parser_dir/task-parser.sh" ]]; then
            tasks=$("$parser_dir/task-parser.sh" "$tasks_file" --output json | jq '.tasks')
            total_tasks=$(echo "$tasks" | jq 'length')
        fi
    fi

    # Create initial state
    cat > "$STATE_FILE" << EOF
{
  "version": "1.0.0",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "execution_state": "idle",
  "current_task": null,
  "current_task_group": null,
  "current_session_type": null,
  "tasks_completed": [],
  "tasks_failed": [],
  "total_tasks": $total_tasks,
  "total_sessions": 0,
  "executor_sessions": 0,
  "validator_sessions": 0,
  "fixer_sessions": 0,
  "self_healing_fixes": 0,
  "pending_checkpoint": null,
  "last_session_at": null,
  "task_queue": $tasks
}
EOF

    echo "State initialized: $STATE_FILE"
    echo "Total tasks queued: $total_tasks"
}

# Get current task
get_current() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "null"
        return
    fi

    jq -r '.current_task // "null"' "$STATE_FILE"
}

# Get next incomplete task
get_next() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "null"
        return
    fi

    # Get completed tasks
    local completed=$(jq -r '.tasks_completed | @json' "$STATE_FILE")

    # Find first incomplete task
    jq -r --argjson completed "$completed" '
        .task_queue[] |
        select(.completed == false) |
        select(.id as $id | ($completed | index($id)) == null) |
        .id
    ' "$STATE_FILE" | head -1
}

# Mark task as complete
complete_task() {
    local task_id="$1"

    if [[ -z "$task_id" ]]; then
        echo "Error: task_id required" >&2
        exit 1
    fi

    # Update state
    local tmp_file=$(mktemp)
    jq --arg task_id "$task_id" '
        .tasks_completed += [$task_id] |
        .task_queue = [.task_queue[] | if .id == $task_id then .completed = true else . end] |
        .updated_at = (now | todate)
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"

    echo "Task $task_id marked complete"
}

# Mark task as failed
fail_task() {
    local task_id="$1"
    local reason="${2:-Unknown}"

    if [[ -z "$task_id" ]]; then
        echo "Error: task_id required" >&2
        exit 1
    fi

    local tmp_file=$(mktemp)
    jq --arg task_id "$task_id" --arg reason "$reason" '
        .tasks_failed += [{"id": $task_id, "reason": $reason, "at": (now | todate)}] |
        .updated_at = (now | todate)
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"

    echo "Task $task_id marked failed: $reason"
}

# Set execution state
set_state() {
    local state="$1"

    if [[ ! "$state" =~ ^(idle|running|paused|cancelled|completed)$ ]]; then
        echo "Error: Invalid state '$state'" >&2
        exit 1
    fi

    local tmp_file=$(mktemp)
    jq --arg state "$state" '
        .execution_state = $state |
        .updated_at = (now | todate)
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"

    echo "Execution state set to: $state"
}

# Set current task
set_current_task() {
    local task_id="$1"
    local session_type="${2:-executor}"

    local tmp_file=$(mktemp)
    jq --arg task_id "$task_id" --arg session_type "$session_type" '
        .current_task = $task_id |
        .current_session_type = $session_type |
        .updated_at = (now | todate)
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
}

# Increment session count
increment_sessions() {
    local session_type="$1"

    local tmp_file=$(mktemp)
    case $session_type in
        executor)
            jq '.total_sessions += 1 | .executor_sessions += 1 | .last_session_at = (now | todate)' "$STATE_FILE" > "$tmp_file"
            ;;
        validator)
            jq '.total_sessions += 1 | .validator_sessions += 1 | .last_session_at = (now | todate)' "$STATE_FILE" > "$tmp_file"
            ;;
        fixer)
            jq '.total_sessions += 1 | .fixer_sessions += 1 | .last_session_at = (now | todate)' "$STATE_FILE" > "$tmp_file"
            ;;
        *)
            jq '.total_sessions += 1 | .last_session_at = (now | todate)' "$STATE_FILE" > "$tmp_file"
            ;;
    esac
    mv "$tmp_file" "$STATE_FILE"
}

# Increment self-healing fixes
increment_fixes() {
    local tmp_file=$(mktemp)
    jq '.self_healing_fixes += 1' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
}

# Set pending checkpoint
set_checkpoint() {
    local checkpoint_id="$1"
    local description="$2"

    local tmp_file=$(mktemp)
    jq --arg id "$checkpoint_id" --arg desc "$description" '
        .pending_checkpoint = {
            "id": $id,
            "description": $desc,
            "triggered_at": (now | todate)
        } |
        .execution_state = "paused" |
        .updated_at = (now | todate)
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"

    echo "Checkpoint triggered: $checkpoint_id"
}

# Clear pending checkpoint
clear_checkpoint() {
    local tmp_file=$(mktemp)
    jq '
        .pending_checkpoint = null |
        .execution_state = "running" |
        .updated_at = (now | todate)
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"

    echo "Checkpoint cleared"
}

# Show status
show_status() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "No state file found. Run 'init' first."
        return 1
    fi

    echo "Professor Frink Status"
    echo "======================"
    echo ""

    # Basic info
    local state=$(jq -r '.execution_state' "$STATE_FILE")
    local current=$(jq -r '.current_task // "none"' "$STATE_FILE")
    local session_type=$(jq -r '.current_session_type // "none"' "$STATE_FILE")
    local total=$(jq -r '.total_tasks' "$STATE_FILE")
    local completed=$(jq -r '.tasks_completed | length' "$STATE_FILE")
    local failed=$(jq -r '.tasks_failed | length' "$STATE_FILE")

    echo "State:          $state"
    echo "Current Task:   $current"
    echo "Session Type:   $session_type"
    echo ""
    echo "Progress:       $completed / $total tasks ($(( completed * 100 / (total > 0 ? total : 1) ))%)"
    echo "Failed:         $failed"
    echo ""

    # Session stats
    local total_sessions=$(jq -r '.total_sessions' "$STATE_FILE")
    local executor_sessions=$(jq -r '.executor_sessions' "$STATE_FILE")
    local validator_sessions=$(jq -r '.validator_sessions' "$STATE_FILE")
    local fixer_sessions=$(jq -r '.fixer_sessions' "$STATE_FILE")
    local fixes=$(jq -r '.self_healing_fixes' "$STATE_FILE")

    echo "Sessions:"
    echo "  Total:        $total_sessions"
    echo "  Executor:     $executor_sessions"
    echo "  Validator:    $validator_sessions"
    echo "  Fixer:        $fixer_sessions"
    echo "  Self-healed:  $fixes"
    echo ""

    # Checkpoint status
    local checkpoint=$(jq -r '.pending_checkpoint.id // "none"' "$STATE_FILE")
    if [[ "$checkpoint" != "none" ]]; then
        local cp_desc=$(jq -r '.pending_checkpoint.description' "$STATE_FILE")
        echo "PENDING CHECKPOINT: $checkpoint"
        echo "  $cp_desc"
        echo ""
    fi

    # Recently completed
    echo "Recently Completed:"
    jq -r '.tasks_completed[-5:][]' "$STATE_FILE" 2>/dev/null | while read task; do
        echo "  [x] $task"
    done
    echo ""
}

# Export state as JSON
export_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "{}"
    fi
}

# Main command dispatch
case "${1:-}" in
    init)
        init_state "${2:-}"
        ;;
    get-current)
        get_current
        ;;
    get-next)
        get_next
        ;;
    complete)
        complete_task "$2"
        ;;
    fail)
        fail_task "$2" "$3"
        ;;
    set-state)
        set_state "$2"
        ;;
    set-current)
        set_current_task "$2" "$3"
        ;;
    set-checkpoint)
        set_checkpoint "$2" "$3"
        ;;
    clear-checkpoint)
        clear_checkpoint
        ;;
    increment-sessions)
        increment_sessions "$2"
        ;;
    increment-fixes)
        increment_fixes
        ;;
    status)
        show_status
        ;;
    export)
        export_state
        ;;
    *)
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  init [tasks_file]      Initialize state"
        echo "  get-current            Get current task ID"
        echo "  get-next               Get next incomplete task ID"
        echo "  complete <task_id>     Mark task as complete"
        echo "  fail <task_id> [reason] Mark task as failed"
        echo "  set-state <state>      Set execution state"
        echo "  set-current <id> [type] Set current task"
        echo "  set-checkpoint <id> <desc> Set pending checkpoint"
        echo "  clear-checkpoint       Clear pending checkpoint"
        echo "  increment-sessions <type> Increment session count"
        echo "  increment-fixes        Increment self-healing count"
        echo "  status                 Show current status"
        echo "  export                 Export state as JSON"
        exit 1
        ;;
esac
