# Workout PWA

## Project Overview
Nuxt 4 PWA for split workout tracking. Static site (Nitro `static` preset, prerendered). Uses `@vite-pwa/nuxt`.

## Tech Stack
- **Framework**: Nuxt 4 (`nuxt` v4.4.x), Vue 3.5.x
- **Language**: TypeScript (~6.x), strict via `vue-tsc`
- **PWA**: `@vite-pwa/nuxt` — `generateSW` strategy, `registerType: "prompt"` (no auto-update dialog)
- **Linting**: `@nuxt/eslint-config` (flat config, stylistic + tooling enabled) via `eslint.config.mjs`
- **Package manager**: pnpm (see `package-lock.json` present; Makefile uses pnpm)
- **Node**: use current LTS (create `.nvmrc` if not present)

## Project Structure
```
src/                 # app source (srcDir: "src/")
  app.vue            # root component — workout UI, stretching modal, run timer
  module.ts          # Nuxt module definition (module author setup)
  assets/main.css    # global styles (no CSS framework, custom design system via CSS vars)
public/
  data/
    exercises.json   # exercise dataset (1324 entries; languages: en, hi only)
    exercises.schema.json  # JSON Schema for exercises.json (en, hi only)
  images/ videos/    # exercise media
nuxt.config.ts       # config: srcDir, PWA manifest, Nitro static preset
eslint.config.mjs     # flat ESLint config via @nuxt/eslint-config
Makefile             # deploy / run / commit commands
```

## Commands
- `make run` — start dev server (`pnpm nuxt dev`)
- `make deploy` — bump patch version, build (`nuxt build`), commit with Copilot-generated message, push
- `make commit` — stage all and commit with Copilot-generated message (`gh copilot suggest -t commit`)
- `pnpm lint` — run ESLint
- `pnpm test` — run Vitest
- `pnpm test:types` — type-check with `vue-tsc --noEmit`

## Conventions
- **Code style**: ESLint flat config enforces `@stylistic` rules — follow existing formatting; quotes/indentation are enforced.
- **Vue SFCs**: `<script setup lang="ts">`; keep reactive state in `reactive`/`ref`; use `computed` for derived values.
- **No CSS framework**: use CSS variables defined in `src/assets/main.css`; match the existing brutalist design (2px borders, hard box-shadows).
- **No comments** in code unless explicitly requested.
- **i18n**: exercise instructions support only `en` and `hi`. Do not add other languages; update `exercises.schema.json` if language set changes.
- **PWA**: updates require manual prompt — do not reintroduce `autoUpdate` or auto-update banners.

## Data
- `public/data/exercises.json`: array of 1324 exercise records. Each has `instructions` and `instruction_steps` keyed by language (`en`, `hi` only). Validate against `exercises.schema.json` before committing changes.
- Schema requires: `id`, `name`, `category`, `body_part`, `equipment`, `instructions`, `instruction_steps`, `muscle_group`, `secondary_muscles`, `target`, `media_id`, `image`, `gif_url`, `attribution`, `created_at`.

## Git & Deployment
- `git init` already done; `.gitignore` excludes `node_modules`, `.nuxt`, `dist`, `.output`, env files.
- Deploy via `make deploy` (version bump → build → commit → push). GitHub Actions workflows exist in `.github/workflows/` (`ci.yml`, `deploy-pages.yml`).

## Homebrew / Distribution
- If distributing via Homebrew, update the formula in the tap repo (`https://github.com/its-ash/homebrew-tap`, local: `/Users/ashvinijangid/Desktop/homebrew-tap`) on each new version push.