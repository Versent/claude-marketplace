# {{PROJECT_NAME}} Claude.md Template

This template is used by Professor Frink to generate the project's `claude.md` file.
The generator populates variables using data from agent-os and discovery questions.

---

## Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{{PROJECT_NAME}}` | agent-os/config.yml or package.json | Project name |
| `{{MISSION_SUMMARY}}` | agent-os/product/mission.md | One-line mission statement |
| `{{TECH_STACK_SUMMARY}}` | agent-os/product/tech-stack.md | Comma-separated tech list |
| `{{BUILD_COMMAND}}` | package.json scripts.build | Build command |
| `{{TEST_COMMAND}}` | package.json scripts.test | Test command |
| `{{LINT_COMMAND}}` | package.json scripts.lint | Lint command |
| `{{DEV_COMMAND}}` | package.json scripts.dev | Dev server command |
| `{{DEPLOY_COMMAND}}` | package.json scripts.deploy or CI/CD | Deploy command |
| `{{ARCHITECTURE_SUMMARY}}` | Discovery questions | Architecture overview |
| `{{CODE_STYLE_RULES}}` | Discovery questions | Code style summary |
| `{{TESTING_SUMMARY}}` | Discovery questions | Testing approach |
| `{{KEY_DECISIONS}}` | agent-os/specs/*/planning | Key architectural decisions |
| `{{GOTCHAS}}` | Discovery questions | Common pitfalls |
| `{{PHASE}}` | Current phase from agent-os/specs | Current development phase |

---

## Generated Output Format

The generated `claude.md` follows this structure (60-75 lines):

```markdown
# {{PROJECT_NAME}}

> {{MISSION_SUMMARY}}

## Quick Reference

- **Stack:** {{TECH_STACK_SUMMARY}}
- **Build:** `{{BUILD_COMMAND}}`
- **Test:** `{{TEST_COMMAND}}`
- **Lint:** `{{LINT_COMMAND}}`

## Architecture

{{ARCHITECTURE_SUMMARY}}

See @agent-os/specs/{{PHASE}}/spec.md for detailed architecture.

## Code Style

{{CODE_STYLE_RULES}}

See @.claude/rules/code-style.md for complete guidelines.

## Testing

{{TESTING_SUMMARY}}

See @.claude/rules/testing.md for test patterns.

## Common Tasks

| Task | Command |
|------|---------|
| Run dev server | `{{DEV_COMMAND}}` |
| Run tests | `{{TEST_COMMAND}}` |
| Build | `{{BUILD_COMMAND}}` |
| Deploy | `{{DEPLOY_COMMAND}}` |

## Key Decisions

{{KEY_DECISIONS}}

## Gotchas

{{GOTCHAS}}

---

For detailed standards: @.claude/rules/
For project tasks: @agent-os/specs/{{PHASE}}/tasks.md
```

---

## Design Principles

### Balanced Mix Approach

The claude.md file should provide:

1. **Overview** (20%) - Quick understanding of what the project does
2. **Guidelines** (40%) - Actionable rules for coding in this project
3. **References** (40%) - Pointers to detailed documentation

### Progressive Disclosure

- Start with the most critical information
- Use `@` references to link to detailed docs
- Keep the file scannable with clear headers

### Line Count Target

- **Minimum**: 60 lines - enough context for meaningful guidance
- **Maximum**: 75 lines - prevents overwhelming the agent
- **Ideal**: 65-70 lines - balanced information density

### @-Reference Strategy

Use inline @-references to:
- Link to detailed rule files: `@.claude/rules/testing.md`
- Link to specs: `@agent-os/specs/phase-1/spec.md`
- Link to standards: `@agent-os/standards/frontend/components.md`

This allows the agent to pull in additional context only when needed.

---

## Customization

The template can be customized by:

1. **Adding sections** - Modify the generator to include project-specific sections
2. **Changing emphasis** - Adjust which sections are included based on project type
3. **Custom references** - Add project-specific documentation links

### Project Type Variations

**API-only projects:**
- Emphasize API guidelines
- Skip frontend sections
- Focus on testing and security

**Frontend-heavy projects:**
- Emphasize component patterns
- Include accessibility guidelines
- Focus on state management

**Infrastructure projects:**
- Emphasize IaC patterns
- Include deployment guidelines
- Focus on security and compliance

---

## Generator Integration

The `lib/claude-folder-generator.sh` script:

1. Reads agent-os files for variable values
2. Uses discovery question answers for summaries
3. Detects commands from package.json
4. Generates the final claude.md

See `lib/claude-folder-generator.sh` for implementation details.
