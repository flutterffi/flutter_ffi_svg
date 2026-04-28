import 'dart:ui';

import 'package:flutter/rendering.dart' show Matrix4;

import 'path_data.dart';
import 'svg_style.dart';

/// One drawable primitive after flattening groups.
final class SvgItem {
  SvgItem({
    required this.path,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final Path path;
  final Paint? fill;
  final Paint? stroke;
  final double strokeWidth;
}

/// Parsed SVG scene: [sizeHint] from width/height; [viewBox] for scaling.
final class SvgScene {
  SvgScene({
    required this.items,
    this.width,
    this.height,
    this.viewBox,
  });

  final List<SvgItem> items;
  final double? width;
  final double? height;
  final Rect? viewBox;

  /// Best effort intrinsic size from viewBox or width/height.
  Size intrinsicSize() {
    if (viewBox != null) {
      return Size(viewBox!.width, viewBox!.height);
    }
    if (width != null && height != null) {
      return Size(width!, height!);
    }
    if (width != null) return Size(width!, width!);
    return const Size(100, 100);
  }
}

/// Parses raw SVG/XML into a drawable [SvgScene].
/// Supports a practical subset: `svg`, `g`, `path`, `rect`, `circle`, `ellipse`.
SvgScene parseSvgString(
  String input, {
  Color defaultColor = const Color(0xFF000000),
}) {
  final flat = _SvgFlattenParser(input, defaultColor).parse();
  return flat;
}

final class _SvgFlattenParser {
  _SvgFlattenParser(this._src, this._defaultColor);

  final String _src;
  final Color _defaultColor;
  int _i = 0;

  SvgScene parse() {
    final s = _stripLeadingDoctype(_stripXmlDeclaration(_stripComments(_src)));
    _i = 0;
    _src2 = s;
    double? w;
    double? h;
    Rect? vb;
    final items = <SvgItem>[];

    while (_i < _src2.length) {
      _skipWs();
      if (_i >= _src2.length) break;
      if (_src2[_i] != '<') {
        _i++;
        continue;
      }
      if (_peekStr('</')) {
        _skipTo('>');
        _i++;
        continue;
      }
      final tag = _parseOpenTag();
      if (tag == null) continue;
      final name = tag.name.toLowerCase();
      if (name == 'svg') {
        w = _parseOptionalLength(tag.attrs['width']) ?? w;
        h = _parseOptionalLength(tag.attrs['height']) ?? h;
        vb = _viewBox(tag.attrs['viewBox']) ?? vb;
        _parseSvgContent(Matrix4.identity(), items);
        break;
      }
    }

    return SvgScene(items: items, width: w, height: h, viewBox: vb);
  }

  late String _src2;

  void _parseSvgContent(Matrix4 parent, List<SvgItem> out) {
    while (_i < _src2.length) {
      _skipWs();
      if (_i >= _src2.length) break;
      if (_peekStr('</svg')) {
        _skipTo('>');
        if (_i < _src2.length && _src2[_i] == '>') _i++;
        break;
      }
      if (_src2[_i] != '<') {
        _i++;
        continue;
      }
      if (_peekStr('<!--')) {
        _skipComment();
        continue;
      }
      if (_peekStr('</')) {
        _skipTo('>');
        if (_i < _src2.length && _src2[_i] == '>') _i++;
        break;
      }
      final tag = _parseOpenTag();
      if (tag == null) continue;
      final name = tag.name.toLowerCase();
      if (tag.selfClosing) {
        _emitShape(name, tag.attrs, parent, out);
        continue;
      }
      if (name == 'g') {
        final m = _mul(parent, _parseTransform(tag.attrs['transform']));
        _parseGroupContent(m, out, 'g');
        continue;
      }
      if (name == 'svg') {
        _skipBranch();
        continue;
      }
      _emitShape(name, tag.attrs, parent, out);
    }
  }

  void _parseGroupContent(Matrix4 parent, List<SvgItem> out, String endTag) {
    while (_i < _src2.length) {
      _skipWs();
      if (_i >= _src2.length) break;
      if (_peekStr('</$endTag')) {
        _skipTo('>');
        if (_i < _src2.length && _src2[_i] == '>') _i++;
        break;
      }
      if (_src2[_i] != '<') {
        _i++;
        continue;
      }
      if (_peekStr('<!--')) {
        _skipComment();
        continue;
      }
      if (_peekStr('</')) {
        _skipTo('>');
        if (_i < _src2.length && _src2[_i] == '>') _i++;
        break;
      }
      final tag = _parseOpenTag();
      if (tag == null) continue;
      final name = tag.name.toLowerCase();
      if (tag.selfClosing) {
        _emitShape(name, tag.attrs, parent, out);
        continue;
      }
      if (name == 'g') {
        final m = _mul(parent, _parseTransform(tag.attrs['transform']));
        _parseGroupContent(m, out, 'g');
      } else if (name == 'defs' || name == 'title' || name == 'desc') {
        _skipBranch();
      } else {
        _emitShape(name, tag.attrs, parent, out);
        _skipBranch();
      }
    }
  }

  void _skipBranch() {
    var depth = 1;
    while (_i < _src2.length && depth > 0) {
      if (_peekStr('</')) {
        final end = _src2.indexOf('>', _i);
        if (end == -1) break;
        depth--;
        _i = end + 1;
        continue;
      }
      if (_i < _src2.length &&
          _src2[_i] == '<' &&
          _i + 1 < _src2.length &&
          _src2[_i + 1] != '/' &&
          _i + 1 < _src2.length) {
        final next = _parseOpenTag();
        if (next != null && !next.selfClosing) {
          depth++;
        }
        continue;
      }
      _i++;
    }
  }

  void _emitShape(
    String name,
    Map<String, String> attrs,
    Matrix4 xf,
    List<SvgItem> out,
  ) {
    final fillRule = parseFillRule(attrs['fill-rule'] ?? attrs['fillrule']);
    Path? path;
    switch (name) {
      case 'path':
        final d = attrs['d'];
        if (d == null || d.isEmpty) return;
        path = parseSvgPathData(d, fillType: fillRule);
        break;
      case 'rect':
        final x = _num(attrs['x']);
        final y = _num(attrs['y']);
        final w = _num(attrs['width']);
        final he = _num(attrs['height']);
        final rx = _num(attrs['rx']);
        final ry = _num(attrs['ry']);
        path = Path();
        if (rx > 0 || ry > 0) {
          final rxx = rx > 0 ? rx : ry;
          final ryy = ry > 0 ? ry : rx;
          path.addRRect(
            RRect.fromRectXY(Rect.fromLTWH(x, y, w, he), rxx, ryy),
          );
        } else {
          path.addRect(Rect.fromLTWH(x, y, w, he));
        }
        break;
      case 'circle':
        final cx = _num(attrs['cx']);
        final cy = _num(attrs['cy']);
        final r = _num(attrs['r']);
        path = Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
        break;
      case 'ellipse':
        final cx = _num(attrs['cx']);
        final cy = _num(attrs['cy']);
        final rx = _num(attrs['rx']);
        final ry = _num(attrs['ry']);
        path = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: rx * 2,
              height: ry * 2,
            ),
          );
        break;
      default:
        return;
    }
    final basePath = path;
    final xfPath = Path()..addPath(basePath, Offset.zero, matrix4: xf.storage);

    final fo = parseOpacity(attrs['fill-opacity']);
    final so = parseOpacity(attrs['stroke-opacity']);
    final oo = parseOpacity(attrs['opacity']);

    Color applyAlpha(Color c, double mult) {
      final a = (c.a * mult).clamp(0.0, 1.0);
      return c.withValues(alpha: a);
    }

    final fillAttr = attrs['fill'];
    Color baseFill = _defaultColor;
    final fillColor = parseSvgPaint(fillAttr, fallback: baseFill);
    Paint? fillPaint;
    if (fillColor != null) {
      var c = fillColor;
      if (fo != null) c = applyAlpha(c, fo);
      if (oo != null) c = applyAlpha(c, oo);
      fillPaint = Paint()
        ..color = c
        ..style = PaintingStyle.fill;
    } else if (fillAttr != null && fillAttr.trim() == 'none') {
      fillPaint = null;
    } else {
      var c = baseFill;
      if (fo != null) c = applyAlpha(c, fo);
      if (oo != null) c = applyAlpha(c, oo);
      fillPaint = Paint()
        ..color = c
        ..style = PaintingStyle.fill;
    }

    final strokeAttr = attrs['stroke'];
    final strokeColor = parseSvgPaint(strokeAttr);
    final sw =
        parseLengthPx(attrs['stroke-width'], fallback: 1).clamp(0.0, 10000.0);
    Paint? strokePaint;
    if (strokeColor != null && sw > 0) {
      var c = strokeColor;
      if (so != null) c = applyAlpha(c, so);
      if (oo != null) c = applyAlpha(c, oo);
      strokePaint = Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter;
    }

    out.add(
      SvgItem(path: xfPath, fill: fillPaint, stroke: strokePaint, strokeWidth: sw),
    );
  }

  double _num(String? s) => double.tryParse(s?.trim() ?? '') ?? 0;

  double? _parseOptionalLength(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final v = parseLengthPx(s, fallback: double.nan);
    return v.isNaN ? null : v;
  }

  Rect? _viewBox(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s
        .split(RegExp(r'[\s,]+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length != 4) return null;
    final x = double.tryParse(parts[0]) ?? 0;
    final y = double.tryParse(parts[1]) ?? 0;
    final w = double.tryParse(parts[2]) ?? 0;
    final h = double.tryParse(parts[3]) ?? 0;
    return Rect.fromLTWH(x, y, w, h);
  }

  Matrix4 _parseTransform(String? t) {
    final m = Matrix4.identity();
    if (t == null || t.trim().isEmpty) return m;
    final re = RegExp(r'([a-zA-Z]+)\(([^)]*)\)');
    for (final x in re.allMatches(t)) {
      final name = x.group(1)!.toLowerCase();
      final args = x
          .group(2)!
          .split(RegExp(r'[\s,]+'))
          .where((e) => e.isNotEmpty)
          .map((e) => double.tryParse(e) ?? 0.0)
          .toList();
      switch (name) {
        case 'matrix':
          if (args.length >= 6) {
            final a = args[0];
            final b = args[1];
            final c = args[2];
            final d = args[3];
            final e = args[4];
            final f = args[5];
            m.multiply(
              Matrix4(
                a, b, 0, 0,
                c, d, 0, 0,
                e, f, 1, 0,
                0, 0, 0, 1,
              ),
            );
          }
          break;
        case 'translate':
          if (args.isNotEmpty) {
            m.multiply(
              Matrix4.translationValues(args[0], args.length > 1 ? args[1] : 0, 0),
            );
          }
          break;
        case 'scale':
          if (args.isNotEmpty) {
            m.multiply(
              Matrix4.diagonal3Values(
                args[0],
                args.length > 1 ? args[1] : args[0],
                1,
              ),
            );
          }
          break;
        case 'rotate':
          if (args.isNotEmpty) {
            final deg = args[0] * 3.141592653589793 / 180;
            if (args.length >= 3) {
              final ox = args[1];
              final oy = args[2];
              m.multiply(Matrix4.translationValues(ox, oy, 0));
              m.multiply(Matrix4.rotationZ(deg));
              m.multiply(Matrix4.translationValues(-ox, -oy, 0));
            } else {
              m.multiply(Matrix4.rotationZ(deg));
            }
          }
          break;
        default:
          break;
      }
    }
    return m;
  }

  Matrix4 _mul(Matrix4 a, Matrix4 b) {
    final r = Matrix4.copy(a);
    r.multiply(b);
    return r;
  }

  _Tag? _parseOpenTag() {
    if (_i >= _src2.length || _src2[_i] != '<') return null;
    final start = _i;
    _i++;
    if (_i < _src2.length && _src2[_i] == '/') return null;
    final nameBuf = StringBuffer();
    while (_i < _src2.length && _isNameChar(_src2[_i])) {
      nameBuf.write(_src2[_i]);
      _i++;
    }
    final name = nameBuf.toString();
    if (name.isEmpty) {
      _i = start;
      return null;
    }
    final attrs = <String, String>{};
    var selfClosing = false;
    while (_i < _src2.length) {
      _skipWs();
      if (_i >= _src2.length) break;
      if (_src2[_i] == '>') {
        _i++;
        break;
      }
      if (_src2[_i] == '/' && _i + 1 < _src2.length && _src2[_i + 1] == '>') {
        selfClosing = true;
        _i += 2;
        break;
      }
      final an = StringBuffer();
      while (_i < _src2.length && _isNameChar(_src2[_i])) {
        an.write(_src2[_i]);
        _i++;
      }
      if (an.isEmpty) {
        _i++;
        continue;
      }
      _skipWs();
      if (_i < _src2.length && _src2[_i] == '=') {
        _i++;
        _skipWs();
        final q = _i < _src2.length ? _src2[_i] : '';
        if (q == '"' || q == "'") {
          _i++;
          final vs = StringBuffer();
          while (_i < _src2.length && _src2[_i] != q) {
            vs.write(_src2[_i]);
            _i++;
          }
          if (_i < _src2.length) _i++;
          attrs[an.toString()] = vs.toString();
        } else {
          final vs = StringBuffer();
          while (_i < _src2.length && _src2[_i] != '>' && !_isWs(_src2[_i])) {
            vs.write(_src2[_i]);
            _i++;
          }
          attrs[an.toString()] = vs.toString();
        }
      }
    }
    return _Tag(name: name, attrs: attrs, selfClosing: selfClosing);
  }

  bool _peekStr(String p) => _src2.startsWith(p, _i);

  void _skipTo(String ch) {
    final idx = _src2.indexOf(ch, _i);
    if (idx == -1) {
      _i = _src2.length;
    } else {
      _i = idx;
    }
  }

  void _skipComment() {
    if (!_peekStr('<!--')) return;
    final end = _src2.indexOf('-->', _i);
    if (end == -1) {
      _i = _src2.length;
    } else {
      _i = end + 3;
    }
  }

  void _skipWs() {
    while (_i < _src2.length && _isWs(_src2[_i])) {
      _i++;
    }
  }

  static bool _isWs(String c) => ' \t\r\n'.contains(c);

  static bool _isNameChar(String c) =>
      (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) ||
      (c.codeUnitAt(0) >= 0x41 && c.codeUnitAt(0) <= 0x5a) ||
      (c.codeUnitAt(0) >= 0x61 && c.codeUnitAt(0) <= 0x7a) ||
      c == '-' ||
      c == '_' ||
      c == ':';
}

final class _Tag {
  _Tag({required this.name, required this.attrs, required this.selfClosing});

  final String name;
  final Map<String, String> attrs;
  final bool selfClosing;
}

String _stripComments(String s) {
  final buf = StringBuffer();
  var i = 0;
  while (i < s.length) {
    if (s.startsWith('<!--', i)) {
      final end = s.indexOf('-->', i);
      if (end == -1) break;
      i = end + 3;
      continue;
    }
    buf.write(s[i]);
    i++;
  }
  return buf.toString();
}

String _stripXmlDeclaration(String s) {
  var t = s.trimLeft();
  while (t.startsWith('<?xml')) {
    final end = t.indexOf('?>');
    if (end == -1) break;
    t = t.substring(end + 2).trimLeft();
  }
  return t;
}

String _stripLeadingDoctype(String s) {
  var t = s.trimLeft();
  while (t.startsWith('<!DOCTYPE')) {
    final end = t.indexOf('>');
    if (end == -1) break;
    t = t.substring(end + 1).trimLeft();
  }
  return t;
}
