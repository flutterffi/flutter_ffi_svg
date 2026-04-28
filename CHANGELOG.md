## 1.0.2

- Align README/metadata for pub.dev and bump version.
- Add `FfiSvg.asset(BuildContext, ...)` convenience API for loading SVG from assets.

## 1.0.1

- Add runnable `example/` app.
- Improve public API dartdoc coverage.
- Add optional in-memory scene cache (`cacheKey`) for `FfiSvg.string`.
- Formatting and analysis cleanups to reach pana 160/160.

## 1.0.0

- Initial stable release: pure Dart SVG subset (`path` `d`, basic shapes, `g`, common `transform`), painted with `CustomPainter`.
- Public API: `FfiSvg.string`, `parseSvgString`, `parseSvgPathData`, `SvgScenePainter`.

## 0.0.1

- Placeholder pre-release.
