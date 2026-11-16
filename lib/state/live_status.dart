import 'package:flutter/foundation.dart';

import '../core/plan.dart';
import '../platform/platform_channel.dart';
import 'interval_timer.dart';
import 'workout_store.dart';

/// Mirrors the running session and interval timers to the outside of the app:
/// one ongoing notification per running clock (Android ticks the clock
/// itself, so it is right even when the app is closed), and the keep-screen-on
/// flag. Only calls the platform when something visible changes, not every
/// second.
class LiveStatus {
  LiveStatus({required this.store, required this.timers, required this.platform, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    store.addListener(sync);
    for (final t in timers) {
      t.addListener(sync);
    }
    sync();
  }

  final WorkoutStore store;
  final List<IntervalTimer> timers;
  final WorkoutPlatform platform;
  final DateTime Function() _now;

  String? _sessionKey;
  String? _intervalKey;
  bool? _screenOn;
  int _openDialogs = 0;

  /// A full-screen timer dialog is open: keep the screen on.
  void dialogOpened() {
    _openDialogs++;
    sync();
  }

  void dialogClosed() {
    if (_openDialogs > 0) _openDialogs--;
    sync();
  }

  /// Forces the notifications to be sent again (e.g. after the app comes back
  /// from the notification permission prompt).
  void resend() {
    _sessionKey = null;
    _intervalKey = null;
    sync();
  }

  void sync() {
    _syncSession();
    _syncInterval();
    final on = store.isActive || _openDialogs > 0 || timers.any((t) => t.running);
    if (on != _screenOn) {
      _screenOn = on;
      platform.keepScreenOn(on);
    }
  }

  void _syncSession() {
    final start = store.startedAt;
    if (start == null) {
      if (_sessionKey != null) platform.cancelNotification(WorkoutNotifications.session);
      _sessionKey = null;
      return;
    }
    final session = store.session;
    final lines = session.workout;
    final text = store.allDone
        ? 'All ${lines.length} exercises done'
        : '${store.current + 1}/${lines.length} · ${WorkoutLine.parse(lines[store.current]).name}';
    final title = '${session.type.label} · ${session.title}';
    final key = '$title|$text|${start.millisecondsSinceEpoch}';
    if (key == _sessionKey) return;
    _sessionKey = key;
    platform.showTimerNotification(
      id: WorkoutNotifications.session,
      title: title,
      text: text,
      baseMs: start.millisecondsSinceEpoch,
    );
  }

  void _syncInterval() {
    // The running timer wins; otherwise a paused one that has started.
    final t =
        timers.where((t) => t.running).firstOrNull ?? timers.where((t) => t.elapsed > 0 && !t.finished).firstOrNull;
    if (t == null) {
      if (_intervalKey != null) platform.cancelNotification(WorkoutNotifications.interval);
      _intervalKey = null;
      return;
    }
    final seg = t.segment;
    final text = t.running
        ? '${seg.label} · ${seg.speed} · ${seg.incline}'
        : 'Paused · ${shortClock(t.remaining)} left · ${seg.speed} · ${seg.incline}';
    final key = '${t.plan.id}|${t.running}|${t.index}|$text';
    if (key == _intervalKey) return;
    _intervalKey = key;
    platform.showTimerNotification(
      id: WorkoutNotifications.interval,
      title: t.plan.title,
      text: text,
      baseMs: t.running ? _now().millisecondsSinceEpoch + t.remaining * 1000 : null,
      countDown: true,
    );
  }

  @visibleForTesting
  bool? get screenOn => _screenOn;

  void dispose() {
    store.removeListener(sync);
    for (final t in timers) {
      t.removeListener(sync);
    }
  }
}
