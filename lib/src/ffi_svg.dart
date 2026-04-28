import 'package:flutter/widgets.dart';

import 'svg_model.dart';
import 'svg_painter.dart';

/// Displays vector graphics from inline SVG/XML [source].
///
/// Parsing and drawing are implemented in Dart only (no third-party runtime deps).
/// Supported subset includes `svg`, `g`, `path`, `rect`, `circle`, `ellipse`,
/// transforms, fills, strokes, opacity, `viewBox`, and width/height hints.
final class FfiSvg extends StatelessWidget {
  /// Creates a widget that renders an SVG from an asset in the current bundle.
  ///
  /// This is a convenience API that loads the asset text and then delegates to
  /// [FfiSvg.string]. During loading (and on errors), it shows an empty
  /// [SizedBox] using the provided [width]/[height] (if any).
  ///
  /// If you need a custom bundle, pass [bundle]. If the asset is in a package,
  /// pass [package] (equivalent to `packages/<package>/<assetName>`).
  static Widget asset(
    BuildContext context,
    String assetName, {
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    Clip clipBehavior = Clip.hardEdge,
    Color? color,
    Object? cacheKey,
    AssetBundle? bundle,
    String? package,
  }) {
    final resolved =
        package == null ? assetName : 'packages/$package/$assetName';
    final b = bundle ?? DefaultAssetBundle.of(context);
    return _FfiSvgAsset(
      key: key,
      bundle: b,
      assetKey: resolved,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      clipBehavior: clipBehavior,
      color: color,
      cacheKey: cacheKey ?? resolved,
    );
  }

  /// Creates a widget that renders SVG from an inline string.
  ///
  /// If parsing fails, this widget falls back to an empty [SizedBox] using the
  /// provided [width]/[height] (if any).
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
    this.cacheKey,
  });

  /// Raw SVG/XML text.
  final String source;

  /// Optional outer width (uses constraints / intrinsic size when null).
  final double? width;

  /// Optional outer height (uses constraints / intrinsic size when null).
  final double? height;

  /// How to scale the intrinsic graphic inside the layout bounds.
  final BoxFit fit;

  /// Alignment used by the internal [FittedBox] when applying [fit].
  final AlignmentGeometry alignment;

  /// Clipping applied around the scaled content.
  final Clip clipBehavior;

  /// Default fill color when the SVG omits explicit paint (`currentColor`).
  final Color? color;

  /// Optional cache key for reusing parsed results across rebuilds.
  ///
  /// When null, parsing is performed on every build. When set, parsed scenes are
  /// cached in-memory with a small, best-effort LRU policy.
  final Object? cacheKey;

  @override
  Widget build(BuildContext context) {
    final SvgScene scene;
    try {
      scene = _SvgSceneCache.getOrParse(
        cacheKey: cacheKey,
        source: source,
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

final class _FfiSvgAsset extends StatefulWidget {
  const _FfiSvgAsset({
    super.key,
    required this.bundle,
    required this.assetKey,
    required this.width,
    required this.height,
    required this.fit,
    required this.alignment,
    required this.clipBehavior,
    required this.color,
    required this.cacheKey,
  });

  final AssetBundle bundle;
  final String assetKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Clip clipBehavior;
  final Color? color;
  final Object? cacheKey;

  @override
  State<_FfiSvgAsset> createState() => _FfiSvgAssetState();
}

final class _FfiSvgAssetState extends State<_FfiSvgAsset> {
  late Future<String> _load;

  @override
  void initState() {
    super.initState();
    _load = widget.bundle.loadString(widget.assetKey);
  }

  @override
  void didUpdateWidget(covariant _FfiSvgAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetKey != widget.assetKey ||
        oldWidget.bundle != widget.bundle) {
      _load = widget.bundle.loadString(widget.assetKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _load,
      builder: (context, snap) {
        final s = snap.data;
        if (s == null) {
          return SizedBox(width: widget.width, height: widget.height);
        }
        return FfiSvg.string(
          s,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          clipBehavior: widget.clipBehavior,
          color: widget.color,
          cacheKey: widget.cacheKey,
        );
      },
    );
  }
}

final class _SvgSceneCache {
  static const int _maxEntries = 64;

  static final Map<Object, SvgScene> _cache = <Object, SvgScene>{};
  static final List<Object> _lru = <Object>[];

  static SvgScene getOrParse({
    required Object? cacheKey,
    required String source,
    required Color defaultColor,
  }) {
    if (cacheKey == null) {
      return parseSvgString(source, defaultColor: defaultColor);
    }

    final hit = _cache[cacheKey];
    if (hit != null) {
      _touch(cacheKey);
      return hit;
    }

    final scene = parseSvgString(source, defaultColor: defaultColor);
    _cache[cacheKey] = scene;
    _touch(cacheKey);
    _evictIfNeeded();
    return scene;
  }

  static void _touch(Object key) {
    _lru.remove(key);
    _lru.add(key);
  }

  static void _evictIfNeeded() {
    while (_lru.length > _maxEntries) {
      final oldest = _lru.removeAt(0);
      _cache.remove(oldest);
    }
  }
}
