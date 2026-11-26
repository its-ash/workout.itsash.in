import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:theme/theme.dart';

import '../platform/platform_channel.dart';
import '../widgets/session_summary_card.dart';

/// Shown after "Stop & export": the summary card. On open it renders the card
/// to a PNG, saves it to `Pictures/Workout`, then opens the calendar event.
/// Share sends the same image anywhere.
class SessionCompleteSheet extends StatefulWidget {
  const SessionCompleteSheet({super.key, required this.summary, required this.platform, this.exportOnOpen = true});

  final SessionSummary summary;
  final WorkoutPlatform platform;
  final bool exportOnOpen;

  static Future<void> show(BuildContext context, SessionSummary summary, WorkoutPlatform platform) =>
      UiSheet.show<void>(
        context,
        title: 'Workout complete',
        subtitle: '${summary.session.title} · ${summaryDuration(summary.seconds)}',
        expand: true,
        child: SessionCompleteSheet(summary: summary, platform: platform),
      );

  @override
  State<SessionCompleteSheet> createState() => _SessionCompleteSheetState();
}

class _SessionCompleteSheetState extends State<SessionCompleteSheet> {
  final _boundary = GlobalKey();
  Uint8List? _png;
  String? _savedTo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.exportOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _export());
    }
  }

  Future<Uint8List?> _render() async {
    if (_png != null) return _png;
    // Fonts and the card's first paint must be done before capture.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return null;
    final ro = _boundary.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return null;
    final image = await ro.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return _png = data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Save the image, then hand the session to the calendar app.
  Future<void> _export() async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    final s = widget.summary;
    String? saved;
    try {
      final png = await _render();
      if (png != null) saved = await widget.platform.saveImage(png, s.fileName);
    } finally {
      if (mounted) {
        setState(() {
          _savedTo = saved;
          _busy = false;
        });
      }
    }
    if (!mounted) return;
    final details = [s.calendarDetails, if (saved != null) '\nSummary image: $saved'].join('\n');
    await widget.platform.addToCalendar(
      title: s.calendarTitle,
      details: details,
      location: 'Gym',
      begin: s.begin,
      end: s.end,
    );
  }

  Future<void> _share() async {
    final png = await _render();
    if (png == null) return;
    await widget.platform.shareImage(png, widget.summary.fileName);
  }

  @override
  Widget build(BuildContext context) {
    return UiColumn(
      gap: UiSpace.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_busy)
          const UiAlert('Saving the summary image…', status: UiStatus.info, icon: Icons.image_outlined)
        else if (_savedTo != null)
          UiAlert(
            'Saved to $_savedTo and added to the calendar event.',
            title: 'Image saved',
            status: UiStatus.success,
          ),
        UiButtonBar(expand: true, [
          UiButton('Calendar', variant: UiButtonVariant.outline, icon: Icons.event_rounded, onPressed: _export),
          UiButton('Share image', icon: Icons.share_rounded, onPressed: _share),
        ]),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UiRadius.lg),
                border: Border.all(color: context.colors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.lg),
                child: RepaintBoundary(
                  key: _boundary,
                  child: SessionSummaryCard(summary: widget.summary),
                ),
              ),
            ),
          ),
        ),
        UiButton('Done', variant: UiButtonVariant.ghost, expand: true, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
