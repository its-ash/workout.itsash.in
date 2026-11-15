import 'sessions.dart';

/// One exercise row: `Barbell Bench Press` + `4 sets x 5-8 reps · RIR 1-2 · ...`.
class WorkoutLine {
  const WorkoutLine({required this.name, required this.plan, required this.raw});

  final String name;
  final String plan;
  final String raw;

  bool get isRunWalk => name == runWalkName;

  factory WorkoutLine.parse(String line) {
    final sep = line.indexOf(' - ');
    final name = sep > -1 ? line.substring(0, sep) : line;
    final plan = sep > -1 ? line.substring(sep + 3) : '';
    return WorkoutLine(name: name, plan: plan.split(', ').join(' · '), raw: line);
  }
}

/// Seconds of work per set, used for the session length estimate.
const workSecondsPerSet = 40;

/// Rough time for one line: `N min`, or sets x (work + rest).
int estimateSeconds(String line) {
  final mins = RegExp(r'(\d+) min\b').firstMatch(line);
  if (mins != null) return int.parse(mins.group(1)!) * 60;
  final sets = int.tryParse(RegExp(r'(\d+) sets?\b').firstMatch(line)?.group(1) ?? '') ?? 0;
  final rest = int.tryParse(RegExp(r'rest (\d+)s').firstMatch(line)?.group(1) ?? '') ?? 0;
  return sets * (workSecondsPerSet + rest);
}

int estimateMinutes(WorkoutSession s) => (s.workout.fold<int>(0, (a, l) => a + estimateSeconds(l)) / 60).round();

/// `Variation 2 of 6 · 9 exercises · ~68 min`.
String sessionMeta(WorkoutSession s) {
  final pool = sessionsOf(s.type);
  final idx = pool.indexWhere((p) => p.id == s.id);
  return 'Variation ${idx + 1} of ${pool.length} · ${s.workout.length} exercises · ~${estimateMinutes(s)} min';
}

/// `05:07`, or `1:02:09` past an hour.
String clockLabel(int secs) {
  String pad(int n) => n.toString().padLeft(2, '0');
  final h = secs ~/ 3600, m = (secs % 3600) ~/ 60, s = secs % 60;
  return h > 0 ? '$h:${pad(m)}:${pad(s)}' : '${pad(m)}:${pad(s)}';
}

/// `4:05` (minutes not padded), for countdowns.
String shortClock(int secs) => '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
