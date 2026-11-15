import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/intervals.dart';

/// Runs an [IntervalPlan]. Elapsed time comes from a wall-clock anchor saved
/// in preferences, so a running timer keeps counting while the app is in the
/// background or closed, and is right again when it comes back.
///
/// In the last [warnSeconds] of a segment [onBeep] fires once per second, so
/// the user knows to change the treadmill speed.
class IntervalTimer extends ChangeNotifier {
  IntervalTimer(this.plan, this._prefs, {this.onBeep, DateTime Function()? now, this.warnSeconds = 5})
    : _now = now ?? DateTime.now {
    _restore();
  }

  final IntervalPlan plan;
  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final void Function()? onBeep;
  final int warnSeconds;

  Timer? _ticker;
  DateTime? _anchor;
  int _base = 0;
  int _elapsed = 0;
  int? _lastBeep;

  String get _key => 'timer_${plan.id}';

  bool get running => _anchor != null;
  int get elapsed => _elapsed;
  bool get finished => _elapsed >= plan.totalSeconds;

  int get index => plan.indexAt(_elapsed);
  IntervalSegment get segment => plan.segments[index];
  IntervalSegment? get next => index + 1 < plan.segments.length ? plan.segments[index + 1] : null;
  int get remaining => max(0, plan.totalSeconds - _elapsed);
  int get leftInSegment => plan.leftInSegment(_elapsed);
  double get segmentProgress => plan.segmentProgress(_elapsed);
  int get calories => plan.calories(_elapsed);

  /// Seconds before the next speed, while inside the warning window.
  int? get changeCountdown {
    if (!running || next == null) return null;
    final left = leftInSegment;
    return left > 0 && left <= warnSeconds ? left : null;
  }

  void toggle() => running ? pause() : start();

  void start() {
    if (running) return;
    if (finished) _elapsed = 0;
    _base = _elapsed;
    _anchor = _now();
    _save();
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    _sync();
    _anchor = null;
    _ticker?.cancel();
    _save();
    notifyListeners();
  }

  void reset() {
    _anchor = null;
    _ticker?.cancel();
    _elapsed = 0;
    _base = 0;
    _lastBeep = null;
    _save();
    notifyListeners();
  }

  /// Recompute from the clock, e.g. when the app comes back to the front.
  void sync() {
    _sync();
    notifyListeners();
  }

  void _sync() {
    final a = _anchor;
    if (a == null) return;
    final e = _base + _now().difference(a).inSeconds;
    if (e >= plan.totalSeconds) {
      _elapsed = plan.totalSeconds;
      _anchor = null;
      _ticker?.cancel();
      _save();
      return;
    }
    _elapsed = max(0, e);
    final c = changeCountdown;
    if (c != null && c != _lastBeep) {
      _lastBeep = c;
      onBeep?.call();
    } else if (c == null) {
      _lastBeep = null;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => sync());
  }

  void _save() {
    final a = _anchor;
    if (a == null) {
      _prefs.remove('${_key}_anchor');
      _prefs.setInt('${_key}_elapsed', _elapsed);
    } else {
      _prefs.setInt('${_key}_anchor', a.millisecondsSinceEpoch);
      _prefs.setInt('${_key}_elapsed', _base);
    }
  }

  void _restore() {
    final saved = _prefs.getInt('${_key}_elapsed') ?? 0;
    final anchor = _prefs.getInt('${_key}_anchor');
    if (anchor == null) {
      _elapsed = saved.clamp(0, plan.totalSeconds);
      return;
    }
    _base = saved;
    _anchor = DateTime.fromMillisecondsSinceEpoch(anchor);
    // No beeps for time that passed while the app was closed.
    _lastBeep = null;
    final a = _anchor!;
    final e = _base + _now().difference(a).inSeconds;
    if (e >= plan.totalSeconds) {
      _elapsed = plan.totalSeconds;
      _anchor = null;
      _save();
    } else {
      _elapsed = max(0, e);
      _startTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
