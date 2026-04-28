import 'dart:math' as math;
import 'dart:ui' show Path, PathFillType;

/// Parses SVG path data (`d` attribute) into a [Path].
///
/// Supports: [Mm Ll Hh Vv Cc Ss Qq Tt Aa Zz].
class SvgPathDataParser {
  SvgPathDataParser(this._src);

  final String _src;
  int _i = 0;

  Path parse() {
    final path = Path();
    double? cx;
    double? cy;
    double? px0;
    double? py0;
    double? qx0;
    double? qy0;
    double? subx;
    double? suby;
    String? prev;
    String? active;

    while (true) {
      _skipWs();
      if (_i >= _src.length) break;
      if (_peekCmd()) {
        active = _readCmdChar();
      } else if (active == null) {
        throw FormatException('Expected path command at $_i');
      }
      final cmd = active;
      final u = cmd.toUpperCase();
      final abs = cmd == u;

      switch (u) {
        case 'M':
          var first = true;
          while (true) {
            final nx = _readNum();
            final ny = _readNum();
            if (abs) {
              cx = nx;
              cy = ny;
            } else {
              cx = (cx ?? 0) + nx;
              cy = (cy ?? 0) + ny;
            }
            if (first) {
              path.moveTo(cx, cy);
              subx = cx;
              suby = cy;
              first = false;
              prev = 'M';
            } else {
              path.lineTo(cx, cy);
              prev = 'L';
            }
            _skipWs();
            if (!_peekNum()) break;
          }
          active = abs ? 'L' : 'l';
          break;

        case 'L':
          while (true) {
            final nx = _readNum();
            final ny = _readNum();
            if (abs) {
              cx = nx;
              cy = ny;
            } else {
              cx = (cx ?? 0) + nx;
              cy = (cy ?? 0) + ny;
            }
            path.lineTo(cx, cy);
            prev = 'L';
            _skipWs();
            if (!_peekNum()) break;
          }
          break;

        case 'H':
          while (true) {
            final nx = _readNum();
            cx = abs ? nx : (cx ?? 0) + nx;
            path.lineTo(cx, cy ?? 0);
            prev = 'H';
            _skipWs();
            if (!_peekNum()) break;
          }
          break;

        case 'V':
          while (true) {
            final ny = _readNum();
            cy = abs ? ny : (cy ?? 0) + ny;
            path.lineTo(cx ?? 0, cy);
            prev = 'V';
            _skipWs();
            if (!_peekNum()) break;
          }
          break;

        case 'C':
          while (true) {
            final x1 = _readNum();
            final y1 = _readNum();
            final x2 = _readNum();
            final y2 = _readNum();
            final x = _readNum();
            final y = _readNum();
            late double ax1;
            late double ay1;
            late double ax2;
            late double ay2;
            late double ax;
            late double ay;
            if (abs) {
              ax1 = x1;
              ay1 = y1;
              ax2 = x2;
              ay2 = y2;
              ax = x;
              ay = y;
            } else {
              final ox = cx ?? 0;
              final oy = cy ?? 0;
              ax1 = ox + x1;
              ay1 = oy + y1;
              ax2 = ox + x2;
              ay2 = oy + y2;
              ax = ox + x;
              ay = oy + y;
            }
            path.cubicTo(ax1, ay1, ax2, ay2, ax, ay);
            px0 = ax2;
            py0 = ay2;
            qx0 = qy0 = null;
            cx = ax;
            cy = ay;
            prev = 'C';
            _skipWs();
            if (!_peekNum()) break;
          }
          break;

        case 'S':
          while (true) {
            final x2 = _readNum();
            final y2 = _readNum();
            final x = _readNum();
            final y = _readNum();
            double ax1;
            double ay1;
            if (prev == 'C' || prev == 'c' || prev == 'S' || prev == 's') {
              ax1 = 2 * (cx ?? 0) - (px0 ?? cx ?? 0);
              ay1 = 2 * (cy ?? 0) - (py0 ?? cy ?? 0);
            } else {
              ax1 = cx ?? 0;
              ay1 = cy ?? 0;
            }
            late double ax2;
            late double ay2;
            late double ax;
            late double ay;
            if (abs) {
              ax2 = x2;
              ay2 = y2;
              ax = x;
              ay = y;
            } else {
              final ox = cx ?? 0;
              final oy = cy ?? 0;
              ax2 = ox + x2;
              ay2 = oy + y2;
              ax = ox + x;
              ay = oy + y;
            }
            path.cubicTo(ax1, ay1, ax2, ay2, ax, ay);
            px0 = ax2;
            py0 = ay2;
            cx = ax;
            cy = ay;
            prev = 'S';
            _skipWs();
            if (!_peekNum()) break;
          }
          break;

        case 'Q':
          while (true) {
            final x1 = _readNum();
            final y1 = _readNum();
            final x = _readNum();
            final y = _readNum();
            late double ax1;
            late double ay1;
            late double ax;
            late double ay;
            if (abs) {
              ax1 = x1;
              ay1 = y1;
              ax = x;
              ay = y;
            } else {
              final ox = cx ?? 0;
              final oy = cy ?? 0;
              ax1 = ox + x1;
              ay1 = oy + y1;
              ax = ox + x;
              ay = oy + y;
            }
            path.quadraticBezierTo(ax1, ay1, ax, ay);
            qx0 = ax1;
            qy0 = ay1;
            px0 = py0 = null;
            cx = ax;
            cy = ay;
            prev = 'Q';
            _skipWs();
            if (!_peekNum()) break;
          }
          break;

        case 'T':
          while (true) {
            final x = _readNum();
            final y = _readNum();
            double ax1;
            double ay1;
            if (prev == 'Q' || prev == 'q' || prev == 'T' || prev == 't') {
              ax1 = 2 * (cx ?? 0) - (qx0 ?? cx ?? 0);
              ay1 = 2 * (cy ?? 0) - (qy0 ?? cy ?? 0);
            } else {
              ax1 = cx ?? 0;
              ay1 = cy ?? 0;
            }
            late double ax;
            late double ay;
            if (abs) {
              ax = x;
              ay = y;
            } else {
              ax = (cx ?? 0) + x;
              ay = (cy ?? 0) + y;
            }
            path.quadraticBezierTo(ax1, ay1, ax, ay);
            qx0 = ax1;
            qy0 = ay1;
            cx = ax;
            cy = ay;
            prev = 'T';
            _skipWs();
            if (!_peekNum()) break;
          }
          break;

        case 'A':
          while (true) {
            final rx = _readNum().abs();
            final ry = _readNum().abs();
            final rot = _readNum();
            final large = _readNum() != 0;
            final sweep = _readNum() != 0;
            final x = _readNum();
            final y = _readNum();
            final x1 = cx ?? 0;
            final y1 = cy ?? 0;
            final x2 = abs ? x : x1 + x;
            final y2 = abs ? y : y1 + y;
            _arcTo(path, rx, ry, rot, large, sweep, x1, y1, x2, y2);
            cx = x2;
            cy = y2;
            px0 = py0 = qx0 = qy0 = null;
            prev = 'A';
            _skipWs();
            if (!_peekNum()) break;
          }
          break;

        case 'Z':
          path.close();
          cx = subx;
          cy = suby;
          px0 = py0 = qx0 = qy0 = null;
          prev = 'Z';
          active = null;
          break;

        default:
          throw FormatException('Bad path command: $cmd');
      }
    }

    return path;
  }

  static void _arcTo(
    Path path,
    double rx,
    double ry,
    double phiDeg,
    bool largeArc,
    bool sweep,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    if (rx == 0 || ry == 0) {
      path.lineTo(x2, y2);
      return;
    }

    rx = rx.abs();
    ry = ry.abs();
    final phi = phiDeg * math.pi / 180;
    final cosPhi = math.cos(phi);
    final sinPhi = math.sin(phi);

    final dx = (x1 - x2) / 2;
    final dy = (y1 - y2) / 2;
    final xd = cosPhi * dx + sinPhi * dy;
    final yd = -sinPhi * dx + cosPhi * dy;

    var rx2 = rx * rx;
    var ry2 = ry * ry;
    final xd2 = xd * xd;
    final yd2 = yd * yd;
    var check = xd2 / rx2 + yd2 / ry2;
    if (check > 1) {
      rx *= math.sqrt(check);
      ry *= math.sqrt(check);
      rx2 = rx * rx;
      ry2 = ry * ry;
    }

    final root = math.max(
      0.0,
      (rx2 * ry2 - rx2 * yd2 - ry2 * xd2) / (rx2 * yd2 + ry2 * xd2),
    );
    final c = (largeArc == sweep ? -1.0 : 1.0) * math.sqrt(root);
    final cxd = c * rx * yd / ry;
    final cyd = -c * ry * xd / rx;

    final cx = cosPhi * cxd - sinPhi * cyd + (x1 + x2) / 2;
    final cy = sinPhi * cxd + cosPhi * cyd + (y1 + y2) / 2;

    double angleBetween(double ux, double uy, double vx, double vy) {
      final dot = ux * vx + uy * vy;
      final len = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
      var a = len == 0 ? 0.0 : dot / len;
      if (a > 1) a = 1;
      if (a < -1) a = -1;
      var ang = math.acos(a);
      if (ux * vy - uy * vx < 0) ang = -ang;
      return ang;
    }

    final ux = (xd - cxd) / rx;
    final uy = (yd - cyd) / ry;
    final vx = (-xd - cxd) / rx;
    final vy = (-yd - cyd) / ry;
    final theta1 = angleBetween(1, 0, ux, uy);
    var delta = angleBetween(ux, uy, vx, vy);
    if (!sweep && delta > 0) {
      delta -= 2 * math.pi;
    } else if (sweep && delta < 0) {
      delta += 2 * math.pi;
    }

    const segments = 32;
    for (var s = 1; s <= segments; s++) {
      final t = theta1 + delta * s / segments;
      final ox = cx + rx * math.cos(t) * cosPhi - ry * math.sin(t) * sinPhi;
      final oy = cy + rx * math.sin(t) * cosPhi + ry * math.cos(t) * sinPhi;
      path.lineTo(ox, oy);
    }
  }

  static bool _isCmd(String c) => 'MmLlHhVvCcSsQqTtAaZz'.contains(c);

  bool _peekCmd() {
    _skipWs();
    return _i < _src.length && _isCmd(_src[_i]);
  }

  String _readCmdChar() {
    _skipWs();
    if (_i >= _src.length) throw FormatException('Unexpected end of path');
    final c = _src[_i];
    if (!_isCmd(c)) throw FormatException('Expected command at $_i');
    _i++;
    return c;
  }

  void _skipWs() {
    while (_i < _src.length && ' ,\t\r\n'.contains(_src[_i])) {
      _i++;
    }
  }

  bool _peekNum() {
    if (_i >= _src.length) return false;
    final cu = _src.codeUnitAt(_i);
    return (cu >= 0x30 && cu <= 0x39) || _src[_i] == '.' || _src[_i] == '-' || _src[_i] == '+';
  }

  double _readNum() {
    _skipWs();
    final start = _i;
    if (_i < _src.length && (_src[_i] == '-' || _src[_i] == '+')) _i++;
    while (_i < _src.length) {
      final c = _src[_i];
      final cu = _src.codeUnitAt(_i);
      if ((cu >= 0x30 && cu <= 0x39) || c == '.') {
        _i++;
        continue;
      }
      if (c == 'e' || c == 'E') {
        _i++;
        if (_i < _src.length && (_src[_i] == '-' || _src[_i] == '+')) {
          _i++;
        }
        while (_i < _src.length) {
          final d = _src.codeUnitAt(_i);
          if (d < 0x30 || d > 0x39) break;
          _i++;
        }
        break;
      }
      break;
    }
    if (start == _i) throw FormatException('Number expected at $start');
    return double.parse(_src.substring(start, _i));
  }
}

/// Parses SVG path data; optional [fillType] for fill-rule.
Path parseSvgPathData(String d, {PathFillType? fillType}) {
  final p = SvgPathDataParser(d.trim()).parse();
  if (fillType != null) {
    p.fillType = fillType;
  }
  return p;
}
