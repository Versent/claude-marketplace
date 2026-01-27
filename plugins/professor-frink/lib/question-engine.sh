#!/bin/bash
# ==============================================================================
# Question Engine - Adaptive Question Batching for Professor Frink
# ==============================================================================
#
# Provides adaptive question generation and batching for init discovery phase.
# Questions adapt based on detected tech stack and prior answers.
#
# Usage:
#   source lib/question-engine.sh
#   question_engine_init
#   get_question_batch "tech_stack" 1
#   record_answer "q1" "option_a"
#   get_next_batch
#
# ==============================================================================

QUESTION_ENGINE_STATE_FILE=""
QUESTION_ENGINE_MODE="standard"  # quick (10), standard (25), comprehensive (45)

# Initialize the question engine
# Arguments:
#   $1 - State file path (typically .frink/question-state.json)
#   $2 - Mode: quick, standard, comprehensive
question_engine_init() {
    local state_file="${1:-.frink/question-state.json}"
    local mode="${2:-standard}"

    QUESTION_ENGINE_STATE_FILE="$state_file"
    QUESTION_ENGINE_MODE="$mode"

    # Create initial state
    cat > "$state_file" << 'EOF'
{
  "mode": "standard",
  "questions_asked": 0,
  "questions_limit": 25,
  "current_batch": 0,
  "current_category": "tech_stack",
  "detected_tech": {},
  "answers": {},
  "skipped_questions": [],
  "categories": ["tech_stack", "standards", "specifications", "tasks", "deep_dive"],
  "category_questions": {
    "tech_stack": 10,
    "standards": 10,
    "specifications": 10,
    "tasks": 10,
    "deep_dive": 5
  }
}
EOF

    # Set questions limit based on mode
    local limit=25
    case "$mode" in
        quick) limit=10 ;;
        standard) limit=25 ;;
        comprehensive) limit=45 ;;
    esac

    jq --arg mode "$mode" --argjson limit "$limit" \
        '.mode = $mode | .questions_limit = $limit' \
        "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"

    echo "Question engine initialized: mode=$mode, limit=$limit"
}

# Record detected technology to adapt questions
# Arguments:
#   $1 - Tech category (frontend, backend, database, etc.)
#   $2 - Tech name (react, node, postgres, etc.)
record_detected_tech() {
    local category="$1"
    local tech="$2"

    jq --arg cat "$category" --arg tech "$tech" \
        '.detected_tech[$cat] = $tech' \
        "$QUESTION_ENGINE_STATE_FILE" > "${QUESTION_ENGINE_STATE_FILE}.tmp" && \
        mv "${QUESTION_ENGINE_STATE_FILE}.tmp" "$QUESTION_ENGINE_STATE_FILE"
}

# Record an answer to adapt follow-up questions
# Arguments:
#   $1 - Question ID
#   $2 - Answer value
record_answer() {
    local question_id="$1"
    local answer="$2"

    jq --arg qid "$question_id" --arg ans "$answer" \
        '.answers[$qid] = $ans | .questions_asked += 1' \
        "$QUESTION_ENGINE_STATE_FILE" > "${QUESTION_ENGINE_STATE_FILE}.tmp" && \
        mv "${QUESTION_ENGINE_STATE_FILE}.tmp" "$QUESTION_ENGINE_STATE_FILE"
}

# Mark a question as skipped (not relevant based on prior answers)
# Arguments:
#   $1 - Question ID
#   $2 - Reason for skipping
skip_question() {
    local question_id="$1"
    local reason="$2"

    jq --arg qid "$question_id" --arg reason "$reason" \
        '.skipped_questions += [{"id": $qid, "reason": $reason}]' \
        "$QUESTION_ENGINE_STATE_FILE" > "${QUESTION_ENGINE_STATE_FILE}.tmp" && \
        mv "${QUESTION_ENGINE_STATE_FILE}.tmp" "$QUESTION_ENGINE_STATE_FILE"
}

# Check if we should skip a question based on detected tech or prior answers
# Arguments:
#   $1 - Question ID
# Returns: 0 if should skip, 1 if should ask
should_skip_question() {
    local question_id="$1"

    # Get current state
    local state
    state=$(cat "$QUESTION_ENGINE_STATE_FILE")

    local detected_tech
    detected_tech=$(echo "$state" | jq -r '.detected_tech')

    local answers
    answers=$(echo "$state" | jq -r '.answers')

    # Example skip logic - adapt based on question ID patterns
    case "$question_id" in
        # Skip frontend questions if no frontend detected
        frontend_*)
            if [ "$(echo "$detected_tech" | jq -r '.frontend // empty')" = "" ]; then
                return 0
            fi
            ;;
        # Skip database questions if they chose "no database"
        database_*)
            if [ "$(echo "$answers" | jq -r '.database_choice // empty')" = "none" ]; then
                return 0
            fi
            ;;
        # Skip advanced testing if they chose minimal testing
        testing_advanced_*)
            if [ "$(echo "$answers" | jq -r '.testing_approach // empty')" = "minimal" ]; then
                return 0
            fi
            ;;
    esac

    return 1
}

# Get the number of questions remaining
get_questions_remaining() {
    local state
    state=$(cat "$QUESTION_ENGINE_STATE_FILE")

    local asked
    asked=$(echo "$state" | jq -r '.questions_asked')

    local limit
    limit=$(echo "$state" | jq -r '.questions_limit')

    echo $((limit - asked))
}

# Check if we have reached the question limit
# Returns: 0 if limit reached, 1 if more questions allowed
is_limit_reached() {
    local remaining
    remaining=$(get_questions_remaining)

    [ "$remaining" -le 0 ]
}

# Get the current category being processed
get_current_category() {
    jq -r '.current_category' "$QUESTION_ENGINE_STATE_FILE"
}

# Advance to the next category
advance_category() {
    local state
    state=$(cat "$QUESTION_ENGINE_STATE_FILE")

    local current
    current=$(echo "$state" | jq -r '.current_category')

    local categories
    categories=$(echo "$state" | jq -r '.categories[]' | tr '\n' ' ')

    local next=""
    local found_current=false

    for cat in $categories; do
        if [ "$found_current" = true ]; then
            next="$cat"
            break
        fi
        if [ "$cat" = "$current" ]; then
            found_current=true
        fi
    done

    if [ -n "$next" ]; then
        jq --arg cat "$next" '.current_category = $cat | .current_batch = 0' \
            "$QUESTION_ENGINE_STATE_FILE" > "${QUESTION_ENGINE_STATE_FILE}.tmp" && \
            mv "${QUESTION_ENGINE_STATE_FILE}.tmp" "$QUESTION_ENGINE_STATE_FILE"
        echo "$next"
    else
        echo ""  # No more categories
    fi
}

# Get questions allocated for current category based on mode
get_category_question_count() {
    local category="$1"
    local mode
    mode=$(jq -r '.mode' "$QUESTION_ENGINE_STATE_FILE")

    case "$mode" in
        quick)
            # Quick mode: 2-3 questions per category for first 3 categories
            case "$category" in
                tech_stack) echo 4 ;;
                standards) echo 3 ;;
                specifications) echo 3 ;;
                *) echo 0 ;;
            esac
            ;;
        standard)
            # Standard mode: 5-6 questions per category
            case "$category" in
                tech_stack) echo 6 ;;
                standards) echo 6 ;;
                specifications) echo 6 ;;
                tasks) echo 5 ;;
                deep_dive) echo 2 ;;
            esac
            ;;
        comprehensive)
            # Comprehensive mode: full allocation
            case "$category" in
                tech_stack) echo 10 ;;
                standards) echo 10 ;;
                specifications) echo 10 ;;
                tasks) echo 10 ;;
                deep_dive) echo 5 ;;
            esac
            ;;
    esac
}

# Generate question batch metadata for the agent to use
# Arguments:
#   $1 - Category
#   $2 - Batch number within category
get_question_batch_metadata() {
    local category="$1"
    local batch="$2"

    local state
    state=$(cat "$QUESTION_ENGINE_STATE_FILE")

    local detected_tech
    detected_tech=$(echo "$state" | jq -c '.detected_tech')

    local answers
    answers=$(echo "$state" | jq -c '.answers')

    local mode
    mode=$(echo "$state" | jq -r '.mode')

    local remaining
    remaining=$(get_questions_remaining)

    cat << EOF
{
  "category": "$category",
  "batch": $batch,
  "mode": "$mode",
  "questions_remaining": $remaining,
  "detected_tech": $detected_tech,
  "prior_answers": $answers,
  "batch_size": 4,
  "instructions": "Generate up to 4 adaptive questions for this batch. Skip questions that are redundant based on detected_tech or prior_answers. Each question should have 2-4 options plus automatic 'Other' support."
}
EOF
}

# Export summary of all answers for documentation generation
export_answers_summary() {
    local state
    state=$(cat "$QUESTION_ENGINE_STATE_FILE")

    echo "$state" | jq '{
        mode: .mode,
        total_questions: .questions_asked,
        detected_tech: .detected_tech,
        answers: .answers,
        skipped: (.skipped_questions | length)
    }'
}

# Get tiered mode descriptions for user selection
get_mode_descriptions() {
    cat << 'EOF'
{
  "modes": [
    {
      "id": "quick",
      "name": "Quick Mode",
      "questions": 10,
      "description": "Essential questions only. Best for simple projects or when you have detailed existing documentation.",
      "categories": ["tech_stack", "standards", "specifications"]
    },
    {
      "id": "standard",
      "name": "Standard Mode (Recommended)",
      "questions": 25,
      "description": "Balanced coverage of all areas. Good for most projects.",
      "categories": ["tech_stack", "standards", "specifications", "tasks", "deep_dive"]
    },
    {
      "id": "comprehensive",
      "name": "Comprehensive Mode",
      "questions": 45,
      "description": "Deep dive into all aspects. Best for complex projects or when specifications need significant refinement.",
      "categories": ["tech_stack", "standards", "specifications", "tasks", "deep_dive"]
    }
  ]
}
EOF
}

# Main entrypoint for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        init)
            question_engine_init "${2:-.frink/question-state.json}" "${3:-standard}"
            ;;
        modes)
            get_mode_descriptions
            ;;
        batch)
            get_question_batch_metadata "${2:-tech_stack}" "${3:-1}"
            ;;
        remaining)
            get_questions_remaining
            ;;
        summary)
            export_answers_summary
            ;;
        *)
            echo "Usage: $0 {init|modes|batch|remaining|summary}"
            echo ""
            echo "Commands:"
            echo "  init [state_file] [mode]  Initialize question engine"
            echo "  modes                      Show available modes"
            echo "  batch [category] [batch]   Get batch metadata"
            echo "  remaining                  Show questions remaining"
            echo "  summary                    Export answers summary"
            ;;
    esac
fi
