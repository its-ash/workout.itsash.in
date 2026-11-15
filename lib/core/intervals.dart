/// Treadmill interval plans and the math for where a timer is in them.
library;

class IntervalSegment {
  const IntervalSegment(this.label, this.speed, this.incline, this.seconds);

  final String label;
  final String speed;
  final String incline;
  final int seconds;
}

class IntervalPlan {
  const IntervalPlan({required this.id, required this.title, required this.segments, this.mets = const {}});

  /// Also the storage key of the timer anchor.
  final String id;
  final String title;
  final List<IntervalSegment> segments;

  /// MET value per speed label, for the calorie estimate. Empty hides calories.
  final Map<String, double> mets;

  int get totalSeconds => segments.fold(0, (a, s) => a + s.seconds);

  /// Start second of segment [i].
  int startOf(int i) => segments.take(i).fold(0, (a, s) => a + s.seconds);

  /// `0:00-2:00`.
  String rangeLabel(int i) => '${_mmss(startOf(i))}-${_mmss(startOf(i) + segments[i].seconds)}';

  /// Index of the segment that is running at [elapsed] seconds.
  int indexAt(int elapsed) {
    var acc = 0;
    for (var i = 0; i < segments.length; i++) {
      acc += segments[i].seconds;
      if (elapsed < acc) return i;
    }
    return segments.length - 1;
  }

  /// Seconds until the current segment ends.
  int leftInSegment(int elapsed) {
    final i = indexAt(elapsed);
    return (startOf(i) + segments[i].seconds - elapsed).clamp(0, segments[i].seconds);
  }

  /// 0..1 through the current segment.
  double segmentProgress(int elapsed) {
    final i = indexAt(elapsed);
    final within = (elapsed - startOf(i)).clamp(0, segments[i].seconds);
    return within / segments[i].seconds;
  }

  /// Calories so far: MET x 3.5 x kg / 200 per minute.
  int calories(int elapsed, {double bodyKg = 70}) {
    var cal = 0.0;
    final cur = indexAt(elapsed);
    for (var i = 0; i <= cur; i++) {
      final seg = segments[i];
      final met = mets[seg.speed] ?? 3.5;
      final secs = i == cur ? (elapsed - startOf(i)).clamp(0, seg.seconds) : seg.seconds;
      cal += (met * 3.5 * bodyKg / 200) * (secs / 60);
    }
    return cal.round();
  }

  static String _mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// 10 min run/walk finisher at the end of every session.
const runWalkPlan = IntervalPlan(
  id: 'run_walk',
  title: 'Run/Walk Interval Timer',
  segments: [
    IntervalSegment('Warm-Up Walk', '3.5 mph', '2%', 120),
    IntervalSegment('Run Interval 1', '6.0 mph', '1%', 60),
    IntervalSegment('Recovery Walk', '3.5 mph', '4%', 90),
    IntervalSegment('Run Interval 2', '6.5 mph', '1%', 60),
    IntervalSegment('Recovery Walk', '3.5 mph', '4%', 90),
    IntervalSegment('Run Interval 3', '7.0 mph', '1%', 60),
    IntervalSegment('Cool-Down Walk', '3.0 mph', '2%', 120),
  ],
);

/// 20 min interval walking: 5 x (90 s low, 90 s high).
const intervalWalkPlan = IntervalPlan(
  id: 'treadmill',
  title: 'Interval Walking',
  mets: {'4.5 km/h': 3.0, '6.5 km/h': 4.3},
  segments: [
    IntervalSegment('Warm-Up Walk', '4.5 km/h', '1%', 120),
    IntervalSegment('Low 1', '4.5 km/h', '1%', 90),
    IntervalSegment('High 1', '6.5 km/h', '1%', 90),
    IntervalSegment('Low 2', '4.5 km/h', '1%', 90),
    IntervalSegment('High 2', '6.5 km/h', '1%', 90),
    IntervalSegment('Low 3', '4.5 km/h', '1%', 90),
    IntervalSegment('High 3', '6.5 km/h', '1%', 90),
    IntervalSegment('Low 4', '4.5 km/h', '1%', 90),
    IntervalSegment('High 4', '6.5 km/h', '1%', 90),
    IntervalSegment('Low 5', '4.5 km/h', '1%', 90),
    IntervalSegment('High 5', '6.5 km/h', '1%', 90),
    IntervalSegment('Cool-Down Walk', '4.5 km/h', '1%', 180),
  ],
);
