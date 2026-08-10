# Workout PWA

A Nuxt 4 Progressive Web App for day-by-day workout tracking with a 4-day repeating cycle.

## Features

- First-time setup flow for level and split selection.
- Level-based programming logic for Beginner, Intermediate, and Advanced users.
- 4-day fixed cycle that repeats after Day 4.
- Complete-day progression with confirmation prompt.
- Persistent local storage state for offline-style continuity.
- PWA install support with in-app install button when available.
- Static site generation ready (`npm run generate`).

## Screenshots

### Setup Screen

![Setup screen](docs/screenshots/setup-screen.png)

### Workout Screen (Desktop)

![Workout desktop](docs/screenshots/workout-screen.png)

### Workout Screen (Mobile)

![Workout mobile](docs/screenshots/workout-mobile.png)

## Run Locally

```bash
npm install
npm run dev
```

Local app: `http://localhost:3000`

## Build

```bash
npm run build
```

## Generate Static Output

```bash
npm run generate
```

Generated output: `.output/public`

## Deploy

The app is deployed to **[workout.itsash.in](https://workout.itsash.in)** via GitHub Pages.

GitHub Pages workflow is configured to deploy on push to `master` via:

- `.github/workflows/deploy-pages.yml`

### Custom domain setup

- `public/CNAME` contains `workout.itsash.in`.
- In GitHub repo → **Settings → Pages → Custom domain**, set `workout.itsash.in` and enable **Enforce HTTPS**.
- Add a `CNAME` DNS record pointing `workout.itsash.in` to `<github-user>.github.io`.
