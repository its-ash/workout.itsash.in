import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/plan.dart';
import '../core/sessions.dart';

/// A finished session, for the summary image and the calendar event.
class SessionSummary {
  const SessionSummary({required this.session, required this.begin, required this.end});

  final WorkoutSession session;
  final DateTime begin;
  final DateTime end;

  int get seconds => end.difference(begin).inSeconds;
  List<WorkoutLine> get lines => session.workout.map(WorkoutLine.parse).toList();

  String get calendarTitle => 'Workout · ${session.title}';

  String get calendarDetails => lines.map((w) => '• ${w.name} — ${w.plan}').join('\n');

  /// `summary_2026-11-15_1830.png`.
  String get fileName {
    String p(int n) => n.toString().padLeft(2, '0');
    return 'workout_${begin.year}-${p(begin.month)}-${p(begin.day)}_${p(begin.hour)}${p(begin.minute)}.png';
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String summaryDate(DateTime t) => '${_days[t.weekday - 1]}, ${t.day} ${_months[t.month - 1]} ${t.year}';

/// Duration as `1 h 05 min` or `42 min` (at least 1 min).
String summaryDuration(int seconds) {
  final mins = (seconds / 60).round().clamp(1, 1 << 30);
  return mins >= 60 ? '${mins ~/ 60} h ${(mins % 60).toString().padLeft(2, '0')} min' : '$mins min';
}

/// The shareable card: split, title, date, time, duration and the exercise
/// list. Fixed 360 dp wide, so the PNG is 1080 px at 3x on every phone.
class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({super.key, required this.summary});

  static const width = 360.0;

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final lines = summary.lines;
    return Container(
      width: width,
      color: colors.background,
      padding: const EdgeInsets.all(UiSpace.xl),
      child: UiColumn(
        gap: UiSpace.lg,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          UiRow(
            children: [
              Icon(Icons.fitness_center_rounded, color: colors.accent, size: 20),
              Text('WORKOUT', style: text.labelLarge?.copyWith(color: colors.accent, letterSpacing: 2)),
              const Spacer(),
              UiStatusPill('Done', status: UiStatus.success, icon: Icons.check_rounded),
            ],
          ),
          UiColumn(
            gap: UiSpace.xxs,
            children: [
              Text(
                '${summary.session.type.label} day'.toUpperCase(),
                style: text.labelSmall?.copyWith(color: colors.textMuted, letterSpacing: 1.2),
              ),
              Text(summary.session.title, style: text.headlineLarge),
              Text(summaryDate(summary.begin), style: text.bodyMedium?.copyWith(color: colors.textMuted)),
            ],
          ),
          UiRow(
            gap: UiSpace.sm,
            children: [
              Expanded(
                child: _Stat(label: 'Duration', value: summaryDuration(summary.seconds)),
              ),
              Expanded(
                child: _Stat(label: 'Time', value: '${_time(summary.begin)}–${_time(summary.end)}'),
              ),
              Expanded(
                child: _Stat(label: 'Exercises', value: '${lines.length}'),
              ),
            ],
          ),
          UiSurface(
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.md, vertical: UiSpace.sm),
            child: UiColumn(
              gap: UiSpace.sm,
              children: [
                for (var i = 0; i < lines.length; i++)
                  UiRow(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    gap: UiSpace.sm,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('${i + 1}', style: text.labelMedium?.copyWith(color: colors.accent)),
                      ),
                      Expanded(
                        child: UiColumn(
                          gap: 0,
                          children: [
                            Text(lines[i].name, style: text.titleSmall),
                            Text(lines[i].plan, style: text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Text(
            'workout.itsash.in',
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: colors.textSubtle),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return UiSurface(
      padding: const EdgeInsets.all(UiSpace.sm),
      color: context.colors.accentSoft,
      border: false,
      radius: UiRadius.md,
      child: UiColumn(
        gap: UiSpace.xxs,
        children: [
          Text(label, style: context.text.labelSmall?.copyWith(color: context.colors.onAccentSoft)),
          Text(value, style: context.text.titleSmall?.copyWith(color: context.colors.onAccentSoft)),
        ],
      ),
    );
  }
}
