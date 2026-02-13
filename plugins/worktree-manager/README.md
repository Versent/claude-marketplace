# worktree-manager

Task management using git worktrees for parallel development with automated workspace isolation.

## What's Included

- **worktree-manager** [Skill] - Create isolated worktrees for tasks with automatic Jira ticket integration
- **git-branching** [Skill] - Standardized branch naming conventions
- **Atlassian MCP** [MCP] - Automatic ticket retrieval from Jira

## Use Cases

**Why use worktrees?**

- **Parallel task execution** - Open 3 terminals, run Claude in 3 separate worktrees, progress on 3 tickets simultaneously
- **Human-agent collaboration** - Fix bugs in `worktree-PROJ-123/` while Claude implements features in `worktree-PROJ-456/`
- **No stashing required** - Each worktree keeps its own uncommitted changes; switch terminals instead of `git stash`
- **Team unblocking** - Push your WIP branch, let teammates review it, immediately switch to another worktree and continue
- **Preserved context** - Come back tomorrow: `cd worktree-PROJ-123/` and your build state, tests, and WIP are exactly as you left them

**When to use this plugin:**

- Starting new tickets/features/fixes
- Urgent task arrives while you're mid-implementation
- Before long-running implementation plans that span multiple sessions
- When builds/tests/dependencies differ between tasks

## Requirements

- Claude Code >=2.0.12 (for plugin and marketplace support)
- Git >=2.5.0 (for worktree support)
