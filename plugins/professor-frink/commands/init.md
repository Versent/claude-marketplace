---
description: Initialize Professor Frink in a project - detects Agent-OS, parses tasks, sets up .frink/ state with comprehensive credential documentation. Use when starting a new autonomous execution session.
argument-hint: [spec-name]
---

# /professor-frink:init - Initialize Professor Frink

You are initializing Professor Frink for autonomous multi-session task execution.

## Prerequisites

**Required:**
- Git repository initialized
- `jq` installed (for JSON processing)

**Optional but Recommended:**
- Agent-OS installed (`agent-os/` directory with specs and standards)
- Without Agent-OS, you'll need to provide a simple task list

Check for Agent-OS:
```bash
if [[ ! -d "agent-os" ]]; then
    echo "Warning: Agent-OS not detected."
    echo "Professor Frink works best with Agent-OS for spec-driven development."
    echo ""
    echo "To install Agent-OS, add the plugin:"
    echo "  /plugin install agent-os@versent-plugins"
    echo ""
    echo "Or continue without it for standalone task execution."
fi
```

## Initialization Steps

### Step 1: Detect Project State

Check the current project state:

1. **Git Repository**: Is this a git repository? If not, ask user if they want to initialize one.
2. **Agent-OS Presence**: Check for `agent-os/config.yml`, `agent-os/specs/`, `agent-os/standards/`
3. **Existing Tasks**: Look for `tasks.md` files in `agent-os/specs/*/tasks.md`
4. **Project Code State**: Is this an empty project or does code already exist?

```bash
# Check git status
git rev-parse --is-inside-work-tree 2>/dev/null

# Check for Agent-OS
ls -la agent-os/config.yml 2>/dev/null
ls -la agent-os/specs/ 2>/dev/null

# Find tasks.md files
find agent-os/specs -name "tasks.md" 2>/dev/null

# Check for existing code
ls package.json 2>/dev/null
ls -d apps/ functions/ src/ 2>/dev/null
```

### Step 2: Verify Required Tools

Check that all required tools are installed. Record versions in state.json:

```bash
# Required tools
node --version    # >= 20.0.0
npm --version     # >= 10.0.0
jq --version      # >= 1.6

# Tools needed for specific task groups (check and note which are present)
docker --version  # For local development (Task Group 3+)
terraform --version  # For infrastructure (Task Group 2+)
aws --version     # For AWS deployment (Task Group 2+)
gh --version      # For GitHub operations (optional)
```

**IMPORTANT:** Do NOT fail if tools are missing at init time. Instead:
1. Record which tools are installed and their versions
2. Note which task groups require which tools
3. The `/professor-frink:run` command will fail-fast when entering a task group that needs a missing tool

### Step 3: Parse Tasks from Agent-OS

For each spec with tasks.md:

1. Parse task groups and sub-tasks
2. Extract task IDs, descriptions, acceptance criteria
3. **Identify credential requirements per task group** by analyzing task content
4. Build task queue in `.frink/state.json`

If multiple specs have tasks, present a multi-select to the user:

**Which specs should be included in this run?**
- [ ] Phase 1: Foundation & Core Platform (X tasks)
- [ ] Phase 2: Living Document Lifecycle (X tasks)
- [ ] Phase 3: Ecosystem Connections (X tasks)

### Step 4: Analyze Credential Requirements

**CRITICAL:** Analyze the selected tasks to determine what credentials are needed and when.

For each task group, identify required credentials by looking for:
- AWS operations (Terraform, Serverless, SDK) → AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
- Azure AD operations → AZURE_AD_TENANT_ID, AZURE_AD_METADATA_URL
- GitHub API operations → GITHUB_TOKEN
- Notification operations → SLACK_WEBHOOK_URL
- Database connections → DATABASE_URL
- Any other service-specific credentials mentioned in tasks

Create a mapping: `task_group_id → required_credentials[]`

### Step 5: Build Task Context Files

For each task group (not individual tasks):

1. Extract task details + acceptance criteria from tasks.md
2. Extract relevant sections from:
   - `spec.md` (requirements related to this task group)
   - `standards/*` (relevant to task domain: backend, frontend, global)
   - `tech-stack.md` (technologies for this task group)
   - `mission.md` (high-level context)
3. Write to `.frink/context/task-group-{id}-context.md`

### Step 6: Create .frink/ Directory Structure

Create the state directory with comprehensive files:

```
.frink/
├── state.json           # Task queue, preflight status, execution state
├── checkpoints.yml      # HITL checkpoint definitions
├── credentials.yml      # COMPREHENSIVE credential documentation (see Step 7)
├── validation.yml       # Validation rules per task group
├── context/             # Per-task-group context files
│   ├── task-group-1-context.md
│   ├── task-group-2-context.md
│   └── ...
├── logs/                # Session logs (populated during run)
└── progress.txt         # Human-readable progress summary
```

### Step 7: Generate Comprehensive credentials.yml

**This is the most important file for smooth execution.**

The credentials.yml MUST include detailed documentation:

```yaml
# Professor Frink Credentials Configuration
# ==========================================
#
# This file documents all credentials required for autonomous execution.
# The /professor-frink:run command will FAIL FAST if required credentials are missing.
#
# Review this file and configure credentials BEFORE running.

# ============================================================================
# REQUIRED TOOLS
# ============================================================================
tools:
  required:
    - name: node
      version: ">=20.0.0"
      install: "nvm install 20 && nvm use 20"
      verify: "node --version"
      needed_from: "Task Group 1"

    - name: npm
      version: ">=10.0.0"
      install: "Included with Node.js"
      verify: "npm --version"
      needed_from: "Task Group 1"

    - name: docker
      version: ">=24.0.0"
      install: "https://docs.docker.com/get-docker/"
      verify: "docker --version"
      needed_from: "Task Group 3 (Local Development)"

    # Add all tools needed by the selected tasks...

  optional:
    - name: gh
      version: ">=2.0.0"
      install: "brew install gh"
      verify: "gh --version"
      needed_for: "GitHub API operations"

# ============================================================================
# REQUIRED CREDENTIALS
# ============================================================================
credentials:
  # For each credential, include:
  # - Which task group first needs it
  # - What it's used for
  # - Step-by-step instructions to obtain it
  # - Command to verify it's working

  - name: AWS_ACCESS_KEY_ID
    required_from_task_group: 2
    description: "AWS access key for Terraform and deployment"
    how_to_obtain: |
      Option 1 - IAM User:
        1. AWS Console > IAM > Users > [Your User]
        2. Security Credentials > Create Access Key
        3. export AWS_ACCESS_KEY_ID=AKIA...

      Option 2 - AWS SSO:
        1. aws sso login --profile your-profile
        2. export AWS_PROFILE=your-profile
    verify: "aws sts get-caller-identity"

  - name: AWS_SECRET_ACCESS_KEY
    required_from_task_group: 2
    description: "AWS secret key (pair with AWS_ACCESS_KEY_ID)"
    how_to_obtain: "Created alongside AWS_ACCESS_KEY_ID"
    verify: "aws sts get-caller-identity"

  # Add all credentials needed by the selected tasks...

# ============================================================================
# OPTIONAL CREDENTIALS
# ============================================================================
optional_credentials:
  - name: SLACK_WEBHOOK_URL
    needed_for: "CI/CD notifications"
    description: "Slack incoming webhook for deployment notifications"
    how_to_obtain: |
      1. Slack > Apps > Incoming Webhooks
      2. Add to Workspace > Select Channel
      3. Copy Webhook URL
    skip_if_missing: true

# ============================================================================
# TASK GROUP CREDENTIAL REQUIREMENTS
# ============================================================================
# Quick reference: which credentials are needed for each task group

task_group_requirements:
  1: []  # Repository Foundation - no credentials
  2: ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_REGION"]
  3: []  # Local Dev - uses Docker, no cloud credentials
  # ... map all task groups

# ============================================================================
# PREFLIGHT CHECKLIST
# ============================================================================
preflight_commands:
  - description: "Verify Node.js version"
    command: "node --version | grep -E 'v2[0-9]\\.' && echo 'OK' || echo 'FAIL'"

  - description: "Verify Docker is running"
    command: "docker info >/dev/null 2>&1 && echo 'OK' || echo 'FAIL'"

  - description: "Verify AWS credentials"
    command: "aws sts get-caller-identity && echo 'OK' || echo 'FAIL'"
```

### Step 8: Generate state.json with Preflight Section

The state.json MUST include:
- Project metadata
- Execution status
- **Preflight section with tool/credential status**
- Task groups with `required_credentials` array
- Checkpoints

```json
{
  "version": "1.0.0",
  "initialized_at": "ISO-8601 timestamp",
  "project": {...},
  "execution": {
    "status": "ready",
    "current_task_group": null,
    "current_task": null
  },
  "preflight": {
    "status": "passed",
    "checked_at": "ISO-8601 timestamp",
    "tools": {
      "node": {"installed": true, "version": "vX.X.X", "required": true},
      "docker": {"installed": true, "version": "X.X.X", "required": true}
    },
    "credentials": {
      "AWS_ACCESS_KEY_ID": {"status": "not_checked", "required_from_task_group": 2}
    },
    "notes": [
      "Task Group 1 can run without credentials",
      "Task Group 2 requires AWS credentials"
    ]
  },
  "task_groups": [
    {
      "id": 1,
      "name": "Task Group Name",
      "status": "pending",
      "dependencies": [],
      "required_credentials": [],
      "tasks": [...]
    },
    {
      "id": 2,
      "name": "Infrastructure",
      "required_credentials": ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"],
      "tasks": [...]
    }
  ]
}
```

### Step 9: Generate progress.txt

Create a human-readable summary with clear next steps:

```markdown
# Professor Frink Progress Log

## Initialization Complete
- Initialized: [timestamp]
- Project: [name]
- Selected Specs: [list]

## Task Queue Summary
| Metric | Value |
|--------|-------|
| Total Task Groups | X |
| Total Tasks | X |

## Tool Verification
| Tool | Version | Status |
|------|---------|--------|
| node | vX.X.X | OK |

## Credential Requirements by Task Group
| Group | Required Credentials |
|-------|---------------------|
| 1 | None |
| 2 | AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY |

## Before Running

**Task Group 1 can run immediately** - no credentials needed.

**Before Task Group 2**, configure AWS:
[Include specific instructions from credentials.yml]

## Next Command
/professor-frink:run
```

## Output

After initialization, display:

1. Number of tasks found and queued
2. Number of HITL checkpoints configured
3. Tool verification status
4. **Credential requirements summary by task group**
5. **Which task groups can run immediately (no credentials)**
6. Ready state

## Example Output

```
Professor Frink Initialized

Project: Blu Platform
Agent-OS: Detected (v2.1.1)
Specs: 1 selected (Phase 1: Foundation & Core Platform)

Tasks Queued: 132
- Task Group 1: Repository Foundation (10 tasks)
- Task Group 2: AWS Infrastructure (13 tasks)
- ...

HITL Checkpoints: 10 configured

Tools: All required tools installed
- node v20.18.0
- npm 11.8.0
- docker 28.5.1
- terraform 1.14.3

Credential Requirements:
| Task Group | Credentials Needed |
|------------|-------------------|
| 1 (Repository) | None - can run immediately |
| 2 (Infrastructure) | AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY |
| 3 (Local Dev) | None |
| 6 (Auth) | AZURE_AD_TENANT_ID, AZURE_AD_METADATA_URL |

See .frink/credentials.yml for setup instructions.

Run `/professor-frink:run` to start autonomous execution.
```

## Key Design Decisions

1. **Init does NOT execute tasks** - it only prepares state. `/professor-frink:run` executes tasks.

2. **Init does NOT fail on missing credentials** - it documents what's needed. Run fails fast when entering a task group with missing credentials.

3. **Credentials are checked per-task-group** - some groups need no credentials and can run immediately.

4. **credentials.yml includes HOW TO OBTAIN** - step-by-step instructions, not just variable names.

5. **state.json tracks credential requirements per task group** - enables run to fail-fast intelligently.
