#!/bin/bash
# checkpoint-manager.sh - Manage HITL checkpoints for Professor Frink
#
# Usage:
#   ./checkpoint-manager.sh check <task_id>       - Check if checkpoint needed before task
#   ./checkpoint-manager.sh trigger <checkpoint_id> - Trigger a checkpoint
#   ./checkpoint-manager.sh approve [comment]     - Approve pending checkpoint
#   ./checkpoint-manager.sh amend <feedback>      - Amend with feedback
#   ./checkpoint-manager.sh list                  - List all checkpoints
#   ./checkpoint-manager.sh history               - Show checkpoint history

set -e

FRINK_DIR=".frink"
CHECKPOINTS_FILE="$FRINK_DIR/checkpoints.yml"
HISTORY_FILE="$FRINK_DIR/checkpoint-history.json"
STATE_FILE="$FRINK_DIR/state.json"
FEEDBACK_FILE="$FRINK_DIR/HITL_FEEDBACK.md"

# Ensure yq is available for YAML parsing (or use simple grep)
parse_yaml_value() {
    local file="$1"
    local key="$2"
    grep -A1 "^[[:space:]]*$key:" "$file" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//'
}

# Initialize checkpoints file with defaults
init_checkpoints() {
    if [[ ! -f "$CHECKPOINTS_FILE" ]]; then
        mkdir -p "$FRINK_DIR"
        cat > "$CHECKPOINTS_FILE" << 'EOF'
# Professor Frink HITL Checkpoints
# These define when human review is required

checkpoints:
  - id: post_initialization
    description: "Review generated artifacts before implementation begins"
    trigger: after_task_group_1
    required: true

  - id: pre_credentials
    description: "Add API keys and secrets before infrastructure deployment"
    trigger: before_task_group_4
    required: true
    manual_setup:
      - "Add AWS_ACCESS_KEY_ID to environment"
      - "Add AWS_SECRET_ACCESS_KEY to environment"
      - "Configure any required API keys"

  - id: pre_deployment
    description: "Final review before production deployment"
    trigger: before_final_task
    required: true

# Checkpoint triggers:
#   after_task_group_N  - After completing task group N
#   before_task_group_N - Before starting task group N
#   after_task_X.Y      - After completing specific task
#   before_task_X.Y     - Before starting specific task
#   before_final_task   - Before the last task
EOF
        echo "Created default checkpoints file: $CHECKPOINTS_FILE"
    fi
}

# Initialize history file
init_history() {
    if [[ ! -f "$HISTORY_FILE" ]]; then
        echo '{"checkpoints": []}' > "$HISTORY_FILE"
    fi
}

# Check if a checkpoint should trigger before a task
check_checkpoint() {
    local task_id="$1"
    local task_group=""

    # Extract task group from task_id (e.g., "2.1" -> "2")
    task_group=$(echo "$task_id" | cut -d'.' -f1)

    init_checkpoints

    # Check for "before_task_X.Y" trigger
    if grep -q "trigger: before_task_$task_id" "$CHECKPOINTS_FILE" 2>/dev/null; then
        local checkpoint_id=$(grep -B3 "trigger: before_task_$task_id" "$CHECKPOINTS_FILE" | grep "id:" | sed 's/.*id:[[:space:]]*//')
        echo "$checkpoint_id"
        return 0
    fi

    # Check for "before_task_group_N" trigger
    # This should trigger on the first task of the group
    if [[ "$task_id" =~ ^${task_group}\.1$ || "$task_id" =~ ^${task_group}\.0$ ]]; then
        if grep -q "trigger: before_task_group_$task_group" "$CHECKPOINTS_FILE" 2>/dev/null; then
            local checkpoint_id=$(grep -B3 "trigger: before_task_group_$task_group" "$CHECKPOINTS_FILE" | grep "id:" | sed 's/.*id:[[:space:]]*//')
            echo "$checkpoint_id"
            return 0
        fi
    fi

    # Check for final task (would need to know total tasks)
    # For now, skip this check

    echo ""
    return 1
}

# Check if checkpoint should trigger after a task
check_checkpoint_after() {
    local task_id="$1"
    local task_group=""

    task_group=$(echo "$task_id" | cut -d'.' -f1)

    init_checkpoints

    # Check for "after_task_X.Y" trigger
    if grep -q "trigger: after_task_$task_id" "$CHECKPOINTS_FILE" 2>/dev/null; then
        local checkpoint_id=$(grep -B3 "trigger: after_task_$task_id" "$CHECKPOINTS_FILE" | grep "id:" | sed 's/.*id:[[:space:]]*//')
        echo "$checkpoint_id"
        return 0
    fi

    # Check for "after_task_group_N" trigger
    # Would need to know if this is the last task in the group
    # For simplicity, check state file for next task's group
    if [[ -f "$STATE_FILE" ]]; then
        local next_task=$(jq -r '
            .task_queue[] |
            select(.completed == false) |
            .id
        ' "$STATE_FILE" 2>/dev/null | head -1)

        if [[ -n "$next_task" ]]; then
            local next_group=$(echo "$next_task" | cut -d'.' -f1)
            if [[ "$next_group" != "$task_group" ]]; then
                # We're transitioning to a new group
                if grep -q "trigger: after_task_group_$task_group" "$CHECKPOINTS_FILE" 2>/dev/null; then
                    local checkpoint_id=$(grep -B3 "trigger: after_task_group_$task_group" "$CHECKPOINTS_FILE" | grep "id:" | sed 's/.*id:[[:space:]]*//')
                    echo "$checkpoint_id"
                    return 0
                fi
            fi
        fi
    fi

    echo ""
    return 1
}

# Trigger a checkpoint
trigger_checkpoint() {
    local checkpoint_id="$1"

    init_checkpoints
    init_history

    # Get checkpoint details
    local description=""
    local manual_setup=""

    # Simple extraction (would be better with proper YAML parser)
    description=$(grep -A2 "id: $checkpoint_id" "$CHECKPOINTS_FILE" | grep "description:" | sed 's/.*description:[[:space:]]*//' | tr -d '"')

    # Update state
    if [[ -f "$STATE_FILE" ]]; then
        local tmp_file=$(mktemp)
        jq --arg id "$checkpoint_id" --arg desc "$description" '
            .pending_checkpoint = {
                "id": $id,
                "description": $desc,
                "triggered_at": (now | todate)
            } |
            .execution_state = "paused"
        ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
    fi

    # Display checkpoint UI
    echo ""
    echo "========================================"
    echo "  HITL CHECKPOINT: $checkpoint_id"
    echo "========================================"
    echo ""
    echo "Description: $description"
    echo ""
    echo "Triggered at: $(date)"
    echo ""

    # Check for manual setup instructions
    if grep -A10 "id: $checkpoint_id" "$CHECKPOINTS_FILE" | grep -q "manual_setup:"; then
        echo "Manual Setup Required:"
        grep -A10 "id: $checkpoint_id" "$CHECKPOINTS_FILE" | grep -A5 "manual_setup:" | grep "^[[:space:]]*-" | sed 's/^[[:space:]]*-[[:space:]]*/  - /'
        echo ""
    fi

    echo "Actions:"
    echo "  /frink-approve          - Approve and continue"
    echo "  /frink-amend \"feedback\" - Add feedback and continue"
    echo "  /frink-cancel           - Cancel execution"
    echo ""
    echo "========================================"
}

# Approve pending checkpoint
approve_checkpoint() {
    local comment="${1:-}"

    init_history

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "Error: No state file found" >&2
        exit 1
    fi

    local checkpoint_id=$(jq -r '.pending_checkpoint.id // ""' "$STATE_FILE")

    if [[ -z "$checkpoint_id" || "$checkpoint_id" == "null" ]]; then
        echo "No pending checkpoint to approve."
        return 1
    fi

    # Log approval
    local tmp_file=$(mktemp)
    jq --arg id "$checkpoint_id" --arg comment "$comment" '
        .checkpoints += [{
            "id": $id,
            "status": "approved",
            "approved_at": (now | todate),
            "comment": $comment
        }]
    ' "$HISTORY_FILE" > "$tmp_file" && mv "$tmp_file" "$HISTORY_FILE"

    # Clear pending checkpoint
    tmp_file=$(mktemp)
    jq '
        .pending_checkpoint = null |
        .execution_state = "running"
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"

    echo ""
    echo "Checkpoint APPROVED: $checkpoint_id"
    if [[ -n "$comment" ]]; then
        echo "Comment: $comment"
    fi
    echo ""
    echo "Resuming execution..."
}

# Amend checkpoint with feedback
amend_checkpoint() {
    local feedback="$1"

    if [[ -z "$feedback" ]]; then
        echo "Error: Feedback required" >&2
        exit 1
    fi

    init_history

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "Error: No state file found" >&2
        exit 1
    fi

    local checkpoint_id=$(jq -r '.pending_checkpoint.id // ""' "$STATE_FILE")

    if [[ -z "$checkpoint_id" || "$checkpoint_id" == "null" ]]; then
        echo "No pending checkpoint to amend."
        return 1
    fi

    # Write feedback file
    cat > "$FEEDBACK_FILE" << EOF
# HITL Feedback

## Checkpoint: $checkpoint_id
**Amended at:** $(date)

### User Feedback
$feedback

### Instructions for Next Session
The following feedback should be incorporated into upcoming tasks:

$feedback
EOF

    # Log amendment
    local tmp_file=$(mktemp)
    jq --arg id "$checkpoint_id" --arg feedback "$feedback" '
        .checkpoints += [{
            "id": $id,
            "status": "amended",
            "amended_at": (now | todate),
            "feedback": $feedback
        }]
    ' "$HISTORY_FILE" > "$tmp_file" && mv "$tmp_file" "$HISTORY_FILE"

    # Clear pending checkpoint
    tmp_file=$(mktemp)
    jq '
        .pending_checkpoint = null |
        .execution_state = "running"
    ' "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"

    echo ""
    echo "Checkpoint AMENDED: $checkpoint_id"
    echo "Feedback saved to: $FEEDBACK_FILE"
    echo ""
    echo "Resuming execution with feedback incorporated..."
}

# List all checkpoints
list_checkpoints() {
    init_checkpoints

    echo "Configured Checkpoints"
    echo "======================"
    echo ""

    # Parse and display checkpoints
    local in_checkpoint=false
    local id=""
    local desc=""
    local trigger=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id: ]]; then
            if [[ -n "$id" ]]; then
                echo "[$id]"
                echo "  Description: $desc"
                echo "  Trigger: $trigger"
                echo ""
            fi
            id=$(echo "$line" | sed 's/.*id:[[:space:]]*//')
            desc=""
            trigger=""
        elif [[ "$line" =~ ^[[:space:]]*description: ]]; then
            desc=$(echo "$line" | sed 's/.*description:[[:space:]]*//' | tr -d '"')
        elif [[ "$line" =~ ^[[:space:]]*trigger: ]]; then
            trigger=$(echo "$line" | sed 's/.*trigger:[[:space:]]*//')
        fi
    done < "$CHECKPOINTS_FILE"

    # Output last checkpoint
    if [[ -n "$id" ]]; then
        echo "[$id]"
        echo "  Description: $desc"
        echo "  Trigger: $trigger"
        echo ""
    fi
}

# Show checkpoint history
show_history() {
    init_history

    echo "Checkpoint History"
    echo "=================="
    echo ""

    if [[ $(jq '.checkpoints | length' "$HISTORY_FILE") -eq 0 ]]; then
        echo "No checkpoints have been processed yet."
        return
    fi

    jq -r '.checkpoints[] | "[\(.status | ascii_upcase)] \(.id) at \(.approved_at // .amended_at)\n  \(.comment // .feedback // "No comment")\n"' "$HISTORY_FILE"
}

# Main command dispatch
case "${1:-}" in
    init)
        init_checkpoints
        init_history
        ;;
    check)
        check_checkpoint "$2"
        ;;
    check-after)
        check_checkpoint_after "$2"
        ;;
    trigger)
        trigger_checkpoint "$2"
        ;;
    approve)
        approve_checkpoint "$2"
        ;;
    amend)
        amend_checkpoint "$2"
        ;;
    list)
        list_checkpoints
        ;;
    history)
        show_history
        ;;
    *)
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  init                    Initialize checkpoints config"
        echo "  check <task_id>         Check for checkpoint before task"
        echo "  check-after <task_id>   Check for checkpoint after task"
        echo "  trigger <checkpoint_id> Trigger a checkpoint"
        echo "  approve [comment]       Approve pending checkpoint"
        echo "  amend <feedback>        Amend with feedback"
        echo "  list                    List configured checkpoints"
        echo "  history                 Show checkpoint history"
        exit 1
        ;;
esac
