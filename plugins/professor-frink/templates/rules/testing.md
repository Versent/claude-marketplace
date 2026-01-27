# Testing Rule Template

This template generates `.claude/rules/testing.md` for projects.

---

## Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{{TEST_FRAMEWORK}}` | Tech stack detection | Jest, Vitest, Pytest, etc. |
| `{{COVERAGE_TARGET}}` | Discovery questions | Coverage percentage |
| `{{E2E_TOOL}}` | Discovery questions | Playwright, Cypress, etc. |
| `{{MOCK_STRATEGY}}` | Discovery questions | Mocking approach |

---

## Default Template

```markdown
---
paths: "**/test/**,**/*.test.*,**/*.spec.*"
---

# Testing Guidelines

## Test Structure

- Use describe/it blocks with clear descriptions
- Follow Arrange-Act-Assert pattern
- One assertion per test when possible
- Name tests: 'should [expected behavior] when [condition]'

## Coverage

- Aim for {{COVERAGE_TARGET}}%+ coverage on business logic
- 100% coverage on utility functions
- Critical paths require integration tests

## Mocking

- Mock external dependencies, not internal modules
- Use dependency injection for testability
- Reset mocks between tests
- Prefer spies over mocks when verifying calls

## E2E Testing

- Test critical user flows end-to-end
- Use data-testid attributes for selectors
- Avoid testing implementation details
- Keep E2E tests focused and fast

## Test Organization

- Mirror source directory structure
- Co-locate unit tests with source files
- Separate integration and E2E tests
- Use fixtures for test data
```

---

## Framework-Specific Variations

### Jest/Vitest

```markdown
## Jest/Vitest Specifics

- Use `describe.each` for parameterized tests
- Prefer `toEqual` over `toBe` for objects
- Use `mockResolvedValue` for async mocks
- Clean up with `beforeEach`/`afterEach`
```

### Pytest

```markdown
## Pytest Specifics

- Use fixtures for test setup
- Use `@pytest.mark.parametrize` for test variations
- Use `pytest-asyncio` for async tests
- Organize tests in classes when related
```

### Go Testing

```markdown
## Go Testing Specifics

- Use table-driven tests
- Use `t.Helper()` in test helpers
- Use `testify/assert` for cleaner assertions
- Use `t.Parallel()` for independent tests
```

---

## Paths Frontmatter

This rule includes `paths:` frontmatter to only load when working on test files:

```yaml
paths: "**/test/**,**/*.test.*,**/*.spec.*"
```
