# Frontend Rule Template

This template generates `.claude/rules/frontend.md` for projects.

---

## Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{{FRAMEWORK}}` | Tech stack detection | React, Vue, Angular, etc. |
| `{{STATE_MANAGEMENT}}` | Discovery questions | Redux, Zustand, Pinia, etc. |
| `{{STYLING_APPROACH}}` | Discovery questions | CSS Modules, Tailwind, etc. |
| `{{A11Y_LEVEL}}` | Discovery questions | WCAG level (A, AA, AAA) |

---

## Default Template

```markdown
---
paths: "**/components/**,**/pages/**,**/views/**,**/*.tsx,**/*.jsx,**/*.vue"
---

# Frontend Guidelines

## Components

- Keep components small and focused (single responsibility)
- Use composition over inheritance
- Separate presentation from logic (container/presentational pattern)
- Use TypeScript interfaces for props
- Document complex components with JSDoc

## State Management

- Keep state as local as possible
- Lift state up only when necessary
- Use context sparingly (performance implications)
- Consider state machines for complex flows
- Normalize complex state shapes

## Performance

- Lazy load routes and heavy components
- Memoize expensive computations
- Use virtualization for long lists
- Optimize images and assets
- Monitor bundle size

## Accessibility

- Use semantic HTML elements
- Include ARIA labels where needed
- Ensure keyboard navigation works
- Test with screen readers
- Maintain color contrast ratios
- Provide alt text for images

## Styling

- Use consistent spacing scale
- Follow design system tokens
- Keep styles co-located with components
- Use CSS variables for theming
- Mobile-first responsive design

## Forms

- Validate on blur and submit
- Show clear error messages
- Preserve input on errors
- Support keyboard submission
- Implement proper loading states
```

---

## React Variations

```markdown
## React Specifics

- Use functional components with hooks
- Prefer `useMemo` and `useCallback` sparingly
- Use React.lazy for code splitting
- Implement error boundaries
- Use React Query/SWR for server state
```

---

## Vue Variations

```markdown
## Vue Specifics

- Use Composition API for new components
- Prefer `<script setup>` syntax
- Use Pinia for global state
- Leverage Vue's built-in transitions
- Use computed properties for derived state
```

---

## Angular Variations

```markdown
## Angular Specifics

- Use OnPush change detection
- Leverage async pipe for observables
- Use standalone components
- Implement proper unsubscription
- Use Angular CDK for common patterns
```

---

## Paths Frontmatter

```yaml
paths: "**/components/**,**/pages/**,**/views/**,**/*.tsx,**/*.jsx,**/*.vue"
```
