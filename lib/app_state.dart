import 'data/demos.dart';
import 'platform/platform_channel.dart';
import 'state/interval_timer.dart';
import 'state/workout_store.dart';

/// Everything the screens need, created once in `main`.
class AppState {
  const AppState({
    required this.store,
    required this.demos,
    required this.runWalk,
    required this.intervalWalk,
    required this.platform,
  });

  final WorkoutStore store;
  final DemoLibrary demos;

  /// 10 min run/walk finisher (opened from the last exercise row).
  final IntervalTimer runWalk;

  /// 20 min interval walking (app bar button).
  final IntervalTimer intervalWalk;

  final WorkoutPlatform platform;
}
