# Professor Frink

> "Glavin! Multi-session autonomous task execution with human-in-the-loop checkpoints!"

Professor Frink is a Claude Code plugin that enables autonomous multi-session task execution with:

- **Fresh Context Windows**: Each task runs in a new Claude session, preventing context rot
- **Principal Skinner Supervisor**: Safety controls with cost, duration, and iteration limits
- **Self-Healing Validation**: The validator agent fixes issues autonomously
- **HITL Checkpoints**: Planned stage gates for human review at critical points
- **Rolling Window Progress**: Context-aware handoff documents that prevent unbounded growth
- **Agent-OS Integration**: Works seamlessly with spec-driven development workflows

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Professor Frink Orchestrator                  │
│                    (Parent Process / Shell Script)               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Principal Skinner Supervisor                │   │
│  │  - Cost limits     - Duration limits    - Iteration caps │   │
│  └─────────────────────────────────────────────────────────┘   │
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
         │  Progress     │
         │  Handoff      │
         │  (Rolling     │
         │   Window)     │
         └───────────────┘
                  │
                  ▼
         ┌───────────────┐
         │  NEXT TASK    │
         │  (Loop)       │
         └───────────────┘
```

## Execution Modes

Professor Frink supports two execution modes:

### CLI Mode (Recommended for Autonomous Execution)

Run the orchestrator **outside** of Claude Code for true session isolation:

```bash
# Initialize
./bin/frink-orchestrator.sh init agent-os/specs/phase-1/tasks.md

# Run autonomous execution
./bin/frink-orchestrator.sh run

# Resume from specific task
./bin/frink-orchestrator.sh run --from 2.1
```

**Benefits:**
- Each task gets a completely fresh Claude session
- No context accumulation between tasks
- Full 100K+ token context for each task
- Parallel execution possible

### Skill Mode (Interactive Use)

Run from within Claude Code for guided execution:

```bash
/professor-frink:init
/professor-frink:run
```

**Note:** Skill mode uses subagents which share some context. Recommended for shorter task groups or when you want interactive oversight.

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
| `git` | Yes | Version control, atomic commits |
| `claude` CLI | Yes | Spawning fresh sessions |
| `bc` | Optional | Floating point math for cost tracking |
| **agent-os** | Recommended | Spec-driven development with tasks.md |

## Quick Start

### 1. Initialize Professor Frink

```bash
# In your project directory
/professor-frink:init

# Or with CLI
./bin/frink-orchestrator.sh init agent-os/specs/phase-1/tasks.md
```

### 2. Configure Safety Limits

Copy and customize the config template:

```bash
cp templates/config.yml .frink/config.yml
```

Edit `.frink/config.yml`:

```yaml
execution:
  max_cost_per_task: 10.00      # USD limit
  max_duration_per_task: 600     # 10 minutes
  max_iterations_per_task: 3     # Retry limit
  cost_per_1k_tokens: 0.015      # Adjust for model
```

### 3. Configure Checkpoints (Optional)

Edit `.frink/checkpoints.yml`:

```yaml
checkpoints:
  - id: post_initialization
    description: "Review before implementation"
    trigger: after_task_group_1
    required: true
```

### 4. Run Execution

```bash
# CLI mode (recommended)
./bin/frink-orchestrator.sh run

# Or skill mode
/professor-frink:run
```

### 5. Monitor Progress

```bash
/professor-frink:status

# Or check supervisor stats
./lib/principal-skinner.sh status
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

## Safety Controls (Principal Skinner)

Professor Frink includes the **Principal Skinner** supervisor to prevent runaway behavior:

### Cost Limits

```yaml
execution:
  max_cost_per_task: 10.00  # Stop if total cost exceeds this
```

### Duration Limits

```yaml
execution:
  max_duration_per_task: 600  # Kill session after 10 minutes
```

### Iteration Limits

```yaml
execution:
  max_iterations_per_task: 3  # Max retries per task
```

### Supervisor Commands

```bash
# Check current limits and usage
./lib/principal-skinner.sh status

# Check if a task can proceed
./lib/principal-skinner.sh check-limits 1.1

# Reset stats for new run
./lib/principal-skinner.sh reset
```

## Structured Task List (Anthropic Best Practice)

Professor Frink uses Anthropic's recommended `passes` boolean pattern:

```json
{
  "task_queue": [
    {"id": "1.1", "description": "Create structure", "passes": false},
    {"id": "1.2", "description": "Add TypeScript", "passes": false}
  ]
}
```

**Key principle:** Agents can only set `passes: true`, never remove tasks or set false. This prevents agents from "completing" tasks prematurely or modifying the task list.

## Rolling Window Progress

To prevent context rot in handoff documents, Professor Frink uses a rolling window:

```yaml
progress:
  rolling_window_size: 5      # Only keep last 5 task summaries
  max_summary_lines: 20       # Limit summary length
```

The progress file (`progress.txt`) contains:
- Quick status (total completed, last task)
- Key decisions (always preserved)
- Open blockers
- Recent task summaries (rolling window)

Full history is preserved in `progress-history.json` for audit.

## Directory Structure

```
.frink/
├── state.json              # Task queue and execution state
├── config.yml              # Configuration (copy from templates/)
├── checkpoints.yml         # HITL checkpoint definitions
├── credentials.yml         # Required credentials
├── validation.yml          # Validation rules
├── supervisor-stats.json   # Principal Skinner stats
├── progress.txt            # Rolling window progress notes
├── progress-history.json   # Full progress history
├── context/                # Per-task context files
│   ├── task-1.1-context.md
│   └── ...
├── logs/                   # Session logs
│   ├── session-1.1-executor-*.log
│   └── ...
└── prompts/                # Generated session prompts
```

## Agent Types

### Executor Agent (`frink-executor`)

Implements a single task:
1. Runs environment health check (lint, tests, types)
2. Implements the task per acceptance criteria
3. Commits changes atomically
4. Reports completion with promise string

### Validator Agent (`frink-validator`)

Validates and self-heals:
1. Checks acceptance criteria
2. Verifies spec alignment
3. Runs tests, lint, type check
4. **Fixes any failures autonomously**
5. Re-validates until all pass

### Fixer Agent (`frink-fixer`)

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

**Important**: HITL checkpoints are ONLY for planned stage gates, not for code validation failures. The validator agent handles code issues autonomously.

## Testing

Professor Frink includes a test suite:

```bash
cd plugins/professor-frink/test

# Run all tests
./run-test.sh

# Run specific tests
./run-test.sh init
./run-test.sh supervisor
./run-test.sh progress

# Clean test artifacts
./run-test.sh clean
```

The test suite verifies:
- Script executability
- Dependency availability
- State initialization with `passes` field
- Principal Skinner supervisor
- Progress handoff rolling window

## Best Practices

Based on [Anthropic's guidance for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

1. **Use CLI mode for production** - True session isolation prevents context rot
2. **Set conservative limits** - Start with low cost/duration limits and increase as needed
3. **Use atomic commits** - Each task gets its own commit for easy rollback
4. **Keep context focused** - Rolling window prevents unbounded growth
5. **Trust the validator** - Let it self-heal rather than stopping for every error
6. **Plan checkpoints carefully** - Use for strategic review points, not error handling

## Agent-OS Integration

Professor Frink integrates with Agent-OS:

| Agent-OS Artifact | Professor Frink Usage |
|-------------------|----------------------|
| `spec.md` | Context for each task session |
| `tasks.md` | Parsed to create task queue |
| `requirements.md` | Available for context |
| `standards/*` | Loaded per task domain |

## Configuration Reference

See `templates/config.yml` for the full configuration reference with all options documented.

## Troubleshooting

### Session not spawning

Ensure you're running via CLI mode (`./bin/frink-orchestrator.sh run`) not skill mode for true isolation.

### Cost limit exceeded

```bash
./lib/principal-skinner.sh reset  # Reset stats
./lib/principal-skinner.sh status # Check current usage
```

### Task stuck in loop

Check iteration count:
```bash
./lib/principal-skinner.sh check-iterations 1.1
```

### Context too large

Reduce rolling window size in config:
```yaml
progress:
  rolling_window_size: 3
```

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT

## References

- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Ralph Wiggum Technique](https://securetrajectories.substack.com/p/ralph-wiggum-principal-skinner-agent-reliability)
- [Agent-OS Documentation](https://github.com/buildermethods/agent-os)
