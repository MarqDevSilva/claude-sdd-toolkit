# Lint & Format — ESLint (flat) + Prettier

> `angular-eslint` flat config for linting, Prettier for formatting. One config at the workspace
> root; each project (`apps/*`, `libs/*`) is linted via `ng lint`.

## Install

```bash
ng add angular-eslint            # adds eslint + angular-eslint, flat config, lint target
npm i -D prettier eslint-config-prettier
```

`eslint-config-prettier` disables ESLint rules that would fight Prettier.

## `eslint.config.js` (flat, workspace root)

```javascript
// @ts-check
const eslint = require('@eslint/js');
const tseslint = require('typescript-eslint');
const angular = require('angular-eslint');

module.exports = tseslint.config(
  {
    files: ['**/*.ts'],
    extends: [
      eslint.configs.recommended,
      ...tseslint.configs.recommended,
      ...angular.configs.tsRecommended,
      require('eslint-config-prettier'),
    ],
    processor: angular.processInlineTemplates,
    rules: {
      '@angular-eslint/directive-selector': ['error', { type: 'attribute', prefix: 'app', style: 'camelCase' }],
      '@angular-eslint/component-selector': ['error', { type: 'element', prefix: 'app', style: 'kebab-case' }],
      '@angular-eslint/prefer-on-push-component-change-detection': 'error',
      '@angular-eslint/prefer-standalone': 'error',
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/explicit-function-return-type': ['warn', { allowExpressions: true }],
    },
  },
  {
    files: ['**/*.html'],
    extends: [
      ...angular.configs.templateRecommended,
      ...angular.configs.templateAccessibility,
    ],
    rules: {},
  },
);
```

> Per-app/lib selector prefixes: override `prefix` in a scoped config block (e.g. `libs/shared`
> uses `ui`, `apps/admin` uses `admin`). Enforcing distinct prefixes keeps boundaries visible.

## `.prettierrc`

```json
{
  "printWidth": 100,
  "singleQuote": true,
  "trailingComma": "all",
  "bracketSameLine": true,
  "overrides": [
    { "files": "*.html", "options": { "parser": "angular" } }
  ]
}
```

## npm scripts

```json
{
  "scripts": {
    "lint": "ng lint",
    "lint:fix": "ng lint --fix",
    "format": "prettier --write \"{apps,libs}/**/*.{ts,html,scss,json}\"",
    "format:check": "prettier --check \"{apps,libs}/**/*.{ts,html,scss,json}\""
  }
}
```

## Linting a single project

```bash
ng lint admin            # one app
ng lint shared           # one lib
ng lint                  # all projects in angular.json
```

## Workflow

1. `npm run format` before committing (or via editor format-on-save).
2. `ng lint` must be clean before pushing; `ng lint --fix` for autofixable issues.
3. Wire both into CI so a red lint/format fails the build.

## Recommended boundary discipline (no Nx enforcement here)

Native CLI has no automatic module-boundary rule. Keep boundaries by convention + review:
- `shared`/`core` never import `domains` or `apps`.
- `domains` never import `apps`.
- Only facades import `@org/api-client`.

If boundary drift becomes a real problem, `eslint-plugin-boundaries` can encode these as lint rules.
