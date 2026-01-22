---
description: Run the autonomous task execution loop with fresh sessions per task. Use after /professor-frink:init to begin autonomous execution. Fails fast if required credentials are missing.
---

# /professor-frink:run - Run Autonomous Task Execution

You are starting the Professor Frink autonomous execution loop.

## Agent Selection (CRITICAL)

When spawning agents for task execution, you MUST use Professor Frink's dedicated agents:

| Phase | Subagent Type | DO NOT Use |
|-------|---------------|------------|
| Executor | `frink-executor` | ❌ `implementer` |
| Validator | `frink-validator` | ❌ `implementation-verifier` |
| Fixer | `frink-fixer` | - |

**IMPORTANT:**
- Use the Task tool with `subagent_type: "frink-executor"` (not "implementer")
- NEVER use agent-os agents for Professor Frink tasks - they have different protocols
- Frink agents are specifically designed for atomic, single-task execution with health checks
- These agents are registered in `.claude/agents/professor-frink/`

## Prerequisites

Before running, verify:
1. `.frink/state.json` exists (run `/professor-frink:init` first if not)
2. Task context files exist in `.frink/context/`
3. No pending HITL checkpoints requiring approval

## Git Commit Protocol (MANDATORY)

**Every subtask MUST be committed atomically.** This is a non-negotiable requirement.

| Task | Commit Required |
|------|-----------------|
| 1.1 Initialize monorepo | YES - separate commit |
| 1.2 Configure TypeScript | YES - separate commit |
| 1.3 Set up .nvmrc | YES - separate commit |
| ... | ... |

### Why Atomic Commits?

1. **Easy Rollback**: `git revert <commit>` undoes exactly one task
2. **Audit Trail**: Clear history of what changed for each task
3. **Recovery**: If task 1.5 fails, tasks 1.1-1.4 are safely committed
4. **Code Review**: Each commit is reviewable in isolation

### Commit Format

```
<type>(<scope>): <description>

- Change 1
- Change 2

Task: X.Y
Refs: tasks.md

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Types:** feat, fix, chore, docs, refactor, test, ci
**Scopes:** web, functions, lib, infra, ci, config, deps

### Rollback Commands

```bash
# Undo last task
git revert HEAD

# Reset to specific task (e.g., back to 1.3)
git log --oneline | grep "Task: 1.3"
git reset --hard <commit-hash>

# View task history
git log --oneline --grep="Task:"
```

## Execution Flow

### 0. Present Execution Plan (HITL Required)

**CRITICAL:** Before executing any tasks, present the execution plan and wait for human approval.

Read `.frink/state.json` first, then present:

```markdown
================================================================================
PROFESSOR FRINK - EXECUTION PLAN
================================================================================

## Current State

**Project:** [name from state.json]
**Status:** [execution.status from state.json]
**Progress:** [completed_tasks] / [total_tasks] tasks completed

## What I Plan To Execute

### Starting Point
- **Task Group:** [current or next task group]
- **Task:** [current or next task]
- **Reason:** [Resuming from checkpoint / Starting fresh / etc.]

### Task Groups to Execute

| # | Task Group | Tasks | Status | Credentials |
|---|------------|-------|--------|-------------|
| 1 | Repository Foundation | 10 | ✅ Complete | None |
| 2 | AWS Infrastructure | 13 | ⏳ Next | AWS profile |
| 3 | Local Development | 10 | Pending | None |
| ... | ... | ... | ... | ... |

### HITL Checkpoints
The following checkpoints will pause for your approval:
- After Task Group 2: "Review infrastructure before backend"
- After Task Group 6: "Verify authentication setup"
- [other checkpoints from checkpoints.yml]

### Execution Approach
For each task, I will:
1. **Health Check** - Verify environment (lint, tests, types pass)
2. **Implement** - Execute the task per acceptance criteria
3. **Commit** - Create atomic git commit with task ID
4. **Validate** - Run full validation suite
5. **Self-Heal** - Fix any issues autonomously
6. **Progress** - Update state and move to next task

### Credential Status
| Credential | Status | Needed From |
|------------|--------|-------------|
| AWS_PROFILE | ✅ Available (gazzwi86) | Task Group 2 |
| AZURE_AD_* | ⚠️ Deferred | Task Group 6 |

### Estimated Scope
- Tasks remaining: [X]
- Task groups remaining: [Y]
- HITL checkpoints ahead: [Z]

================================================================================
```

**Use AskUserQuestion to get approval:**

```
Question: "Ready to begin autonomous execution?"
Options:
- "Yes, start execution" (proceed with execution)
- "Review state first" (display state.json contents for review)
- "Cancel" (abort execution)
```

**If user selects "Review state first":**
1. Display the contents of `.frink/state.json`
2. Display the contents of `.frink/checkpoints.yml`
3. Re-ask the question

**If user selects "Cancel":** Output "Execution cancelled." and stop.

---

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
- Update progress artifacts

**Executor Phase 3: Atomic Commit (REQUIRED)**
After task implementation, IMMEDIATELY create an atomic git commit:

```bash
git add <specific-files-changed>
git commit -m "$(cat <<'EOF'
feat(scope): task description

- Change 1
- Change 2
- Change 3

Task: X.Y
Refs: tasks.md

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

**IMPORTANT:** Each subtask (e.g., 1.1, 1.2, 1.3) MUST have its own commit. This enables:
- Easy rollback to any task boundary with `git revert` or `git reset`
- Clear audit trail of changes per task
- Isolation of changes for code review
- Recovery from failed tasks without losing prior work

The commit message MUST include:
- Task ID in the body (e.g., "Task: 1.4")
- Conventional commit format (feat/fix/chore/etc.)
- Appropriate scope (web, functions, lib, infra, config)

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
3. Log validation results to `.frink/validation-history.json`

**Note:** The git commit was already created in Step 5 (Executor Phase 3).
If the validator made additional fixes, commit those as a separate fixup commit:

```bash
git commit -m "fix(scope): address validation issues for task X.Y

- Fixed lint error in file.ts
- Corrected type annotation

Task: X.Y (validation fixes)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

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
