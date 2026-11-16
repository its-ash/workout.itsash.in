import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme/theme.dart';

import 'app_state.dart';
import 'core/intervals.dart';
import 'data/demos.dart';
import 'platform/platform_channel.dart';
import 'screens/home_screen.dart';
import 'state/interval_timer.dart';
import 'state/workout_store.dart';

/// Brand accent: gold. Workout is a dark app (black background, gold accent).
const workoutAccent = Color(0xFFD4AF37);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // One-time move to the dark gold look: forget an older saved Light/System
  // choice so the new dark default shows. Later choices in Settings stick.
  if (!(prefs.getBool('dark_gold_v1') ?? false)) {
    await prefs.remove(UiAppearance.key);
    await prefs.setBool('dark_gold_v1', true);
  }
  const platform = MethodChannelPlatform();
  final state = AppState(
    store: await WorkoutStore.load(),
    demos: await DemoLibrary.load(),
    runWalk: IntervalTimer(runWalkPlan, prefs, onBeep: platform.beep),
    intervalWalk: IntervalTimer(intervalWalkPlan, prefs, onBeep: platform.beep),
    platform: platform,
  );
  runApp(WorkoutApp(state: state));
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return UiApp(
      title: 'Workout',
      accent: workoutAccent,
      // Exception to the workspace's light default: Workout starts dark. The
      // user can still pick Light or System in Settings.
      themeMode: ThemeMode.dark,
      home: HomeScreen(state: state),
    );
  }
}
