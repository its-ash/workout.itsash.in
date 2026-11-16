import 'package:flutter/services.dart';

/// Calls into `MainActivity.kt` (channel `com.itsash.workout/platform`).
abstract class WorkoutPlatform {
  /// Short beep on the alarm stream (segment change countdown).
  Future<void> beep();

  /// Keep the screen on while a timer runs.
  Future<void> keepScreenOn(bool on);

  /// Opens the calendar app's new-event screen, filled in. Falls back to the
  /// Google Calendar web form when no calendar app handles it.
  Future<void> addToCalendar({
    required String title,
    required String details,
    required String location,
    required DateTime begin,
    required DateTime end,
  });

  /// Saves a PNG to `Pictures/Workout`. Returns where it went (for the user),
  /// or null when saving failed.
  Future<String?> saveImage(Uint8List png, String fileName);

  /// Opens the Android share sheet with a PNG.
  Future<void> shareImage(Uint8List png, String fileName);

  /// Shows (or updates) the ongoing notification [id] with a live clock that
  /// Android ticks by itself: counting up from [baseMs] (a past wall-clock
  /// time), or down to [baseMs] (a future one) when [countDown]. A null
  /// [baseMs] shows no clock (paused). Asks for the notification permission
  /// the first time on Android 13+.
  Future<void> showTimerNotification({
    required int id,
    required String title,
    required String text,
    int? baseMs,
    bool countDown = false,
  });

  /// Removes notification [id].
  Future<void> cancelNotification(int id);
}

/// Notification ids.
abstract final class WorkoutNotifications {
  static const session = 1;
  static const interval = 2;
}

class MethodChannelPlatform implements WorkoutPlatform {
  const MethodChannelPlatform();

  static const _channel = MethodChannel('com.itsash.workout/platform');

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException {
      // Best effort: a missed beep or flag never breaks a workout.
    } on MissingPluginException {
      // Tests and unsupported platforms.
    }
  }

  @override
  Future<void> beep() => _call('beep');

  @override
  Future<void> keepScreenOn(bool on) => _call('keepScreenOn', on);

  @override
  Future<void> addToCalendar({
    required String title,
    required String details,
    required String location,
    required DateTime begin,
    required DateTime end,
  }) => _call('addToCalendar', {
    'title': title,
    'details': details,
    'location': location,
    'begin': begin.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'webUrl': googleCalendarUrl(title: title, details: details, location: location, begin: begin, end: end),
  });

  @override
  Future<String?> saveImage(Uint8List png, String fileName) async {
    try {
      return await _channel.invokeMethod<String>('saveImage', {'png': png, 'name': fileName});
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> shareImage(Uint8List png, String fileName) => _call('shareImage', {'png': png, 'name': fileName});

  @override
  Future<void> showTimerNotification({
    required int id,
    required String title,
    required String text,
    int? baseMs,
    bool countDown = false,
  }) =>
      _call('showTimerNotification', {'id': id, 'title': title, 'text': text, 'base': baseMs, 'countDown': countDown});

  @override
  Future<void> cancelNotification(int id) => _call('cancelNotification', id);
}

/// The web app's export link: a prefilled Google Calendar event.
String googleCalendarUrl({
  required String title,
  required String details,
  required String location,
  required DateTime begin,
  required DateTime end,
}) {
  String fmt(DateTime t) => '${t.toUtc().toIso8601String().split('.').first.replaceAll(RegExp('[-:]'), '')}Z';
  return 'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(title)}'
      '&dates=${fmt(begin)}/${fmt(end)}'
      '&details=${Uri.encodeComponent(details)}'
      '&location=${Uri.encodeComponent(location)}';
}
