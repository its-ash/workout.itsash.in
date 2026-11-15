import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app_state.dart';
import '../core/plan.dart';
import '../core/sessions.dart';
import '../widgets/demo_gif.dart';
import '../widgets/session_summary_card.dart';
import 'exercise_sheet.dart';
import 'interval_timer_sheet.dart';
import 'session_complete_sheet.dart';
import 'settings_screen.dart';
import 'stretching_sheet.dart';

/// Today's session: split picker, the chosen variation and its exercises.
/// The bottom bar starts and stops the session clock.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppState get _s => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _s.store.addListener(_syncScreenOn);
    _syncScreenOn();
    // A timer that was running when the app was closed: show it again.
    final running = [_s.runWalk, _s.intervalWalk].where((t) => t.running).firstOrNull;
    if (running != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          IntervalTimerSheet.show(context, running, _s.platform, keepScreenOnAfter: _s.store.isActive);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _s.store.removeListener(_syncScreenOn);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _s.runWalk.sync();
      _s.intervalWalk.sync();
    }
  }

  bool? _screenOn;

  /// The screen stays on during a session, so the clock is always in view.
  void _syncScreenOn() {
    final on = _s.store.isActive;
    if (on == _screenOn) return;
    _screenOn = on;
    _s.platform.keepScreenOn(on);
  }

  Future<void> _stop() async {
    final store = _s.store;
    final choice = await UiDialog.show<String>(
      context,
      title: 'Stop workout session?',
      message: 'Session duration: ${clockLabel(store.elapsed)}',
      icon: Icons.stop_circle_outlined,
      actions: const [
        UiDialogAction('Cancel', value: 'cancel'),
        UiDialogAction('Stop', value: 'stop'),
        UiDialogAction('Stop & export to Calendar', value: 'export', primary: true),
      ],
    );
    if (choice == null || choice == 'cancel') return;
    final session = store.session;
    final times = store.stop();
    if (choice != 'export' || times == null || !mounted) return;
    await SessionCompleteSheet.show(
      context,
      SessionSummary(session: session, begin: times.begin, end: times.end),
      _s.platform,
    );
  }

  void _openDemo(WorkoutLine line) {
    final demo = _s.demos.find(_s.store.type, line.name);
    if (demo == null) return;
    ExerciseSheet.show(context, line: line, demo: demo, attribution: _s.demos.attribution);
  }

  @override
  Widget build(BuildContext context) {
    final store = _s.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final session = store.session;
        final active = store.isActive;
        final lines = session.workout.map(WorkoutLine.parse).toList();
        return UiScaffold(
          appBar: UiAppBar(
            title: 'Workout',
            actions: [
              UiIconButton(
                Icons.self_improvement_rounded,
                tooltip: 'Stretching routine',
                onPressed: () => StretchingSheet.show(context),
              ),
              UiIconButton(
                Icons.directions_walk_rounded,
                tooltip: 'Interval walk timer',
                onPressed: () =>
                    IntervalTimerSheet.show(context, _s.intervalWalk, _s.platform, keepScreenOnAfter: store.isActive),
              ),
              UiIconButton(
                Icons.settings_rounded,
                tooltip: 'Settings',
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => SettingsScreen(demos: _s.demos))),
              ),
            ],
          ),
          scrollable: true,
          maxWidth: 720,
          bottomBar: UiBottomBar(
            children: [
              if (!active)
                UiButton('Start', icon: Icons.play_arrow_rounded, size: UiSize.lg, onPressed: store.start)
              else ...[
                UiButton(
                  clockLabel(store.elapsed),
                  icon: Icons.timer_outlined,
                  size: UiSize.lg,
                  variant: UiButtonVariant.soft,
                  onPressed: () {},
                ),
                UiButton(
                  'Stop',
                  icon: Icons.stop_rounded,
                  size: UiSize.lg,
                  variant: UiButtonVariant.danger,
                  onPressed: _stop,
                ),
              ],
            ],
          ),
          body: UiColumn(
            gap: UiSpace.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!active)
                UiSegmentedControl<SessionType>(
                  [for (final t in SessionType.values) UiSegment(t, label: t.label)],
                  value: store.type,
                  expand: true,
                  onChanged: store.selectType,
                ),
              _SessionCard(session: session, active: active, store: _s),
              UiSection(
                title: 'Exercises',
                child: UiColumn(
                  gap: UiSpace.sm,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final line in lines)
                      _ExerciseRow(
                        line: line,
                        thumb: _s.demos.find(store.type, line.name)?.gif,
                        onTap: line.isRunWalk
                            ? () => IntervalTimerSheet.show(
                                context,
                                _s.runWalk,
                                _s.platform,
                                keepScreenOnAfter: store.isActive,
                              )
                            : () => _openDemo(line),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.active, required this.store});

  final WorkoutSession session;
  final bool active;
  final AppState store;

  @override
  Widget build(BuildContext context) {
    final s = store.store;
    return UiCard(
      child: UiColumn(
        gap: UiSpace.xs,
        children: [
          Text(
            active ? 'IN PROGRESS · ${session.type.label.toUpperCase()}' : "TODAY'S SESSION",
            style: context.text.labelSmall?.copyWith(color: context.colors.accent, letterSpacing: 1.2),
          ),
          Text(session.title, style: context.text.headlineMedium),
          Text(sessionMeta(session), style: context.text.bodySmall),
          if (!active) ...[
            const UiGap(UiSpace.sm),
            UiRow(
              children: [
                UiIconButton(
                  Icons.shuffle_rounded,
                  tooltip: 'Shuffle variation',
                  variant: UiButtonVariant.outline,
                  onPressed: s.shuffle,
                ),
                Expanded(
                  child: UiButton(
                    'Next variation',
                    trailingIcon: Icons.arrow_forward_rounded,
                    variant: UiButtonVariant.secondary,
                    expand: true,
                    onPressed: s.nextVariation,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.line, required this.thumb, required this.onTap});

  final WorkoutLine line;
  final String? thumb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget leading;
    if (line.isRunWalk) {
      leading = const UiIconBox(Icons.timer_outlined, size: 56);
    } else if (thumb != null) {
      leading = DemoGif(thumb!, size: 56);
    } else {
      leading = UiIconBox(Icons.fitness_center_rounded, size: 56, color: colors.textSubtle);
    }
    return UiCard(
      padding: const EdgeInsets.all(UiSpace.md),
      onTap: line.isRunWalk || thumb != null ? onTap : null,
      semanticLabel: line.name,
      child: UiRow(
        gap: UiSpace.md,
        children: [
          leading,
          Expanded(
            child: UiColumn(
              gap: UiSpace.xxs,
              children: [
                Text(line.name, style: context.text.titleSmall),
                Text(line.plan, style: context.text.bodySmall),
                if (line.isRunWalk)
                  const UiStatusPill('Tap for the pace guide', status: UiStatus.accent, icon: Icons.timer_outlined),
              ],
            ),
          ),
          if (!line.isRunWalk && thumb != null) Icon(Icons.play_circle_outline_rounded, color: colors.accent),
        ],
      ),
    );
  }
}
