import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme/theme.dart';
import 'package:workout/app_state.dart';
import 'package:workout/core/intervals.dart';
import 'package:workout/data/demos.dart';
import 'package:workout/main.dart';
import 'package:workout/platform/platform_channel.dart';
import 'package:workout/screens/interval_timer_dialog.dart';
import 'package:workout/state/interval_timer.dart';
import 'package:workout/state/workout_store.dart';

class FakePlatform implements WorkoutPlatform {
  final calls = <String>[];
  String? calendarTitle;

  @override
  Future<void> beep() async => calls.add('beep');

  @override
  Future<void> keepScreenOn(bool on) async => calls.add('screen:$on');

  @override
  Future<void> addToCalendar({
    required String title,
    required String details,
    required String location,
    required DateTime begin,
    required DateTime end,
  }) async {
    calls.add('calendar');
    calendarTitle = title;
    calendarDetails = details;
  }

  String? calendarDetails;
  Uint8List? savedPng;

  @override
  Future<String?> saveImage(Uint8List png, String fileName) async {
    calls.add('save:$fileName');
    savedPng = png;
    return 'Pictures/Workout/$fileName';
  }

  @override
  Future<void> shareImage(Uint8List png, String fileName) async => calls.add('share');

  @override
  Future<void> showTimerNotification({
    required int id,
    required String title,
    required String text,
    int? baseMs,
    bool countDown = false,
  }) async => calls.add('notify:$id:$text');

  @override
  Future<void> cancelNotification(int id) async => calls.add('cancel:$id');
}

void main() {
  UiTypography.useGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(AppState, FakePlatform)> pumpApp(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final platform = FakePlatform();
    final state = AppState(
      store: WorkoutStore.forTest(prefs),
      demos: DemoLibrary.parse(File('assets/data/demos.json').readAsStringSync()),
      runWalk: IntervalTimer(runWalkPlan, prefs),
      intervalWalk: IntervalTimer(intervalWalkPlan, prefs),
      platform: platform,
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(WorkoutApp(state: state));
    await tester.pump(const Duration(milliseconds: 500));
    return (state, platform);
  }

  testWidgets('shows today\'s session and switches split', (tester) async {
    final (state, _) = await pumpApp(tester);
    expect(find.text('Heavy Bench & Press'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.textContaining('Variation 1 of 6'), findsOneWidget);

    await tester.tap(find.text('Legs'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(state.store.session.id, startsWith('legs-'));
    expect(find.text(state.store.session.title), findsOneWidget);
  });

  testWidgets('start, then stop and export image + calendar', (tester) async {
    final (state, platform) = await pumpApp(tester);
    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.store.isActive, isTrue);
    expect(platform.calls, contains('screen:true'));
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Push'), findsNothing, reason: 'split picker hides during a session');

    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Stop & export to Calendar'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(state.store.isActive, isFalse);
    expect(find.text('Workout complete'), findsOneWidget);

    // Rendering the card to PNG needs real async work.
    for (var i = 0; i < 20 && !platform.calls.contains('calendar'); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(platform.calls.where((c) => c.startsWith('save:workout_')), hasLength(1));
    expect(platform.savedPng, isNotNull);
    // PNG signature.
    expect(platform.savedPng!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(platform.calendarTitle, 'Workout · Heavy Bench & Press');
    expect(platform.calendarDetails, contains('Summary image: Pictures/Workout/workout_'));
    expect(platform.calendarDetails, contains('• Barbell Bench Press'));

    await tester.tap(find.text('Share image'));
    for (var i = 0; i < 10 && platform.calls.last != 'share'; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(platform.calls.last, 'share');
  });

  testWidgets('current exercise card: Completed moves on, notification follows', (tester) async {
    final (state, platform) = await pumpApp(tester);
    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('EXERCISE 1 OF ${state.store.session.workout.length}'), findsOneWidget);
    expect(platform.calls, contains('notify:1:1/${state.store.session.workout.length} · Barbell Bench Press'));

    await tester.tap(find.text('Completed'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.store.current, 1);
    expect(find.text('EXERCISE 2 OF ${state.store.session.workout.length}'), findsOneWidget);
    expect(platform.calls.last, startsWith('notify:1:2/'));

    state.store.stop();
    await tester.pump(const Duration(milliseconds: 300));
    expect(platform.calls, contains('cancel:1'));
  });

  testWidgets('interval timer dialog closes while running and shows a banner', (tester) async {
    final (state, platform) = await pumpApp(tester);
    await tester.tap(find.byTooltip('Interval walk timer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.byType(IntervalTimerDialog), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(IntervalTimerDialog), matching: find.text('Start')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.intervalWalk.running, isTrue);
    expect(platform.calls.any((c) => c.startsWith('notify:2:')), isTrue);

    await tester.tap(find.byTooltip('Close (the timer keeps running)'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(state.intervalWalk.running, isTrue, reason: 'closing does not pause');
    expect(find.byType(UiPromoBanner), findsOneWidget);
    state.intervalWalk.reset();
    await tester.pump(const Duration(milliseconds: 300));
    expect(platform.calls, contains('cancel:2'));
  });

  testWidgets('settings ends with Updates and Developer', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(UiAppearanceSection), findsOneWidget);
    expect(find.byType(UiUpdateSection), findsOneWidget);
    expect(find.byType(UiDeveloperSection), findsOneWidget);
  });
}
