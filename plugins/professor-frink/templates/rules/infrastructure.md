# Infrastructure Rule Template

This template generates `.claude/rules/infrastructure.md` for projects.

---

## Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{{IAC_TOOL}}` | Tech stack detection | Terraform, Pulumi, CDK |
| `{{CLOUD_PROVIDER}}` | Discovery questions | AWS, Azure, GCP |
| `{{DEPLOYMENT_STRATEGY}}` | Discovery questions | Blue/green, Canary, etc. |
| `{{ENVIRONMENTS}}` | Discovery questions | dev, staging, prod |

---

## Default Template

```markdown
---
paths: "**/terraform/**,**/infrastructure/**,**/deploy/**,**/cdk/**"
---

# Infrastructure Guidelines

## Infrastructure as Code

- Version all infrastructure code
- Use modules for reusability
- Tag all resources consistently:
  - Environment (dev/staging/prod)
  - Owner (team)
  - Project
  - Cost center
- Document resource purposes
- Review changes before apply

## Resource Naming

- Use consistent naming convention:
  `{project}-{environment}-{resource}-{identifier}`
- Keep names lowercase with hyphens
- Include environment in names
- Avoid abbreviations that aren't obvious

## Environments

- Use separate environments: dev, staging, prod
- Use consistent naming across environments
- Minimize differences between environments
- Use feature flags for gradual rollouts
- Prod should match staging as closely as possible

## State Management

- Use remote state storage
- Enable state locking
- Separate state per environment
- Never store secrets in state
- Regular state backups

## Modules

- One module per logical resource group
- Version modules explicitly
- Document module inputs/outputs
- Test modules before publishing
- Use semantic versioning

## Security

- Apply least privilege principle
- Encrypt data at rest and in transit
- Use private networks where possible
- Enable logging and auditing
- Regular security audits
- No hardcoded credentials

## Monitoring

- Set up alerts for critical metrics
- Log structured data
- Implement health checks
- Monitor costs
- Set up dashboards per service

## Deployment

- Automate deployments via CI/CD
- Use immutable infrastructure
- Implement rollback procedures
- Test deployments in staging first
- Document runbooks for incidents
```

---

## Terraform Variations

```markdown
## Terraform Specifics

- Use terraform fmt before commit
- Run terraform validate in CI
- Use workspaces sparingly (prefer separate states)
- Pin provider versions
- Use data sources over hardcoded values
- Enable detailed exit codes in CI
```

---

## AWS CDK Variations

```markdown
## CDK Specifics

- Use L2 constructs when available
- Implement proper removal policies
- Use environment variables for config
- Create reusable construct libraries
- Test with cdk-assertions
- Use cdk diff before deploy
```

---

## Pulumi Variations

```markdown
## Pulumi Specifics

- Use typed configuration
- Implement component resources
- Use stack references for cross-stack
- Test with unit tests
- Use automation API for CI/CD
```

---

## Paths Frontmatter

```yaml
paths: "**/terraform/**,**/infrastructure/**,**/deploy/**,**/cdk/**"
```
