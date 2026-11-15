/// The Push / Pull / Legs program, six variations per split. Ported from the
/// web app (`src/workout-sessions.ts`). Each line is `Name - plan, plan, ...`.
library;

enum SessionType {
  push('Push'),
  pull('Pull'),
  legs('Legs');

  const SessionType(this.label);
  final String label;

  static SessionType? byName(String? name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

class WorkoutSession {
  const WorkoutSession({required this.id, required this.type, required this.title, required this.workout});

  final String id;
  final SessionType type;
  final String title;
  final List<String> workout;
}

abstract final class _Abs {
  static const cableCrunch = 'Cable Crunch - 3 sets x 10-15 reps, RIR 0-1, rest 60s, full spinal flexion';
  static const hangingLegRaise = 'Hanging Leg Raise - 3 sets x 8-12 reps, RIR 0-1, rest 60s, control the descent';
  static const machineCrunch = 'Machine Crunch - 3 sets x 10-15 reps, RIR 0-1, rest 60s, add load weekly';
  static const cableReverseCrunch = 'Cable Reverse Crunch - 3 sets x 10-15 reps, RIR 0-1, rest 60s';
  static const reverseCrunch = 'Reverse Crunch - 3 sets x 12-20 reps, RIR 0-1, rest 60s, curl hips off the floor';
}

abstract final class _Obliques {
  static const cableTwist = 'Cable Twist - 3 sets x 10-15 reps each side, RIR 1, rest 45s, rotate through the ribs';
  static const pallofPress = 'Pallof Press - 3 sets x 10-12 reps each side, RIR 2, rest 45s';
  static const cableSideBend = 'Cable Side Bend - 3 sets x 12-15 reps each side, RIR 1, rest 45s, full stretch at top';
  static const hangingObliqueKneeRaise = 'Hanging Oblique Knee Raise - 3 sets x 8-12 reps each side, RIR 1, rest 45s';
  static const dumbbellSideBend =
      'Dumbbell Side Bend - 3 sets x 12-15 reps each side, RIR 1, rest 45s, full stretch at top';
  static const russianTwist = 'Weighted Russian Twist - 3 sets x 12-20 reps each side, RIR 1, rest 45s';
}

abstract final class _Serratus {
  static const pullover = 'Dumbbell Pullover - 2 sets x 10-15 reps, RIR 1, rest 90s, deep stretch overhead';
  static const pushUpPlus = 'Push-up Plus - 2 sets x 12-15 reps, RIR 1, rest 60s, spread shoulder blades at top';
}

/// Name of the treadmill finisher; its row opens the run/walk timer.
const runWalkName = 'Run/Walk Interval Protocol';
const _finisher = '$runWalkName - 10 min, run/walk intervals';

const workoutSessions = <WorkoutSession>[
  WorkoutSession(
    id: 'push-01',
    type: SessionType.push,
    title: 'Heavy Bench & Press',
    workout: [
      'Barbell Bench Press - 4 sets x 5-8 reps, RIR 1-2, rest 180s, 1s pause on chest',
      'Seated Dumbbell Shoulder Press - 3 sets x 8-10 reps, RIR 1-2, rest 150s',
      'Cable Standing Fly - 3 sets x 10-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Cable Lateral Raise - 4 sets x 12-20 reps, RIR 0-1, rest 60s',
      'Overhead Cable Triceps Extension - 3 sets x 10-15 reps, RIR 0-1, rest 90s, full stretch behind head',
      _Serratus.pullover,
      _Abs.cableCrunch,
      _Obliques.cableTwist,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'push-02',
    type: SessionType.push,
    title: 'Incline Chest Focus',
    workout: [
      'Barbell Incline Bench Press - 4 sets x 6-8 reps, RIR 1-2, rest 180s, 30 degree bench',
      'Dumbbell Bench Press - 3 sets x 8-12 reps, RIR 1-2, rest 150s, deep stretch at bottom',
      'Cable Incline Fly - 3 sets x 12-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Dumbbell Lateral Raise - 4 sets x 12-20 reps, RIR 0-1, rest 60s',
      'Skull Crusher - 3 sets x 8-12 reps, RIR 0-1, rest 90s, lower bar behind head',
      _Serratus.pushUpPlus,
      _Abs.hangingLegRaise,
      _Obliques.cableSideBend,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'push-03',
    type: SessionType.push,
    title: 'Shoulder Emphasis',
    workout: [
      'Standing Overhead Press - 4 sets x 5-8 reps, RIR 1-2, rest 180s',
      'Incline Dumbbell Press - 3 sets x 8-12 reps, RIR 1-2, rest 150s, deep stretch at bottom',
      'Cable Lateral Raise - 4 sets x 12-20 reps, RIR 0-1, rest 60s, last set lengthened partials',
      'Reverse Pec Deck - 3 sets x 15-20 reps, RIR 0-1, rest 60s',
      'Overhead Dumbbell Extension - 3 sets x 10-15 reps, RIR 0-1, rest 90s, full stretch behind head',
      _Serratus.pullover,
      _Abs.machineCrunch,
      _Obliques.pallofPress,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'push-04',
    type: SessionType.push,
    title: 'Machine Push',
    workout: [
      'Machine Incline Chest Press - 4 sets x 8-12 reps, RIR 1-2, rest 150s, full stretch at bottom',
      'Machine Shoulder Press - 3 sets x 8-12 reps, RIR 1-2, rest 120s',
      'Cable Standing Fly - 3 sets x 12-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Machine Lateral Raise - 4 sets x 12-20 reps, RIR 0-1, rest 60s',
      'Overhead Cable Triceps Extension - 3 sets x 10-15 reps, RIR 0-1, rest 90s, full stretch behind head',
      'Rope Triceps Pushdown - 2 sets x 12-15 reps, RIR 0, rest 60s',
      _Serratus.pushUpPlus,
      _Abs.machineCrunch,
      _Obliques.cableTwist,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'push-05',
    type: SessionType.push,
    title: 'Dumbbell Push',
    workout: [
      'Dumbbell Bench Press - 4 sets x 8-10 reps, RIR 1-2, rest 150s, deep stretch at bottom',
      'Dumbbell Shoulder Press - 3 sets x 8-12 reps, RIR 1-2, rest 120s',
      'Dumbbell Incline Fly - 3 sets x 10-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Seated Dumbbell Lateral Raise - 4 sets x 12-20 reps, RIR 0-1, rest 60s',
      'Overhead Dumbbell Extension - 3 sets x 10-15 reps, RIR 0-1, rest 90s, full stretch behind head',
      'Push-up Plus - 2 sets x AMRAP, RIR 0, rest 90s, spread shoulder blades at top',
      _Abs.reverseCrunch,
      _Obliques.russianTwist,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'push-06',
    type: SessionType.push,
    title: 'Close Grip & Dips',
    workout: [
      'Close Grip Bench Press - 4 sets x 6-8 reps, RIR 1-2, rest 180s',
      'Chest Dip - 3 sets x 8-12 reps, RIR 1-2, rest 150s, deep stretch at bottom',
      'Incline Dumbbell Press - 3 sets x 8-12 reps, RIR 1-2, rest 120s',
      'Cable Standing Fly - 3 sets x 12-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Cable Lateral Raise - 4 sets x 15-20 reps, RIR 0-1, rest 60s',
      'Overhead Cable Triceps Extension - 3 sets x 10-15 reps, RIR 0-1, rest 90s, full stretch behind head',
      _Abs.cableReverseCrunch,
      _Obliques.hangingObliqueKneeRaise,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'pull-01',
    type: SessionType.pull,
    title: 'Heavy Row & Pull-up',
    workout: [
      'Weighted Pull-up - 4 sets x 5-8 reps, RIR 1-2, rest 180s, full hang at bottom',
      'Barbell Pendlay Row - 3 sets x 6-10 reps, RIR 1-2, rest 150s',
      'Chest Supported Row - 3 sets x 10-12 reps, RIR 1-2, rest 120s, full stretch at bottom',
      'Face Pulls - 3 sets x 15-20 reps, RIR 0-1, rest 60s',
      'Barbell Preacher Curl - 3 sets x 8-12 reps, RIR 0-1, rest 90s, full extension at bottom',
      'Dumbbell Hammer Curl - 2 sets x 10-15 reps, RIR 0-1, rest 60s',
      _Abs.cableReverseCrunch,
      _Obliques.cableTwist,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'pull-02',
    type: SessionType.pull,
    title: 'Lat Width',
    workout: [
      'Lat Pulldown - 4 sets x 8-12 reps, RIR 1-2, rest 150s, full stretch at top',
      'Dumbbell Row - 3 sets x 8-12 reps each side, RIR 1-2, rest 120s, reach at bottom',
      'Cable Straight Arm Pulldown - 3 sets x 12-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Reverse Pec Deck - 3 sets x 15-20 reps, RIR 0-1, rest 60s',
      'Incline Dumbbell Curl - 3 sets x 8-12 reps, RIR 0-1, rest 90s, arms hang behind torso',
      'Cable Rope Hammer Curl - 2 sets x 12-15 reps, RIR 0-1, rest 60s',
      _Abs.cableCrunch,
      _Obliques.cableSideBend,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'pull-03',
    type: SessionType.pull,
    title: 'Mid-Back Thickness',
    workout: [
      'Barbell Pendlay Row - 4 sets x 6-8 reps, RIR 1-2, rest 180s',
      'Chest Supported Row - 3 sets x 8-12 reps, RIR 1-2, rest 120s, full stretch at bottom',
      'Lat Pulldown - 3 sets x 10-12 reps, RIR 1-2, rest 120s, full stretch at top',
      'Barbell Shrug - 3 sets x 10-15 reps, RIR 0-1, rest 90s, 1s pause at top',
      'EZ Bar Preacher Curl - 3 sets x 8-12 reps, RIR 0-1, rest 90s, full extension at bottom',
      'Reverse Cable Curl - 2 sets x 12-15 reps, RIR 0-1, rest 60s',
      _Abs.hangingLegRaise,
      _Obliques.pallofPress,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'pull-04',
    type: SessionType.pull,
    title: 'Deadlift Pull',
    workout: [
      'Deadlift - 3 sets x 3-5 reps, RIR 2, rest 240s',
      'Weighted Pull-up - 3 sets x 6-8 reps, RIR 1-2, rest 180s, full hang at bottom',
      'Seated Cable Row - 3 sets x 8-12 reps, RIR 1-2, rest 120s, reach forward at bottom',
      'Face Pulls - 3 sets x 15-20 reps, RIR 0-1, rest 60s',
      'Barbell Preacher Curl - 3 sets x 8-10 reps, RIR 0-1, rest 90s, full extension at bottom',
      _Abs.machineCrunch,
      _Obliques.pallofPress,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'pull-05',
    type: SessionType.pull,
    title: 'Machine Pull',
    workout: [
      'Lat Pulldown - 3 sets x 10-12 reps, RIR 1-2, rest 120s, full stretch at top',
      'Machine Row - 4 sets x 8-12 reps, RIR 1-2, rest 120s, full stretch at bottom',
      'Reverse Pec Deck - 3 sets x 15-20 reps, RIR 0-1, rest 60s',
      'Barbell Shrug - 3 sets x 10-15 reps, RIR 0-1, rest 90s, 1s pause at top',
      'Machine Preacher Curl - 3 sets x 10-12 reps, RIR 0-1, rest 90s, full extension at bottom',
      'Cable Rope Hammer Curl - 3 sets x 12-15 reps, RIR 0-1, rest 60s',
      _Abs.cableReverseCrunch,
      _Obliques.cableSideBend,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'pull-06',
    type: SessionType.pull,
    title: 'Dumbbell Pull',
    workout: [
      'Dumbbell Row - 4 sets x 8-12 reps each side, RIR 1-2, rest 120s, reach at bottom',
      'Dumbbell Straight Arm Pullover - 3 sets x 10-15 reps, RIR 1, rest 90s, deep stretch overhead',
      'Dumbbell Reverse Fly - 3 sets x 15-20 reps, RIR 0-1, rest 60s',
      'Dumbbell Shrug - 3 sets x 12-15 reps, RIR 0-1, rest 90s, 1s pause at top',
      'Dumbbell Preacher Curl - 3 sets x 8-12 reps, RIR 0-1, rest 90s, full extension at bottom',
      'Dumbbell Hammer Curl - 3 sets x 10-12 reps, RIR 0-1, rest 60s',
      _Abs.reverseCrunch,
      _Obliques.dumbbellSideBend,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'legs-01',
    type: SessionType.legs,
    title: 'Squat Focus',
    workout: [
      'Barbell Back Squat - 4 sets x 5-8 reps, RIR 1-2, rest 180s, full depth',
      'Romanian Deadlift - 3 sets x 8-10 reps, RIR 1-2, rest 150s, 3s eccentric',
      'Leg Extension - 3 sets x 10-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Seated Leg Curl - 3 sets x 10-15 reps, RIR 0-1, rest 90s',
      'Standing Calf Raise - 4 sets x 10-15 reps, RIR 0-1, rest 60s, 2s pause at bottom stretch',
      _Abs.cableCrunch,
      _Obliques.pallofPress,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'legs-02',
    type: SessionType.legs,
    title: 'Hinge & Glutes',
    workout: [
      'Romanian Deadlift - 4 sets x 6-10 reps, RIR 1-2, rest 180s, 3s eccentric',
      'Bulgarian Split Squat - 3 sets x 8-12 reps each leg, RIR 1-2, rest 120s, full depth',
      'Barbell Glute Bridge - 3 sets x 8-12 reps, RIR 1-2, rest 120s, 1s squeeze at top',
      'Seated Leg Curl - 3 sets x 10-15 reps, RIR 0-1, rest 90s',
      'Seated Hip Abduction - 3 sets x 12-20 reps, RIR 0-1, rest 60s, lean torso forward',
      'Standing Calf Raise - 3 sets x 10-15 reps, RIR 0-1, rest 60s, 2s pause at bottom stretch',
      _Abs.machineCrunch,
      _Obliques.cableTwist,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'legs-03',
    type: SessionType.legs,
    title: 'Quad Focus',
    workout: [
      'Front Squat - 4 sets x 6-8 reps, RIR 1-2, rest 180s, full depth',
      'Leg Press - 3 sets x 10-15 reps, RIR 1-2, rest 150s, deep knee bend',
      'Sissy Squat - 3 sets x 8-12 reps, RIR 1, rest 90s, lean back for full stretch',
      'Leg Extension - 3 sets x 12-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Seated Leg Curl - 2 sets x 12-15 reps, RIR 0-1, rest 90s',
      'Standing Calf Raise - 4 sets x 10-15 reps, RIR 0-1, rest 60s, 2s pause at bottom stretch',
      _Abs.hangingLegRaise,
      _Obliques.cableSideBend,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'legs-04',
    type: SessionType.legs,
    title: 'Machine Legs',
    workout: [
      'Sled Hack Squat - 4 sets x 8-12 reps, RIR 1-2, rest 150s, full depth',
      'Leg Press - 3 sets x 10-15 reps, RIR 1-2, rest 150s, deep knee bend',
      'Leg Extension - 3 sets x 10-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Seated Leg Curl - 4 sets x 10-15 reps, RIR 0-1, rest 90s',
      'Hyperextension - 3 sets x 10-15 reps, RIR 1, rest 90s, round through hips not spine',
      'Calf Press on Leg Press - 4 sets x 10-15 reps, RIR 0-1, rest 60s, 2s pause at bottom stretch',
      _Abs.cableReverseCrunch,
      _Obliques.cableTwist,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'legs-05',
    type: SessionType.legs,
    title: 'Unilateral Legs',
    workout: [
      'Bulgarian Split Squat - 4 sets x 8-12 reps each leg, RIR 1-2, rest 120s, full depth',
      'Dumbbell Single Leg Deadlift - 3 sets x 8-10 reps each leg, RIR 1-2, rest 120s, 3s eccentric',
      'Dumbbell Step-up - 3 sets x 10 reps each leg, RIR 1-2, rest 90s, knee-high box',
      'Leg Extension - 3 sets x 12-15 reps, RIR 0-1, rest 90s, last set lengthened partials',
      'Seated Leg Curl - 3 sets x 12-15 reps, RIR 0-1, rest 90s',
      'Single Leg Standing Calf Raise - 3 sets x 12-15 reps each leg, RIR 0-1, rest 60s, 2s pause at bottom stretch',
      _Abs.cableCrunch,
      _Obliques.hangingObliqueKneeRaise,
      _finisher,
    ],
  ),
  WorkoutSession(
    id: 'legs-06',
    type: SessionType.legs,
    title: 'Dumbbell Legs',
    workout: [
      'Dumbbell Goblet Squat - 4 sets x 10-15 reps, RIR 1-2, rest 120s, full depth',
      'Dumbbell Romanian Deadlift - 4 sets x 8-12 reps, RIR 1-2, rest 120s, 3s eccentric',
      'Dumbbell Walking Lunge - 3 sets x 10-12 reps each leg, RIR 1-2, rest 90s, long stride',
      'Dumbbell Step-up - 3 sets x 10 reps each leg, RIR 1-2, rest 90s, knee-high box',
      'Dumbbell Calf Raise - 4 sets x 12-20 reps, RIR 0-1, rest 60s, 2s pause at bottom stretch',
      _Abs.reverseCrunch,
      _Obliques.russianTwist,
      _finisher,
    ],
  ),
];

List<WorkoutSession> sessionsOf(SessionType type) => workoutSessions.where((s) => s.type == type).toList();

WorkoutSession sessionById(String? id) =>
    workoutSessions.firstWhere((s) => s.id == id, orElse: () => workoutSessions.first);
