import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

/// An animated exercise demo from `assets/gifs/`. The GIFs are drawn on
/// white, so they always sit on a white rounded tile, in dark mode too.
class DemoGif extends StatelessWidget {
  const DemoGif(this.asset, {super.key, this.size, this.radius = UiRadius.sm, this.semanticLabel});

  final String asset;

  /// Square size. Null fills the width at the GIF's own aspect ratio.
  final double? size;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: Colors.white,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          // Thumbnails decode small; the GIFs are 360-ish px.
          cacheWidth: size == null ? null : (size! * dpr).round(),
          gaplessPlayback: true,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
          errorBuilder: (context, _, _) => SizedBox(
            width: size,
            height: size ?? 200,
            child: Icon(Icons.fitness_center_rounded, color: context.colors.textSubtle),
          ),
        ),
      ),
    );
  }
}
