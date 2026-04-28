# flutter_ffi_svg

Pure Dart SVG rendering for Flutter: parse a practical subset of SVG/XML and draw with `CustomPainter`. **No third-party SVG or XML packages**—only the Flutter SDK.

Published by [flutterffi](https://pub.dev/publishers/flutterffi) on [pub.dev](https://pub.dev/packages/flutter_ffi_svg).

## Features

- **Inline SVG strings** via `FfiSvg.string` (layout, `BoxFit`, optional size).
- **Path data** via `parseSvgPathData` for SVG `d` attributes (`M L H V C S Q T A Z`, relative/absolute).
- **Document parsing** via `parseSvgString` into flat drawables (`SvgScene`, `SvgItem`).
- **Elements**: `svg`, `g`, `path`, `rect`, `circle`, `ellipse`; `viewBox` and basic `width`/`height`; `fill`, `stroke`, opacity; `fill-rule`; **`transform`**: `matrix`, `translate`, `scale`, `rotate`.

## Installation

```yaml
dependencies:
  flutter_ffi_svg: ^1.0.0
```

Run `flutter pub get`.

## Usage

Minimal example:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_ffi_svg/flutter_ffi_svg.dart';

class Demo extends StatelessWidget {
  const Demo({super.key});

  static const _svg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#2196F3" d="M12 2 L22 8 L22 16 L12 22 L2 16 L2 8 Z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FfiSvg.string(
          _svg,
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
```

Run the full example app in `example/`:

```bash
cd example
flutter pub get
flutter run
```

Parse only (no widget):

```dart
import 'package:flutter_ffi_svg/flutter_ffi_svg.dart';

void main() {
  final scene = parseSvgString(svgXml);
  final path = parseSvgPathData('M0 0 L10 10');
}
```

## Limitations

This package targets **icons and simple graphics**, not full SVG 1.1 or every editor export.

Unsupported or partial (non-exhaustive): `<text>`, `<image>`, `<defs>` / `<use>`, gradients, patterns, filters, masks, clip-path, complex CSS, external fonts, full unit system, and some path edge cases. For those, consider a different approach or pre-process assets.

## API overview

| Symbol | Role |
|--------|------|
| `FfiSvg.string` | `StatelessWidget` that paints inline SVG. |
| `parseSvgString` | Build an `SvgScene` from XML. |
| `parseSvgPathData` | Build a `dart:ui` `Path` from a `d` string. |
| `SvgScenePainter` | `CustomPainter` for a pre-parsed `SvgScene`. |

## License

Apache License 2.0 — see [LICENSE](LICENSE).

## Links

- **Repository**: <https://github.com/flutterffi/flutter_ffi_svg>
- **Issue tracker**: <https://github.com/flutterffi/flutter_ffi_svg/issues>
