import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout/core/intervals.dart';
import 'package:workout/core/sessions.dart';
import 'package:workout/state/interval_timer.dart';
import 'package:workout/state/workout_store.dart';

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() {
    now = DateTime(2026, 11, 15, 18);
    SharedPreferences.setMockInitialValues({});
  });

  group('WorkoutStore', () {
    test('defaults to the first push session', () async {
      final s = WorkoutStore.forTest(await SharedPreferences.getInstance(), now: clock);
      expect(s.type, SessionType.push);
      expect(s.session.id, 'push-01');
      expect(s.isActive, isFalse);
      s.dispose();
    });

    test('split, next and shuffle stay in the split and persist', () async {
      final prefs = await SharedPreferences.getInstance();
      final s = WorkoutStore.forTest(prefs, random: Random(1), now: clock);
      s.selectType(SessionType.legs);
      expect(s.session.type, SessionType.legs);
      final before = s.session.id;
      s.shuffle();
      expect(s.session.type, SessionType.legs);
      expect(s.session.id, isNot(before));
      s.nextVariation();
      expect(s.session.type, SessionType.legs);

      final again = WorkoutStore.forTest(prefs, now: clock);
      expect(again.session.id, s.session.id);
      s.dispose();
      again.dispose();
    });

    test('next variation wraps around', () async {
      final s = WorkoutStore.forTest(await SharedPreferences.getInstance(), now: clock);
      for (var i = 0; i < 6; i++) {
        s.nextVariation();
      }
      expect(s.session.id, 'push-01');
      s.dispose();
    });

    test('session clock survives a restart and locks the plan', () async {
      final prefs = await SharedPreferences.getInstance();
      final s = WorkoutStore.forTest(prefs, now: clock);
      s.start();
      now = now.add(const Duration(minutes: 42, seconds: 7));
      expect(s.elapsed, 42 * 60 + 7);
      s.nextVariation();
      expect(s.session.id, 'push-01', reason: 'plan is locked while a session runs');
      s.dispose();

      final restored = WorkoutStore.forTest(prefs, now: clock);
      expect(restored.isActive, isTrue);
      expect(restored.elapsed, 42 * 60 + 7);
      final times = restored.stop()!;
      expect(times.end.difference(times.begin).inSeconds, 42 * 60 + 7);
      expect(restored.isActive, isFalse);
      expect(WorkoutStore.forTest(prefs, now: clock).isActive, isFalse);
      restored.dispose();
    });
  });

  group('IntervalTimer', () {
    test('counts from the anchor, pauses and resumes', () async {
      final prefs = await SharedPreferences.getInstance();
      final t = IntervalTimer(intervalWalkPlan, prefs, now: clock);
      t.start();
      now = now.add(const Duration(seconds: 130));
      t.sync();
      expect(t.elapsed, 130);
      expect(t.index, 1);
      t.pause();
      now = now.add(const Duration(minutes: 5));
      t.sync();
      expect(t.elapsed, 130);
      t.start();
      now = now.add(const Duration(seconds: 10));
      t.sync();
      expect(t.elapsed, 140);
      t.dispose();
    });

    test('beeps once per second in the last 5 s of a segment', () async {
      var beeps = 0;
      final t = IntervalTimer(
        intervalWalkPlan,
        await SharedPreferences.getInstance(),
        now: clock,
        onBeep: () => beeps++,
      );
      t.start();
      for (var i = 0; i < 125; i++) {
        now = now.add(const Duration(seconds: 1));
        t.sync();
      }
      expect(beeps, 5);
      t.dispose();
    });

    test('a running timer is restored after the app is killed', () async {
      final prefs = await SharedPreferences.getInstance();
      final t = IntervalTimer(runWalkPlan, prefs, now: clock);
      t.start();
      now = now.add(const Duration(seconds: 200));
      t.dispose();

      final r = IntervalTimer(runWalkPlan, prefs, now: clock);
      expect(r.running, isTrue);
      expect(r.elapsed, 200);
      r.dispose();
    });

    test('stops at the end and restarts from zero', () async {
      final t = IntervalTimer(runWalkPlan, await SharedPreferences.getInstance(), now: clock);
      t.start();
      now = now.add(const Duration(minutes: 30));
      t.sync();
      expect(t.finished, isTrue);
      expect(t.running, isFalse);
      t.start();
      expect(t.elapsed, 0);
      t.reset();
      expect(t.running, isFalse);
      t.dispose();
    });
  });
}
