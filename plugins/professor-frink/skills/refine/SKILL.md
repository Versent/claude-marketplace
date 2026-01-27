---
description: Incrementally improve agent-os documentation
---

# /professor-frink:refine

You are executing the Professor Frink documentation refinement workflow. Your goal is to
incrementally improve agent-os documentation based on learnings, feedback, or changes.

## Purpose

Unlike the full `/professor-frink:init` discovery process, `refine` is for:
- Quick, targeted updates
- Capturing learnings from task execution
- Incorporating team feedback
- Keeping docs in sync with reality

---

## Execution Flow

### Phase 1: Analyze Current State

**Read current documentation:**
- `agent-os/product/mission.md`
- `agent-os/product/tech-stack.md`
- `agent-os/specs/*/spec.md`
- `agent-os/specs/*/tasks.md`
- `agent-os/standards/*.md`
- `.claude/rules/*.md` (if exists)
- `claude.md` (if exists)

**Check implementation state:**
- Read key source files to compare with docs
- Check git log for recent changes
- Look for TODO comments or FIXME markers

**Identify gaps:**
- Documentation that doesn't match implementation
- Missing sections or unclear descriptions
- Outdated technology references
- Tasks that need refinement

### Phase 2: Present Findings

```
================================================================================
PROFESSOR FRINK - DOCUMENTATION REFINEMENT
================================================================================

## Current State Analysis

**Documentation coverage:**
- Mission: ✓ Complete
- Tech Stack: ⚠ Needs update (new dependencies detected)
- Spec Phase 1: ✓ Complete
- Tasks: ⚠ 3 tasks need refinement
- Standards: ✓ Complete

**Recent changes detected:**
- Added: `@tanstack/query` (not in tech-stack.md)
- Modified: Authentication flow (spec may be outdated)
- Completed: 5 tasks since last init

**Suggested refinements:**
1. Update tech-stack.md with new dependencies
2. Review auth section in spec.md
3. Add acceptance criteria to tasks 1.4, 1.7, 2.1

Shall I proceed with targeted questions to refine these areas?
================================================================================
```

### Phase 3: Targeted Questions

Ask **5-10 focused questions** (not the full 45-question discovery):

**Question selection criteria:**
- Only ask about identified gaps
- Skip areas that are already accurate
- Focus on recent changes
- Prioritize high-impact updates

**Example targeted questions:**

For tech stack updates:
```
Question: "I detected @tanstack/query was added. What's its primary use in this project?"
Options:
- "Server state management for API calls"
- "Client-side caching"
- "Both server state and caching"
- "Other purpose"
```

For task refinement:
```
Question: "Task 1.4 'Implement user profile' has no test approach. How should it be tested?"
Options:
- "Unit tests for validation, integration tests for API"
- "E2E tests only for critical flow"
- "Manual testing checklist"
- "Specify differently"
```

### Phase 4: Apply Updates

Based on answers, update the relevant files:

**For each update:**
1. Read the current file
2. Identify the specific section to update
3. Make the minimal necessary change
4. Preserve existing structure and formatting

**Update targets by type:**

| Gap Type | File to Update | Section |
|----------|---------------|---------|
| New dependency | `tech-stack.md` | Add to appropriate category |
| Architecture change | `spec.md` | Update architecture section |
| Task refinement | `tasks.md` | Update specific task |
| Pattern change | `standards/*.md` | Update or add pattern |
| Rule update | `.claude/rules/*.md` | Update specific rule |

### Phase 5: Generate Diff Summary

After updates, show what changed:

```
================================================================================
REFINEMENT COMPLETE
================================================================================

## Files Updated

### agent-os/product/tech-stack.md
+ Added @tanstack/query to Frontend Dependencies
+ Added usage notes for query patterns

### agent-os/specs/phase-1/tasks.md
+ Task 1.4: Added test approach
+ Task 1.7: Clarified acceptance criteria
+ Task 2.1: Added tech details

### .claude/rules/frontend.md
+ Added section on query patterns

## Summary
- 3 files modified
- 5 sections updated
- 0 new files created

## Commit Message (if requested)
docs: refine documentation based on implementation learnings

- Add @tanstack/query to tech stack
- Clarify task acceptance criteria for tasks 1.4, 1.7, 2.1
- Document query patterns in frontend rules
================================================================================
```

---

## Focus Area Mode

If called with a focus area (e.g., `/professor-frink:refine testing`):

Only analyze and update documentation related to that area:

| Focus | Files to Analyze |
|-------|------------------|
| `testing` | standards/testing/, tasks.md (test sections), rules/testing.md |
| `security` | standards/security/, rules/security.md |
| `api` | standards/backend/, spec.md (API sections), rules/api.md |
| `frontend` | standards/frontend/, rules/frontend.md |
| `infrastructure` | standards/infrastructure/, rules/infrastructure.md |
| `all` | Everything (default) |

---

## Question Limits by Focus

| Focus | Max Questions |
|-------|--------------|
| Single area | 5 |
| All areas | 10 |

This keeps refinement quick and targeted.

---

## Integration with Task Completion

When refine is called after task completion:

1. **Read completed task** from `.frink/state.json`
2. **Check what was implemented** by reading changed files
3. **Compare with task description** and acceptance criteria
4. **Identify documentation gaps** based on actual implementation
5. **Suggest updates** to capture learnings

Example prompt after completing Task 1.3:
```
Task 1.3 "Configure ESLint" is complete.

Implementation details I detected:
- Using @typescript-eslint/parser
- Custom rules for import ordering
- Prettier integration

The standards/global/linting.md doesn't mention:
- Import ordering rules
- Prettier integration setup

Should I add these details to the documentation?
```

---

## Safety Controls

**Before making changes:**
- Show exactly what will be modified
- Get confirmation before writing
- Never delete existing content without confirmation
- Preserve git history (atomic commits)

**What NOT to change without explicit request:**
- Mission or high-level goals
- Major architectural decisions
- Task completion status
- Credential configurations

---

## Example Session

```
User: /professor-frink:refine