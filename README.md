# Workout

Push/Pull/Legs gym planner with exercise demos and treadmill interval timers. Works offline.

**[Website](https://workout.itsash.in)** · **[Download APK](https://github.com/its-ash/workout.itsash.in/releases/latest/download/workout.apk)** · Get it in **[Ash Store](https://store.itsash.in)**

The Android version of the Workout web app. The original Nuxt PWA is kept on
the [`master` branch](https://github.com/its-ash/workout.itsash.in/tree/master).

## Features

- Evidence-based Push / Pull / Legs program: six variations per split, each with sets, reps, RIR and rest times.
- Shuffle to a random variation or step to the next one. Your pick is remembered.
- Animated demo for every exercise, with target muscles, equipment and step-by-step instructions in English or Hindi.
- Session clock that keeps running if you close the app. The screen stays on during a session.
- Stop & export to Calendar: the session becomes a summary image (saved to Pictures/Workout, shareable) and a calendar event with its start, end, exercise list and the image's location.
- Run/walk finisher (10 min) and interval walking (20 min) timers: speed, incline, time left, calories, and a beep in the last 5 seconds before each speed change.
- Full body stretching routine with 20 animated stretches.
- No account, no ads, no tracking. The internet is used only to check for app updates.

## Install

- **Ash Store**: install [Ash Store](https://store.itsash.in) once, then install and update Workout from it.
- **APK**: download the [latest APK](https://github.com/its-ash/workout.itsash.in/releases/latest/download/workout.apk) on your phone and open it. Allow your browser to install unknown apps if Android asks.

Requires Android 8.0 or newer.

## Develop

Needs Flutter ≥ 3.44 and the shared theme package at `../theme`.

```bash
make run      # run on a connected device
make test     # analyze + tests
make build    # release APK
make import WEB=/path/to/workout.itsash.in   # re-pick demos from the web dataset
make deploy   # bump version, build, tag, push, GitHub release (see store.mk)
```

The exercise demos come from the web app's dataset (1324 exercises, 125 MB of
GIFs). `tool/import_web.dart` runs the same matcher as the web app for every
exercise in the program and bundles only the GIFs that are used (about 10 MB).

## Release

`make deploy` follows the Ash Store kit (`store.mk`, `store.json`): it bumps the
version in `pubspec.yaml`, builds, commits, tags `vX.Y.Z`, pushes, and publishes
a GitHub release with `workout.apk`. Ash Store and the website pick up the new
version from that release.

## Project layout

```
lib/
  core/        sessions (the program), plan, intervals, stretches, matcher (pure Dart)
  data/        demos.dart: bundled demo library
  state/       WorkoutStore (split, variation, session clock), IntervalTimer
  platform/    channel to MainActivity.kt: beep, keep screen on, calendar
  screens/     home, exercise sheet, stretching sheet, interval timer sheet, session complete, settings
  widgets/     DemoGif, SessionSummaryCard (the exported image)
assets/
  data/demos.json   workout line -> exercise, instructions (generated)
  gifs/             used demo GIFs (generated)
  icon/             launcher icon sources
tool/import_web.dart
android/app/src/main/kotlin/com/itsash/workout/MainActivity.kt
```

## License

No license file is included yet. Exercise demos © Gym visual (https://gymvisual.com/).

Built by [itsash.in](https://itsash.in).
