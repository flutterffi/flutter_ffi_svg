import 'package:flutter/material.dart';
import 'package:flutter_ffi_svg/flutter_ffi_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseSvgPathData builds a closed path', () {
    final p = parseSvgPathData('M0 0 L10 0 10 10 Z');
    final b = p.getBounds();
    expect(b.width, 10);
    expect(b.height, 10);
  });

  test('parseSvgString flattens a rect', () {
    const s = '<svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">'
        '<rect x="0" y="0" width="10" height="10" fill="red"/>'
        '</svg>';
    final sc = parseSvgString(s);
    expect(sc.items, isNotEmpty);
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
}
