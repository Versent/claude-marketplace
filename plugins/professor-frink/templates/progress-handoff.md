# Progress Handoff Template

This template shows the format for `.frink/progress.txt`, which preserves context between sessions.

## Format

```markdown
# Professor Frink Progress Log

## Session History

### Task 1.1 - Initialize monorepo structure
**Completed:** 2026-01-22 10:15:00
**Session:** Executor #1

**Changes Made:**
- Created root package.json with npm workspaces
- Created apps/web/, functions/, lib/ directories
- Set up workspace configuration

**Notes for Future Sessions:**
- Using npm workspaces (not pnpm or yarn)
- apps/web will be Next.js
- functions/ will contain Lambda handlers

---

### Task 1.2 - Configure TypeScript
**Completed:** 2026-01-22 10:25:00
**Session:** Executor #2

**Changes Made:**
- Created root tsconfig.json with strict mode
- Created workspace-specific tsconfig files
- Configured relative imports (no path aliases)

**Notes for Future Sessions:**
- Strict mode enabled throughout
- No path aliases per project conventions
- Each workspace extends root config

---

### Task 1.3 - Set up .nvmrc
**Completed:** 2026-01-22 10:28:00
**Session:** Executor #3

**Changes Made:**
- Created .nvmrc with Node 20

**Notes for Future Sessions:**
- Project requires Node 20.x
```

## Guidelines

When updating progress.txt:

1. **Be Concise**
   - Focus on decisions made, not code details
   - Note configuration choices
   - Highlight anything unusual

2. **Preserve History**
   - Append new entries, don't overwrite
   - Keep last 10-20 entries
   - Archive older entries if needed

3. **Note Dependencies**
   - If a task depends on previous work, note it
   - If a task creates something others will use, note it

4. **Flag Issues**
   - Note any warnings or TODOs
   - Flag anything that needs human attention
   - Document workarounds

## Example Entry

```markdown
### Task 2.3 - Create DynamoDB table definitions
**Completed:** 2026-01-22 11:45:00
**Session:** Executor #8
**Validator:** Self-healed 2 lint issues

**Changes Made:**
- Created lib/dynamodb/tables.ts with table definitions
- Created lib/dynamodb/client.ts with DynamoDB client
- Added @aws-sdk/client-dynamodb dependency

**Notes for Future Sessions:**
- Using single-table design per spec
- Table name prefix: ${stage}-blu-
- GSI for user lookups configured

**Warnings:**
- DynamoDB Local not yet configured (Task 3.4)
- Tests are mocked until local setup complete
```
