import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sessions.dart';

/// The chosen split and variation, and the running session clock. The clock
/// is anchored to the wall-clock start time, so it survives the app being
/// closed or killed mid-workout.
class WorkoutStore extends ChangeNotifier {
  WorkoutStore._(this._prefs, {Random? random, DateTime Function()? now})
    : _random = random ?? Random(),
      _now = now ?? DateTime.now {
    _type = SessionType.byName(_prefs.getString(_kType)) ?? SessionType.push;
    final saved = _prefs.getString(_kSession);
    _sessionId = workoutSessions.any((s) => s.id == saved && s.type == _type) ? saved! : sessionsOf(_type).first.id;
    final start = _prefs.getInt(_kStart);
    if (start != null) {
      _startedAt = DateTime.fromMillisecondsSinceEpoch(start);
      _startTicker();
    }
  }

  static const _kType = 'session_type';
  static const _kSession = 'session_id';
  static const _kStart = 'session_start_ms';

  final SharedPreferences _prefs;
  final Random _random;
  final DateTime Function() _now;

  late SessionType _type;
  late String _sessionId;
  DateTime? _startedAt;
  Timer? _ticker;

  static Future<WorkoutStore> load() async => WorkoutStore._(await SharedPreferences.getInstance());

  @visibleForTesting
  static WorkoutStore forTest(SharedPreferences prefs, {Random? random, DateTime Function()? now}) =>
      WorkoutStore._(prefs, random: random, now: now);

  SessionType get type => _type;
  WorkoutSession get session => sessionById(_sessionId);

  bool get isActive => _startedAt != null;
  DateTime? get startedAt => _startedAt;

  /// Seconds since Start.
  int get elapsed => _startedAt == null ? 0 : max(0, _now().difference(_startedAt!).inSeconds);

  /// Switches split and picks a random variation of it.
  void selectType(SessionType type) {
    if (isActive) return;
    _type = type;
    _setSession(_randomId(type));
  }

  /// A random other variation of the same split.
  void shuffle() {
    if (isActive) return;
    _setSession(_randomId(_type, exclude: _sessionId));
  }

  /// The next variation in order, wrapping around.
  void nextVariation() {
    if (isActive) return;
    final pool = sessionsOf(_type);
    final i = pool.indexWhere((s) => s.id == _sessionId);
    _setSession(pool[(i + 1) % pool.length].id);
  }

  void start() {
    if (isActive) return;
    _startedAt = _now();
    _prefs.setInt(_kStart, _startedAt!.millisecondsSinceEpoch);
    _startTicker();
    notifyListeners();
  }

  /// Stops the clock. Returns the start time and duration of the session.
  ({DateTime begin, DateTime end})? stop() {
    final begin = _startedAt;
    if (begin == null) return null;
    final end = _now();
    _startedAt = null;
    _ticker?.cancel();
    _ticker = null;
    _prefs.remove(_kStart);
    notifyListeners();
    return (begin: begin, end: end);
  }

  String _randomId(SessionType type, {String? exclude}) {
    final all = sessionsOf(type);
    final pool = all.where((s) => s.id != exclude).toList();
    if (pool.isEmpty) return all.first.id;
    return pool[_random.nextInt(pool.length)].id;
  }

  void _setSession(String id) {
    _sessionId = id;
    _prefs.setString(_kType, _type.name);
    _prefs.setString(_kSession, id);
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
