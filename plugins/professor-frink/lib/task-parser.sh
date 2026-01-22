#!/bin/bash
# task-parser.sh - Parse tasks from Agent-OS tasks.md files
#
# Usage: ./task-parser.sh <tasks_md_file> [--output json|list]
#
# Parses tasks.md format and outputs structured task data

set -e

TASKS_FILE="${1:-}"
OUTPUT_FORMAT="${2:---output}"
OUTPUT_VALUE="${3:-json}"

if [[ -z "$TASKS_FILE" ]]; then
    echo "Usage: $0 <tasks_md_file> [--output json|list]" >&2
    exit 1
fi

if [[ ! -f "$TASKS_FILE" ]]; then
    echo "Error: File not found: $TASKS_FILE" >&2
    exit 1
fi

# Parse tasks from markdown format
parse_tasks() {
    local file="$1"
    local current_group=""
    local current_group_num=""
    local tasks=()
    local task_id=""
    local task_title=""
    local in_task=false
    local task_content=""

    while IFS= read -r line; do
        # Match task group headers: "#### Task Group N: Name" or "### Task Group N: Name"
        if [[ "$line" =~ ^#{3,4}[[:space:]]+Task[[:space:]]+Group[[:space:]]+([0-9]+):?[[:space:]]*(.*) ]]; then
            current_group_num="${BASH_REMATCH[1]}"
            current_group="${BASH_REMATCH[2]}"
            continue
        fi

        # Match task lines: "- [ ] N.N Task title" or "- [x] N.N Task title"
        if [[ "$line" =~ ^-[[:space:]]+\[([[:space:]]|x|X)\][[:space:]]+([0-9]+\.[0-9]+)[[:space:]]+(.*) ]]; then
            # Save previous task if exists
            if [[ "$in_task" == true && -n "$task_id" ]]; then
                echo "{\"id\":\"$task_id\",\"title\":\"$task_title\",\"group\":\"$current_group\",\"group_num\":\"$current_group_num\",\"completed\":$task_completed}"
            fi

            local checkbox="${BASH_REMATCH[1]}"
            task_id="${BASH_REMATCH[2]}"
            task_title="${BASH_REMATCH[3]}"

            if [[ "$checkbox" == "x" || "$checkbox" == "X" ]]; then
                task_completed="true"
            else
                task_completed="false"
            fi

            in_task=true
            task_content=""
            continue
        fi

        # Also match "- [ ] N.N.N Task title" for sub-sub-tasks
        if [[ "$line" =~ ^-[[:space:]]+\[([[:space:]]|x|X)\][[:space:]]+([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+(.*) ]]; then
            if [[ "$in_task" == true && -n "$task_id" ]]; then
                echo "{\"id\":\"$task_id\",\"title\":\"$task_title\",\"group\":\"$current_group\",\"group_num\":\"$current_group_num\",\"completed\":$task_completed}"
            fi

            local checkbox="${BASH_REMATCH[1]}"
            task_id="${BASH_REMATCH[2]}"
            task_title="${BASH_REMATCH[3]}"

            if [[ "$checkbox" == "x" || "$checkbox" == "X" ]]; then
                task_completed="true"
            else
                task_completed="false"
            fi

            in_task=true
            task_content=""
            continue
        fi

        # Collect task content
        if [[ "$in_task" == true ]]; then
            task_content+="$line"$'\n'
        fi

    done < "$file"

    # Output last task
    if [[ "$in_task" == true && -n "$task_id" ]]; then
        echo "{\"id\":\"$task_id\",\"title\":\"$task_title\",\"group\":\"$current_group\",\"group_num\":\"$current_group_num\",\"completed\":$task_completed}"
    fi
}

# Parse task groups
parse_groups() {
    local file="$1"

    grep -E "^#{3,4}[[:space:]]+Task[[:space:]]+Group[[:space:]]+[0-9]+" "$file" | \
    while read -r line; do
        if [[ "$line" =~ ^#{3,4}[[:space:]]+Task[[:space:]]+Group[[:space:]]+([0-9]+):?[[:space:]]*(.*) ]]; then
            local num="${BASH_REMATCH[1]}"
            local name="${BASH_REMATCH[2]}"
            echo "{\"number\":$num,\"name\":\"$name\"}"
        fi
    done
}

# Count tasks in a group
count_tasks_in_group() {
    local file="$1"
    local group_num="$2"

    local in_group=false
    local count=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^#{3,4}[[:space:]]+Task[[:space:]]+Group[[:space:]]+([0-9]+) ]]; then
            if [[ "${BASH_REMATCH[1]}" == "$group_num" ]]; then
                in_group=true
            else
                in_group=false
            fi
        fi

        if [[ "$in_group" == true && "$line" =~ ^-[[:space:]]+\[[[:space:]x]\][[:space:]]+[0-9]+\.[0-9]+ ]]; then
            ((count++))
        fi
    done < "$file"

    echo "$count"
}

# Extract task details (acceptance criteria, files, verify, etc.)
extract_task_details() {
    local file="$1"
    local task_id="$2"

    local in_task=false
    local in_section=""
    local details=""

    while IFS= read -r line; do
        # Start of our task
        if [[ "$line" =~ ^-[[:space:]]+\[[[:space:]x]\][[:space:]]+${task_id}[[:space:]] ]]; then
            in_task=true
            continue
        fi

        # End at next task or group
        if [[ "$in_task" == true ]]; then
            if [[ "$line" =~ ^-[[:space:]]+\[[[:space:]x]\][[:space:]]+[0-9]+\.[0-9]+ ]]; then
                break
            fi
            if [[ "$line" =~ ^#{3,4}[[:space:]]+Task[[:space:]]+Group ]]; then
                break
            fi

            echo "$line"
        fi
    done < "$file"
}

# Main output
case "$OUTPUT_VALUE" in
    json)
        echo "{"
        echo "  \"tasks\": ["
        parse_tasks "$TASKS_FILE" | sed 's/^/    /' | sed '$ ! s/$/,/'
        echo "  ],"
        echo "  \"groups\": ["
        parse_groups "$TASKS_FILE" | sed 's/^/    /' | sed '$ ! s/$/,/'
        echo "  ]"
        echo "}"
        ;;
    list)
        parse_tasks "$TASKS_FILE" | while read -r task; do
            id=$(echo "$task" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
            title=$(echo "$task" | grep -o '"title":"[^"]*"' | cut -d'"' -f4)
            completed=$(echo "$task" | grep -o '"completed":[^,}]*' | cut -d':' -f2)
            if [[ "$completed" == "true" ]]; then
                echo "[x] $id $title"
            else
                echo "[ ] $id $title"
            fi
        done
        ;;
    ids)
        parse_tasks "$TASKS_FILE" | while read -r task; do
            echo "$task" | grep -o '"id":"[^"]*"' | cut -d'"' -f4
        done
        ;;
    incomplete)
        parse_tasks "$TASKS_FILE" | while read -r task; do
            completed=$(echo "$task" | grep -o '"completed":[^,}]*' | cut -d':' -f2)
            if [[ "$completed" != "true" ]]; then
                echo "$task" | grep -o '"id":"[^"]*"' | cut -d'"' -f4
            fi
        done
        ;;
    details)
        task_id="${4:-}"
        if [[ -z "$task_id" ]]; then
            echo "Usage: $0 <file> --output details <task_id>" >&2
            exit 1
        fi
        extract_task_details "$TASKS_FILE" "$task_id"
        ;;
    *)
        echo "Unknown output format: $OUTPUT_VALUE" >&2
        echo "Valid formats: json, list, ids, incomplete, details" >&2
        exit 1
        ;;
esac
