---
description: Cancel the current execution run. Use when you need to stop Professor Frink autonomous execution.
argument-hint: [reason]
---

# /professor-frink:cancel - Cancel Execution

Cancel the current Professor Frink execution run.

## Usage

```
/professor-frink:cancel
```

Or with reason:
```
/professor-frink:cancel "Need to restructure the task list"
```

## Behavior

### 1. Check Execution State

Read `.frink/state.json`:

```json
{
  "execution_state": "running",
  "current_task": "3.5",
  "current_session_type": "executor"
}
```

If not running:
```
No active execution to cancel.
Current state: IDLE

Last completed task: 3.4 Configure local DynamoDB
Completed at: 2026-01-22 10:45:00 AM
```

### 2. Confirm Cancellation

```
Cancel Execution?

Current State:
- Task: 3.5 Set up local S3 (LocalStack)
- Progress: 32/85 tasks (37.6%)
- Session: Executor #32 (in progress)

WARNING: Cancelling will:
- Terminate the current session
- Leave task 3.5 incomplete
- Preserve all completed work

Any uncommitted changes from the current session
may need manual review.

Confirm cancel? [y/N]
```

### 3. Terminate Current Session

If a session is running:
- Send interrupt signal to Claude CLI process
- Allow graceful shutdown (5s timeout)
- Force kill if needed

### 4. Update State

Update `.frink/state.json`:

```json
{
  "execution_state": "cancelled",
  "cancelled_at": "2026-01-22T11:30:00Z",
  "cancel_reason": "Need to restructure the task list",
  "last_completed_task": "3.4",
  "incomplete_task": "3.5"
}
```

### 5. Generate Cancel Report

```
Execution CANCELLED

Reason: Need to restructure the task list
Cancelled at: 2026-01-22 11:30:00 AM

Summary:
- Tasks Completed: 32/85 (37.6%)
- Last Completed: 3.4 Configure local DynamoDB
- Incomplete: 3.5 Set up local S3 (LocalStack)

Preserved State:
- All completed work committed to git
- State saved in .frink/state.json
- Logs available in .frink/logs/

To resume from last completed task:
  /professor-frink:run

To restart from a specific task:
  /professor-frink:run --from 3.5

To reinitialize completely:
  /professor-frink:init --reset
```

## Recovery Options

After cancellation:

1. **Resume**: Run `/professor-frink:run` to continue from last completed task
2. **Restart Task**: Run `/professor-frink:run --from 3.5` to retry the incomplete task
3. **Reset**: Run `/professor-frink:init --reset` to start over (preserves code, resets state)
4. **Manual Fix**: Review `.frink/logs/session-*` for the incomplete session

## Force Cancel

If normal cancel doesn't work:

```
/professor-frink:cancel --force
```

This will:
- Immediately kill any running processes
- Mark state as `force_cancelled`
- May leave working directory in inconsistent state
- Requires manual cleanup
