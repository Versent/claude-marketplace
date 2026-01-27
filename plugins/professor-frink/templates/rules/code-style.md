# Code Style Rule Template

This template generates `.claude/rules/code-style.md` for projects.

---

## Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{{LANGUAGE}}` | Tech stack detection | Primary language (TypeScript, Python, etc.) |
| `{{INDENT_STYLE}}` | Discovery questions | Tabs or spaces |
| `{{INDENT_SIZE}}` | Discovery questions | Number of spaces |
| `{{QUOTE_STYLE}}` | Discovery questions | Single or double quotes |
| `{{NAMING_CONVENTION}}` | Discovery questions | Naming patterns |

---

## Default Template

```markdown
# Code Style Guidelines

## Naming Conventions

- Use camelCase for variables and functions
- Use PascalCase for classes and components
- Use SCREAMING_SNAKE_CASE for constants
- Use kebab-case for file names

## Formatting

- Use consistent indentation ({{INDENT_SIZE}} {{INDENT_STYLE}})
- Max line length: 100 characters
- Use trailing commas in multi-line structures
- Prefer {{QUOTE_STYLE}} quotes for strings

## Patterns

- Prefer functional programming patterns where appropriate
- Use early returns to reduce nesting
- Extract complex conditionals into named functions
- Use descriptive variable names over comments

## Imports

- Group imports: external, internal, relative
- Sort imports alphabetically within groups
- Avoid circular dependencies

## Comments

- Write comments for "why", not "what"
- Use JSDoc/TSDoc for public APIs
- Keep comments up to date with code changes
```

---

## Language-Specific Variations

### TypeScript

```markdown
## TypeScript Specifics

- Use explicit types for function parameters and returns
- Prefer `interface` over `type` for object shapes
- Use `readonly` for immutable properties
- Avoid `any` - use `unknown` with type guards
- Enable strict mode in tsconfig
```

### Python

```markdown
## Python Specifics

- Follow PEP 8 guidelines
- Use type hints for all functions
- Prefer f-strings over .format()
- Use list comprehensions when readable
- Use dataclasses for data structures
```

### Go

```markdown
## Go Specifics

- Follow Effective Go guidelines
- Use gofmt for formatting
- Prefer short variable names in short scopes
- Handle errors explicitly
- Use interfaces for abstraction
```

---

## Frontmatter

The generated file does not include `paths:` frontmatter since code style
applies to all files.
