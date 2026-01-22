# /professor-frink:approve - Approve HITL Checkpoint

Approve a pending HITL (Human-in-the-Loop) checkpoint to continue execution.

## Usage

```
/professor-frink:approve
```

Or with optional comment:
```
/professor-frink:approve "Looks good, proceed with infrastructure setup"
```

## Behavior

### 1. Check for Pending Checkpoint

Read `.frink/state.json` to find pending checkpoint:

```json
{
  "pending_checkpoint": {
    "id": "post_initialization",
    "description": "Review generated artifacts before implementation",
    "triggered_at": "2026-01-22T10:30:00Z"
  }
}
```

If no pending checkpoint:
```
No pending HITL checkpoint.
Current state: RUNNING (or IDLE)
```

### 2. Display Checkpoint Details

```
HITL Checkpoint: post_initialization

Description: Review generated artifacts before implementation
Triggered: 2026-01-22 10:30:00 AM
Trigger Point: After Task Group 1

What was completed:
- Repository Foundation (10 tasks)
- Monorepo structure initialized
- TypeScript configured
- ESLint and Prettier set up
- Git hooks configured

This checkpoint allows you to review the project foundation
before proceeding with infrastructure and backend work.

Ready to approve? (This will resume execution)
```

### 3. Log Approval Decision

Write to `.frink/checkpoint-history.json`:

```json
{
  "checkpoints": [
    {
      "id": "post_initialization",
      "status": "approved",
      "approved_at": "2026-01-22T10:45:00Z",
      "comment": "Looks good, proceed with infrastructure setup",
      "approved_by": "human"
    }
  ]
}
```

### 4. Clear Pending State

Update `.frink/state.json`:

```json
{
  "pending_checkpoint": null,
  "execution_state": "running"
}
```

### 5. Resume Execution

```
Checkpoint APPROVED: post_initialization

Resuming execution...
Next Task: 2.1 Create Terraform AWS provider configuration

Run `/professor-frink:status` to monitor progress.
```

## Related Commands

- `/professor-frink:amend` - Provide feedback before approving
- `/professor-frink:status` - Check current checkpoint status
- `/professor-frink:cancel` - Cancel execution entirely
