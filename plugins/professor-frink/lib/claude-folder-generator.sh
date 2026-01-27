#!/bin/bash
# ==============================================================================
# Claude Folder Generator - Generate .claude/ Structure
# ==============================================================================
#
# Generates the .claude/ folder structure including:
# - claude.md (project overview, 60-75 lines)
# - .claude/rules/ (domain-based rule files)
# - .claude/skills/ (MCP skill suggestions)
#
# Usage:
#   source lib/claude-folder-generator.sh
#   generate_claude_folder "/path/to/project"
#
# ==============================================================================

GENERATOR_CONFIG_FILE=""
GENERATOR_PROJECT_DIR=""

# Initialize the generator with project context
# Arguments:
#   $1 - Project directory
#   $2 - Config file (typically .frink/generator-config.json)
generator_init() {
    local project_dir="${1:-.}"
    local config_file="${2:-.frink/generator-config.json}"

    GENERATOR_PROJECT_DIR="$project_dir"
    GENERATOR_CONFIG_FILE="$config_file"

    cat > "$config_file" << 'EOF'
{
  "version": "1.0.0",
  "generated_at": null,
  "project": {
    "name": "",
    "mission": "",
    "tech_stack": {},
    "commands": {
      "build": "",
      "test": "",
      "lint": "",
      "dev": "",
      "deploy": ""
    }
  },
  "rules_generated": [],
  "skills_suggested": [],
  "mcp_servers": []
}
EOF

    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.generated_at = $ts' \
        "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
}

# Set project metadata from agent-os or package.json
# Arguments:
#   $1 - Project name
#   $2 - Mission summary
set_project_metadata() {
    local name="$1"
    local mission="$2"

    jq --arg name "$name" --arg mission "$mission" \
        '.project.name = $name | .project.mission = $mission' \
        "$GENERATOR_CONFIG_FILE" > "${GENERATOR_CONFIG_FILE}.tmp" && \
        mv "${GENERATOR_CONFIG_FILE}.tmp" "$GENERATOR_CONFIG_FILE"
}

# Set a command
# Arguments:
#   $1 - Command type (build, test, lint, dev, deploy)
#   $2 - Command value
set_command() {
    local cmd_type="$1"
    local cmd_value="$2"

    jq --arg type "$cmd_type" --arg value "$cmd_value" \
        '.project.commands[$type] = $value' \
        "$GENERATOR_CONFIG_FILE" > "${GENERATOR_CONFIG_FILE}.tmp" && \
        mv "${GENERATOR_CONFIG_FILE}.tmp" "$GENERATOR_CONFIG_FILE"
}

# Set tech stack item
# Arguments:
#   $1 - Layer (frontend, backend, database, infrastructure, etc.)
#   $2 - Technology name
set_tech_stack() {
    local layer="$1"
    local tech="$2"

    jq --arg layer "$layer" --arg tech "$tech" \
        '.project.tech_stack[$layer] = $tech' \
        "$GENERATOR_CONFIG_FILE" > "${GENERATOR_CONFIG_FILE}.tmp" && \
        mv "${GENERATOR_CONFIG_FILE}.tmp" "$GENERATOR_CONFIG_FILE"
}

# Create the .claude directory structure
create_claude_directories() {
    local project_dir="${1:-$GENERATOR_PROJECT_DIR}"

    mkdir -p "$project_dir/.claude/rules"
    mkdir -p "$project_dir/.claude/skills"

    echo "Created .claude/ directory structure"
}

# Generate claude.md from template and config
# Arguments:
#   $1 - Project directory
#   $2 - Additional content sections (JSON)
generate_claude_md() {
    local project_dir="${1:-$GENERATOR_PROJECT_DIR}"
    local additional_content="${2:-{}}"

    local config
    config=$(cat "$GENERATOR_CONFIG_FILE")

    local name
    name=$(echo "$config" | jq -r '.project.name')

    local mission
    mission=$(echo "$config" | jq -r '.project.mission')

    local build_cmd
    build_cmd=$(echo "$config" | jq -r '.project.commands.build // "npm run build"')

    local test_cmd
    test_cmd=$(echo "$config" | jq -r '.project.commands.test // "npm test"')

    local lint_cmd
    lint_cmd=$(echo "$config" | jq -r '.project.commands.lint // "npm run lint"')

    local dev_cmd
    dev_cmd=$(echo "$config" | jq -r '.project.commands.dev // "npm run dev"')

    # Extract tech stack summary
    local tech_stack
    tech_stack=$(echo "$config" | jq -r '.project.tech_stack | to_entries | map("\(.key): \(.value)") | join(", ")')

    # Get additional sections
    local architecture
    architecture=$(echo "$additional_content" | jq -r '.architecture // "See @agent-os/specs/*/spec.md for detailed architecture."')

    local code_style
    code_style=$(echo "$additional_content" | jq -r '.code_style // "See @.claude/rules/code-style.md for complete guidelines."')

    local testing
    testing=$(echo "$additional_content" | jq -r '.testing // "See @.claude/rules/testing.md for test patterns."')

    local key_decisions
    key_decisions=$(echo "$additional_content" | jq -r '.key_decisions // "Documented in agent-os/specs/*/planning/*.md"')

    local gotchas
    gotchas=$(echo "$additional_content" | jq -r '.gotchas // "None documented yet."')

    # Determine current phase from agent-os
    local phase="phase-1"
    if [ -d "$project_dir/agent-os/specs" ]; then
        phase=$(ls -1 "$project_dir/agent-os/specs" 2>/dev/null | head -1 || echo "phase-1")
    fi

    cat > "$project_dir/claude.md" << EOF
# $name

> $mission

## Quick Reference

- **Stack:** $tech_stack
- **Build:** \`$build_cmd\`
- **Test:** \`$test_cmd\`
- **Lint:** \`$lint_cmd\`

## Architecture

$architecture

## Code Style

$code_style

## Testing

$testing

## Common Tasks

| Task | Command |
|------|---------|
| Run dev server | \`$dev_cmd\` |
| Run tests | \`$test_cmd\` |
| Build | \`$build_cmd\` |
| Lint | \`$lint_cmd\` |

## Key Decisions

$key_decisions

## Gotchas

$gotchas

---

For detailed standards: @.claude/rules/
For project tasks: @agent-os/specs/$phase/tasks.md
EOF

    echo "Generated claude.md"
}

# Generate a domain-based rule file
# Arguments:
#   $1 - Domain name (code-style, testing, security, api, frontend, infrastructure)
#   $2 - Content
#   $3 - Paths pattern (optional, for conditional loading)
generate_rule_file() {
    local domain="$1"
    local content="$2"
    local paths="${3:-}"

    local project_dir="${GENERATOR_PROJECT_DIR:-.}"
    local rule_file="$project_dir/.claude/rules/${domain}.md"

    # Add frontmatter if paths specified
    if [ -n "$paths" ]; then
        cat > "$rule_file" << EOF
---
paths: $paths
---

$content
EOF
    else
        echo "$content" > "$rule_file"
    fi

    # Track generated rule
    jq --arg rule "$domain" '.rules_generated += [$rule]' \
        "$GENERATOR_CONFIG_FILE" > "${GENERATOR_CONFIG_FILE}.tmp" && \
        mv "${GENERATOR_CONFIG_FILE}.tmp" "$GENERATOR_CONFIG_FILE"

    echo "Generated rule: $domain"
}

# Generate MCP skill suggestion
# Arguments:
#   $1 - MCP server name
#   $2 - Skill description
#   $3 - Skill content
generate_mcp_skill() {
    local mcp_name="$1"
    local description="$2"
    local content="$3"

    local project_dir="${GENERATOR_PROJECT_DIR:-.}"
    local skill_dir="$project_dir/.claude/skills/$mcp_name"

    mkdir -p "$skill_dir"

    cat > "$skill_dir/SKILL.md" << EOF
---
name: $mcp_name
description: $description
---

$content
EOF

    # Track generated skill
    jq --arg skill "$mcp_name" '.skills_suggested += [$skill]' \
        "$GENERATOR_CONFIG_FILE" > "${GENERATOR_CONFIG_FILE}.tmp" && \
        mv "${GENERATOR_CONFIG_FILE}.tmp" "$GENERATOR_CONFIG_FILE"

    echo "Generated MCP skill: $mcp_name"
}

# Detect and suggest MCP servers based on tech stack
# Returns: JSON array of suggested MCP servers
detect_mcp_suggestions() {
    local config
    config=$(cat "$GENERATOR_CONFIG_FILE")

    local tech_stack
    tech_stack=$(echo "$config" | jq -r '.project.tech_stack | keys[]' 2>/dev/null)

    local suggestions="[]"

    # Always suggest context7 for documentation
    suggestions=$(echo "$suggestions" | jq '. += [{"name": "context7", "purpose": "Documentation lookup for any library"}]')

    for tech in $tech_stack; do
        case "$tech" in
            frontend)
                local frontend_tech
                frontend_tech=$(echo "$config" | jq -r '.project.tech_stack.frontend')
                case "$frontend_tech" in
                    *react*|*vue*|*angular*|*svelte*)
                        suggestions=$(echo "$suggestions" | jq '. += [{"name": "playwright", "purpose": "Browser testing and automation"}]')
                        ;;
                esac
                ;;
            infrastructure)
                local infra_tech
                infra_tech=$(echo "$config" | jq -r '.project.tech_stack.infrastructure')
                case "$infra_tech" in
                    *terraform*)
                        suggestions=$(echo "$suggestions" | jq '. += [{"name": "terraform-registry", "purpose": "Terraform provider documentation"}]')
                        ;;
                esac
                ;;
            cloud)
                local cloud_tech
                cloud_tech=$(echo "$config" | jq -r '.project.tech_stack.cloud')
                case "$cloud_tech" in
                    *aws*|*AWS*)
                        suggestions=$(echo "$suggestions" | jq '. += [{"name": "aws-docs", "purpose": "AWS service documentation"}]')
                        ;;
                    *azure*|*Azure*)
                        suggestions=$(echo "$suggestions" | jq '. += [{"name": "azure-docs", "purpose": "Azure service documentation"}]')
                        ;;
                    *gcp*|*GCP*|*google*)
                        suggestions=$(echo "$suggestions" | jq '. += [{"name": "gcp-docs", "purpose": "Google Cloud documentation"}]')
                        ;;
                esac
                ;;
            database)
                local db_tech
                db_tech=$(echo "$config" | jq -r '.project.tech_stack.database')
                case "$db_tech" in
                    *postgres*|*PostgreSQL*)
                        suggestions=$(echo "$suggestions" | jq '. += [{"name": "postgres", "purpose": "PostgreSQL database queries"}]')
                        ;;
                    *mysql*|*MySQL*)
                        suggestions=$(echo "$suggestions" | jq '. += [{"name": "mysql", "purpose": "MySQL database queries"}]')
                        ;;
                esac
                ;;
        esac
    done

    # Check for GitHub integration
    if [ -d ".git" ]; then
        local remote
        remote=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$remote" == *github* ]]; then
            suggestions=$(echo "$suggestions" | jq '. += [{"name": "github", "purpose": "GitHub PR and issue management"}]')
        fi
    fi

    # Store suggestions
    jq --argjson suggestions "$suggestions" '.mcp_servers = $suggestions' \
        "$GENERATOR_CONFIG_FILE" > "${GENERATOR_CONFIG_FILE}.tmp" && \
        mv "${GENERATOR_CONFIG_FILE}.tmp" "$GENERATOR_CONFIG_FILE"

    echo "$suggestions"
}

# Generate all default rule files
generate_default_rules() {
    local project_dir="${1:-$GENERATOR_PROJECT_DIR}"

    # Code Style Rules
    generate_rule_file "code-style" "# Code Style Guidelines

## Naming Conventions

- Use camelCase for variables and functions
- Use PascalCase for classes and components
- Use SCREAMING_SNAKE_CASE for constants
- Use kebab-case for file names

## Formatting

- Use consistent indentation (2 spaces for JS/TS, 4 for Python)
- Max line length: 100 characters
- Use trailing commas in multi-line structures
- Prefer single quotes for strings (except when containing quotes)

## Patterns

- Prefer functional programming patterns where appropriate
- Use early returns to reduce nesting
- Extract complex conditionals into named functions
- Use descriptive variable names over comments

## Imports

- Group imports: external, internal, relative
- Sort imports alphabetically within groups
- Avoid circular dependencies"

    # Testing Rules
    generate_rule_file "testing" "# Testing Guidelines

## Test Structure

- Use describe/it blocks with clear descriptions
- Follow Arrange-Act-Assert pattern
- One assertion per test when possible
- Name tests: 'should [expected behavior] when [condition]'

## Coverage

- Aim for 80%+ coverage on business logic
- 100% coverage on utility functions
- Critical paths require integration tests

## Mocking

- Mock external dependencies, not internal modules
- Use dependency injection for testability
- Reset mocks between tests

## E2E Testing

- Test critical user flows end-to-end
- Use data-testid attributes for selectors
- Avoid testing implementation details" \
    "**/test/**,**/*.test.*,**/*.spec.*"

    # Security Rules
    generate_rule_file "security" "# Security Guidelines

## Input Validation

- Validate all user input at system boundaries
- Use allowlists over denylists
- Sanitize data before display (XSS prevention)
- Use parameterized queries (SQL injection prevention)

## Authentication

- Never store passwords in plain text
- Use secure session management
- Implement proper logout functionality
- Use HTTPS for all communications

## Secrets

- Never commit secrets to version control
- Use environment variables or secrets manager
- Rotate credentials regularly
- Audit secret access

## Dependencies

- Keep dependencies updated
- Review security advisories
- Use lockfiles for reproducible builds"

    # API Rules
    generate_rule_file "api" "# API Guidelines

## REST Conventions

- Use nouns for resources, verbs for actions
- Use proper HTTP methods (GET, POST, PUT, DELETE)
- Return appropriate status codes
- Use consistent response format

## Request/Response

- Use JSON for request and response bodies
- Include Content-Type headers
- Implement pagination for list endpoints
- Use consistent error response format

## Versioning

- Version APIs in the URL (e.g., /api/v1/)
- Maintain backward compatibility
- Document breaking changes

## Documentation

- Document all endpoints
- Include request/response examples
- Document error codes and messages" \
    "**/api/**,**/routes/**,**/handlers/**"

    # Frontend Rules
    generate_rule_file "frontend" "# Frontend Guidelines

## Components

- Keep components small and focused
- Use composition over inheritance
- Separate presentation from logic
- Use prop types or TypeScript interfaces

## State Management

- Keep state as local as possible
- Lift state up only when necessary
- Use context sparingly
- Consider state machines for complex flows

## Performance

- Lazy load routes and heavy components
- Memoize expensive computations
- Optimize images and assets
- Monitor bundle size

## Accessibility

- Use semantic HTML
- Include ARIA labels where needed
- Ensure keyboard navigation
- Test with screen readers" \
    "**/components/**,**/pages/**,**/views/**,**/*.tsx,**/*.jsx"

    # Infrastructure Rules
    generate_rule_file "infrastructure" "# Infrastructure Guidelines

## Infrastructure as Code

- Version all infrastructure code
- Use modules for reusability
- Tag resources consistently
- Document resource purposes

## Environments

- Use separate environments (dev, staging, prod)
- Use consistent naming across environments
- Minimize differences between environments
- Use feature flags for gradual rollouts

## Monitoring

- Set up alerts for critical metrics
- Log structured data
- Implement health checks
- Monitor costs

## Security

- Apply least privilege principle
- Encrypt data at rest and in transit
- Use private networks where possible
- Regular security audits" \
    "**/terraform/**,**/infrastructure/**,**/deploy/**"

    echo "Generated all default rule files"
}

# Generate complete .claude folder
generate_claude_folder() {
    local project_dir="${1:-$GENERATOR_PROJECT_DIR}"

    create_claude_directories "$project_dir"
    generate_claude_md "$project_dir"
    generate_default_rules "$project_dir"

    # Detect and store MCP suggestions
    detect_mcp_suggestions > /dev/null

    echo ""
    echo "Claude folder generation complete!"
    echo ""
    echo "Generated files:"
    echo "  - claude.md"
    echo "  - .claude/rules/code-style.md"
    echo "  - .claude/rules/testing.md"
    echo "  - .claude/rules/security.md"
    echo "  - .claude/rules/api.md"
    echo "  - .claude/rules/frontend.md"
    echo "  - .claude/rules/infrastructure.md"
    echo ""
    echo "Suggested MCP servers:"
    jq -r '.mcp_servers[] | "  - \(.name): \(.purpose)"' "$GENERATOR_CONFIG_FILE"
}

# Get generation summary
get_generation_summary() {
    cat "$GENERATOR_CONFIG_FILE"
}

# Main entrypoint for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        init)
            generator_init "${2:-.}" "${3:-.frink/generator-config.json}"
            echo "Generator initialized"
            ;;
        generate)
            generate_claude_folder "${2:-.}"
            ;;
        claude-md)
            generate_claude_md "${2:-.}"
            ;;
        rules)
            generate_default_rules "${2:-.}"
            ;;
        detect-mcp)
            detect_mcp_suggestions
            ;;
        summary)
            get_generation_summary
            ;;
        *)
            echo "Usage: $0 {init|generate|claude-md|rules|detect-mcp|summary}"
            echo ""
            echo "Commands:"
            echo "  init [project_dir] [config_file]  Initialize generator"
            echo "  generate [project_dir]            Generate complete .claude folder"
            echo "  claude-md [project_dir]           Generate only claude.md"
            echo "  rules [project_dir]               Generate only rule files"
            echo "  detect-mcp                        Detect MCP server suggestions"
            echo "  summary                           Show generation config"
            ;;
    esac
fi
