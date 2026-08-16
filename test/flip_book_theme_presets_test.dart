import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_curl_flip/page_curl_flip.dart';

void main() {
  group('FlipBookTheme presets', () {
    test('classic is exactly the default theme', () {
      const def = FlipBookTheme();
      expect(FlipBookTheme.classic.closeIconColor, def.closeIconColor);
      expect(FlipBookTheme.classic.pageTitleStyle, def.pageTitleStyle);
      expect(FlipBookTheme.classic.tocDividerColor, def.tocDividerColor);
    });

    test('every preset pairs with its paper colour', () {
      expect(FlipBookTheme.classicPaper, Colors.white);
      expect(FlipBookTheme.oldBookPaper, const Color(0xFFF6ECD9));
      expect(FlipBookTheme.nightPaper, const Color(0xFF121212));
      expect(FlipBookTheme.magazinePaper, Colors.white);
      expect(FlipBookTheme.kidsPaper, const Color(0xFFFFFDF5));
      expect(FlipBookTheme.newspaperPaper, const Color(0xFFF4F1E8));
    });

    test('night never paints dark text on its dark paper', () {
      const t = FlipBookTheme.night;
      final inkColors = <Color>[
        t.closeIconColor,
        t.indexButtonStyle.color!,
        t.navButtonStyle.color!,
        t.navButtonIconColor,
        t.muteIconColor,
        t.tocHeadingStyle.color!,
        t.tocSearchStyle.color!,
        t.tocItemTitleStyle.color!,
        t.tocItemCurrentStyle.color!,
        t.pageTitleStyle.color!,
        t.pageTaglineStyle.color!,
      ];
      const paperLuminance = 0.006; // ~#121212
      for (final c in inkColors) {
        expect(c.computeLuminance(), greaterThan(paperLuminance * 10),
            reason: '$c is too dark for night paper');
      }
    });

    test('serif presets carry the serif fallback chain', () {
      expect(FlipBookTheme.oldBook.pageTitleStyle.fontFamilyFallback,
          contains('Georgia'));
      expect(FlipBookTheme.newspaper.pageTitleStyle.fontFamilyFallback,
          contains('Georgia'));
    });

    test('presets stay adjustable through copyWith', () {
      final adjusted =
          FlipBookTheme.magazine.copyWith(closeIconColor: Colors.teal);
      expect(adjusted.closeIconColor, Colors.teal);
      expect(adjusted.pageTitleStyle, FlipBookTheme.magazine.pageTitleStyle);
    });
  });
}
