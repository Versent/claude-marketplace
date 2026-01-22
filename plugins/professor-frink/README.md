# Professor Frink

> "Glavin! Multi-session autonomous task execution with human-in-the-loop checkpoints!"

Professor Frink is a Claude Code plugin that enables autonomous multi-session task execution with:

- **Fresh Context Windows**: Each task runs in a new Claude session, preventing context rot
- **Self-Healing Validation**: The validator agent fixes issues autonomously
- **HITL Checkpoints**: Planned stage gates for human review at critical points
- **Agent-OS Integration**: Works seamlessly with spec-driven development workflows

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Professor Frink Orchestrator                  │
│                    (Parent Process / Shell Script)               │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐      ┌───────────────┐
│   EXECUTOR    │     │   VALIDATOR   │      │    FIXER      │
│   (Fresh      │────▶│   (Fresh      │      │   (Fresh      │
│    Session)   │     │    Session)   │      │    Session)   │
└───────────────┘     └───────────────┘      └───────────────┘
        │                     │
        └─────────┬───────────┘
                  ▼
         ┌───────────────┐
         │  NEXT TASK    │
         │  (Loop)       │
         └───────────────┘
```

## Installation

```bash
# Add Versent marketplace
/plugin marketplace add Versent/claude-marketplace

# Install Professor Frink
/plugin install professor-frink@versent-plugins

# (Recommended) Also install Agent-OS for spec-driven workflows
/plugin install agent-os@versent-plugins
```

## Dependencies

| Dependency | Required? | Purpose |
|------------|-----------|---------|
| `jq` | Yes | JSON processing in shell scripts |
| `git` | Yes | Version control, commits |
| `claude` CLI | Yes | Spawning fresh sessions |
| **agent-os** | Recommended | Spec-driven development with tasks.md |

Without Agent-OS, Professor Frink runs in **standalone mode** - you provide a simple task list instead of using spec-driven tasks.md files.

## Quick Start

### 1. Initialize Professor Frink

```bash
# In your project directory
/professor-frink:init
```

Or with the CLI:

```bash
frink init agent-os/specs/phase-1/tasks.md
```

### 2. Configure Checkpoints (Optional)

Edit `.frink/checkpoints.yml` to define when human review is required:

```yaml
checkpoints:
  - id: post_initialization
    description: "Review before implementation"
    trigger: after_task_group_1
    required: true
```

### 3. Run Execution

```bash
/professor-frink:run
```

Or with the CLI:

```bash
frink run
```

### 4. Monitor Progress

```bash
/professor-frink:status
```

## Commands

| Command | Description |
|---------|-------------|
| `/professor-frink:init` | Initialize Professor Frink for a project |
| `/professor-frink:run` | Start autonomous task execution |
| `/professor-frink:status` | Show current progress and statistics |
| `/professor-frink:approve` | Approve a pending HITL checkpoint |
| `/professor-frink:amend` | Add feedback to a checkpoint |
| `/professor-frink:cancel` | Cancel execution |

## Directory Structure

When initialized, Professor Frink creates:

```
.frink/
├── state.json           # Task queue and execution state
├── checkpoints.yml      # HITL checkpoint configuration
├── credentials.yml      # Required credentials
├── validation.yml       # Validation rules
├── context/             # Per-task context files
│   ├── task-1.1-context.md
│   ├── task-1.2-context.md
│   └── ...
├── logs/                # Session logs
├── progress.txt         # Session handoff notes
└── HITL_FEEDBACK.md     # Human feedback (when amended)
```

## Agent Registration

Professor Frink uses three specialized subagents: `frink-executor`, `frink-validator`, and `frink-fixer`.

### Plugin Mode (Installed via Marketplace)

When Professor Frink is installed as a plugin:
```bash
/plugin install professor-frink@versent-plugins
```

The agents in `agents/` are **automatically registered** by Claude Code's plugin system. No additional setup required.

### Development Mode (Embedded in Project)

When Professor Frink lives in a project repo (e.g., during development):

1. The `/professor-frink:init` command creates symlinks in `.claude/agents/professor-frink/`
2. These symlinks point to `professor-frink/agents/*.md`
3. This makes agents discoverable by Claude Code's agent system

```
.claude/agents/professor-frink/
├── frink-executor.md → ../../../professor-frink/agents/task-executor.md
├── frink-validator.md → ../../../professor-frink/agents/task-validator.md
└── frink-fixer.md → ../../../professor-frink/agents/task-fixer.md
```

The symlinks are only needed in development mode and are not part of the plugin distribution.

## Agent Types

### Executor Agent
Implements a single task:
1. Runs environment health check (lint, tests, types)
2. Implements the task per acceptance criteria
3. Commits changes
4. Reports completion

### Validator Agent (Self-Healing)
Validates task implementation:
1. Checks acceptance criteria
2. Verifies spec alignment
3. Runs tests, lint, type check
4. **Fixes any failures autonomously**
5. Re-validates until all pass

### Fixer Agent
Repairs pre-existing issues:
1. Analyzes lint/test/type errors
2. Applies fixes aligned with spec
3. Verifies all checks pass

## HITL Checkpoints

Checkpoints pause execution for human review at planned stage gates:

```yaml
checkpoints:
  - id: pre_credentials
    description: "Add API keys before infrastructure"
    trigger: before_task_group_4
    required: true
    manual_setup:
      - "Add AWS credentials to environment"
```

When a checkpoint triggers:
1. Execution pauses
2. Clear notification displayed
3. Use `/professor-frink:approve` or `/professor-frink:amend` to continue

**Important**: HITL checkpoints are ONLY for planned stage gates, not for code validation failures. The validator agent handles code issues autonomously.

## Agent-OS Integration

Professor Frink integrates with Agent-OS:

| Agent-OS Artifact | Professor Frink Usage |
|-------------------|----------------------|
| `spec.md` | Context for each task session |
| `tasks.md` | Parsed to create task queue |
| `requirements.md` | Available for context |
| `standards/*` | Loaded per task domain |

## Configuration

### Credentials (`.frink/credentials.yml`)

```yaml
credentials:
  required_env_vars:
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
  optional_env_vars:
    - SLACK_WEBHOOK_URL
```

### Validation (`.frink/validation.yml`)

```yaml
validation:
  enabled: true
  self_healing: true
  checks:
    acceptance_criteria: true
    spec_alignment: true
    run_tests: true
    lint: true
    type_check: true
```

## CLI Usage

The orchestrator can run outside of Claude Code:

```bash
# Initialize
frink init tasks.md

# Run execution
frink run

# Start from specific task
frink run --from 2.1

# Show status
frink status
```

## How It Works

### Fresh Context Windows

Unlike traditional approaches that keep a single session alive, Professor Frink:

1. Spawns a **new Claude session** for each task
2. Loads only **task-specific context** (not the entire codebase)
3. Preserves progress in **artifact files** for session handoff

This prevents context rot and ensures each task gets maximum context window efficiency.

### Self-Healing Validation

The validator agent is designed to be autonomous:

1. When a check fails, it **analyzes the failure**
2. It **makes targeted fixes** based on spec and standards
3. It **re-validates** until all checks pass
4. It **never returns to human** for code issues

This means execution can proceed through the entire task list with minimal human intervention.

### Task Context Generation

During initialization, Professor Frink:

1. Parses `tasks.md` for all tasks
2. Extracts relevant sections from spec, standards, tech-stack
3. Generates focused context files for each task
4. Each file is ~500 lines of highly relevant information

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT
