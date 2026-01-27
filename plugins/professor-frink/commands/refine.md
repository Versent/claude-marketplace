---
description: Incrementally improve agent-os documentation - run after completing tasks or when requirements change to keep docs up to date.
---

# /professor-frink:refine - Refine Documentation

Incrementally improve and update agent-os documentation based on:
- Learnings from task execution
- New requirements discovered
- Team feedback and corrections
- Implementation details that emerged

## What This Command Does

Unlike `/professor-frink:init` which does comprehensive discovery, `refine` is for
incremental updates to keep documentation in sync with reality.

## When to Use

Run `/professor-frink:refine` when:

1. **After completing a task group** - Capture lessons learned
2. **When requirements change** - Update specs with new information
3. **After team feedback** - Incorporate corrections and clarifications
4. **Before starting a new phase** - Ensure docs are accurate
5. **After resolving blockers** - Document the solution

## Flow

1. **Analyze Current State**
   - Read existing agent-os documentation
   - Compare with actual implementation
   - Identify gaps or outdated information

2. **Targeted Questions**
   - Ask 5-10 focused questions about specific gaps
   - Skip areas that are already accurate
   - Focus on recent changes

3. **Update Documentation**
   - Update relevant spec files
   - Update standards if patterns changed
   - Update tech-stack if new tools added

4. **Commit Changes**
   - Create atomic commit with updates
   - Clear description of what changed

## Usage

```bash
/professor-frink:refine
```

### With Focus Area

```bash
/professor-frink:refine testing
```

Focus areas: `testing`, `security`, `api`, `frontend`, `infrastructure`, `all`

## What Gets Updated

| File Type | Updates |
|-----------|---------|
| `spec.md` | Architecture changes, new components |
| `tasks.md` | Task clarifications, new acceptance criteria |
| `standards/*` | Pattern changes, new conventions |
| `tech-stack.md` | New tools, version updates |
| `.claude/rules/*` | Rule refinements |
| `claude.md` | Quick reference updates |

## Comparison: init vs refine

| Aspect | `/frink:init` | `/frink:refine` |
|--------|---------------|-----------------|
| Questions | 10-45 (tiered) | 5-10 (targeted) |
| Scope | Full discovery | Incremental updates |
| When | Start of project | Throughout development |
| Output | Full documentation | Targeted updates |

## Related Commands

- `/professor-frink:init` - Full initialization with discovery
- `/professor-frink:onboard` - Learn the codebase
- `/professor-frink:status` - Check current state
