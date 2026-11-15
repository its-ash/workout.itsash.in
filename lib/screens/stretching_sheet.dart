import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/stretches.dart';
import '../widgets/demo_gif.dart';

/// The full body stretching routine, one card per stretch.
class StretchingSheet extends StatelessWidget {
  const StretchingSheet({super.key});

  static Future<void> show(BuildContext context) => UiSheet.show<void>(
    context,
    title: 'Full Body Stretching Routine',
    subtitle: '${stretchingRoutine.length} stretches, about 15 minutes',
    expand: true,
    child: const StretchingSheet(),
    actions: [
      Builder(builder: (context) => UiButton('Done', expand: true, onPressed: () => Navigator.of(context).pop())),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return UiColumn(
      gap: UiSpace.sm,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in stretchingRoutine)
          UiCard(
            padding: const EdgeInsets.all(UiSpace.md),
            child: UiRow(
              gap: UiSpace.md,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DemoGif('assets/gifs/${s.gif}', size: 96, semanticLabel: s.name),
                Expanded(
                  child: UiColumn(
                    gap: UiSpace.xxs,
                    children: [
                      Text(s.name, style: context.text.titleSmall),
                      Text(s.duration, style: context.text.labelMedium?.copyWith(color: context.colors.accent)),
                      Text(s.description, style: context.text.bodySmall),
                      Text(s.instruction, style: context.text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
