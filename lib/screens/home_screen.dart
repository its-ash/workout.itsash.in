import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app_state.dart';
import '../core/plan.dart';
import '../core/sessions.dart';
import '../state/interval_timer.dart';
import '../state/live_status.dart';
import '../widgets/demo_gif.dart';
import '../widgets/session_summary_card.dart';
import 'exercise_sheet.dart';
import 'interval_timer_dialog.dart';
import 'session_complete_sheet.dart';
import 'settings_screen.dart';
import 'stretching_sheet.dart';

/// Today's session: split picker, the chosen variation and its exercises.
/// The bottom bar starts and stops the session clock. While a session runs,
/// the current exercise is shown big on top with a Completed button that
/// moves to the next one. A running interval timer shows as a banner that
/// reopens its full-screen dialog.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppState get _s => widget.state;
  late final LiveStatus _live;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _live = LiveStatus(store: _s.store, timers: [_s.runWalk, _s.intervalWalk], platform: _s.platform);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _live.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _s.runWalk.sync();
      _s.intervalWalk.sync();
      // Also covers coming back from the notification permission prompt.
      _live.resend();
    }
  }

  void _openTimer(IntervalTimer timer) => IntervalTimerDialog.show(context, timer, _live);

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
      listenable: Listenable.merge([store, _s.runWalk, _s.intervalWalk]),
      builder: (context, _) {
        final session = store.session;
        final active = store.isActive;
        final lines = session.workout.map(WorkoutLine.parse).toList();
        final timer =
            [_s.runWalk, _s.intervalWalk].where((t) => t.running).firstOrNull ??
            [_s.runWalk, _s.intervalWalk].where((t) => t.elapsed > 0 && !t.finished).firstOrNull;
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
                onPressed: () => _openTimer(_s.intervalWalk),
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
              if (timer != null)
                UiPromoBanner(
                  title: '${timer.plan.title} · ${shortClock(timer.remaining)}',
                  subtitle: timer.running
                      ? '${timer.segment.speed} · ${timer.segment.incline}'
                      : 'Paused · tap to open',
                  icon: timer.running ? Icons.directions_walk_rounded : Icons.pause_rounded,
                  onTap: () => _openTimer(timer),
                ),
              if (!active)
                UiSegmentedControl<SessionType>(
                  [for (final t in SessionType.values) UiSegment(t, label: t.label)],
                  value: store.type,
                  expand: true,
                  onChanged: store.selectType,
                ),
              if (active)
                _CurrentExercise(
                  lines: lines,
                  index: store.current,
                  gif: store.allDone ? null : _s.demos.find(store.type, lines[store.current].name)?.gif,
                  onComplete: store.completeCurrent,
                  onPrevious: store.current > 0 ? store.previous : null,
                  onOpenTimer: () => _openTimer(_s.runWalk),
                  onOpenDemo: store.allDone ? null : () => _openDemo(lines[store.current]),
                  onFinish: _stop,
                )
              else
                _SessionCard(session: session, active: active, store: _s),
              UiSection(
                title: active
                    ? '${session.title} · ${store.current.clamp(0, lines.length)}/${lines.length} done'
                    : 'Exercises',
                child: UiColumn(
                  gap: UiSpace.sm,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      _ExerciseRow(
                        line: lines[i],
                        thumb: _s.demos.find(store.type, lines[i].name)?.gif,
                        state: !active
                            ? _RowState.idle
                            : i < store.current
                            ? _RowState.done
                            : i == store.current
                            ? _RowState.current
                            : _RowState.upcoming,
                        onTap: lines[i].isRunWalk ? () => _openTimer(_s.runWalk) : () => _openDemo(lines[i]),
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

/// The exercise being done, big enough to read from the bench: a large demo,
/// the name and plan, and a Completed button that moves to the next one.
class _CurrentExercise extends StatelessWidget {
  const _CurrentExercise({
    required this.lines,
    required this.index,
    required this.gif,
    required this.onComplete,
    required this.onPrevious,
    required this.onOpenTimer,
    required this.onOpenDemo,
    required this.onFinish,
  });

  final List<WorkoutLine> lines;
  final int index;
  final String? gif;
  final VoidCallback onComplete;
  final VoidCallback? onPrevious;
  final VoidCallback onOpenTimer;
  final VoidCallback? onOpenDemo;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (index >= lines.length) {
      return UiCard(
        padding: const EdgeInsets.all(UiSpace.xl),
        child: UiColumn(
          gap: UiSpace.md,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, size: 64, color: c.accent),
            Text('All exercises done', style: t.headlineMedium, textAlign: TextAlign.center),
            Text('Great work. Stop the session to save it.', style: t.bodyLarge, textAlign: TextAlign.center),
            UiButtonBar(expand: true, [
              UiButton('Back', variant: UiButtonVariant.outline, size: UiSize.lg, onPressed: onPrevious),
              UiButton('Finish', icon: Icons.stop_rounded, size: UiSize.lg, onPressed: onFinish),
            ]),
          ],
        ),
      );
    }
    final line = lines[index];
    final isLast = index == lines.length - 1;
    return UiCard(
      padding: const EdgeInsets.all(UiSpace.lg),
      child: UiColumn(
        gap: UiSpace.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'EXERCISE ${index + 1} OF ${lines.length}',
            style: t.titleSmall?.copyWith(color: c.accent, letterSpacing: 1.2),
          ),
          if (line.isRunWalk)
            Container(
              height: 180,
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: UiRadius.all(UiRadius.lg)),
              child: Icon(Icons.directions_run_rounded, size: 96, color: c.accent),
            )
          else if (gif != null)
            GestureDetector(
              onTap: onOpenDemo,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
                  child: DemoGif(gif!, radius: UiRadius.lg, semanticLabel: '${line.name} demo'),
                ),
              ),
            ),
          Text(line.name, style: t.headlineLarge),
          Text(
            line.plan,
            style: t.titleLarge?.copyWith(color: c.textMuted, fontWeight: FontWeight.w400),
          ),
          if (line.isRunWalk)
            UiButton(
              'Open run/walk timer',
              icon: Icons.timer_outlined,
              variant: UiButtonVariant.soft,
              size: UiSize.lg,
              expand: true,
              onPressed: onOpenTimer,
            ),
          Row(
            children: [
              UiIconButton(
                Icons.undo_rounded,
                tooltip: 'Previous exercise',
                variant: UiButtonVariant.outline,
                size: UiSize.lg,
                onPressed: onPrevious,
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: UiButton(
                  isLast ? 'Completed · finish' : 'Completed',
                  icon: Icons.check_rounded,
                  size: UiSize.lg,
                  expand: true,
                  onPressed: onComplete,
                ),
              ),
            ],
          ),
          if (!isLast)
            Text(
              'Next: ${lines[index + 1].name}',
              style: t.bodyLarge?.copyWith(color: c.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

enum _RowState { idle, done, current, upcoming }

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.line, required this.thumb, required this.onTap, this.state = _RowState.idle});

  final WorkoutLine line;
  final String? thumb;
  final VoidCallback onTap;
  final _RowState state;

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
    final done = state == _RowState.done;
    final card = UiCard(
      padding: const EdgeInsets.all(UiSpace.md),
      onTap: line.isRunWalk || thumb != null ? onTap : null,
      selected: state == _RowState.current,
      semanticLabel: done ? '${line.name}, done' : line.name,
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
          if (done)
            Icon(Icons.check_circle_rounded, color: colors.success)
          else if (!line.isRunWalk && thumb != null)
            Icon(Icons.play_circle_outline_rounded, color: colors.accent),
        ],
      ),
    );
    return done ? Opacity(opacity: 0.55, child: card) : card;
  }
}
