import 'package:flutter/material.dart';
import 'package:flutter_ffi_svg/flutter_ffi_svg.dart';

void main() {
  runApp(const _App());
}

final class _App extends StatelessWidget {
  const _App();

  static const _samples = <String>[
    _iconCube,
    _shapes,
    _transforms,
    _arcs,
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_ffi_svg example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3F51B5),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_ffi_svg')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _samples.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final svg = _samples[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: FfiSvg.string(svg, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        svg.trim(),
                        maxLines: 12,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

const _iconCube = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#2196F3" d="M12 2 L22 8 L22 16 L12 22 L2 16 L2 8 Z"/>
</svg>
''';

const _shapes = '''
<svg viewBox="0 0 100 60" xmlns="http://www.w3.org/2000/svg">
  <rect x="5" y="5" width="40" height="40" rx="6" fill="#4CAF50" opacity="0.9"/>
  <circle cx="70" cy="25" r="18" fill="#FF9800" fill-opacity="0.8"/>
  <ellipse cx="70" cy="45" rx="22" ry="10" fill="none" stroke="#9C27B0" stroke-width="3"/>
</svg>
''';

const _transforms = '''
<svg viewBox="0 0 100 60" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(15,10) rotate(20 20 20) scale(1.1)">
    <rect x="0" y="0" width="40" height="40" fill="#03A9F4"/>
    <path d="M0 40 L40 0" stroke="#FFFFFF" stroke-width="3"/>
  </g>
</svg>
''';

const _arcs = '''
<svg viewBox="0 0 120 60" xmlns="http://www.w3.org/2000/svg">
  <path d="M10 30 A 20 20 0 0 1 50 30" fill="none" stroke="#F44336" stroke-width="4"/>
  <path d="M60 30 A 20 10 30 1 1 110 30" fill="none" stroke="#607D8B" stroke-width="4"/>
</svg>
''';

