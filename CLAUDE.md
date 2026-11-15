# Workout (package: workout / com.itsash.workout)

Android version of the Nuxt PWA. Repo: its-ash/workout.itsash.in, branch
`main` (default; this app, landing page `index.html` on Pages at
workout.itsash.in). The PWA is kept, unchanged, on branch `master`. The repo
name differs from the store id `workout`: `store.json` has the repo, and
Settings passes `UiUpdateSection(storeId: 'workout', repo: 'workout.itsash.in')`.
Push/Pull/Legs gym planner, offline. One home screen: split picker
(`UiSegmentedControl`), session card (shuffle / next variation), exercise list,
and a bottom bar with Start, then the session clock and Stop (dialog: Stop, or
Stop & export to Calendar). Export opens `SessionCompleteSheet`: it renders
`SessionSummaryCard` (360 dp wide, PNG at 3x = 1080 px) from a
`RepaintBoundary`, saves it to `Pictures/Workout` (MediaStore), then opens the
calendar insert with the image's location in the description. Calendar insert
intents cannot attach files, so the image itself is in the gallery; Share sends
it anywhere (FileProvider, `res/xml/file_paths.xml`). App bar: stretching routine sheet, interval walk timer
sheet, Settings. The run/walk row in every session opens the run/walk timer.

## Code layout

- `lib/core/` (pure Dart, tested in `test/core_test.dart`):
  - `sessions.dart`: the program, ported line for line from the web app's
    `src/workout-sessions.ts`. Lines are `Name - plan, plan`.
  - `plan.dart`: `WorkoutLine.parse`, length estimate (40 s per set + rest),
    `sessionMeta`, clock labels.
  - `intervals.dart`: `IntervalPlan` (segment at time, time left, progress,
    calories = MET x 3.5 x 70 kg / 200 per min), `runWalkPlan`, `intervalWalkPlan`.
  - `stretches.dart`: the 20 stretches and their GIF file names.
  - `matcher.dart`: port of the web's `findGifForWorkout`. Used only by
    `tool/import_web.dart`, not at runtime.
- `lib/data/demos.dart`: `DemoLibrary` over `assets/data/demos.json`, keyed
  `<split>|<exercise name>` (the matcher depends on the split).
- `lib/state/`: `WorkoutStore` (split, variation, session start time, all in
  `shared_preferences`) and `IntervalTimer` (wall-clock anchor in prefs, beeps
  once a second in the last 5 s of a segment). Both take a `now` for tests.
- `lib/platform/platform_channel.dart` + `MainActivity.kt`: channel
  `com.itsash.workout/platform`: `beep` (ToneGenerator, alarm stream),
  `keepScreenOn`, `addToCalendar` (ACTION_INSERT on CalendarContract, falls
  back to the Google Calendar web URL), `saveImage`, `shareImage`.
- `lib/screens/`, `lib/widgets/`: UI from the shared theme only. GIFs sit on a
  white tile (`DemoGif`) in both modes. Accent `0xFF4D7C0F` (the web's lime,
  darkened for light mode); the icon uses the web's `#C8FF4D` on `#111411`.

## Demo assets

`assets/gifs/` and `assets/data/demos.json` are generated:
`make import WEB=<checkout of workout.itsash.in>`. It bundles only the GIFs
used by the program and the stretches (~10 MB of 125 MB). Re-run it after
changing `sessions.dart` or `stretches.dart`; `test/core_test.dart` fails if a
line has no demo or a GIF is missing or unused.

## Behaviour notes

- Closing a timer sheet pauses that timer (as in the web app). A timer still
  running from a killed app reopens its sheet on start.
- The split picker, shuffle and next are disabled while a session runs.
- Screen stays on during a session and while a timer sheet is open.

## Commands

- `make run`, `make test` (analyze + tests), `make build` (release APK),
  `make import`.
- Format: `dart format -l 120 lib test tool`.

## Release

Ash Store kit: `store.json`, `store.mk` (copied from `ash-store/store-kit/`
with `make store-sync` at the root). `make deploy` bumps, builds, commits,
tags, pushes and publishes `workout.apk`. Never hand-craft releases.
