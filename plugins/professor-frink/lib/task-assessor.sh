#!/bin/bash
# ==============================================================================
# Task Assessor - Quality Scoring for Agent-OS Tasks
# ==============================================================================
#
# Analyzes tasks from agent-os/specs/*/tasks.md and generates quality scores
# to identify gaps in acceptance criteria, tech details, and test approaches.
#
# Usage:
#   source lib/task-assessor.sh
#   assess_tasks_file "agent-os/specs/phase-1/tasks.md"
#   get_assessment_report
#
# ==============================================================================

ASSESSMENT_OUTPUT_FILE=""

# Initialize the task assessor
# Arguments:
#   $1 - Output file for assessment (typically .frink/task-assessment.json)
task_assessor_init() {
    local output_file="${1:-.frink/task-assessment.json}"
    ASSESSMENT_OUTPUT_FILE="$output_file"

    cat > "$output_file" << 'EOF'
{
  "version": "1.0.0",
  "assessed_at": null,
  "files_assessed": [],
  "summary": {
    "total_tasks": 0,
    "average_score": 0,
    "tasks_by_score": {
      "excellent": 0,
      "good": 0,
      "fair": 0,
      "poor": 0
    }
  },
  "tasks": [],
  "improvement_suggestions": []
}
EOF

    # Update timestamp
    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.assessed_at = $ts' \
        "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
}

# Score a single task based on criteria
# Arguments:
#   $1 - Task ID
#   $2 - Task description
#   $3 - Has acceptance criteria (true/false)
#   $4 - Has tech details (true/false)
#   $5 - Has test approach (true/false)
#   $6 - Has dependencies (true/false)
#   $7 - Has effort estimate (true/false)
# Returns: JSON object with score and breakdown
score_task() {
    local task_id="$1"
    local description="$2"
    local has_ac="${3:-false}"
    local has_tech="${4:-false}"
    local has_test="${5:-false}"
    local has_deps="${6:-false}"
    local has_effort="${7:-false}"

    # Weights for scoring
    local ac_weight=25
    local tech_weight=25
    local test_weight=20
    local deps_weight=15
    local effort_weight=15

    local score=0
    local breakdown=""
    local missing=""

    # Calculate score
    if [ "$has_ac" = "true" ]; then
        score=$((score + ac_weight))
        breakdown="${breakdown}acceptance_criteria:${ac_weight},"
    else
        missing="${missing}acceptance_criteria,"
    fi

    if [ "$has_tech" = "true" ]; then
        score=$((score + tech_weight))
        breakdown="${breakdown}tech_details:${tech_weight},"
    else
        missing="${missing}tech_details,"
    fi

    if [ "$has_test" = "true" ]; then
        score=$((score + test_weight))
        breakdown="${breakdown}test_approach:${test_weight},"
    else
        missing="${missing}test_approach,"
    fi

    if [ "$has_deps" = "true" ]; then
        score=$((score + deps_weight))
        breakdown="${breakdown}dependencies:${deps_weight},"
    else
        missing="${missing}dependencies,"
    fi

    if [ "$has_effort" = "true" ]; then
        score=$((score + effort_weight))
        breakdown="${breakdown}effort_estimate:${effort_weight},"
    else
        missing="${missing}effort_estimate,"
    fi

    # Remove trailing commas
    breakdown="${breakdown%,}"
    missing="${missing%,}"

    # Determine score category
    local category="poor"
    if [ "$score" -ge 90 ]; then
        category="excellent"
    elif [ "$score" -ge 70 ]; then
        category="good"
    elif [ "$score" -ge 50 ]; then
        category="fair"
    fi

    cat << EOF
{
  "task_id": "$task_id",
  "description": "$description",
  "score": $score,
  "category": "$category",
  "breakdown": {
    "acceptance_criteria": $has_ac,
    "tech_details": $has_tech,
    "test_approach": $has_test,
    "dependencies": $has_deps,
    "effort_estimate": $has_effort
  },
  "missing": "$(echo "$missing" | tr ',' ' ' | xargs)"
}
EOF
}

# Add a task assessment to the output file
# Arguments:
#   $1 - Task JSON (from score_task)
add_task_assessment() {
    local task_json="$1"

    jq --argjson task "$task_json" \
        '.tasks += [$task]' \
        "$ASSESSMENT_OUTPUT_FILE" > "${ASSESSMENT_OUTPUT_FILE}.tmp" && \
        mv "${ASSESSMENT_OUTPUT_FILE}.tmp" "$ASSESSMENT_OUTPUT_FILE"
}

# Add an improvement suggestion
# Arguments:
#   $1 - Task ID
#   $2 - Suggestion type (acceptance_criteria, tech_details, test_approach, etc.)
#   $3 - Suggestion text
add_suggestion() {
    local task_id="$1"
    local suggestion_type="$2"
    local suggestion_text="$3"

    jq --arg id "$task_id" --arg type "$suggestion_type" --arg text "$suggestion_text" \
        '.improvement_suggestions += [{"task_id": $id, "type": $type, "suggestion": $text}]' \
        "$ASSESSMENT_OUTPUT_FILE" > "${ASSESSMENT_OUTPUT_FILE}.tmp" && \
        mv "${ASSESSMENT_OUTPUT_FILE}.tmp" "$ASSESSMENT_OUTPUT_FILE"
}

# Calculate and update summary statistics
update_summary() {
    local state
    state=$(cat "$ASSESSMENT_OUTPUT_FILE")

    local total
    total=$(echo "$state" | jq '.tasks | length')

    if [ "$total" -eq 0 ]; then
        return
    fi

    local avg_score
    avg_score=$(echo "$state" | jq '[.tasks[].score] | add / length | floor')

    local excellent
    excellent=$(echo "$state" | jq '[.tasks[] | select(.category == "excellent")] | length')

    local good
    good=$(echo "$state" | jq '[.tasks[] | select(.category == "good")] | length')

    local fair
    fair=$(echo "$state" | jq '[.tasks[] | select(.category == "fair")] | length')

    local poor
    poor=$(echo "$state" | jq '[.tasks[] | select(.category == "poor")] | length')

    jq --argjson total "$total" \
       --argjson avg "$avg_score" \
       --argjson excellent "$excellent" \
       --argjson good "$good" \
       --argjson fair "$fair" \
       --argjson poor "$poor" \
        '.summary = {
            "total_tasks": $total,
            "average_score": $avg,
            "tasks_by_score": {
                "excellent": $excellent,
                "good": $good,
                "fair": $fair,
                "poor": $poor
            }
        }' \
        "$ASSESSMENT_OUTPUT_FILE" > "${ASSESSMENT_OUTPUT_FILE}.tmp" && \
        mv "${ASSESSMENT_OUTPUT_FILE}.tmp" "$ASSESSMENT_OUTPUT_FILE"
}

# Generate a human-readable assessment report
get_assessment_report() {
    local state
    state=$(cat "$ASSESSMENT_OUTPUT_FILE")

    local total
    total=$(echo "$state" | jq -r '.summary.total_tasks')

    local avg
    avg=$(echo "$state" | jq -r '.summary.average_score')

    local excellent
    excellent=$(echo "$state" | jq -r '.summary.tasks_by_score.excellent')

    local good
    good=$(echo "$state" | jq -r '.summary.tasks_by_score.good')

    local fair
    fair=$(echo "$state" | jq -r '.summary.tasks_by_score.fair')

    local poor
    poor=$(echo "$state" | jq -r '.summary.tasks_by_score.poor')

    cat << EOF
================================================================================
TASK QUALITY ASSESSMENT
================================================================================

Summary
-------
Total Tasks Assessed: $total
Average Score: $avg/100

Distribution:
  Excellent (90-100): $excellent tasks
  Good (70-89):       $good tasks
  Fair (50-69):       $fair tasks
  Poor (<50):         $poor tasks

EOF

    # List tasks needing improvement
    local poor_tasks
    poor_tasks=$(echo "$state" | jq -r '.tasks[] | select(.category == "poor" or .category == "fair") | "  Task \(.task_id): \(.score)/100 - Missing: \(.missing)"')

    if [ -n "$poor_tasks" ]; then
        echo "Tasks Needing Improvement"
        echo "-------------------------"
        echo "$poor_tasks"
        echo ""
    fi

    # List top suggestions
    local suggestions
    suggestions=$(echo "$state" | jq -r '.improvement_suggestions[:5][] | "  [\(.task_id)] \(.type): \(.suggestion)"')

    if [ -n "$suggestions" ]; then
        echo "Top Improvement Suggestions"
        echo "---------------------------"
        echo "$suggestions"
        echo ""
    fi

    echo "================================================================================"
}

# Detect criteria presence in task text
# Arguments:
#   $1 - Task text block
# Returns: JSON with detected criteria
detect_task_criteria() {
    local task_text="$1"

    local has_ac=false
    local has_tech=false
    local has_test=false
    local has_deps=false
    local has_effort=false

    # Check for acceptance criteria indicators
    if echo "$task_text" | grep -qiE "(acceptance criteria|ac:|expected:|should|must|verify|when.*then)"; then
        has_ac=true
    fi

    # Check for tech details indicators
    if echo "$task_text" | grep -qiE "(implement|use|create|configure|setup|install|api|endpoint|component|function|class|module|package)"; then
        has_tech=true
    fi

    # Check for test approach indicators
    if echo "$task_text" | grep -qiE "(test|spec|verify|validate|check|assert|expect|coverage|e2e|unit|integration)"; then
        has_test=true
    fi

    # Check for dependency indicators
    if echo "$task_text" | grep -qiE "(depends|after|before|requires|prerequisite|blocked|dependency)"; then
        has_deps=true
    fi

    # Check for effort indicators
    if echo "$task_text" | grep -qiE "(hours?|days?|points?|effort|estimate|complexity|simple|medium|complex|trivial)"; then
        has_effort=true
    fi

    cat << EOF
{
  "has_acceptance_criteria": $has_ac,
  "has_tech_details": $has_tech,
  "has_test_approach": $has_test,
  "has_dependencies": $has_deps,
  "has_effort_estimate": $has_effort
}
EOF
}

# Generate suggestions based on missing criteria
# Arguments:
#   $1 - Task ID
#   $2 - Missing criteria (space-separated)
generate_suggestions() {
    local task_id="$1"
    local missing="$2"

    for criteria in $missing; do
        case "$criteria" in
            acceptance_criteria)
                add_suggestion "$task_id" "acceptance_criteria" \
                    "Add clear acceptance criteria with testable conditions (Given/When/Then format recommended)"
                ;;
            tech_details)
                add_suggestion "$task_id" "tech_details" \
                    "Specify implementation approach: technologies, patterns, file locations, and code structure"
                ;;
            test_approach)
                add_suggestion "$task_id" "test_approach" \
                    "Define how this task should be tested: unit tests, integration tests, manual verification steps"
                ;;
            dependencies)
                add_suggestion "$task_id" "dependencies" \
                    "Identify any tasks that must be completed before this one, or external dependencies"
                ;;
            effort_estimate)
                add_suggestion "$task_id" "effort_estimate" \
                    "Add complexity indicator or time estimate to help with planning"
                ;;
        esac
    done
}

# Mark a file as assessed
mark_file_assessed() {
    local file_path="$1"

    jq --arg file "$file_path" \
        '.files_assessed += [$file]' \
        "$ASSESSMENT_OUTPUT_FILE" > "${ASSESSMENT_OUTPUT_FILE}.tmp" && \
        mv "${ASSESSMENT_OUTPUT_FILE}.tmp" "$ASSESSMENT_OUTPUT_FILE"
}

# Get JSON output for agent consumption
get_assessment_json() {
    cat "$ASSESSMENT_OUTPUT_FILE"
}

# Get tasks below a certain score threshold
# Arguments:
#   $1 - Score threshold (default: 70)
get_low_score_tasks() {
    local threshold="${1:-70}"

    jq --argjson threshold "$threshold" \
        '[.tasks[] | select(.score < $threshold)]' \
        "$ASSESSMENT_OUTPUT_FILE"
}

# Main entrypoint for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        init)
            task_assessor_init "${2:-.frink/task-assessment.json}"
            echo "Task assessor initialized"
            ;;
        score)
            # score task_id description has_ac has_tech has_test has_deps has_effort
            score_task "$2" "$3" "${4:-false}" "${5:-false}" "${6:-false}" "${7:-false}" "${8:-false}"
            ;;
        detect)
            # Read task text from stdin
            detect_task_criteria "$(cat)"
            ;;
        report)
            get_assessment_report
            ;;
        json)
            get_assessment_json
            ;;
        low-score)
            get_low_score_tasks "${2:-70}"
            ;;
        *)
            echo "Usage: $0 {init|score|detect|report|json|low-score}"
            echo ""
            echo "Commands:"
            echo "  init [output_file]        Initialize assessor"
            echo "  score <task_id> <desc> [ac] [tech] [test] [deps] [effort]"
            echo "                            Score a task manually"
            echo "  detect                    Detect criteria from stdin"
            echo "  report                    Show human-readable report"
            echo "  json                      Output raw JSON"
            echo "  low-score [threshold]     Get tasks below threshold"
            ;;
    esac
fi
