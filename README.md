# Versent Claude Marketplace

A curated collection of Claude Code plugins for Versent engineering teams.

## Installation

### Add the Marketplace

```bash
# From GitHub (once published)
/plugin marketplace add versent/claude-marketplace

# For private repositories, set your GitHub token first
export GITHUB_TOKEN=ghp_your_token_here
```

### Local Development

```bash
# Add from local path
/plugin marketplace add /path/to/claude-marketplace
```

### Install Plugins

```bash
# Browse available plugins
/plugin discover

# Install a specific plugin
/plugin install example-versent-toolkit@versent-marketplace
/plugin install professor-frink@versent-marketplace
/plugin install worktree-manager@versent-marketplace

# List installed plugins
/plugin list
```

## Available Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| `example-versent-toolkit` | 1.0.0 | EXAMPLE: Template toolkit plugin - copy this to create your own |
| `professor-frink` | 0.1.0 | Autonomous multi-session Claude Code plugin with HITL checkpoints, fresh context windows per task, and self-healing validation |
| `worktree-manager` | 1.0.0 | Task management using git worktrees for parallel development with automated workspace isolation |

## Plugin Development Guide

### Plugin Structure

Each plugin lives in its own directory under `plugins/`:

```
plugins/your-plugin/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (required)
├── commands/                 # Slash commands
│   └── your-command.md
├── agents/                   # Specialized agents
│   └── your-agent.md
└── skills/                   # Reusable skills
    └── your-skill.md
```

### Plugin Manifest (`plugin.json`)

```json
{
  "name": "your-plugin",
  "description": "What your plugin does",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "you@versent.com.au"
  },
  "keywords": ["relevant", "keywords"],
  "commands": [
    {
      "name": "command-name",
      "description": "What the command does",
      "file": "./commands/command-name.md"
    }
  ],
  "agents": [
    {
      "name": "agent-name",
      "description": "What the agent does",
      "file": "./agents/agent-name.md"
    }
  ],
  "skills": [
    {
      "name": "skill-name",
      "description": "What the skill does",
      "file": "./skills/skill-name.md"
    }
  ]
}
```

### Slash Commands

Commands are markdown files that define behavior when a user runs `/command-name`:

```markdown
# /command-name Command

Description of what this command does.

## Usage

/command-name [arguments]

## Instructions

Detailed instructions for Claude on how to handle this command...
```

### Agents

Agents are specialized assistants with YAML frontmatter defining their capabilities:

```markdown
---
name: agent-name
description: What this agent specializes in
model: sonnet
tools:
  - Read
  - Glob
  - Grep
---

# Agent Name

Instructions for the agent's behavior...
```

### Skills

Skills are reusable prompt templates:

```markdown
# Skill Name

Instructions for how to perform this skill...

## Output Format

Expected output structure...
```

## Contributing

### Adding a New Plugin

1. Create a new directory under `plugins/`
2. Add the required `.claude-plugin/plugin.json` manifest
3. Add your commands, agents, and/or skills
4. Update the marketplace manifest (`.claude-plugin/marketplace.json`)
5. Submit a pull request

### Updating the Marketplace Manifest

When adding a plugin, add an entry to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "your-plugin",
      "description": "Brief description",
      "version": "1.0.0",
      "path": "./plugins/your-plugin"
    }
  ]
}
```

### Testing Locally

```bash
# Validate marketplace structure
/plugin validate /path/to/claude-marketplace

# Test plugin installation
/plugin marketplace add /path/to/claude-marketplace
/plugin install your-plugin@versent-marketplace
```

## Resources

- [Official Claude Code Plugin Docs](https://code.claude.com/docs/en/plugins)
- [Plugin Marketplace Guide](https://code.claude.com/docs/en/plugin-marketplaces)
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)

## License

Internal use only - Versent Pty Ltd
