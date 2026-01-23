# Phase 1: Foundation Tasks

This is a sample tasks.md file for testing Professor Frink.

## Task Group 1: Project Setup

### Task 1.1: Initialize Project Structure

**Description:** Create the basic project structure with package.json and folders.

**Acceptance Criteria:**
- [ ] package.json exists with name and version
- [ ] src/ directory exists
- [ ] test/ directory exists
- [ ] README.md exists

**Files to Create:**
- package.json
- src/.gitkeep
- test/.gitkeep
- README.md

**Verification:**
```bash
test -f package.json && test -d src && test -d test
```

---

### Task 1.2: Add TypeScript Configuration

**Description:** Configure TypeScript for the project.

**Acceptance Criteria:**
- [ ] tsconfig.json exists with strict mode
- [ ] src/index.ts exists as entry point
- [ ] TypeScript compiles without errors

**Files to Create:**
- tsconfig.json
- src/index.ts

**Verification:**
```bash
npx tsc --noEmit
```

---

### Task 1.3: Add ESLint Configuration

**Description:** Set up ESLint for code quality.

**Acceptance Criteria:**
- [ ] .eslintrc.json exists
- [ ] ESLint runs without errors on src/

**Files to Create:**
- .eslintrc.json

**Verification:**
```bash
npx eslint src/
```

---

## Task Group 2: Core Features

### Task 2.1: Create Utility Functions

**Description:** Add basic utility functions to the project.

**Acceptance Criteria:**
- [ ] src/utils.ts exists with at least one exported function
- [ ] Function has JSDoc documentation
- [ ] Function has corresponding test

**Files to Create:**
- src/utils.ts
- test/utils.test.ts

**Verification:**
```bash
npm test
```

---

### Task 2.2: Add CLI Entry Point

**Description:** Create a simple CLI that uses the utilities.

**Acceptance Criteria:**
- [ ] src/cli.ts exists
- [ ] CLI can be run with `npx ts-node src/cli.ts`
- [ ] CLI outputs usage when called without args

**Files to Create:**
- src/cli.ts

**Verification:**
```bash
npx ts-node src/cli.ts --help
```

---

## Summary

| Group | Tasks | Description |
|-------|-------|-------------|
| 1 | 3 | Project Setup |
| 2 | 2 | Core Features |
| **Total** | **5** | |
