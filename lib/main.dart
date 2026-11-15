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

/// Brand accent: the web app's lime, darkened so it reads on light surfaces.
const workoutAccent = Color(0xFF4D7C0F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
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
      home: HomeScreen(state: state),
    );
  }
}
