import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/plan.dart';
import '../platform/platform_channel.dart';
import '../state/interval_timer.dart';

/// Treadmill interval timer: time left, current speed and incline, the next
/// change with a 5 second beep countdown, and the full segment list. The
/// screen stays on while the sheet is open. Closing it pauses the timer.
class IntervalTimerSheet extends StatelessWidget {
  const IntervalTimerSheet({super.key, required this.timer});

  final IntervalTimer timer;

  static Future<void> show(
    BuildContext context,
    IntervalTimer timer,
    WorkoutPlatform platform, {
    bool keepScreenOnAfter = false,
  }) async {
    platform.keepScreenOn(true);
    await UiSheet.show<void>(
      context,
      title: timer.plan.title,
      subtitle: '${timer.plan.segments.length} segments · ${timer.plan.totalSeconds ~/ 60} min',
      expand: true,
      child: IntervalTimerSheet(timer: timer),
      actions: [
        ListenableBuilder(
          listenable: timer,
          builder: (context, _) => UiButtonBar(expand: true, [
            if (timer.elapsed > 0)
              UiButton('Reset', variant: UiButtonVariant.outline, icon: Icons.replay_rounded, onPressed: timer.reset),
            UiButton(
              timer.running ? 'Pause' : (timer.elapsed > 0 && !timer.finished ? 'Resume' : 'Start'),
              icon: timer.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onPressed: timer.toggle,
            ),
          ]),
        ),
      ],
    );
    timer.pause();
    platform.keepScreenOn(keepScreenOnAfter);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        final plan = timer.plan;
        final seg = timer.segment;
        final next = timer.next;
        final countdown = timer.changeCountdown;
        final colors = context.colors;
        return UiColumn(
          gap: UiSpace.lg,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiCard(
              variant: UiCardVariant.filled,
              child: UiColumn(
                gap: UiSpace.sm,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    timer.finished ? 'Done' : shortClock(timer.remaining),
                    style: context.text.displayLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  Text(
                    seg.label.toUpperCase(),
                    style: context.text.labelMedium?.copyWith(color: colors.accent, letterSpacing: 1.2),
                  ),
                  UiRow(
                    mainAxisAlignment: MainAxisAlignment.center,
                    gap: UiSpace.xl,
                    children: [
                      _Stat(label: 'Speed', value: seg.speed, large: true),
                      _Stat(label: 'Incline', value: seg.incline, large: true),
                    ],
                  ),
                  Text(
                    [
                      '${shortClock(timer.leftInSegment)} left in segment',
                      if (plan.mets.isNotEmpty) '${timer.calories} kcal',
                    ].join(' · '),
                    style: context.text.bodySmall,
                  ),
                  UiProgressBar(timer.segmentProgress),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: context.motion(UiMotion.normal),
              child: countdown != null && next != null
                  ? UiAlert(
                      key: const ValueKey('change'),
                      'Change to ${next.speed} · ${next.incline} in $countdown s',
                      title: 'New speed',
                      status: UiStatus.warning,
                      icon: Icons.speed_rounded,
                    )
                  : next != null
                  ? UiListTile(
                      key: const ValueKey('next'),
                      'Next: ${next.label}',
                      subtitle: '${next.speed} · ${next.incline}',
                      icon: Icons.skip_next_rounded,
                      value: timer.running ? '${timer.leftInSegment}s' : null,
                    )
                  : const SizedBox.shrink(key: ValueKey('none')),
            ),
            UiListGroup(
              header: 'Plan',
              children: [
                for (var i = 0; i < plan.segments.length; i++)
                  UiListTile(
                    plan.segments[i].label,
                    subtitle: '${plan.segments[i].speed} · ${plan.segments[i].incline}',
                    value: plan.rangeLabel(i),
                    dense: true,
                    selected: i == timer.index && timer.elapsed > 0,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.large = false});

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: context.text.labelSmall?.copyWith(color: context.colors.textMuted)),
        Text(value, style: large ? context.text.headlineMedium : context.text.titleMedium),
      ],
    );
  }
}
