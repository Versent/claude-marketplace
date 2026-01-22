# Example Versent Toolkit

> **This is an example plugin.** Copy this folder to create your own toolkit plugin.

A "toolkit" plugin bundles multiple general-purpose agents, skills, and commands into a single installable package. This pattern works well for:

- Team-wide utilities everyone should have
- Related tools that make sense together
- Starter kits for new team members

## What's Included

| Type | Name | Description |
|------|------|-------------|
| Command | `/greet` | A friendly greeting command |
| Agent | `reviewer` | Code review assistant |
| Skill | `summarize` | Summarize code or documentation |

## Creating Your Own Toolkit

1. Copy this folder: `cp -r example-versent-toolkit your-toolkit`
2. Update `.claude-plugin/plugin.json` with your plugin name and description
3. Add/remove/modify agents, commands, and skills as needed
4. Add your plugin to the marketplace manifest (`.claude-plugin/marketplace.json`)
5. Submit a PR

## Structure

```
example-versent-toolkit/
├── .claude-plugin/
│   └── plugin.json      # Plugin manifest
├── agents/
│   └── reviewer.md      # Code review agent
├── commands/
│   └── greet.md         # /greet command
├── skills/
│   └── summarize.md     # Summarization skill
└── README.md            # This file
```
