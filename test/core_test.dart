import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout/core/intervals.dart';
import 'package:workout/core/matcher.dart';
import 'package:workout/core/plan.dart';
import 'package:workout/core/sessions.dart';
import 'package:workout/core/stretches.dart';
import 'package:workout/data/demos.dart';

void main() {
  group('sessions', () {
    test('six variations per split, unique ids, run/walk finisher last', () {
      for (final t in SessionType.values) {
        expect(sessionsOf(t), hasLength(6));
      }
      expect(workoutSessions.map((s) => s.id).toSet(), hasLength(workoutSessions.length));
      for (final s in workoutSessions) {
        expect(WorkoutLine.parse(s.workout.last).isRunWalk, isTrue, reason: s.id);
      }
    });

    test('sessionById falls back to the first session', () {
      expect(sessionById('legs-03').title, 'Quad Focus');
      expect(sessionById('nope').id, 'push-01');
    });
  });

  group('plan', () {
    test('parses a line into name and dotted plan', () {
      final l = WorkoutLine.parse('Barbell Bench Press - 4 sets x 5-8 reps, RIR 1-2, rest 180s');
      expect(l.name, 'Barbell Bench Press');
      expect(l.plan, '4 sets x 5-8 reps · RIR 1-2 · rest 180s');
    });

    test('estimates like the web app', () {
      expect(estimateSeconds('X - 4 sets x 5-8 reps, rest 180s'), 4 * (40 + 180));
      expect(estimateSeconds('Run - 10 min, intervals'), 600);
      expect(estimateSeconds('X - AMRAP'), 0);
      expect(sessionMeta(sessionById('push-01')), startsWith('Variation 1 of 6 · 9 exercises · ~'));
    });

    test('clock labels', () {
      expect(clockLabel(65), '01:05');
      expect(clockLabel(3725), '1:02:05');
      expect(shortClock(125), '2:05');
    });
  });

  group('intervals', () {
    test('totals and range labels', () {
      expect(runWalkPlan.totalSeconds, 600);
      expect(intervalWalkPlan.totalSeconds, 1200);
      expect(intervalWalkPlan.rangeLabel(0), '0:00-2:00');
      expect(intervalWalkPlan.rangeLabel(11), '17:00-20:00');
    });

    test('segment position', () {
      const p = intervalWalkPlan;
      expect(p.indexAt(0), 0);
      expect(p.indexAt(119), 0);
      expect(p.indexAt(120), 1);
      expect(p.indexAt(5000), p.segments.length - 1);
      expect(p.leftInSegment(115), 5);
      expect(p.segmentProgress(60), closeTo(0.5, 1e-9));
    });

    test('calories use MET x 3.5 x kg / 200 per minute', () {
      // 2 min at 3.0 MET, 70 kg = 7.35 kcal.
      expect(intervalWalkPlan.calories(120), 7);
      expect(intervalWalkPlan.calories(0), 0);
    });
  });

  group('matcher', () {
    final db = [
      const ExerciseRecord(
        name: 'barbell bench press',
        bodyPart: 'chest',
        target: 'pectorals',
        equipment: 'barbell',
        secondaryMuscles: [],
      ),
      const ExerciseRecord(
        name: 'dumbbell bench press',
        bodyPart: 'chest',
        target: 'pectorals',
        equipment: 'dumbbell',
        secondaryMuscles: [],
      ),
      const ExerciseRecord(
        name: 'cable seated row',
        bodyPart: 'back',
        target: 'upper back',
        equipment: 'cable',
        secondaryMuscles: ['biceps'],
      ),
      const ExerciseRecord(
        name: 'rear delt row',
        bodyPart: 'shoulders',
        target: 'delts',
        equipment: 'cable',
        secondaryMuscles: [],
      ),
    ];

    test('exact name wins', () => expect(findExercise('Barbell Bench Press', SessionType.push, db), 0));
    test('equipment hint picks the variant', () {
      expect(findExercise('Flat Dumbbell Bench Press', SessionType.push, db), 1);
    });
    test('keyword and synonyms', () {
      expect(findExercise('Seated Cable Row', SessionType.pull, db), 2);
      expect(findExercise('Face Pulls', SessionType.pull, db), 3);
    });
    test('run/walk has no demo', () => expect(findExercise(runWalkName, SessionType.legs, db), isNull));
    test('normalize and singularize', () {
      expect(normalizeName('  Push-up   Plus! '), 'pushup plus');
      expect(singularize('pulls'), 'pull');
      expect(singularize('press'), 'press');
      expect(singularize('abs'), 'abs');
    });
  });

  group('bundled demos', () {
    final lib = DemoLibrary.parse(File('assets/data/demos.json').readAsStringSync());

    test('every exercise line has a demo whose GIF is bundled', () {
      for (final s in workoutSessions) {
        for (final raw in s.workout) {
          final line = WorkoutLine.parse(raw);
          if (line.isRunWalk) continue;
          final demo = lib.find(s.type, line.name);
          expect(demo, isNotNull, reason: '${s.id}: ${line.name}');
          expect(File(demo!.gif).existsSync(), isTrue, reason: demo.gif);
          expect(demo.steps['en'], isNotEmpty);
        }
      }
    });

    test('stretch GIFs are bundled', () {
      for (final s in stretchingRoutine) {
        expect(File('assets/gifs/${s.gif}').existsSync(), isTrue, reason: s.gif);
      }
    });

    test('no unused GIFs in the APK', () {
      final used = {...lib.demos.values.map((d) => d.gif.split('/').last), ...stretchingRoutine.map((s) => s.gif)};
      final files = Directory('assets/gifs').listSync().map((f) => f.uri.pathSegments.last).toSet();
      expect(files, used);
    });

    test('attribution is kept', () {
      final j = jsonDecode(File('assets/data/demos.json').readAsStringSync()) as Map<String, dynamic>;
      expect(j['attribution'], isNotEmpty);
    });
  });
}
