import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/plan.dart';
import '../data/demos.dart';
import '../widgets/demo_gif.dart';

/// Demo GIF, the plan, target muscles and step-by-step instructions (English
/// or Hindi) for one exercise.
class ExerciseSheet extends StatefulWidget {
  const ExerciseSheet({super.key, required this.line, required this.demo, required this.attribution});

  final WorkoutLine line;
  final Demo demo;
  final String attribution;

  static Future<void> show(
    BuildContext context, {
    required WorkoutLine line,
    required Demo demo,
    required String attribution,
  }) => UiSheet.show<void>(
    context,
    title: line.name,
    subtitle: line.plan,
    child: ExerciseSheet(line: line, demo: demo, attribution: attribution),
    actions: [
      Builder(builder: (context) => UiButton('Done', expand: true, onPressed: () => Navigator.of(context).pop())),
    ],
  );

  @override
  State<ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<ExerciseSheet> {
  String _lang = 'en';

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    final steps = demo.steps[_lang] ?? demo.steps['en'] ?? const <String>[];
    final muscles = {demo.target, ...demo.secondary};
    return UiColumn(
      gap: UiSpace.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: DemoGif(demo.gif, radius: UiRadius.md, semanticLabel: '${widget.line.name} demo'),
          ),
        ),
        Wrap(
          spacing: UiSpace.xs,
          runSpacing: UiSpace.xs,
          children: [
            UiTag(demo.equipment, icon: Icons.fitness_center_rounded),
            for (final m in muscles) UiTag(m, status: m == demo.target ? UiStatus.accent : null),
          ],
        ),
        if (steps.isNotEmpty) ...[
          UiRow(
            children: [
              Expanded(child: Text('How to do it', style: context.text.titleMedium)),
              if ((demo.steps['hi'] ?? const []).isNotEmpty)
                UiSegmentedControl<String>(
                  const [UiSegment('en', label: 'English'), UiSegment('hi', label: 'हिन्दी')],
                  value: _lang,
                  size: UiSize.sm,
                  onChanged: (v) => setState(() => _lang = v),
                ),
            ],
          ),
          UiColumn(
            gap: UiSpace.sm,
            children: [
              for (var i = 0; i < steps.length; i++)
                UiRow(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  gap: UiSpace.md,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('${i + 1}.', style: context.text.labelLarge?.copyWith(color: context.colors.accent)),
                    ),
                    Expanded(child: Text(steps[i], style: context.text.bodyMedium)),
                  ],
                ),
            ],
          ),
        ],
        if (widget.attribution.isNotEmpty) Text('Demo ${widget.attribution}', style: context.text.bodySmall),
      ],
    );
  }
}
