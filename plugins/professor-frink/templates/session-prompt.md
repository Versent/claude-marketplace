# Professor Frink Session Template

This template is used to generate prompts for each Claude session.

## Variables

- `{{TASK_ID}}` - The task identifier (e.g., "2.1")
- `{{TASK_TITLE}}` - The task title
- `{{TASK_GROUP}}` - The task group name
- `{{SESSION_TYPE}}` - executor, validator, or fixer
- `{{TASK_CONTEXT}}` - Contents of task context file
- `{{PROGRESS_NOTES}}` - Contents of progress.txt
- `{{HITL_FEEDBACK}}` - Contents of HITL_FEEDBACK.md (if any)

## Executor Session Prompt

```markdown
# Task Executor Session

You are implementing task {{TASK_ID}}: {{TASK_TITLE}}

## Task Context

{{TASK_CONTEXT}}

## Progress Notes

{{PROGRESS_NOTES}}

## HITL Feedback

{{HITL_FEEDBACK}}

## Instructions

1. **Environment Health Check**
   Run lint, tests, and type check first.
   If any fail, output ENVIRONMENT_UNHEALTHY and stop.

2. **Implement the Task**
   Follow acceptance criteria and coding standards.

3. **Verify**
   Run verification commands from task context.

4. **Commit**
   Stage and commit changes with task ID in message.

5. **Complete**
   Output: <promise>TASK_{{TASK_ID}}_COMPLETE</promise>
```

## Validator Session Prompt

```markdown
# Task Validator Session (Self-Healing)

You are validating task {{TASK_ID}}: {{TASK_TITLE}}

## Task Context

{{TASK_CONTEXT}}

## Git Diff

{{GIT_DIFF}}

## Instructions

1. **Run Full Validation**
   - Check acceptance criteria
   - Verify spec alignment
   - Run tests, lint, type check

2. **Fix Any Failures**
   When checks fail, FIX them yourself.
   You are self-healing - do not return failures.

3. **Report**
   Output: VALIDATION COMPLETE: PASS
```

## Fixer Session Prompt

```markdown
# Task Fixer Session

You are fixing pre-existing issues before task {{TASK_ID}}.

## Error Output

{{ERROR_OUTPUT}}

## Standards Context

{{STANDARDS_CONTEXT}}

## Instructions

1. **Analyze Errors**
   Identify each issue type and affected file.

2. **Apply Fixes**
   Fix lint, type, and test issues.
   Align with project standards.

3. **Verify**
   Run all checks. All must pass.

4. **Report**
   Output: ENVIRONMENT_FIXED
```
