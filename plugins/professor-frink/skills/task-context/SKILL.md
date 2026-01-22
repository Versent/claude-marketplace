# Task Context Skill

This skill loads the context file for the current task, providing focused information for the executor or validator session.

## Trigger

This skill is automatically invoked when a Professor Frink session starts, loading the appropriate context file.

## Usage

```
/task-context [task_id]
```

If no task_id is provided, uses the current task from `.frink/state.json`.

## Behavior

1. **Identify Current Task**
   - Read task ID from argument or state file
   - Locate context file: `.frink/context/task-{id}-context.md`

2. **Load Context**
   - Read the task context file
   - Display task details, acceptance criteria, and relevant standards

3. **Load Additional Context**
   - Check for HITL feedback: `.frink/HITL_FEEDBACK.md`
   - Check for progress notes: `.frink/progress.txt`

4. **Display Summary**
   ```
   Task Context Loaded

   Task: 2.1 Create Terraform AWS provider configuration
   Group: Infrastructure - Terraform (1 of 12)

   Acceptance Criteria:
   - [ ] Provider configuration for AWS
   - [ ] Backend configuration for state
   - [ ] Variables file for environment config

   Relevant Standards: 2 sections loaded
   HITL Feedback: None
   Progress Notes: 5 entries
   ```

## Context File Structure

Each task context file contains:
- Task details (ID, title, group)
- Acceptance criteria
- Implementation notes
- Files to create/modify
- Verification commands
- Relevant standards excerpts
- Spec requirements excerpts
- Mission context
- Technology notes

## Example

```bash
# Load context for current task
/task-context

# Load context for specific task
/task-context 2.1
```

## Integration

This skill is used by:
- `agents/task-executor.md` - To understand what to implement
- `agents/task-validator.md` - To know what to validate
- `agents/task-fixer.md` - To understand project standards

The context files are generated during `/professor-frink:init` by the context-builder agent.
