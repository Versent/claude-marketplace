# /professor-frink:amend - Amend Checkpoint with Feedback

Provide feedback at a HITL checkpoint before continuing execution.

## Usage

```
/professor-frink:amend "Your feedback here"
```

Or interactively:
```
/professor-frink:amend
> Please provide your feedback:
```

## Behavior

### 1. Check for Pending Checkpoint

Same as `/professor-frink:approve` - verify a checkpoint is pending.

### 2. Capture Feedback

Accept feedback as argument or prompt interactively:

```
HITL Checkpoint: pre_credentials

Description: Add API keys and secrets before infrastructure deployment

Required Setup:
- Add AWS_ACCESS_KEY_ID to .env
- Add AWS_SECRET_ACCESS_KEY to .env
- Configure SLACK_WEBHOOK_URL (optional)

Enter your feedback or instructions for the next session:
> I've added AWS credentials. Skip Slack for now, we'll add it later.
  Also, use us-west-2 region instead of us-east-1.
```

### 3. Write Feedback to HITL_FEEDBACK.md

Create/update `.frink/HITL_FEEDBACK.md`:

```markdown
# HITL Feedback

## Checkpoint: pre_credentials
**Amended at:** 2026-01-22 11:15:00 AM

### User Feedback
I've added AWS credentials. Skip Slack for now, we'll add it later.
Also, use us-west-2 region instead of us-east-1.

### Instructions for Next Session
- AWS credentials are now available in environment
- Skip Slack webhook configuration
- Use AWS region: us-west-2 (not us-east-1)
```

### 4. Log Amendment Decision

Write to `.frink/checkpoint-history.json`:

```json
{
  "checkpoints": [
    {
      "id": "pre_credentials",
      "status": "amended",
      "amended_at": "2026-01-22T11:15:00Z",
      "feedback": "I've added AWS credentials. Skip Slack for now...",
      "feedback_file": ".frink/HITL_FEEDBACK.md"
    }
  ]
}
```

### 5. Resume Execution with Context

```
Checkpoint AMENDED: pre_credentials

Feedback saved to: .frink/HITL_FEEDBACK.md

The next executor session will receive this feedback
as additional context for implementing upcoming tasks.

Resuming execution...
Next Task: 4.1 Create DynamoDB table definitions

Run `/professor-frink:status` to monitor progress.
```

## Feedback Integration

The feedback is loaded into the next executor session:

```markdown
# Task Context: 4.1 Create DynamoDB table definitions

## HITL Feedback (from checkpoint: pre_credentials)
- AWS credentials are now available in environment
- Skip Slack webhook configuration
- Use AWS region: us-west-2 (not us-east-1)

## Task Details
...
```

This ensures human guidance is incorporated into the execution flow.

## Examples

**Quick amend:**
```
/professor-frink:amend "Credentials added, proceed"
```

**Detailed instructions:**
```
/professor-frink:amend "I've configured AWS with a different account than planned.
Use account ID 123456789012. The S3 bucket should be named blu-prod-assets
instead of the default. Also add KMS encryption for all DynamoDB tables."
```

**Request changes:**
```
/professor-frink:amend "The TypeScript config needs adjustment. Please use
moduleResolution: bundler instead of node. Also enable verbatimModuleSyntax."
```
