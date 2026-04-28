import 'package:flutter/widgets.dart';

import 'svg_model.dart';

/// Draws [scene] at 1:1 in units of [scene] intrinsic / view-box space.
///
/// Intended to be placed inside [FittedBox], [SizedBox], or layouts that give a bounded area.
final class SvgScenePainter extends CustomPainter {
  /// Creates a painter that draws [scene] at 1:1 in viewBox space.
  SvgScenePainter(this.scene);

  /// The parsed and flattened scene to draw.
  final SvgScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in scene.items) {
      final fill = item.fill;
      if (fill != null) {
        canvas.drawPath(item.path, fill);
      }
      final stroke = item.stroke;
      if (stroke != null && item.strokeWidth > 0) {
        canvas.drawPath(item.path, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SvgScenePainter oldDelegate) =>
      oldDelegate.scene != scene;
}
