---
description: Onboard a human to the codebase interactively
---

# /professor-frink:onboard

You are executing the Professor Frink onboarding workflow. Your goal is to help a human
understand this codebase so they can start contributing quickly.

## Execution Roadmap

**CRITICAL:** Before any action, present the onboarding roadmap and get confirmation:

```
================================================================================
PROFESSOR FRINK - CODEBASE ONBOARDING
================================================================================

I'll help you understand this codebase so you can start contributing quickly.

Here's our journey:

1. **Mission & Context** (2 min)
   - What this project does and why
   - Key stakeholders and users

2. **Tech Stack Overview** (3 min)
   - Languages, frameworks, tools
   - Why these choices were made

3. **Architecture Walk-through** (5 min)
   - System components and their roles
   - How they communicate
   - [Go deeper on any component as needed]

4. **Developer Workflow** (3 min)
   - Local setup
   - Running and testing
   - Making changes

5. **Deployment Pipeline** (3 min)
   - How code gets to production
   - Environments and stages

6. **Code Navigation** (5-10 min)
   - Starting from external dependencies
   - Following data flow to core logic
   - [Interactive: ask to go deeper at each level]

Total time: ~20-30 minutes (adaptive based on your questions)

Ready to begin?
================================================================================
```

Use AskUserQuestion to confirm:
- "Ready to start onboarding?"
- Options: "Yes, let's begin", "Skip to a specific section", "Not now"

---

## Prerequisites Check

Before starting, verify:

1. **Agent-OS Present**: Check for `agent-os/` directory
   ```bash
   if [[ ! -d "agent-os" ]]; then
       echo "Error: Agent-OS not detected. Run /professor-frink:init first."
       exit 1
   fi
   ```

2. **Key Files Exist**:
   - `agent-os/product/mission.md` (or equivalent)
   - `agent-os/product/tech-stack.md`
   - `agent-os/specs/*/spec.md`

---

## Step 1: Mission & Context

**Read:**
- `agent-os/product/mission.md`
- `agent-os/product/requirements.md` (if exists)

**Present:**
- Summarize in 3-4 sentences what the project does
- Identify the target users/audience
- State the key goals or success metrics

**Format:**
```
## Mission & Context

**What it does:** [1-2 sentence summary]

**For whom:** [Target users/audience]

**Key goals:**
- [Goal 1]
- [Goal 2]
- [Goal 3]
```

**Ask:** "Any questions before we continue to the tech stack?"

---

## Step 2: Tech Stack Overview

**Read:**
- `agent-os/product/tech-stack.md`
- `agent-os/standards/*.md` (scan for tech mentions)
- `package.json` or equivalent for actual dependencies

**Present as table:**

```
## Tech Stack

| Layer | Technology | Why This Choice |
|-------|------------|-----------------|
| Frontend | React 18 | Component model, ecosystem |
| Backend | Node.js | Shared language, async |
| Database | PostgreSQL | ACID, JSON support |
| Infrastructure | Terraform | IaC, state management |
| CI/CD | GitHub Actions | Integration with repo |
```

**Ask:** "Want to go deeper on any technology? Or continue to architecture?"

---

## Step 3: Architecture Walk-through (Adaptive Depth)

**Read:**
- `agent-os/specs/*/spec.md`
- Any architecture diagrams or docs

**Present high-level ASCII diagram:**

```
## Architecture Overview

┌─────────────────────────────────────────────────────────────┐
│                      User Interface                          │
│  (React SPA / Components / State Management)                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                             │
│  (Authentication / Rate Limiting / Routing)                  │
└─────────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
         ┌─────────┐  ┌─────────┐  ┌─────────┐
         │ Service │  │ Service │  │ Service │
         │    A    │  │    B    │  │    C    │
         └─────────┘  └─────────┘  └─────────┘
              │             │             │
              └─────────────┼─────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  (Database / Cache / External APIs)                          │
└─────────────────────────────────────────────────────────────┘
```

**For each component:**
1. Brief description (2 sentences max)
2. Ask: "Go deeper into [component]?"
3. If yes → explain internals, patterns, key files
4. If no → continue to next component

**Deep dive content includes:**
- Directory structure
- Key files and their purposes
- Design patterns used
- Important abstractions

---

## Step 4: Developer Workflow

**Read:**
- `README.md`
- `package.json` scripts
- `.github/workflows/` or CI config
- `CONTRIBUTING.md` (if exists)

**Present:**

```
## Developer Workflow

### Local Setup
1. Clone the repository
2. Install dependencies: `npm install`
3. Copy environment: `cp .env.example .env`
4. Start services: `docker-compose up -d`
5. Run dev server: `npm run dev`

### Making Changes
1. Create feature branch from main
2. Make changes following code style guidelines
3. Write/update tests
4. Run lint: `npm run lint`
5. Run tests: `npm test`
6. Commit with conventional commit format
7. Open PR for review

### Testing
- Unit tests: `npm test`
- Integration tests: `npm run test:integration`
- E2E tests: `npm run test:e2e`

### Debugging
- Dev tools: [browser dev tools, debugger setup]
- Logs: [where to find logs]
- Common issues: [link to troubleshooting]
```

---

## Step 5: Deployment Pipeline

**Read:**
- CI/CD configuration files
- Infrastructure code
- Deployment documentation

**Present:**

```
## Deployment Pipeline

### Environments
| Environment | URL | Purpose |
|-------------|-----|---------|
| Development | dev.example.com | Active development |
| Staging | staging.example.com | Pre-production testing |
| Production | example.com | Live users |

### Pipeline Stages
1. **Build** - Compile code, run linters
2. **Test** - Run unit and integration tests
3. **Deploy to Staging** - Automatic on main branch
4. **E2E Tests** - Run against staging
5. **Deploy to Production** - Manual approval required

### Rollback Procedure
[How to rollback if something goes wrong]
```

---

## Step 6: Code Navigation (Dependency Flow)

**Interactive walkthrough from external boundaries inward:**

```
External Dependencies (APIs, DBs, Third-party services)
    ↓
Infrastructure Layer (IaC, networking, deployment)
    ↓
Backend Services (APIs, workers, background jobs)
    ↓
Shared Libraries (utilities, types, common code)
    ↓
Frontend Application (state management, data fetching)
    ↓
User Interface (components, pages, routing)
```

**At each level:**

1. **List key directories/files:**
   ```
   ### Backend Services

   Key locations:
   - `src/api/` - REST API endpoints
   - `src/services/` - Business logic
   - `src/models/` - Data models
   - `src/workers/` - Background jobs
   ```

2. **Explain purpose** (2-3 sentences)

3. **Ask:** "Explore this level further?" or "Continue to next level?"

4. **If exploring:**
   - Read key files
   - Explain patterns used
   - Show example code paths
   - Identify entry points

---

## Session Memory

Throughout the onboarding, track:

- Which components were explored in depth
- Questions asked by the user
- Areas of particular interest
- Skipped sections

Use this to:
- Personalize remaining walkthrough
- Suggest relevant next steps
- Avoid repeating information

---

## Closing Summary

After completing all sections:

```
================================================================================
ONBOARDING COMPLETE
================================================================================

## What We Covered

- [List sections completed]
- [Note any sections explored in depth]

## Quick Reference

| Task | Command |
|------|---------|
| Run locally | `npm run dev` |
| Run tests | `npm test` |
| Build | `npm run build` |

## Recommended Next Steps

1. Set up your local environment
2. Review the current task list: `@agent-os/specs/phase-1/tasks.md`
3. Pick a small task to start with
4. Ask questions in [team channel]

## Key Files to Know

- Entry point: `src/index.ts`
- Main config: `config/default.ts`
- Route definitions: `src/api/routes.ts`

================================================================================
Ready to start contributing!
================================================================================
```

---

## Handling Questions

Throughout the onboarding:

- **Technical questions**: Answer directly from docs and code
- **"Go deeper" requests**: Provide detailed exploration
- **"Why" questions**: Reference design decisions from planning docs
- **"Where" questions**: Point to specific files and directories
- **Process questions**: Reference workflows and standards

If a question can't be answered from existing docs:
```
I don't see this documented in the current specs. This would be a good
topic to discuss with the team or document via `/professor-frink:refine`.
```
