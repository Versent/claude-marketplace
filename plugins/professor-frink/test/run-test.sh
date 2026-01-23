#!/bin/bash
# run-test.sh - Test Professor Frink with the sample project
#
# Usage: ./run-test.sh [init|run|status|clean]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
SAMPLE_PROJECT="$SCRIPT_DIR/sample-project"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Test: Verify all scripts are executable
test_scripts_executable() {
    print_header "Testing: Scripts are executable"

    local scripts=(
        "$PLUGIN_DIR/bin/frink-orchestrator.sh"
        "$PLUGIN_DIR/lib/session-spawner.sh"
        "$PLUGIN_DIR/lib/progress-tracker.sh"
        "$PLUGIN_DIR/lib/principal-skinner.sh"
        "$PLUGIN_DIR/lib/progress-handoff.sh"
        "$PLUGIN_DIR/lib/checkpoint-manager.sh"
        "$PLUGIN_DIR/lib/credential-validator.sh"
        "$PLUGIN_DIR/lib/task-parser.sh"
    )

    local failed=0
    for script in "${scripts[@]}"; do
        if [[ -x "$script" ]]; then
            echo -e "  ${GREEN}[OK]${NC} $(basename "$script")"
        else
            echo -e "  ${RED}[FAIL]${NC} $(basename "$script") - not executable"
            ((failed++))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Fixing permissions...${NC}"
        chmod +x "$PLUGIN_DIR/bin/"*.sh "$PLUGIN_DIR/lib/"*.sh 2>/dev/null || true
    fi

    return $failed
}

# Test: Verify jq is installed
test_dependencies() {
    print_header "Testing: Dependencies"

    local deps=("jq" "git" "bash")
    local failed=0

    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo -e "  ${GREEN}[OK]${NC} $dep"
        else
            echo -e "  ${RED}[FAIL]${NC} $dep - not installed"
            ((failed++))
        fi
    done

    # Check for claude CLI (optional for testing)
    if command -v claude &> /dev/null; then
        echo -e "  ${GREEN}[OK]${NC} claude CLI"
    else
        echo -e "  ${YELLOW}[WARN]${NC} claude CLI - not installed (needed for full test)"
    fi

    return $failed
}

# Test: Initialize in sample project
test_init() {
    print_header "Testing: Initialization"

    cd "$SAMPLE_PROJECT"

    # Clean previous state
    rm -rf .frink

    # Run task parser test
    echo "Testing task parser..."
    if "$PLUGIN_DIR/lib/task-parser.sh" agent-os/specs/phase-1/tasks.md --output json > /dev/null 2>&1; then
        echo -e "  ${GREEN}[OK]${NC} Task parser works"
    else
        echo -e "  ${RED}[FAIL]${NC} Task parser failed"
        return 1
    fi

    # Initialize state
    echo "Testing state initialization..."
    "$PLUGIN_DIR/lib/progress-tracker.sh" init agent-os/specs/phase-1/tasks.md

    if [[ -f ".frink/state.json" ]]; then
        echo -e "  ${GREEN}[OK]${NC} State file created"

        # Verify state structure
        local version=$(jq -r '.version' .frink/state.json)
        local total=$(jq -r '.total_tasks' .frink/state.json)

        echo "    Version: $version"
        echo "    Total tasks: $total"

        # Verify passes field exists
        local has_passes=$(jq -r '.task_queue[0].passes // "missing"' .frink/state.json)
        if [[ "$has_passes" == "false" ]]; then
            echo -e "  ${GREEN}[OK]${NC} Tasks have 'passes' field (Anthropic pattern)"
        else
            echo -e "  ${YELLOW}[WARN]${NC} Tasks missing 'passes' field"
        fi
    else
        echo -e "  ${RED}[FAIL]${NC} State file not created"
        return 1
    fi

    cd - > /dev/null
}

# Test: Principal Skinner supervisor
test_supervisor() {
    print_header "Testing: Principal Skinner Supervisor"

    cd "$SAMPLE_PROJECT"

    # Initialize stats
    "$PLUGIN_DIR/lib/principal-skinner.sh" reset

    # Test check-limits
    echo "Testing limit checks..."
    if "$PLUGIN_DIR/lib/principal-skinner.sh" check-limits "1.1" > /dev/null 2>&1; then
        echo -e "  ${GREEN}[OK]${NC} check-limits works"
    else
        echo -e "  ${RED}[FAIL]${NC} check-limits failed"
    fi

    # Test update-stats
    echo "Testing stats update..."
    "$PLUGIN_DIR/lib/principal-skinner.sh" update-stats "1.1" "60" "1000" "false"

    local session_count=$(jq -r '.session_count' .frink/supervisor-stats.json 2>/dev/null || echo "0")
    if [[ "$session_count" -ge 1 ]]; then
        echo -e "  ${GREEN}[OK]${NC} Stats updated (sessions: $session_count)"
    else
        echo -e "  ${RED}[FAIL]${NC} Stats not updated"
    fi

    # Test iteration limit
    echo "Testing iteration limits..."
    "$PLUGIN_DIR/lib/principal-skinner.sh" update-stats "1.1" "60" "1000" "false"
    "$PLUGIN_DIR/lib/principal-skinner.sh" update-stats "1.1" "60" "1000" "false"

    if "$PLUGIN_DIR/lib/principal-skinner.sh" check-iterations "1.1" 2>&1 | grep -q "LIMIT_EXCEEDED"; then
        echo -e "  ${GREEN}[OK]${NC} Iteration limit enforced"
    else
        echo -e "  ${YELLOW}[WARN]${NC} Iteration limit may not be enforced"
    fi

    cd - > /dev/null
}

# Test: Progress handoff
test_progress_handoff() {
    print_header "Testing: Progress Handoff"

    cd "$SAMPLE_PROJECT"

    # Add some progress
    "$PLUGIN_DIR/lib/progress-handoff.sh" add "1.1" "Created project structure with package.json" "abc123"
    "$PLUGIN_DIR/lib/progress-handoff.sh" add "1.2" "Added TypeScript configuration" "def456"
    "$PLUGIN_DIR/lib/progress-handoff.sh" add-decision "Using Vitest for testing" "Faster than Jest"

    # Check progress file exists
    if [[ -f ".frink/progress.txt" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Progress file created"

        # Check rolling window
        if grep -q "Rolling window" .frink/progress.txt 2>/dev/null || grep -q "last 5" .frink/progress.txt 2>/dev/null; then
            echo -e "  ${GREEN}[OK]${NC} Rolling window documented"
        fi

        # Check key decisions preserved
        if grep -q "Key Decisions" .frink/progress.txt 2>/dev/null; then
            echo -e "  ${GREEN}[OK]${NC} Key decisions section present"
        fi
    else
        echo -e "  ${RED}[FAIL]${NC} Progress file not created"
    fi

    # Check history file
    if [[ -f ".frink/progress-history.json" ]]; then
        local entries=$(jq -r '.entries | length' .frink/progress-history.json)
        echo -e "  ${GREEN}[OK]${NC} History file created ($entries entries)"
    fi

    cd - > /dev/null
}

# Clean test artifacts
clean() {
    print_header "Cleaning test artifacts"

    rm -rf "$SAMPLE_PROJECT/.frink"
    echo -e "  ${GREEN}[OK]${NC} Removed .frink directory"
}

# Show test status
status() {
    print_header "Test Environment Status"

    echo "Plugin directory: $PLUGIN_DIR"
    echo "Sample project: $SAMPLE_PROJECT"
    echo ""

    if [[ -d "$SAMPLE_PROJECT/.frink" ]]; then
        echo "Sample project state:"
        "$PLUGIN_DIR/lib/progress-tracker.sh" status 2>/dev/null || echo "  (no state)"
    else
        echo "Sample project: not initialized"
    fi
}

# Run all tests
run_all_tests() {
    print_header "Professor Frink Test Suite"

    local failed=0

    test_dependencies || ((failed++))
    test_scripts_executable || ((failed++))
    test_init || ((failed++))
    test_supervisor || ((failed++))
    test_progress_handoff || ((failed++))

    echo ""
    print_header "Test Summary"

    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
    else
        echo -e "${RED}$failed test(s) failed${NC}"
    fi

    return $failed
}

# Main dispatch
case "${1:-all}" in
    all)
        run_all_tests
        ;;
    init)
        test_init
        ;;
    supervisor)
        test_supervisor
        ;;
    progress)
        test_progress_handoff
        ;;
    status)
        status
        ;;
    clean)
        clean
        ;;
    *)
        echo "Professor Frink Test Runner"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  all        Run all tests (default)"
        echo "  init       Test initialization only"
        echo "  supervisor Test Principal Skinner supervisor"
        echo "  progress   Test progress handoff"
        echo "  status     Show test environment status"
        echo "  clean      Remove test artifacts"
        ;;
esac
