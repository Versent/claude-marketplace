#!/bin/bash
# progress-handoff.sh - Manage rolling window progress for session handoff
#
# Implements context-aware handoff documents that prevent unbounded growth
# while preserving essential information for subsequent sessions.
#
# Usage:
#   ./progress-handoff.sh add <task_id> <summary>
#   ./progress-handoff.sh get-context
#   ./progress-handoff.sh get-recent [n]
#   ./progress-handoff.sh compact

set -e

FRINK_DIR=".frink"
PROGRESS_FILE="$FRINK_DIR/progress.txt"
FULL_HISTORY="$FRINK_DIR/progress-history.json"
CONFIG_FILE="$FRINK_DIR/config.yml"

# Default config
DEFAULT_WINDOW_SIZE=5
DEFAULT_MAX_LINES=20

# Load config
load_config() {
    WINDOW_SIZE=$DEFAULT_WINDOW_SIZE
    MAX_LINES=$DEFAULT_MAX_LINES

    if [[ -f "$CONFIG_FILE" ]]; then
        if command -v yq &> /dev/null; then
            WINDOW_SIZE=$(yq -r '.progress.rolling_window_size // 5' "$CONFIG_FILE" 2>/dev/null || echo "5")
            MAX_LINES=$(yq -r '.progress.max_summary_lines // 20' "$CONFIG_FILE" 2>/dev/null || echo "20")
        fi
    fi
}

# Initialize files
init_files() {
    mkdir -p "$FRINK_DIR"

    if [[ ! -f "$FULL_HISTORY" ]]; then
        echo '{"entries": [], "key_decisions": [], "blockers": []}' > "$FULL_HISTORY"
    fi

    if [[ ! -f "$PROGRESS_FILE" ]]; then
        cat > "$PROGRESS_FILE" << 'EOF'
# Professor Frink - Session Progress Notes

This file contains rolling context for session handoff.
Only the most recent task summaries are included to prevent context rot.

## Quick Status

*Updated automatically by Professor Frink*

---

EOF
    fi
}

# Add a task summary to progress
add_summary() {
    local task_id="$1"
    local summary="$2"
    local commit_hash="${3:-}"

    init_files
    load_config

    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Add to full history (JSON)
    local tmp_file=$(mktemp)
    jq --arg task_id "$task_id" \
       --arg summary "$summary" \
       --arg timestamp "$timestamp" \
       --arg commit "$commit_hash" '
        .entries += [{
            "task_id": $task_id,
            "summary": $summary,
            "timestamp": $timestamp,
            "commit": $commit
        }]
    ' "$FULL_HISTORY" > "$tmp_file" && mv "$tmp_file" "$FULL_HISTORY"

    # Regenerate rolling window progress file
    regenerate_progress
}

# Add a key decision to preserve across sessions
add_decision() {
    local decision="$1"
    local context="${2:-}"

    init_files

    local tmp_file=$(mktemp)
    jq --arg decision "$decision" \
       --arg context "$context" \
       --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
        .key_decisions += [{
            "decision": $decision,
            "context": $context,
            "timestamp": $timestamp
        }]
    ' "$FULL_HISTORY" > "$tmp_file" && mv "$tmp_file" "$FULL_HISTORY"

    regenerate_progress
}

# Add a blocker to track
add_blocker() {
    local blocker="$1"
    local status="${2:-open}"

    init_files

    local tmp_file=$(mktemp)
    jq --arg blocker "$blocker" \
       --arg status "$status" \
       --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
        .blockers += [{
            "description": $blocker,
            "status": $status,
            "timestamp": $timestamp
        }]
    ' "$FULL_HISTORY" > "$tmp_file" && mv "$tmp_file" "$FULL_HISTORY"

    regenerate_progress
}

# Regenerate the rolling window progress file
regenerate_progress() {
    load_config

    cat > "$PROGRESS_FILE" << 'HEADER'
# Professor Frink - Session Progress Notes

This file contains rolling context for session handoff.
Only the most recent task summaries are included to prevent context rot.

For full history, see .frink/progress-history.json

HEADER

    # Add quick status
    local total_tasks=$(jq -r '.entries | length' "$FULL_HISTORY")
    local last_task=$(jq -r '.entries[-1].task_id // "none"' "$FULL_HISTORY")

    echo "## Quick Status" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"
    echo "- **Total tasks completed**: $total_tasks" >> "$PROGRESS_FILE"
    echo "- **Last task**: $last_task" >> "$PROGRESS_FILE"
    echo "- **Updated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"

    # Add key decisions (always included)
    local decision_count=$(jq -r '.key_decisions | length' "$FULL_HISTORY")
    if [[ "$decision_count" -gt 0 ]]; then
        echo "## Key Decisions" >> "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
        jq -r '.key_decisions[] | "- **\(.decision)**\(if .context != "" then ": " + .context else "" end)"' "$FULL_HISTORY" >> "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
    fi

    # Add open blockers
    local blocker_count=$(jq -r '[.blockers[] | select(.status == "open")] | length' "$FULL_HISTORY")
    if [[ "$blocker_count" -gt 0 ]]; then
        echo "## Open Blockers" >> "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
        jq -r '.blockers[] | select(.status == "open") | "- \(.description)"' "$FULL_HISTORY" >> "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
    fi

    # Add recent task summaries (rolling window)
    echo "## Recent Tasks (last $WINDOW_SIZE)" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"

    jq -r --argjson window "$WINDOW_SIZE" '
        .entries | .[-$window:] | reverse | .[] |
        "### Task \(.task_id)\n\(.summary)\n\(if .commit != "" then "Commit: `" + .commit + "`\n" else "" end)"
    ' "$FULL_HISTORY" >> "$PROGRESS_FILE" 2>/dev/null || echo "*No tasks completed yet*" >> "$PROGRESS_FILE"

    echo "" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
    echo "" >> "$PROGRESS_FILE"
    echo "*This is a rolling window of the last $WINDOW_SIZE tasks. Full history in progress-history.json*" >> "$PROGRESS_FILE"
}

# Get context for next session (formatted for prompt injection)
get_context() {
    init_files

    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo "No progress notes available yet."
        return
    fi

    cat "$PROGRESS_FILE"
}

# Get recent N task summaries as JSON
get_recent() {
    local count="${1:-5}"

    init_files

    jq -r --argjson count "$count" '.entries | .[-$count:]' "$FULL_HISTORY"
}

# Compact history (remove old entries, keep summary)
compact_history() {
    local keep="${1:-50}"

    init_files

    local total=$(jq -r '.entries | length' "$FULL_HISTORY")

    if [[ "$total" -le "$keep" ]]; then
        echo "History has $total entries, no compaction needed (threshold: $keep)"
        return
    fi

    local to_remove=$((total - keep))

    # Create summary of removed entries
    local summary=$(jq -r --argjson n "$to_remove" '
        .entries[:$n] |
        "Compacted \($n) entries from tasks " +
        (.[0].task_id) + " to " + (.[-1].task_id)
    ' "$FULL_HISTORY")

    # Remove old entries
    local tmp_file=$(mktemp)
    jq --argjson keep "$keep" '
        .entries = .entries[-$keep:] |
        .compacted_at = (now | todate) |
        .compacted_count = (.compacted_count // 0) + ($keep | tonumber)
    ' "$FULL_HISTORY" > "$tmp_file" && mv "$tmp_file" "$FULL_HISTORY"

    echo "$summary"
    regenerate_progress
}

# Main dispatch
case "${1:-}" in
    add)
        add_summary "$2" "$3" "${4:-}"
        ;;
    add-decision)
        add_decision "$2" "${3:-}"
        ;;
    add-blocker)
        add_blocker "$2" "${3:-open}"
        ;;
    get-context)
        get_context
        ;;
    get-recent)
        get_recent "${2:-5}"
        ;;
    compact)
        compact_history "${2:-50}"
        ;;
    regenerate)
        regenerate_progress
        ;;
    *)
        echo "Progress Handoff - Rolling Window Context Manager"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  add <task_id> <summary> [commit]  Add task completion summary"
        echo "  add-decision <decision> [context] Add key decision to preserve"
        echo "  add-blocker <description> [status] Add blocker (status: open/resolved)"
        echo "  get-context                       Get formatted context for session"
        echo "  get-recent [n]                    Get last N task summaries as JSON"
        echo "  compact [keep]                    Compact history, keeping last N"
        echo "  regenerate                        Regenerate progress.txt from history"
        exit 1
        ;;
esac
