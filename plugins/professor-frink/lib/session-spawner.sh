#!/bin/bash
# session-spawner.sh - Spawn fresh Claude Code sessions for task execution
#
# Usage: ./session-spawner.sh --task <task_id> --mode <executor|validator|fixer>
#
# Spawns a new Claude Code session with the appropriate prompt and context.
# Integrates with Principal Skinner for supervision and safety limits.

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
TASK_ID=""
MODE=""
MAX_TURNS=50
FRINK_DIR=".frink"
CONTEXT_DIR="$FRINK_DIR/context"
PROMPTS_DIR="$FRINK_DIR/prompts"
LOGS_DIR="$FRINK_DIR/logs"
SUPERVISOR_ENABLED=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --task)
            TASK_ID="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --max-turns)
            MAX_TURNS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$TASK_ID" ]]; then
    echo "Error: --task is required" >&2
    exit 1
fi

if [[ -z "$MODE" ]]; then
    echo "Error: --mode is required (executor|validator|fixer)" >&2
    exit 1
fi

if [[ ! "$MODE" =~ ^(executor|validator|fixer)$ ]]; then
    echo "Error: Invalid mode '$MODE'. Must be: executor, validator, or fixer" >&2
    exit 1
fi

# Ensure directories exist
mkdir -p "$PROMPTS_DIR" "$LOGS_DIR"

# Get context file path
CONTEXT_FILE="$CONTEXT_DIR/task-$TASK_ID-context.md"
if [[ ! -f "$CONTEXT_FILE" && "$MODE" != "fixer" ]]; then
    echo "Error: Context file not found: $CONTEXT_FILE" >&2
    exit 1
fi

# Generate session prompt based on mode
generate_prompt() {
    local mode="$1"
    local task_id="$2"
    local prompt_file="$PROMPTS_DIR/$mode-$task_id-prompt.md"

    case $mode in
        executor)
            cat > "$prompt_file" << 'EXECUTOR_PROMPT'
# Task Executor Session

You are executing a single task from the Professor Frink task queue.

## Your Task Context

EXECUTOR_PROMPT
            cat "$CONTEXT_FILE" >> "$prompt_file"

            cat >> "$prompt_file" << 'EXECUTOR_PROMPT'

## Progress Notes

EXECUTOR_PROMPT
            if [[ -f "$FRINK_DIR/progress.txt" ]]; then
                cat "$FRINK_DIR/progress.txt" >> "$prompt_file"
            else
                echo "No previous progress notes." >> "$prompt_file"
            fi

            cat >> "$prompt_file" << 'EXECUTOR_PROMPT'

## HITL Feedback

EXECUTOR_PROMPT
            if [[ -f "$FRINK_DIR/HITL_FEEDBACK.md" ]]; then
                cat "$FRINK_DIR/HITL_FEEDBACK.md" >> "$prompt_file"
            else
                echo "No HITL feedback." >> "$prompt_file"
            fi

            cat >> "$prompt_file" << 'EXECUTOR_PROMPT'

## Execution Instructions

1. **FIRST: Run Environment Health Check**
   ```bash
   npm run lint 2>&1 || echo "LINT_FAILED"
   npm test 2>&1 || echo "TESTS_FAILED"
   npm run typecheck 2>&1 || echo "TYPES_FAILED"
   ```

   If ANY check fails, output: `ENVIRONMENT_UNHEALTHY: <which_check>`
   and STOP. Do not proceed with implementation.

   If all pass, output: `ENVIRONMENT_HEALTHY` and continue.

2. **Implement the Task**
   - Follow the acceptance criteria exactly
   - Create/modify files as specified
   - Follow the coding standards in the context

3. **Verify Your Work**
   - Run the verification commands from the task
   - Ensure all acceptance criteria are met

4. **Commit and Complete**
   - Stage all changes: `git add -A`
   - Commit with descriptive message including the task ID
   - Output the completion promise: `<promise>TASK_X.X_COMPLETE</promise>`

5. **Update Progress**
   - Append notes to .frink/progress.txt about what you did

## Constraints
- Focus ONLY on this task
- Do NOT start other tasks
- Do NOT refactor unrelated code
- Keep changes minimal

EXECUTOR_PROMPT
            ;;

        validator)
            cat > "$prompt_file" << 'VALIDATOR_PROMPT'
# Task Validator Session (Self-Healing)

You are validating a task implementation and will FIX any issues you find.

## Task Context

VALIDATOR_PROMPT
            cat "$CONTEXT_FILE" >> "$prompt_file"

            cat >> "$prompt_file" << 'VALIDATOR_PROMPT'

## Git Diff (Changes to Validate)

```diff
VALIDATOR_PROMPT
            git diff HEAD~1 2>/dev/null >> "$prompt_file" || echo "No diff available" >> "$prompt_file"
            cat >> "$prompt_file" << 'VALIDATOR_PROMPT'
```

## Validation Instructions

You are a SELF-HEALING validator. When checks fail, you FIX them yourself.

1. **Run Full Validation Suite**

   a. **Acceptance Criteria Check**
      - Parse the acceptance criteria from the context above
      - Verify EACH criterion is satisfied
      - Note any that fail

   b. **Spec Alignment**
      - Compare implementation against spec requirements in context
      - Verify behavior matches spec intent

   c. **Run Tests**
      ```bash
      npm test
      ```

   d. **Run Lint**
      ```bash
      npm run lint
      ```

   e. **Run Type Check**
      ```bash
      npm run typecheck
      ```

2. **If ANY Check Fails: FIX IT**
   - Analyze the failure
   - Make targeted fixes
   - Re-run the failed check
   - Repeat until it passes

3. **Continue Until ALL Pass**
   - Loop through all checks
   - Fix any failures
   - Do NOT return to human for code issues
   - Only escalate if truly stuck in a loop

4. **Commit Fixes (if any)**
   ```bash
   git add -A
   git commit -m "fix: Address validation issues for task X.X"
   ```

5. **Report Completion**
   ```
   VALIDATION COMPLETE: PASS

   Checks:
   - Acceptance Criteria: PASS (N/N)
   - Spec Alignment: PASS
   - Tests: PASS
   - Lint: PASS
   - Types: PASS

   Self-Healing Applied: [list any fixes made]
   ```

## Key Principle
You do NOT return failures to the human. You fix issues yourself.
HITL checkpoints are for planned stage gates, not validation failures.

VALIDATOR_PROMPT
            ;;

        fixer)
            cat > "$prompt_file" << 'FIXER_PROMPT'
# Task Fixer Session

You are fixing pre-existing issues in the codebase so the executor can proceed.

## Error Output

The following errors were found during health check:

```
FIXER_PROMPT
            # Read error output from state file
            if [[ -f "$FRINK_DIR/health-check-errors.txt" ]]; then
                cat "$FRINK_DIR/health-check-errors.txt" >> "$prompt_file"
            else
                echo "No error file found" >> "$prompt_file"
            fi

            cat >> "$prompt_file" << 'FIXER_PROMPT'
```

## Spec Context

FIXER_PROMPT
            # Include relevant spec context if available
            if [[ -f "$CONTEXT_FILE" ]]; then
                grep -A 50 "## Relevant Standards" "$CONTEXT_FILE" >> "$prompt_file" 2>/dev/null || true
            fi

            cat >> "$prompt_file" << 'FIXER_PROMPT'

## Fixing Instructions

1. **Analyze the Errors**
   - Parse each error message
   - Identify affected files
   - Understand the issue type (lint, test, type)

2. **Fix Each Issue**
   - For lint: Try `npm run lint -- --fix` first, then manual fixes
   - For types: Check imports, annotations, and interfaces
   - For tests: Determine if test or implementation is wrong

3. **Align with Spec**
   - Fixes should align with project standards and spec
   - Don't change intended behavior
   - Keep fixes minimal

4. **Verify All Fixed**
   ```bash
   npm run lint
   npm test
   npm run typecheck
   ```
   All must pass.

5. **Commit Fixes**
   ```bash
   git add -A
   git commit -m "fix: Repair pre-existing issues before task X.X"
   ```

6. **Report Completion**
   ```
   ENVIRONMENT_FIXED

   Fixed Issues:
   - [list what was fixed]

   All checks now passing.
   ```

FIXER_PROMPT
            ;;
    esac

    echo "$prompt_file"
}

# Generate the prompt file
PROMPT_FILE=$(generate_prompt "$MODE" "$TASK_ID")

# Generate log file path
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOGS_DIR/session-$TASK_ID-$MODE-$TIMESTAMP.log"

# Build claude command
CLAUDE_CMD="claude"

# Check if claude command exists
if ! command -v claude &> /dev/null; then
    echo "Error: 'claude' command not found. Is Claude Code installed?" >&2
    exit 1
fi

# Output session info
echo "=========================================="
echo "Professor Frink Session"
echo "=========================================="
echo "Task:     $TASK_ID"
echo "Mode:     $MODE"
echo "Turns:    $MAX_TURNS"
echo "Prompt:   $PROMPT_FILE"
echo "Log:      $LOG_FILE"
echo "=========================================="
echo ""

# Pre-flight: Check with Principal Skinner
if [[ "$SUPERVISOR_ENABLED" == "true" && -f "$SCRIPT_DIR/principal-skinner.sh" ]]; then
    echo "Checking supervisor limits..."
    if ! "$SCRIPT_DIR/principal-skinner.sh" check-iterations "$TASK_ID" >/dev/null 2>&1; then
        echo "ERROR: Task $TASK_ID has exceeded iteration limit"
        echo "Run '$SCRIPT_DIR/principal-skinner.sh status' for details"
        exit 3  # Special exit code for iteration limit
    fi

    if ! "$SCRIPT_DIR/principal-skinner.sh" check-cost >/dev/null 2>&1; then
        echo "ERROR: Cost limit exceeded"
        echo "Run '$SCRIPT_DIR/principal-skinner.sh status' for details"
        exit 4  # Special exit code for cost limit
    fi
fi

# Spawn the session
# Note: The actual claude CLI syntax may vary - adjust as needed
echo "Starting Claude session..."

START_TIME=$(date +%s)

# Run claude with the prompt and capture output
# Use background process with supervisor monitoring if enabled
if [[ "$SUPERVISOR_ENABLED" == "true" && -f "$SCRIPT_DIR/principal-skinner.sh" ]]; then
    # Run claude in background so supervisor can monitor
    $CLAUDE_CMD --print "$(cat "$PROMPT_FILE")" \
        --max-turns "$MAX_TURNS" \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep,TodoWrite" \
        2>&1 | tee "$LOG_FILE" &

    CLAUDE_PID=$!

    # Supervisor monitors in background
    "$SCRIPT_DIR/principal-skinner.sh" supervise "$CLAUDE_PID" "$TASK_ID" &
    SUPERVISOR_PID=$!

    # Wait for claude to finish
    wait $CLAUDE_PID 2>/dev/null
    EXIT_CODE=$?

    # Kill supervisor if still running
    kill $SUPERVISOR_PID 2>/dev/null || true

    # Update stats
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    "$SCRIPT_DIR/principal-skinner.sh" update-stats "$TASK_ID" "$DURATION" "0" "false" 2>/dev/null || true
else
    # Run without supervisor
    $CLAUDE_CMD --print "$(cat "$PROMPT_FILE")" \
        --max-turns "$MAX_TURNS" \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep,TodoWrite" \
        2>&1 | tee "$LOG_FILE"

    EXIT_CODE=$?
fi

# Extract result from log
if grep -q "ENVIRONMENT_UNHEALTHY" "$LOG_FILE"; then
    echo ""
    echo "Result: ENVIRONMENT_UNHEALTHY"
    # Save errors for fixer
    grep -A 100 "LINT_FAILED\|TESTS_FAILED\|TYPES_FAILED" "$LOG_FILE" > "$FRINK_DIR/health-check-errors.txt"
    exit 10  # Special exit code for unhealthy environment
fi

if grep -q "ENVIRONMENT_FIXED" "$LOG_FILE"; then
    echo ""
    echo "Result: ENVIRONMENT_FIXED"
    exit 0
fi

if grep -q "TASK_${TASK_ID//./_}_COMPLETE\|TASK_.*_COMPLETE" "$LOG_FILE"; then
    echo ""
    echo "Result: TASK_COMPLETE"
    exit 0
fi

if grep -q "VALIDATION COMPLETE: PASS" "$LOG_FILE"; then
    echo ""
    echo "Result: VALIDATION_PASS"
    exit 0
fi

if grep -q "TASK_BLOCKED\|VALIDATION_STUCK\|VALIDATION_UNCLEAR" "$LOG_FILE"; then
    echo ""
    echo "Result: BLOCKED"
    exit 20  # Special exit code for blocked
fi

# If we get here, session ended without clear result
echo ""
echo "Result: UNKNOWN (check log for details)"
exit $EXIT_CODE
