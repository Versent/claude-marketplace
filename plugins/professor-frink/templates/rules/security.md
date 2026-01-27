# Security Rule Template

This template generates `.claude/rules/security.md` for projects.

---

## Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{{AUTH_METHOD}}` | Discovery questions | JWT, Session, OAuth, etc. |
| `{{SECRETS_MANAGEMENT}}` | Discovery questions | Env vars, Secrets Manager, etc. |
| `{{COMPLIANCE_REQUIREMENTS}}` | Discovery questions | SOC2, HIPAA, etc. |

---

## Default Template

```markdown
# Security Guidelines

## Input Validation

- Validate all user input at system boundaries
- Use allowlists over denylists
- Sanitize data before display (XSS prevention)
- Use parameterized queries (SQL injection prevention)
- Validate file uploads (type, size, content)

## Authentication

- Never store passwords in plain text
- Use secure session management
- Implement proper logout functionality
- Use HTTPS for all communications
- Implement rate limiting on auth endpoints

## Authorization

- Verify permissions on every request
- Use role-based access control (RBAC)
- Check resource ownership before operations
- Fail closed (deny by default)

## Secrets

- Never commit secrets to version control
- Use environment variables or secrets manager
- Rotate credentials regularly
- Audit secret access
- Use different secrets per environment

## Dependencies

- Keep dependencies updated
- Review security advisories
- Use lockfiles for reproducible builds
- Audit dependencies regularly

## Data Protection

- Encrypt sensitive data at rest
- Use TLS for data in transit
- Implement proper data retention
- Log security events
- Mask sensitive data in logs
```

---

## Compliance-Specific Additions

### SOC 2

```markdown
## SOC 2 Compliance

- Implement audit logging for all data access
- Maintain access control documentation
- Implement change management procedures
- Regular security assessments
- Incident response procedures
```

### HIPAA

```markdown
## HIPAA Compliance

- Encrypt all PHI at rest and in transit
- Implement minimum necessary access
- Maintain audit trails for PHI access
- Business Associate Agreements required
- Regular risk assessments
```

### GDPR

```markdown
## GDPR Compliance

- Implement data subject rights (access, deletion)
- Maintain processing records
- Privacy by design principles
- Data breach notification procedures
- Consent management
```

---

## Paths Frontmatter

Security rules apply globally, so no paths filter is used.
