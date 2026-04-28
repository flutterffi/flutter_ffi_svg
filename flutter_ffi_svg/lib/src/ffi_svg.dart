import 'package:flutter/widgets.dart';

import 'svg_model.dart';
import 'svg_painter.dart';

/// Displays vector graphics from inline SVG/XML [source].
///
/// Parsing and drawing are implemented in Dart only (no third-party runtime deps).
/// Supported subset includes `svg`, `g`, `path`, `rect`, `circle`, `ellipse`,
/// transforms, fills, strokes, opacity, `viewBox`, and width/height hints.
final class FfiSvg extends StatelessWidget {
  /// Renders SVG from [source].
  const FfiSvg.string(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
    this.color,
  });

  /// Raw SVG/XML text.
  final String source;

  /// Optional outer width (uses constraints / intrinsic size when null).
  final double? width;

  /// Optional outer height (uses constraints / intrinsic size when null).
  final double? height;

  /// How to scale the intrinsic graphic inside the layout bounds.
  final BoxFit fit;

  final AlignmentGeometry alignment;

  /// Clipping applied around the scaled content.
  final Clip clipBehavior;

  /// Default fill color when the SVG omits explicit paint (`currentColor`).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final SvgScene scene;
    try {
      scene = parseSvgString(
        source,
        defaultColor: color ?? const Color(0xFF000000),
      );
    } catch (_) {
      return SizedBox(width: width, height: height);
    }

    final vb = scene.viewBox;
    final intrinsic = scene.intrinsicSize();
    final Rect basis = vb ??
        Rect.fromLTWH(
          0,
          0,
          intrinsic.width.clamp(1e-6, double.infinity),
          intrinsic.height.clamp(1e-6, double.infinity),
        );

    Widget painted = SizedBox(
      width: basis.width,
      height: basis.height,
      child: CustomPaint(painter: SvgScenePainter(scene)),
    );

    painted = FittedBox(fit: fit, alignment: alignment, child: painted);

    if (clipBehavior != Clip.none) {
      painted = ClipRect(clipBehavior: clipBehavior, child: painted);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackW =
            constraints.hasBoundedWidth ? constraints.maxWidth : basis.width;
        final fallbackH =
            constraints.hasBoundedHeight ? constraints.maxHeight : basis.height;
        final ow = width ?? fallbackW;
        final oh = height ?? fallbackH;
        return SizedBox(
          width: width ?? ow,
          height: height ?? oh,
          child: painted,
        );
      },
    );
  }
}
