---
description: Initialize Professor Frink in a project - detects Agent-OS, parses tasks, sets up .frink/ state. Includes tiered discovery modes (Quick/Standard/Comprehensive), task quality assessment, and Claude folder generation.
argument-hint: [spec-name] [--quick|--standard|--comprehensive]
---

# /professor-frink:init - Initialize Professor Frink

You are initializing Professor Frink for autonomous multi-session task execution.

## Prerequisites

**Required:**
- Git repository initialized
- `jq` installed (for JSON processing)
- Agent-OS installed (`agent-os/` directory with specs and standards)

Check for Agent-OS (REQUIRED):
```bash
if [[ ! -d "agent-os" ]]; then
    echo "================================================================================
ERROR: Agent-OS not detected.
================================================================================

Professor Frink requires Agent-OS for spec-driven development.

To install Agent-OS:
  1. Add the marketplace: /plugin marketplace add Versent/claude-marketplace
  2. Install: /plugin install agent-os@versent-plugins
  3. Initialize: /agent-os:init

Then run /professor-frink:init again.
================================================================================"
    exit 1
fi
```

## Initialization Steps

### Step 0: Present Initialization Plan (HITL Required)

**CRITICAL:** Before performing any actions, present the initialization plan and wait for human approval.

Read the project state first, then present:

```markdown
================================================================================
PROFESSOR FRINK - INITIALIZATION ROADMAP
================================================================================

I've detected the following project state:

**Project:** [detected project name from package.json or directory]
**Agent-OS:** Detected ✓
**Existing Code:** [Yes/No - based on src/, apps/, etc.]
**Git Repository:** [Initialized / Not Initialized]

## What I Will Do

### Phase 1: Project Detection & Tool Verification (~1 min)
- Verify required tools (node, npm, docker, terraform, etc.)
- Parse existing Agent-OS specifications
- Identify credential requirements per task group

### Phase 2: Task Quality Assessment (~2 min)
- Score each task on completeness (0-100)
- Identify gaps in acceptance criteria, tech details, tests
- Focus discovery questions on low-scoring areas

### Phase 3: Discovery Questions (5-20 min based on mode)
Choose your mode:
- **Quick Mode**: 10 essential questions (~5 min)
- **Standard Mode**: 25 questions (recommended, ~10 min)
- **Comprehensive Mode**: 45 questions (~20 min)

Question categories:
- Tech Stack (batches 1-2)
- Standards (batches 3-4)
- Specifications (batches 5-6)
- Tasks (batches 7-8)
- Deep Dive (batch 9) - paragraph responses

### Phase 4: Update Agent-OS Documentation (~2 min)
- Update specs based on your answers
- Enrich tasks with tech details and test approaches
- Document key decisions

### Phase 5: Generate Claude Folder (~1 min)
- Generate `claude.md` (project overview, 60-75 lines)
- Create `.claude/rules/` (domain-based rule files)
- Suggest relevant MCP servers and generate skill files

### Phase 6: State Generation & Summary
- Create `.frink/` directory structure
- Generate credentials.yml with setup instructions
- Build task context files
- Display summary and next steps

================================================================================
```

**Use AskUserQuestion to get mode selection:**

```
Question: "Which initialization mode would you like?"
Options:
- "Standard Mode (25 questions) - Recommended"
- "Quick Mode (10 questions) - For simple projects"
- "Comprehensive Mode (45 questions) - For complex projects"
- "Skip discovery - Use existing specs as-is"
```

Record the mode selection for use in Phase 3.

**If user selects "Skip discovery":** Proceed directly to Phase 4 (Update) and Phase 5 (Claude Folder) with existing specs.

---

### Phase 2: Task Quality Assessment (NEW)

**Before asking discovery questions, assess task quality to focus the questions.**

Use the task assessor helper:
```bash
source lib/task-assessor.sh
task_assessor_init ".frink/task-assessment.json"
```

For each task in `agent-os/specs/*/tasks.md`:

1. **Parse the task** - Extract ID, description, and any existing details
2. **Detect criteria presence**:
   - Acceptance criteria (AC:, Expected:, Should:, Given/When/Then)
   - Tech details (Implement using, Create, Configure)
   - Test approach (Test:, Verify by:, Coverage)
   - Dependencies (After task, Depends on, Requires)
   - Effort indicators (Small/Medium/Large, hours, points)

3. **Calculate score** (out of 100):
   - Acceptance Criteria: 25%
   - Tech Details: 25%
   - Test Approach: 20%
   - Dependencies: 15%
   - Effort Estimate: 15%

4. **Generate report**:

```
================================================================================
TASK QUALITY ASSESSMENT
================================================================================

Summary
-------
Total Tasks Assessed: 25
Average Score: 72/100

Distribution:
  Excellent (90-100): 5 tasks
  Good (70-89):       12 tasks
  Fair (50-69):       6 tasks
  Poor (<50):         2 tasks

Tasks Needing Improvement
-------------------------
  Task 1.4: 45/100 - Missing: acceptance_criteria, test_approach
  Task 2.1: 55/100 - Missing: tech_details, effort_estimate

================================================================================
```

**Use assessment to focus discovery questions:**
- Low-scoring tasks become priority topics
- Skip questions about well-documented areas
- Generate task-specific refinement questions

---

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

### Step 2.5: Setup Agent Registration (Development Mode Only)

**NOTE:** This step is only needed when Professor Frink is embedded in a project repo (development mode). When installed as a plugin via marketplace, agent registration happens automatically through the plugin's `agents/` directory.

Check if Professor Frink is installed as a plugin or embedded in the repo:

```bash
# If professor-frink/ exists at repo root, we're in development mode
if [[ -d "professor-frink/agents" ]] && [[ ! -d ".claude/agents/professor-frink" ]]; then
    echo "Development mode detected - creating agent symlinks"

    mkdir -p .claude/agents/professor-frink

    # Create symlinks to make agents discoverable
    [ ! -L .claude/agents/professor-frink/frink-executor.md ] && \
      ln -s ../../../professor-frink/agents/task-executor.md .claude/agents/professor-frink/frink-executor.md

    [ ! -L .claude/agents/professor-frink/frink-validator.md ] && \
      ln -s ../../../professor-frink/agents/task-validator.md .claude/agents/professor-frink/frink-validator.md

    [ ! -L .claude/agents/professor-frink/frink-fixer.md ] && \
      ln -s ../../../professor-frink/agents/task-fixer.md .claude/agents/professor-frink/frink-fixer.md

    ls -la .claude/agents/professor-frink/
else
    echo "Plugin mode - agents auto-registered via plugin system"
fi
```

**Why this step exists:** During development, Professor Frink lives in the project repo but isn't installed as a plugin. Symlinks make the agents discoverable by Claude Code's agent system at `.claude/agents/`. Once published to a marketplace and installed properly, the plugin system handles registration automatically.

---

## Spec Refinement Phase (If Agent-OS Detected)

**Skip this entire phase if:**
- Agent-OS directory doesn't exist
- User selected "Skip spec refinement" in Step 0

**Purpose:** Refine Agent-OS specifications through targeted questions to create comprehensive documentation suitable for autonomous coding agents.

### Question Design Principles

1. **Use AskUserQuestion tool** with 2-4 options per question
2. **Ask 5 questions at a time** (max allowed by tool)
3. **Questions should be specific and actionable** - not vague
4. **Each question should help clarify implementation details**
5. **Include "Other" for custom responses** (automatic with AskUserQuestion)
6. **Focus on details an autonomous agent would need** - testing approaches, code patterns, error handling, etc.

### Question Categories by Round

Good questions ask about:
- **Specific choices** - "Which auth pattern?" not "Tell me about auth"
- **Implementation details** - "How should errors be displayed?"
- **Testing approaches** - "How should this be verified?"
- **Code patterns** - "Which state management pattern?"
- **Edge cases** - "What happens when X fails?"

Avoid questions that:
- Are too broad ("Describe the project")
- Have obvious answers from existing docs
- Don't impact implementation

---

### Round 1: Product Vision (Questions 1-5)

**Read first:** `agent-os/product/mission.md`, `agent-os/product/roadmap.md`, `agent-os/product/tech-stack.md`

**Focus areas for questions:**
- Target users and their primary workflows
- Success metrics and acceptance criteria
- Technology trade-offs not covered in tech-stack
- Integration priorities with external systems
- Performance requirements and constraints

**Example questions (adapt based on what's missing from docs):**

```
Question 1: "What's the primary user persona for this application?"
Options:
- "Internal enterprise users (employees)"
- "External customers/clients"
- "Developers/technical users"
- "Mixed audience with role-based access"

Question 2: "How should the application handle offline scenarios?"
Options:
- "Full offline support with sync (PWA)"
- "Graceful degradation with cached data"
- "Online-only with clear error states"
- "Not applicable for this use case"

Question 3: "What's the expected data volume for the primary entities?"
Options:
- "Small (<1000 records per entity)"
- "Medium (1K-100K records)"
- "Large (100K-1M records)"
- "Very large (>1M records, needs pagination strategies)"

Question 4: "How should real-time updates be handled?"
Options:
- "WebSocket for instant updates"
- "Polling every 30-60 seconds"
- "Manual refresh only"
- "Server-Sent Events (SSE) for one-way updates"

Question 5: "What's the deployment frequency expectation?"
Options:
- "Continuous deployment on every merge"
- "Daily deployments"
- "Weekly release cycles"
- "Manual releases with approval gates"
```

### Round 2: Product Vision (Questions 6-10)

**Continue with questions about:**
- Multi-tenancy approach
- Audit and compliance requirements
- Backup and disaster recovery expectations
- Internationalization requirements
- Accessibility requirements (WCAG level)

**After Round 2:** Update `agent-os/product/` files with refined details.

```markdown
## Updating Product Files

Based on answers, enhance:
- `mission.md` - Add user personas, success metrics
- `tech-stack.md` - Add rationale for choices based on requirements
- `roadmap.md` - Clarify phase priorities based on answers
```

---

### Round 3: Standards (Questions 11-15)

**Read first:** `agent-os/standards/global/`, `agent-os/standards/frontend/`, `agent-os/standards/backend/`

**Focus areas:**
- Code organization patterns
- Error handling strategies
- Logging and observability approaches
- Testing requirements and coverage expectations
- Documentation requirements

**Example questions:**

```
Question 11: "How should API errors be communicated to users?"
Options:
- "Toast notifications with retry option"
- "Inline error messages near the failed action"
- "Modal dialogs for critical errors"
- "Combination based on error severity"

Question 12: "What's the expected test coverage approach?"
Options:
- "Unit tests for business logic only (60%+)"
- "Unit + integration tests (80%+)"
- "Full coverage including E2E (90%+)"
- "Critical paths only with smoke tests"

Question 13: "How should loading states be displayed?"
Options:
- "Skeleton screens for content areas"
- "Spinner overlays"
- "Progress bars for long operations"
- "Optimistic UI with rollback on failure"

Question 14: "What's the preferred data fetching pattern?"
Options:
- "Fetch on mount with loading states"
- "Prefetch on hover/focus"
- "Infinite scroll for lists"
- "Pagination with page numbers"

Question 15: "How should form validation work?"
Options:
- "Validate on blur (field exit)"
- "Validate on submit only"
- "Real-time validation as user types"
- "Hybrid: blur for format, submit for business rules"
```

### Round 4: Standards (Questions 16-20)

**Continue with questions about:**
- State management boundaries (local vs global)
- Caching strategies
- Security patterns (XSS, CSRF, injection prevention)
- Performance budgets
- Naming conventions for files/components

**After Round 4:** Update `agent-os/standards/` files.

```markdown
## Updating Standards Files

Based on answers, enhance:
- `global/error-handling.md` - Add specific error display patterns
- `frontend/components.md` - Add loading state patterns
- `frontend/state-management.md` - Add caching strategies
- `testing/test-writing.md` - Add coverage requirements
- `backend/api.md` - Add error response formats
```

---

### Round 5: Specifications (Questions 21-25)

**Read first:** `agent-os/specs/*/planning/`, `agent-os/specs/*/spec.md`

**Focus areas:**
- Feature prioritization within phases
- Integration points between features
- Data model relationships
- User flow specifics
- Edge cases and error scenarios

**Example questions:**

```
Question 21: "How should user sessions be managed across tabs?"
Options:
- "Shared session - actions sync across tabs"
- "Independent sessions per tab"
- "Primary tab with read-only secondary tabs"
- "Prompt user to choose on conflict"

Question 22: "What happens when a user's permissions change mid-session?"
Options:
- "Immediate logout with explanation"
- "Graceful degradation - hide restricted features"
- "Warning banner with option to refresh"
- "Complete session until next login"

Question 23: "How should draft/unsaved work be handled?"
Options:
- "Auto-save every 30 seconds"
- "Manual save with unsaved indicator"
- "Local storage backup with recovery prompt"
- "Warn on navigation, no auto-save"

Question 24: "How should long-running operations be communicated?"
Options:
- "Background with notification on complete"
- "Modal with progress and cancel option"
- "Inline progress with ability to navigate away"
- "Queue system with status dashboard"

Question 25: "How should the application handle concurrent edits?"
Options:
- "Last write wins"
- "Optimistic locking with conflict resolution"
- "Real-time collaboration (Google Docs style)"
- "Check-out/check-in model"
```

### Round 6: Specifications (Questions 26-30)

**Continue with questions about:**
- Search and filtering requirements
- Notification preferences and channels
- Export/import capabilities
- Audit trail requirements
- Admin vs user feature differences

**After Round 6:** Update `agent-os/specs/*/` files.

```markdown
## Updating Spec Files

Based on answers, enhance:
- `spec.md` - Add detailed acceptance criteria
- `planning/requirements.md` - Add edge cases and error scenarios
- Add new sections for: session management, conflict resolution, notifications
```

---

### Round 7: Tasks (Questions 31-35)

**Read first:** `agent-os/specs/*/tasks.md`

**Focus areas:**
- Task verification methods
- Acceptance criteria specifics
- Dependencies between tasks
- Testing approach per task type
- Code patterns to use

**Example questions:**

```
Question 31: "How should Lambda handlers be tested?"
Options:
- "Unit tests with mocked AWS services"
- "Integration tests against LocalStack"
- "Both unit and integration"
- "E2E tests through API Gateway only"

Question 32: "How should database migrations be verified?"
Options:
- "Automated migration tests with rollback"
- "Manual verification in dev environment"
- "Schema validation against TypeScript types"
- "All of the above"

Question 33: "How should UI components be documented?"
Options:
- "Storybook with all variants"
- "JSDoc comments only"
- "README per component directory"
- "No documentation, self-documenting code"

Question 34: "How should API endpoints be verified?"
Options:
- "OpenAPI schema validation"
- "Integration tests with real requests"
- "Contract tests against frontend expectations"
- "All of the above"

Question 35: "How should frontend routing be tested?"
Options:
- "E2E tests for critical paths"
- "Unit tests for route guards/middleware"
- "Manual testing with test plan"
- "Automated visual regression"
```

### Round 8: Tasks (Questions 36-40)

**Continue with questions about:**
- Code review expectations
- Performance testing requirements
- Security testing requirements
- Accessibility testing approach
- Documentation requirements per task

**After Round 8:** Update `agent-os/specs/*/tasks.md` files.

```markdown
## Updating Task Files

Based on answers, enhance each task with:
- Specific verification commands
- Expected test coverage
- Code patterns to follow
- Documentation requirements
- Acceptance criteria details
```

---

### Round 9: Deep Dive (Questions 41-45)

**Final questions that cut across all specifications.**

**Read first:** Review all previous answers and identify gaps.

**Focus areas:**
- Cross-cutting concerns not yet addressed
- Integration between features
- Deployment and operations
- Monitoring and alerting
- Security and compliance

**Example questions:**

```
Question 41: "How should secrets be managed across environments?"
Options:
- "AWS Secrets Manager with automatic rotation"
- "Environment variables from CI/CD"
- "HashiCorp Vault"
- "AWS Parameter Store"

Question 42: "What should happen when an external service is unavailable?"
Options:
- "Circuit breaker with fallback behavior"
- "Retry with exponential backoff"
- "Fail fast with clear error message"
- "Queue requests and process when available"

Question 43: "How should feature flags be managed?"
Options:
- "AWS AppConfig"
- "LaunchDarkly or similar service"
- "Environment variables"
- "Database-driven with admin UI"

Question 44: "How should logs be structured?"
Options:
- "JSON structured logs to CloudWatch"
- "Plain text with grep-friendly format"
- "OpenTelemetry with distributed tracing"
- "Minimal logging, rely on metrics"

Question 45: "What's the rollback strategy for failed deployments?"
Options:
- "Automatic rollback on health check failure"
- "Blue/green with manual switch"
- "Canary with gradual rollout"
- "Manual rollback with runbook"
```

**After Round 9:** Update all relevant files across `agent-os/`.

```markdown
## Final Updates

Based on deep dive answers, add sections for:
- `standards/global/error-handling.md` - Circuit breaker patterns
- `standards/infrastructure/` - Secrets management, feature flags
- `standards/testing/` - Integration testing approaches
- `spec.md` files - Cross-cutting requirements
```

---

### Spec Refinement Summary

After all rounds, display:

```markdown
================================================================================
SPEC REFINEMENT COMPLETE
================================================================================

## Files Updated

| Category | Files Modified |
|----------|---------------|
| Product | mission.md, roadmap.md, tech-stack.md |
| Standards | [list modified files] |
| Specs | [list modified files] |
| Tasks | [list modified files] |

## Key Decisions Captured

1. [Summary of important decisions from questions]
2. [...]
3. [...]

## Proceeding to Claude Folder Generation...
================================================================================
```

---

## Phase 5: Generate Claude Folder (NEW)

**After spec refinement, generate the `.claude/` folder structure.**

Use the Claude folder generator helper:
```bash
source lib/claude-folder-generator.sh
generator_init "." ".frink/generator-config.json"
```

### Step 5.1: Gather Project Metadata

Extract from agent-os and package.json:
```bash
# Get project name
PROJECT_NAME=$(jq -r '.name' package.json 2>/dev/null || basename $(pwd))

# Get mission summary
MISSION=$(head -5 agent-os/product/mission.md | grep -v "^#" | head -1)

# Detect commands
BUILD_CMD=$(jq -r '.scripts.build // "npm run build"' package.json)
TEST_CMD=$(jq -r '.scripts.test // "npm test"' package.json)
LINT_CMD=$(jq -r '.scripts.lint // "npm run lint"' package.json)
DEV_CMD=$(jq -r '.scripts.dev // "npm run dev"' package.json)
```

### Step 5.2: Create .claude Directory Structure

```bash
mkdir -p .claude/rules
mkdir -p .claude/skills
```

### Step 5.3: Generate claude.md

Create a balanced `claude.md` file (60-75 lines) with:
- Project overview and mission
- Quick reference (stack, commands)
- Architecture summary with @-references
- Code style summary with link to rules
- Testing summary with link to rules
- Common tasks table
- Key decisions
- Gotchas
- Footer with links to detailed docs

**Template structure:**
```markdown
# {PROJECT_NAME}

> {MISSION_SUMMARY}

## Quick Reference

- **Stack:** {TECH_STACK_SUMMARY}
- **Build:** `{BUILD_COMMAND}`
- **Test:** `{TEST_COMMAND}`
- **Lint:** `{LINT_COMMAND}`

## Architecture

{ARCHITECTURE_SUMMARY}

See @agent-os/specs/{PHASE}/spec.md for detailed architecture.

## Code Style

{CODE_STYLE_SUMMARY}

See @.claude/rules/code-style.md for complete guidelines.

## Testing

{TESTING_SUMMARY}

See @.claude/rules/testing.md for test patterns.

## Common Tasks

| Task | Command |
|------|---------|
| Run dev server | `{DEV_COMMAND}` |
| Run tests | `{TEST_COMMAND}` |
| Build | `{BUILD_COMMAND}` |
| Lint | `{LINT_COMMAND}` |

## Key Decisions

{KEY_DECISIONS from discovery answers}

## Gotchas

{GOTCHAS from discovery answers}

---

For detailed standards: @.claude/rules/
For project tasks: @agent-os/specs/{PHASE}/tasks.md
```

### Step 5.4: Generate Domain-Based Rule Files

Create rule files in `.claude/rules/`:

| File | Paths Filter | Content Focus |
|------|-------------|---------------|
| `code-style.md` | (none - global) | Naming, formatting, patterns |
| `testing.md` | `**/test/**,**/*.test.*` | Test approach, coverage |
| `security.md` | (none - global) | Auth, validation, secrets |
| `api.md` | `**/api/**,**/routes/**` | REST, responses, versioning |
| `frontend.md` | `**/*.tsx,**/components/**` | Components, state, styling |
| `infrastructure.md` | `**/terraform/**,**/deploy/**` | IaC, environments, deployment |

Each rule file should:
1. Include `paths:` frontmatter for conditional loading (where applicable)
2. Contain 30-50 lines of focused guidelines
3. Reference discovery question answers for project-specific rules
4. Link to relevant standards in agent-os

### Step 5.5: Detect and Suggest MCP Servers

Auto-detect based on tech stack:

| Tech Stack | Suggested MCP | Purpose |
|------------|---------------|---------|
| Any project | context7 | Documentation lookup |
| React/Vue/Angular | playwright | Browser testing |
| Terraform | terraform-registry | Provider docs |
| AWS | aws-docs | Service documentation |
| PostgreSQL | postgres | Database queries |
| GitHub | github | PR/Issue management |

For each suggested MCP:
1. Check if already configured
2. Display suggestion with install command
3. Generate skill file in `.claude/skills/{mcp-name}/SKILL.md`

### Step 5.6: Display Generation Summary

```
================================================================================
CLAUDE FOLDER GENERATED
================================================================================

## Files Created

| File | Purpose |
|------|---------|
| `claude.md` | Project overview (67 lines) |
| `.claude/rules/code-style.md` | Code style guidelines |
| `.claude/rules/testing.md` | Testing patterns |
| `.claude/rules/security.md` | Security guidelines |
| `.claude/rules/api.md` | API conventions |
| `.claude/rules/frontend.md` | Frontend patterns |
| `.claude/rules/infrastructure.md` | IaC guidelines |

## Suggested MCP Servers

| MCP | Purpose | Install |
|-----|---------|---------|
| context7 | Documentation lookup | Already configured |
| playwright | Browser testing | /mcp add playwright |
| aws-docs | AWS documentation | /mcp add aws-docs |

Skill files generated in .claude/skills/

## Proceeding to State Generation...
================================================================================
```

---

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

HITL Checkpoints: 3 configured

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

---

## Post-Initialization Guide

**IMPORTANT:** After initialization completes, display this comprehensive guide to help users configure their execution environment.

### Output Template

After successful initialization, output the following guide (adapt content based on actual detected configuration):

```markdown
================================================================================
PROFESSOR FRINK - INITIALIZATION COMPLETE
================================================================================

## What Was Created

The following files have been created in `.frink/`:

| File | Purpose |
|------|---------|
| `state.json` | Execution state, task queue, progress tracking |
| `checkpoints.yml` | HITL checkpoint definitions (when to pause for approval) |
| `credentials.yml` | Credential requirements with setup instructions |
| `progress.txt` | Human-readable progress log |
| `context/` | Task context files for each task group |

## Files You Should Review

### 1. Checkpoints Configuration
📁 `.frink/checkpoints.yml`

This file defines when Professor Frink pauses for human approval.
Review and customize:

- **Add checkpoints** before risky operations (deployments, migrations)
- **Remove checkpoints** if you want faster execution
- **Modify descriptions** to clarify what should be reviewed

Example checkpoint structure:
```yaml
checkpoints:
  - id: post_infrastructure
    after_task_group: 2
    name: "Infrastructure Ready"
    description: "Review Terraform plan before backend development"
    approval_required: true
```

To skip a checkpoint during execution: `/professor-frink:approve`
To provide feedback at a checkpoint: `/professor-frink:amend "your feedback"`

### 2. Credentials Configuration
📁 `.frink/credentials.yml`

This file documents all credentials needed for execution.
**Execution will fail-fast if required credentials are missing.**

Actions to take:
- Review which credentials are needed per task group
- Set up credentials BEFORE the task group that needs them
- Use environment variables, AWS profiles, or secrets manager

Common credential setup methods:

**AWS (via profile - recommended):**
```bash
# Using AWS SSO
aws sso login --profile your-profile
export AWS_PROFILE=your-profile

# Verify
aws sts get-caller-identity
```

**AWS (via environment variables):**
```bash
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=us-east-1
```

**Other services:**
Review `.frink/credentials.yml` for service-specific instructions.

### 3. Execution State
📁 `.frink/state.json`

Review the parsed task groups and verify:
- Task descriptions match your expectations
- Dependencies between task groups are correct
- Required credentials per group are accurate

You can modify `state.json` to:
- Skip a task group: Set `"status": "skipped"`
- Change task order: Modify the `tasks` array
- Defer credentials: Add `"deferred_credentials"` and update `"required_credentials"`

### 4. Task Context (Optional)
📁 `.frink/context/task-group-*.md`

These files contain the context given to each task executor session.
Review if you want to:
- Add project-specific notes
- Include additional standards
- Clarify acceptance criteria

## Task Groups Ready to Run

Based on current credential availability:

| Status | Task Group | Credentials |
|--------|------------|-------------|
| ✅ Ready | [Groups with no credential requirements] | None needed |
| ⏳ Needs Setup | [Groups requiring credentials] | [List credentials] |

## Execution Options

### Start Execution
```
/professor-frink:run
```
Begins autonomous execution from the first pending task group.
Will pause at HITL checkpoints for your approval.

### Check Status
```
/professor-frink:status
```
Shows current progress, completed tasks, and next steps.

### Skip Credentials (Defer)
If you don't have credentials for a task group but want to continue:

1. Edit `.frink/state.json`
2. Move credentials from `required_credentials` to `deferred_credentials`
3. Add a `notes` field explaining the workaround
4. Modify affected task descriptions if needed

Example:
```json
{
  "id": 6,
  "name": "Authentication",
  "required_credentials": [],
  "deferred_credentials": ["AZURE_AD_TENANT_ID"],
  "notes": "Using alternative auth method for Phase 1"
}
```

## Git Integration

Professor Frink creates atomic commits for each task.
Commits follow conventional commit format:
```
feat(scope): description [Task X.Y]
```

To rollback a specific task:
```bash
git log --grep="Task: X.Y"  # Find the commit
git revert <commit-hash>    # Undo that task
```

## Troubleshooting

### Missing Tools
If a required tool is missing, install it before running.
Check `.frink/credentials.yml` for installation instructions.

### Credential Errors
If execution fails due to credentials:
1. Check `.frink/credentials.yml` for setup instructions
2. Verify with the provided verify commands
3. Re-run `/professor-frink:run` - it resumes from where it stopped

### Checkpoint Approval
When paused at a checkpoint:
- Review the completed work
- Run `/professor-frink:approve` to continue
- Run `/professor-frink:amend "feedback"` to provide corrections

================================================================================
Ready to start? Run: /professor-frink:run
================================================================================
```

### Guide Generation Rules

When generating this guide:

1. **Adapt to detected state** - Only show credential sections for credentials that were detected as required
2. **Show actual task groups** - List the real task group names and their credential requirements
3. **Highlight ready groups** - Clearly indicate which groups can run immediately
4. **Be specific about files** - Always reference actual file paths in `.frink/`
5. **Include verification commands** - Help users confirm their setup is correct
6. **Explain modification options** - Users should know they can customize before running

## Key Design Decisions

1. **Init does NOT execute tasks** - it only prepares state. `/professor-frink:run` executes tasks.

2. **Init does NOT fail on missing credentials** - it documents what's needed. Run fails fast when entering a task group with missing credentials.

3. **Credentials are checked per-task-group** - some groups need no credentials and can run immediately.

4. **credentials.yml includes HOW TO OBTAIN** - step-by-step instructions, not just variable names.

5. **state.json tracks credential requirements per task group** - enables run to fail-fast intelligently.

6. **Post-initialization guide is MANDATORY** - always display the comprehensive guide explaining what files to review, how to configure credentials, and how to customize checkpoints.

7. **Project-agnostic output** - the guide template adapts to the actual detected configuration, not hardcoded project-specific content.

8. **User empowerment** - explain how users can modify state.json, defer credentials, skip task groups, and customize checkpoints before running.
