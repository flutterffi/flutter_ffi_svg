/// Pure Dart SVG subset for Flutter: see [package:flutter_ffi_svg](https://pub.dev/packages/flutter_ffi_svg).
library;

/// Widget API for rendering inline SVG strings.
export 'src/ffi_svg.dart';

/// Parses SVG path data (`d="..."`) into a [dart:ui.Path].
export 'src/path_data.dart' show parseSvgPathData;

/// Scene model and SVG/XML parser.
export 'src/svg_model.dart' show SvgItem, SvgScene, parseSvgString;

/// Custom painter for a pre-parsed [SvgScene].
export 'src/svg_painter.dart';
