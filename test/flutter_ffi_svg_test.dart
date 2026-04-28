import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_ffi_svg/flutter_ffi_svg.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final v = _assets[key];
    if (v == null) {
      throw FlutterError('Missing asset: $key');
    }
    final bytes = utf8.encode(v);
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final v = _assets[key];
    if (v == null) {
      throw FlutterError('Missing asset: $key');
    }
    return v;
  }
}

void main() {
  test('parseSvgPathData builds a closed path', () {
    final p = parseSvgPathData('M0 0 L10 0 10 10 Z');
    final b = p.getBounds();
    expect(b.width, 10);
    expect(b.height, 10);
  });

  test('parseSvgPathData supports relative commands (m/l/z)', () {
    final p = parseSvgPathData('m 1 1 l 9 0 l 0 9 z');
    final b = p.getBounds();
    expect(b.left, 1);
    expect(b.top, 1);
    expect(b.width, 9);
    expect(b.height, 9);
  });

  test('parseSvgPathData supports H/V', () {
    final p = parseSvgPathData('M0 0 H10 V10 H0 Z');
    final b = p.getBounds();
    expect(b.width, 10);
    expect(b.height, 10);
  });

  test('parseSvgPathData supports quadratic and smooth quadratic (Q/T)', () {
    final p = parseSvgPathData('M0 0 Q 10 0 10 10 T 20 20');
    final b = p.getBounds();
    expect(b.right, greaterThan(0));
    expect(b.bottom, greaterThan(0));
  });

  test('parseSvgPathData supports cubic and smooth cubic (C/S)', () {
    final p = parseSvgPathData('M0 0 C 10 0 10 10 20 10 S 30 20 40 0');
    final b = p.getBounds();
    expect(b.right, greaterThan(0));
    expect(b.bottom, greaterThan(0));
  });

  test('parseSvgPathData supports elliptical arc (A)', () {
    final p = parseSvgPathData('M0 0 A 10 10 0 0 1 20 0');
    final b = p.getBounds();
    expect(b.right, greaterThan(0));
  });

  test('parseSvgString flattens a rect', () {
    const s = '<svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">'
        '<rect x="0" y="0" width="10" height="10" fill="red"/>'
        '</svg>';
    final sc = parseSvgString(s);
    expect(sc.items, isNotEmpty);
  });

  test('parseSvgString applies transform on group', () {
    const s = '<svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">'
        '<g transform="translate(2,3) scale(2) rotate(90 1 1)">'
        '<rect x="0" y="0" width="1" height="1" fill="red"/>'
        '</g>'
        '</svg>';
    final sc = parseSvgString(s);
    expect(sc.items, isNotEmpty);
    final b = sc.items.first.path.getBounds();
    // Just sanity-check that something was transformed and has area.
    expect(b.width, greaterThan(0));
    expect(b.height, greaterThan(0));
  });

  testWidgets('FfiSvg.string pumps', (tester) async {
    const s = '<svg viewBox="0 0 2 2">'
        '<rect width="2" height="2" fill="#0000ff"/>'
        '</svg>';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FfiSvg.string(s, width: 20, height: 20),
        ),
      ),
    );
  });

  testWidgets('FfiSvg.asset loads from bundle and pumps', (tester) async {
    const svg = '<svg viewBox="0 0 2 2">'
        '<rect width="2" height="2" fill="#ff0000"/>'
        '</svg>';
    final bundle = _TestAssetBundle({'assets/a.svg': svg});

    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: bundle,
          child: Scaffold(
            body: Builder(
              builder: (context) =>
                  FfiSvg.asset(context, 'assets/a.svg', width: 20, height: 20),
            ),
          ),
        ),
      ),
    );

    // Let the FutureBuilder complete.
    await tester.pump();
  });
}
