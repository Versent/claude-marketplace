#!/bin/bash
# principal-skinner.sh - Supervisor for autonomous agent sessions
#
# Named after Principal Skinner from The Simpsons - the deterministic control plane
# that monitors and constrains agent behavior.
#
# Usage:
#   ./principal-skinner.sh supervise <session_pid> [options]
#   ./principal-skinner.sh check-limits
#   ./principal-skinner.sh get-stats
#
# Options:
#   --max-cost <usd>        Maximum cost in USD (default: 10.00)
#   --max-duration <sec>    Maximum duration in seconds (default: 600)
#   --max-iterations <n>    Maximum iterations per task (default: 3)
#   --cost-per-1k <usd>     Cost per 1K tokens (default: 0.015 for Claude Sonnet)

set -e

FRINK_DIR=".frink"
STATS_FILE="$FRINK_DIR/supervisor-stats.json"
CONFIG_FILE="$FRINK_DIR/config.yml"

# Default limits
DEFAULT_MAX_COST="10.00"
DEFAULT_MAX_DURATION="600"
DEFAULT_MAX_ITERATIONS="3"
DEFAULT_COST_PER_1K="0.015"

# Parse config file if exists
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Try to parse YAML (requires yq or fallback to grep)
        if command -v yq &> /dev/null; then
            MAX_COST=$(yq -r '.execution.max_cost_per_task // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
            MAX_DURATION=$(yq -r '.execution.max_duration_per_task // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
            MAX_ITERATIONS=$(yq -r '.execution.max_iterations_per_task // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
            COST_PER_1K=$(yq -r '.execution.cost_per_1k_tokens // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
        else
            # Fallback: simple grep parsing
            MAX_COST=$(grep 'max_cost_per_task:' "$CONFIG_FILE" 2>/dev/null | awk '{print $2}' || echo "")
            MAX_DURATION=$(grep 'max_duration_per_task:' "$CONFIG_FILE" 2>/dev/null | awk '{print $2}' || echo "")
            MAX_ITERATIONS=$(grep 'max_iterations_per_task:' "$CONFIG_FILE" 2>/dev/null | awk '{print $2}' || echo "")
            COST_PER_1K=$(grep 'cost_per_1k_tokens:' "$CONFIG_FILE" 2>/dev/null | awk '{print $2}' || echo "")
        fi
    fi

    # Apply defaults
    MAX_COST="${MAX_COST:-$DEFAULT_MAX_COST}"
    MAX_DURATION="${MAX_DURATION:-$DEFAULT_MAX_DURATION}"
    MAX_ITERATIONS="${MAX_ITERATIONS:-$DEFAULT_MAX_ITERATIONS}"
    COST_PER_1K="${COST_PER_1K:-$DEFAULT_COST_PER_1K}"
}

# Initialize stats file
init_stats() {
    mkdir -p "$FRINK_DIR"
    if [[ ! -f "$STATS_FILE" ]]; then
        cat > "$STATS_FILE" << EOF
{
  "total_cost_usd": 0.0,
  "total_duration_sec": 0,
  "total_tokens": 0,
  "session_count": 0,
  "task_iterations": {},
  "cost_by_task": {},
  "terminated_sessions": [],
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    fi
}

# Get current stats
get_stats() {
    init_stats
    cat "$STATS_FILE"
}

# Update stats with session data
update_stats() {
    local task_id="$1"
    local duration="$2"
    local tokens="${3:-0}"
    local terminated="${4:-false}"

    init_stats

    # Calculate cost
    local cost=$(echo "scale=4; $tokens / 1000 * $COST_PER_1K" | bc 2>/dev/null || echo "0")

    local tmp_file=$(mktemp)
    jq --arg task_id "$task_id" \
       --argjson duration "$duration" \
       --argjson tokens "$tokens" \
       --argjson cost "$cost" \
       --argjson terminated "$terminated" '
        .total_cost_usd = (.total_cost_usd + $cost) |
        .total_duration_sec = (.total_duration_sec + $duration) |
        .total_tokens = (.total_tokens + $tokens) |
        .session_count = (.session_count + 1) |
        .task_iterations[$task_id] = ((.task_iterations[$task_id] // 0) + 1) |
        .cost_by_task[$task_id] = ((.cost_by_task[$task_id] // 0) + $cost) |
        (if $terminated then .terminated_sessions += [$task_id] else . end) |
        .last_updated = (now | todate)
    ' "$STATS_FILE" > "$tmp_file" && mv "$tmp_file" "$STATS_FILE"
}

# Check if task has exceeded iteration limit
check_iterations() {
    local task_id="$1"

    init_stats

    local iterations=$(jq -r --arg task_id "$task_id" '.task_iterations[$task_id] // 0' "$STATS_FILE")

    if [[ "$iterations" -ge "$MAX_ITERATIONS" ]]; then
        echo "LIMIT_EXCEEDED: Task $task_id has reached max iterations ($iterations >= $MAX_ITERATIONS)"
        return 1
    fi

    echo "OK: Task $task_id iteration $((iterations + 1)) of $MAX_ITERATIONS"
    return 0
}

# Check if total cost is within budget
check_cost() {
    init_stats

    local total_cost=$(jq -r '.total_cost_usd' "$STATS_FILE")

    # Compare using bc for floating point
    local exceeded=$(echo "$total_cost >= $MAX_COST" | bc 2>/dev/null || echo "0")

    if [[ "$exceeded" == "1" ]]; then
        echo "LIMIT_EXCEEDED: Total cost \$$total_cost exceeds max \$$MAX_COST"
        return 1
    fi

    echo "OK: Cost \$$total_cost of \$$MAX_COST budget"
    return 0
}

# Supervise a running session
supervise_session() {
    local session_pid="$1"
    local task_id="${2:-unknown}"
    local start_time=$(date +%s)

    echo "Principal Skinner supervising session $session_pid for task $task_id"
    echo "  Max duration: ${MAX_DURATION}s"
    echo "  Max cost: \$${MAX_COST}"
    echo "  Max iterations: ${MAX_ITERATIONS}"

    # Check iteration limit before starting
    if ! check_iterations "$task_id" >/dev/null; then
        echo "ERROR: Task $task_id has exceeded iteration limit"
        if kill -0 "$session_pid" 2>/dev/null; then
            kill "$session_pid" 2>/dev/null || true
        fi
        return 1
    fi

    # Monitor loop
    while kill -0 "$session_pid" 2>/dev/null; do
        local current_time=$(date +%s)
        local duration=$((current_time - start_time))

        # Check duration limit
        if [[ "$duration" -ge "$MAX_DURATION" ]]; then
            echo ""
            echo "SUPERVISOR: Duration limit exceeded (${duration}s >= ${MAX_DURATION}s)"
            echo "SUPERVISOR: Terminating session $session_pid"

            kill "$session_pid" 2>/dev/null || true
            sleep 2
            kill -9 "$session_pid" 2>/dev/null || true

            update_stats "$task_id" "$duration" "0" "true"

            echo "SUPERVISOR: Session terminated due to duration limit"
            return 2
        fi

        # Check cost limit (would need token counting from logs)
        # For now, this is a placeholder - real implementation would
        # parse Claude's output for token usage

        sleep 10
    done

    # Session ended naturally
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo "SUPERVISOR: Session completed in ${duration}s"
    update_stats "$task_id" "$duration" "0" "false"

    return 0
}

# Check all limits before starting a task
check_limits() {
    local task_id="${1:-}"
    local all_ok=true

    load_config
    init_stats

    echo "Principal Skinner - Pre-flight Checks"
    echo "======================================"
    echo ""

    # Check cost
    if check_cost; then
        echo "[OK] Cost limit"
    else
        echo "[FAIL] Cost limit exceeded"
        all_ok=false
    fi

    # Check iterations if task specified
    if [[ -n "$task_id" ]]; then
        if check_iterations "$task_id"; then
            echo "[OK] Iteration limit for task $task_id"
        else
            echo "[FAIL] Iteration limit exceeded for task $task_id"
            all_ok=false
        fi
    fi

    echo ""
    if $all_ok; then
        echo "All checks passed - execution may proceed"
        return 0
    else
        echo "Some checks failed - execution blocked"
        return 1
    fi
}

# Show current limits and usage
show_status() {
    load_config
    init_stats

    echo "Principal Skinner - Supervisor Status"
    echo "======================================"
    echo ""
    echo "Configured Limits:"
    echo "  Max cost per run:      \$${MAX_COST}"
    echo "  Max duration per task: ${MAX_DURATION}s"
    echo "  Max iterations/task:   ${MAX_ITERATIONS}"
    echo "  Cost per 1K tokens:    \$${COST_PER_1K}"
    echo ""

    local total_cost=$(jq -r '.total_cost_usd' "$STATS_FILE")
    local total_duration=$(jq -r '.total_duration_sec' "$STATS_FILE")
    local total_tokens=$(jq -r '.total_tokens' "$STATS_FILE")
    local session_count=$(jq -r '.session_count' "$STATS_FILE")
    local terminated=$(jq -r '.terminated_sessions | length' "$STATS_FILE")

    echo "Current Usage:"
    echo "  Total cost:        \$$total_cost of \$$MAX_COST"
    echo "  Total duration:    ${total_duration}s"
    echo "  Total tokens:      $total_tokens"
    echo "  Sessions:          $session_count"
    echo "  Terminated:        $terminated"
    echo ""

    # Show per-task iterations
    echo "Task Iterations:"
    jq -r '.task_iterations | to_entries[] | "  \(.key): \(.value) of '"$MAX_ITERATIONS"'"' "$STATS_FILE" 2>/dev/null || echo "  (none)"
}

# Reset stats (for new run)
reset_stats() {
    rm -f "$STATS_FILE"
    init_stats
    echo "Supervisor stats reset"
}

# Main dispatch
case "${1:-}" in
    supervise)
        load_config
        shift
        supervise_session "$@"
        ;;
    check-limits)
        check_limits "${2:-}"
        ;;
    check-iterations)
        load_config
        check_iterations "$2"
        ;;
    check-cost)
        load_config
        check_cost
        ;;
    get-stats)
        get_stats
        ;;
    status)
        show_status
        ;;
    update-stats)
        load_config
        update_stats "$2" "$3" "${4:-0}" "${5:-false}"
        ;;
    reset)
        reset_stats
        ;;
    *)
        echo "Principal Skinner - Session Supervisor"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  supervise <pid> [task_id]   Monitor a session process"
        echo "  check-limits [task_id]      Check all limits before execution"
        echo "  check-iterations <task_id>  Check task iteration count"
        echo "  check-cost                  Check total cost against budget"
        echo "  get-stats                   Get raw stats JSON"
        echo "  status                      Show supervisor status"
        echo "  update-stats <task> <dur> [tokens] [terminated]"
        echo "  reset                       Reset all stats"
        exit 1
        ;;
esac
