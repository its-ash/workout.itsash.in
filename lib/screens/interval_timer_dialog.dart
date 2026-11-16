import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/plan.dart';
import '../state/interval_timer.dart';
import '../state/live_status.dart';

/// Full-screen treadmill timer, readable from arm's length while walking:
/// a huge countdown, big speed and incline, a loud "change speed" countdown,
/// then the next segment and the full plan. Close (X or back) any time: the
/// timer keeps running, with its clock in the notification and a banner on
/// the home screen that reopens it.
class IntervalTimerDialog extends StatelessWidget {
  const IntervalTimerDialog({super.key, required this.timer});

  final IntervalTimer timer;

  static Future<void> show(BuildContext context, IntervalTimer timer, LiveStatus live) async {
    live.dialogOpened();
    try {
      await Navigator.of(
        context,
      ).push<void>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => IntervalTimerDialog(timer: timer)));
    } finally {
      live.dialogClosed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        final plan = timer.plan;
        return UiScaffold(
          appBar: UiAppBar(
            title: plan.title,
            subtitle: '${plan.segments.length} segments · ${plan.totalSeconds ~/ 60} min',
            leading: UiIconButton(
              Icons.close_rounded,
              tooltip: 'Close (the timer keeps running)',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          scrollable: true,
          maxWidth: 720,
          bottomBar: UiBottomBar(
            children: [
              if (timer.elapsed > 0)
                UiButton(
                  'Reset',
                  variant: UiButtonVariant.outline,
                  icon: Icons.replay_rounded,
                  size: UiSize.lg,
                  onPressed: timer.reset,
                ),
              UiButton(
                timer.running ? 'Pause' : (timer.elapsed > 0 && !timer.finished ? 'Resume' : 'Start'),
                icon: timer.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: UiSize.lg,
                onPressed: timer.toggle,
              ),
            ],
          ),
          body: _Body(timer: timer),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.timer});

  final IntervalTimer timer;

  @override
  Widget build(BuildContext context) {
    final plan = timer.plan;
    final seg = timer.segment;
    final next = timer.next;
    final countdown = timer.changeCountdown;
    final c = context.colors;
    final t = context.text;
    const tabular = [FontFeature.tabularFigures()];
    return UiColumn(
      gap: UiSpace.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiCard(
          variant: UiCardVariant.filled,
          padding: const EdgeInsets.fromLTRB(UiSpace.lg, UiSpace.xl, UiSpace.lg, UiSpace.xl),
          child: UiColumn(
            gap: UiSpace.md,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                timer.finished ? 'DONE' : seg.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: t.titleLarge?.copyWith(color: c.accent, letterSpacing: 1.5, fontWeight: FontWeight.w600),
              ),
              // The countdown fills the width, whatever the phone.
              SizedBox(
                height: 132,
                child: FittedBox(
                  child: Text(
                    timer.finished ? '0:00' : shortClock(timer.remaining),
                    style: t.displayLarge?.copyWith(fontSize: 132, height: 1, fontFeatures: tabular),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _BigStat(label: 'SPEED', value: seg.speed),
                  ),
                  const SizedBox(width: UiSpace.md),
                  Expanded(
                    child: _BigStat(label: 'INCLINE', value: seg.incline),
                  ),
                ],
              ),
              Text(
                [
                  '${shortClock(timer.leftInSegment)} left in segment',
                  if (plan.mets.isNotEmpty) '${timer.calories} kcal',
                ].join(' · '),
                textAlign: TextAlign.center,
                style: t.titleLarge?.copyWith(color: c.textMuted, fontFeatures: tabular),
              ),
              UiProgressBar(timer.segmentProgress),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: context.motion(UiMotion.normal),
          child: countdown != null && next != null
              ? _ChangeAlert(
                  key: const ValueKey('change'),
                  seconds: countdown,
                  speed: next.speed,
                  incline: next.incline,
                )
              : next != null
              ? UiCard(
                  key: const ValueKey('next'),
                  child: UiRow(
                    gap: UiSpace.md,
                    children: [
                      Icon(Icons.skip_next_rounded, size: 32, color: c.textMuted),
                      Expanded(
                        child: UiColumn(
                          gap: UiSpace.xxs,
                          children: [
                            Text('Next: ${next.label}', style: t.titleLarge),
                            Text('${next.speed} · ${next.incline}', style: t.headlineSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                selected: i == timer.index && timer.elapsed > 0,
              ),
          ],
        ),
      ],
    );
  }
}

/// Speed or incline in a size you can read while walking.
class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UiSpace.md, vertical: UiSpace.lg),
      decoration: BoxDecoration(color: c.background, borderRadius: UiRadius.all(UiRadius.lg)),
      child: Column(
        children: [
          Text(label, style: context.text.titleMedium?.copyWith(color: c.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: UiSpace.xs),
          SizedBox(
            height: 56,
            child: FittedBox(
              child: Text(
                value,
                style: context.text.displayMedium?.copyWith(
                  fontSize: 56,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loud warning in the last seconds before a speed change.
class _ChangeAlert extends StatelessWidget {
  const _ChangeAlert({super.key, required this.seconds, required this.speed, required this.incline});

  final int seconds;
  final String speed;
  final String incline;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.tone(UiStatus.warning);
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(UiSpace.lg),
      decoration: BoxDecoration(color: tone.color, borderRadius: UiRadius.all(UiRadius.lg)),
      child: Row(
        children: [
          Text('$seconds', style: t.displayLarge?.copyWith(fontSize: 72, height: 1, color: tone.onColor)),
          const SizedBox(width: UiSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHANGE SPEED', style: t.titleMedium?.copyWith(color: tone.onColor, letterSpacing: 1.2)),
                Text('$speed · $incline', maxLines: 2, style: t.headlineMedium?.copyWith(color: tone.onColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
