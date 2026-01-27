# MCP Skill Template

This template is used by Professor Frink to generate MCP server skill files.
Each detected MCP server gets a corresponding skill in `.claude/skills/`.

---

## Template Structure

```markdown
---
name: {{MCP_NAME}}
description: {{MCP_DESCRIPTION}}
---

# Using {{MCP_NAME}}

{{USAGE_OVERVIEW}}

## Available Tools

{{TOOL_LIST}}

## Common Tasks

{{TASK_EXAMPLES}}

## Best Practices

{{BEST_PRACTICES}}
```

---

## Template Variables

| Variable | Description |
|----------|-------------|
| `{{MCP_NAME}}` | MCP server name (e.g., context7, playwright) |
| `{{MCP_DESCRIPTION}}` | Brief description of what the MCP provides |
| `{{USAGE_OVERVIEW}}` | When and how to use this MCP |
| `{{TOOL_LIST}}` | List of available tools from the MCP |
| `{{TASK_EXAMPLES}}` | Common task examples with tool calls |
| `{{BEST_PRACTICES}}` | Tips for effective use |

---

## Auto-Detection Mapping

Professor Frink automatically suggests MCP servers based on detected tech stack:

| Tech Stack | Suggested MCP | Purpose |
|------------|---------------|---------|
| Any project | context7 | Documentation lookup |
| React/Vue/Angular/Svelte | playwright | Browser testing |
| Terraform | terraform-registry | Provider docs |
| AWS | aws-docs | Service documentation |
| Azure | azure-docs | Service documentation |
| GCP | gcp-docs | Google Cloud docs |
| PostgreSQL | postgres | Database queries |
| MySQL | mysql | Database queries |
| GitHub repo | github | PR/Issue management |

---

## Example: Context7 Skill

```markdown
---
name: context7
description: Documentation lookup for any library or framework
---

# Using Context7

Context7 provides up-to-date documentation for any programming library.
Use it when you need to look up API references, examples, or best practices.

## Available Tools

- `resolve-library-id` - Find the library ID for a package name
- `query-docs` - Query documentation for a specific library

## Common Tasks

### Look up React hooks documentation

1. First resolve the library:
   ```
   resolve-library-id: query="React hooks", libraryName="react"
   ```

2. Then query the docs:
   ```
   query-docs: libraryId="/facebook/react", query="useEffect cleanup"
   ```

### Find Next.js API routes documentation

1. Resolve library:
   ```
   resolve-library-id: query="Next.js API routes", libraryName="next.js"
   ```

2. Query docs:
   ```
   query-docs: libraryId="/vercel/next.js", query="API routes handlers"
   ```

## Best Practices

- Always resolve library ID before querying
- Be specific in your queries
- Include context about what you're trying to accomplish
```

---

## Example: Playwright Skill

```markdown
---
name: playwright
description: Browser testing and automation
---

# Using Playwright

Playwright enables browser automation for testing and scraping.
Use it for E2E tests, visual regression, and browser interactions.

## Available Tools

- `navigate` - Navigate to a URL
- `click` - Click an element
- `fill` - Fill a form field
- `screenshot` - Take a screenshot
- `evaluate` - Run JavaScript in the browser

## Common Tasks

### Run E2E test flow

1. Navigate to the application
2. Fill login form
3. Click submit
4. Verify redirect to dashboard

### Visual regression testing

1. Navigate to page
2. Wait for content to load
3. Take screenshot
4. Compare with baseline

## Best Practices

- Use data-testid selectors for reliability
- Wait for network idle before screenshots
- Clean up browser state between tests
```

---

## Example: Terraform Registry Skill

```markdown
---
name: terraform-registry
description: Terraform provider and module documentation
---

# Using Terraform Registry

Access Terraform provider documentation and module references.
Use it when writing or debugging Terraform configurations.

## Available Tools

- `search-providers` - Search for Terraform providers
- `get-provider-docs` - Get documentation for a provider
- `search-modules` - Search for Terraform modules
- `get-module-docs` - Get module documentation

## Common Tasks

### Look up AWS provider resource

1. Get provider docs:
   ```
   get-provider-docs: provider="hashicorp/aws", resource="aws_lambda_function"
   ```

### Find a VPC module

1. Search modules:
   ```
   search-modules: query="AWS VPC"
   ```

2. Get module docs:
   ```
   get-module-docs: namespace="terraform-aws-modules", name="vpc"
   ```

## Best Practices

- Use official providers when available
- Check module version compatibility
- Review module inputs and outputs before use
```

---

## Generator Integration

The `lib/claude-folder-generator.sh` script:

1. Detects tech stack from project configuration
2. Maps tech stack to suggested MCP servers
3. Generates skill files for each suggestion
4. Prompts user to confirm MCP installations

### Skill Generation Flow

```bash
# In generator script
detect_mcp_suggestions() {
    # Analyze tech stack
    # Return JSON array of suggestions
}

generate_mcp_skill() {
    # Create .claude/skills/{mcp-name}/SKILL.md
    # Use appropriate template based on MCP type
}
```

---

## Customization

Projects can customize MCP skills by:

1. **Adding project-specific examples** - Include common tasks for your codebase
2. **Removing unused tools** - Focus on tools actually used
3. **Adding team conventions** - Document how your team uses the MCP

---

## MCP Installation Prompt

After generating skill files, Professor Frink displays:

```
================================================================================
SUGGESTED MCP SERVERS
================================================================================

Based on your tech stack, these MCP servers would be helpful:

| MCP | Purpose | Install Command |
|-----|---------|-----------------|
| context7 | Documentation lookup | Already configured |
| playwright | Browser testing | /mcp add playwright |
| aws-docs | AWS documentation | /mcp add aws-docs |

Skill files have been generated in .claude/skills/
Install the MCPs above to enable these skills.
================================================================================
```
