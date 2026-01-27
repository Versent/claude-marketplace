---
description: Interactive onboarding for humans - walks you through the codebase architecture, patterns, and workflows so you can start contributing quickly.
---

# /professor-frink:onboard - Codebase Onboarding

Onboard yourself to this codebase with an interactive walkthrough guided by Professor Frink.

## What This Command Does

This command provides a structured walkthrough of the codebase to help you:

1. **Understand the Mission** - What this project does and why
2. **Learn the Tech Stack** - Technologies used and why they were chosen
3. **Explore the Architecture** - Components, services, and how they interact
4. **Learn the Workflow** - Local development, testing, and deployment
5. **Navigate the Code** - Entry points and key files

## Interactive Features

The onboarding is **adaptive** - you can:
- Ask to "go deeper" on any topic
- Skip sections you already understand
- Request examples and code walkthroughs
- Ask clarifying questions at any point

## Prerequisites

- Agent-OS must be initialized (`agent-os/` directory exists)
- Professor Frink should be initialized (`.frink/` directory recommended)

## Usage

```bash
/professor-frink:onboard
```

## Walkthrough Structure

### 1. Mission & Context (2 min)
Overview of what the project does, its users, and key goals.

### 2. Tech Stack Overview (3 min)
Languages, frameworks, tools, and why these choices were made.

### 3. Architecture Walk-through (5 min)
System components and how they communicate. Includes ASCII diagrams
and the option to dive deeper into any component.

### 4. Developer Workflow (3 min)
How to set up locally, run tests, and make changes.

### 5. Deployment Pipeline (3 min)
How code gets from your machine to production.

### 6. Code Navigation (5-10 min)
Interactive walkthrough following the dependency flow:
- External dependencies → Infrastructure → Services → Libraries → UI

## After Onboarding

You'll be ready to:
- Set up your local development environment
- Run and debug the application
- Understand where to make changes
- Follow project conventions
- Start on your first task

## Related Commands

- `/professor-frink:init` - Initialize Professor Frink (run first if not done)
- `/professor-frink:refine` - Update documentation based on learnings
- `/professor-frink:status` - Check project status and next tasks
