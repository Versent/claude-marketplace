---
description: Run the autonomous task execution loop with fresh sessions per task. Use after /professor-frink:init to begin autonomous execution. Fails fast if required credentials are missing.
---

# /professor-frink:run - Run Autonomous Task Execution

You are starting the Professor Frink autonomous execution loop.

## Prerequisites

Before running, verify:
1. `.frink/state.json` exists (run `/professor-frink:init` first if not)
2. Task context files exist in `.frink/context/`
3. No pending HITL checkpoints requiring approval

## Execution Flow

### 1. Load Current State and Verify Prerequisites

Read `.frink/state.json` to determine:
- Current task group and task ID
- Previously completed tasks
- Session statistics
- **Required credentials for the next task group**

**FAIL FAST CHECK:** If `.frink/state.json` does not exist:
```
ERROR: Professor Frink not initialized.

Run `/professor-frink:init` first to:
- Parse tasks from Agent-OS specs
- Set up credential requirements
- Create execution state

Then run `/professor-frink:run` again.
```

### 2. Credential Validation (FAIL FAST)

**Before entering each task group**, check that all required credentials are available.

Read the `required_credentials` array from the task group in state.json:

```json
{
  "id": 2,
  "name": "AWS Infrastructure",
  "required_credentials": ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_REGION"],
  "tasks": [...]
}
```

For each required credential:
1. Check if the environment variable is set
2. Optionally verify it works (e.g., `aws sts get-caller-identity`)

**If ANY required credential is missing, FAIL IMMEDIATELY:**

```
CREDENTIAL CHECK FAILED

Task Group 2 (AWS Infrastructure) requires the following credentials:

  MISSING: AWS_ACCESS_KEY_ID
  MISSING: AWS_SECRET_ACCESS_KEY
  OK:      AWS_REGION (ap-southeast-2)

See .frink/credentials.yml for setup instructions:

  AWS_ACCESS_KEY_ID:
    Option 1 - IAM User:
      1. AWS Console > IAM > Users > [Your User]
      2. Security Credentials > Create Access Key
      3. export AWS_ACCESS_KEY_ID=AKIA...

    Option 2 - AWS SSO:
      1. aws sso login --profile your-profile
      2. export AWS_PROFILE=your-profile

After configuring credentials, run `/professor-frink:run` again.
```

**DO NOT** attempt to proceed without required credentials. This prevents:
- Confusing errors mid-execution
- Partial state from failed operations
- Wasted time on tasks that will fail

### 3. Tool Verification (FAIL FAST)

Before entering a task group, verify required tools are installed:

```bash
# Check tools needed for this task group
command -v docker >/dev/null 2>&1 || echo "MISSING: docker"
command -v terraform >/dev/null 2>&1 || echo "MISSING: terraform"
```

**If required tools are missing:**

```
TOOL CHECK FAILED

Task Group 2 (AWS Infrastructure) requires:

  MISSING: terraform
    Install: brew install terraform
    Verify:  terraform --version

  OK: aws (2.33.3)

Install missing tools and run `/professor-frink:run` again.
```

### 4. Check for HITL Checkpoint

Before starting the next task, check if a checkpoint is configured:

```yaml
# .frink/checkpoints.yml
checkpoints:
  - id: post_initialization
    trigger: after_task_group_1
    required: true
```

If checkpoint is reached:
1. Pause execution
2. Display checkpoint details to user
3. Wait for `/professor-frink:approve` or `/professor-frink:amend`
4. Log decision to `.frink/checkpoint-history.json`

### 5. Spawn Executor Session

For the current task, spawn a fresh Claude Code session:

```bash
# Build the session prompt
./lib/session-spawner.sh --task "1.1" --mode executor
```

The executor session receives:
- Task context from `.frink/context/task-group-{id}-context.md`
- Progress notes from `.frink/progress.txt`
- HITL feedback from `.frink/HITL_FEEDBACK.md` (if any)

**Executor Phase 1: Environment Health Check**
Before implementing, the executor:
1. Runs lint (`npm run lint` or equivalent)
2. Runs tests (`npm test` or equivalent)
3. Runs type check (`npm run typecheck` or equivalent)

If environment is unhealthy:
- Spawn **Fixer Agent** to repair pre-existing issues
- Fixer reads spec context to repair in alignment with project standards
- Re-verify environment is clean before proceeding

**Executor Phase 2: Task Implementation**
- Implement the task per acceptance criteria
- Commit changes with descriptive message
- Update progress artifacts

### 6. Spawn Validator Session

After executor completes, spawn validator in fresh session:

```bash
./lib/session-spawner.sh --task "1.1" --mode validator
```

The validator runs full validation suite:
1. **Acceptance Criteria**: Check all criteria from tasks.md
2. **Spec Alignment**: Verify changes align with spec.md
3. **Test Execution**: Run full test suite
4. **Lint**: Run linting, check for violations
5. **Type Check**: Run type checking

**On Validation Failure (Self-Healing):**
1. Validator fixes issues itself (same fresh session)
2. Validator has full context: spec, AC, git diff, error output
3. Makes targeted fixes based on specific failures
4. Re-validates after fix
5. Repeats until ALL checks pass
6. NO HITL for code issues - fully autonomous

### 7. Save Progress Artifacts

After validation passes:
1. Update `.frink/state.json` with task completion
2. Write session notes to `.frink/progress.txt`
3. Commit changes to git
4. Log validation results to `.frink/validation-history.json`

### 8. Loop to Next Task

Continue to Step 2 for the next task in queue.

**When entering a NEW task group:**
- Re-run credential validation for the new group's requirements
- Re-run tool verification
- Check for HITL checkpoints

## Session Spawning

Each task runs in a **fresh context window**:

```bash
# Executor session
claude --prompt "$(cat .frink/prompts/executor-prompt.md)" \
  --max-turns 50 \
  --allowedTools "Bash,Read,Write,Edit,Glob,Grep"

# Validator session
claude --prompt "$(cat .frink/prompts/validator-prompt.md)" \
  --max-turns 30 \
  --allowedTools "Bash,Read,Write,Edit,Glob,Grep"
```

This ensures:
- Each session starts with clean context
- No context rot from accumulated history
- Focused execution on single task

## Monitoring Output

During execution, display:

```
Professor Frink - Autonomous Execution

═══════════════════════════════════════════════════════════════
STARTING TASK GROUP 1: Repository Foundation
═══════════════════════════════════════════════════════════════

[PREFLIGHT] Checking credentials for Task Group 1...
[PREFLIGHT] No credentials required - proceeding

[PREFLIGHT] Checking tools for Task Group 1...
[PREFLIGHT] node v20.18.0 - OK
[PREFLIGHT] npm 11.8.0 - OK
[PREFLIGHT] All tools available - proceeding

---

Current Task: 1.1 Initialize monorepo structure
Task Group: Repository Foundation (1 of 10)
Session: Executor #1

[HEALTH CHECK] Running environment validation...
[HEALTH CHECK] Lint: SKIP (no config yet)
[HEALTH CHECK] Tests: SKIP (no tests yet)
[HEALTH CHECK] Types: SKIP (no tsconfig yet)

[EXECUTOR] Implementing task...
[EXECUTOR] Created /package.json
[EXECUTOR] Created /apps/web/package.json
[EXECUTOR] Running verify command...
[EXECUTOR] Task implementation complete.

[VALIDATOR] Running validation suite...
[VALIDATOR] Acceptance Criteria: PASS (3/3)
[VALIDATOR] Spec Alignment: PASS
[VALIDATOR] Tests: N/A
[VALIDATOR] Lint: N/A
[VALIDATOR] Types: N/A

Task 1.1 COMPLETE - Moving to 1.2

---

═══════════════════════════════════════════════════════════════
ENTERING TASK GROUP 2: AWS Infrastructure
═══════════════════════════════════════════════════════════════

[PREFLIGHT] Checking credentials for Task Group 2...
[PREFLIGHT] AWS_ACCESS_KEY_ID - OK
[PREFLIGHT] AWS_SECRET_ACCESS_KEY - OK
[PREFLIGHT] AWS_REGION - OK (ap-southeast-2)
[PREFLIGHT] Verifying AWS access...
[PREFLIGHT] AWS Identity: arn:aws:iam::123456789:user/deploy
[PREFLIGHT] All credentials valid - proceeding

[PREFLIGHT] Checking tools for Task Group 2...
[PREFLIGHT] terraform 1.14.3 - OK
[PREFLIGHT] aws 2.33.3 - OK
[PREFLIGHT] All tools available - proceeding

---

Current Task: 2.1 Write Terraform validation tests
...
```

## Interrupt Handling

If execution is interrupted:
1. State is preserved in `.frink/state.json`
2. Run `/professor-frink:run` again to resume from last completed task
3. Partial work from interrupted task may need manual review

## Completion

When all tasks are complete:

```
Professor Frink - Execution Complete

Total Tasks: 132
Completed: 132
Failed: 0
Sessions Spawned: 264 (132 executor + 132 validator)

All acceptance criteria verified.
All tests passing.
All lint checks clean.

Project is ready for review.
```

## Error Handling Summary

| Condition | Behavior |
|-----------|----------|
| `.frink/state.json` missing | FAIL with "run init first" message |
| Required credential missing | FAIL with setup instructions from credentials.yml |
| Required tool missing | FAIL with install instructions |
| HITL checkpoint reached | PAUSE and wait for approval |
| Validation failure | Self-heal (no HITL) |
| Unrecoverable error | FAIL with context for manual intervention |
