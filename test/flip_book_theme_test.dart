import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

void main() {
  group('FlipBookTheme', () {
    test('const default constructor works with no arguments', () {
      const theme = FlipBookTheme();
      expect(theme.closeIconColor, Colors.black54);
      expect(theme.indexButtonStyle.fontWeight, FontWeight.w600);
      expect(theme.tocDividerColor, const Color(0x14000000));
    });

    test('copyWith replaces only the given fields', () {
      const original = FlipBookTheme();
      final changed = original.copyWith(closeIconColor: Colors.red);

      expect(changed.closeIconColor, Colors.red);
      expect(changed.navButtonStyle, original.navButtonStyle);
      expect(changed.tocSplashColor, original.tocSplashColor);
    });
  });
}
