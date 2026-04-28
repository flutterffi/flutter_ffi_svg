import 'dart:ui' show Color, PathFillType;

/// Parses common SVG paint values (hex, rgb(), named subset).
Color? parseSvgPaint(String? value, {Color? fallback}) {
  if (value == null) return fallback;
  final v = value.trim();
  if (v.isEmpty || v == 'none') return null;
  if (v == 'currentColor') return fallback ?? const Color(0xFF000000);

  if (v.startsWith('#')) {
    var hex = v.substring(1);
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) {
      final n = int.tryParse(hex, radix: 16);
      if (n != null) return Color(0xFF000000 | n);
    }
    if (hex.length == 8) {
      final n = int.tryParse(hex, radix: 16);
      if (n != null) return Color(n);
    }
  }

  final rgb = RegExp(
    r'rgba?\(\s*([\d.]+)\s*%\s*,\s*([\d.]+)\s*%\s*,\s*([\d.]+)\s*%(?:\s*,\s*([\d.]+))?\s*\)',
    caseSensitive: false,
  );
  final m3 = rgb.firstMatch(v);
  if (m3 != null) {
    final r = (double.parse(m3.group(1)!) * 255 / 100).round().clamp(0, 255);
    final g = (double.parse(m3.group(2)!) * 255 / 100).round().clamp(0, 255);
    final b = (double.parse(m3.group(3)!) * 255 / 100).round().clamp(0, 255);
    final a = m3.group(4) != null ? double.parse(m3.group(4)!) / 100 : 1.0;
    return Color.fromARGB((a * 255).round().clamp(0, 255), r, g, b);
  }

  final rgb2 = RegExp(
    r'rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)',
    caseSensitive: false,
  );
  final m2 = rgb2.firstMatch(v);
  if (m2 != null) {
    final r = double.parse(m2.group(1)!);
    final g = double.parse(m2.group(2)!);
    final b = double.parse(m2.group(3)!);
    final a = m2.group(4) != null ? double.parse(m2.group(4)!) : 1.0;
    return Color.fromARGB(
      (a * 255).round().clamp(0, 255),
      r.round().clamp(0, 255),
      g.round().clamp(0, 255),
      b.round().clamp(0, 255),
    );
  }

  const named = <String, int>{
    'black': 0xFF000000,
    'white': 0xFFFFFFFF,
    'red': 0xFFFF0000,
    'green': 0xFF008000,
    'blue': 0xFF0000FF,
    'transparent': 0x00000000,
  };
  final n = named[v.toLowerCase()];
  if (n != null) return Color(n);

  return fallback;
}

double? parseOpacity(String? v) {
  if (v == null) return null;
  final x = double.tryParse(v.trim());
  return x?.clamp(0.0, 1.0);
}

PathFillType parseFillRule(String? v) {
  if (v != null && v.trim() == 'evenodd') {
    return PathFillType.evenOdd;
  }
  return PathFillType.nonZero;
}

double parseLengthPx(String? v, {double fallback = 0}) {
  if (v == null || v.trim().isEmpty) return fallback;
  final s = v.trim();
  final n = double.tryParse(
    s.replaceAll(RegExp(r'(px|pt|em|rem)$', caseSensitive: false), '').trim(),
  );
  return n ?? fallback;
}
