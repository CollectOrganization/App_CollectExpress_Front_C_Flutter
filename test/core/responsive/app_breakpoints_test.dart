import 'package:app_collect_express_with_flutter/core/responsive/app_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBreakpoints.contentMaxWidthFor', () {
    test('preserves narrow viewport width', () {
      expect(AppBreakpoints.contentMaxWidthFor(360), 360);
      expect(AppBreakpoints.contentMaxWidthFor(390), 390);
      expect(AppBreakpoints.contentMaxWidthFor(430), 430);
      expect(AppBreakpoints.contentMaxWidthFor(599), 599);
      expect(AppBreakpoints.contentMaxWidthFor(600), 600);
    });

    test('caps tablet content at 960 pixels', () {
      expect(AppBreakpoints.contentMaxWidthFor(768), 768);
      expect(AppBreakpoints.contentMaxWidthFor(1023), 960);
    });

    test('caps desktop content at 1200 pixels', () {
      expect(AppBreakpoints.contentMaxWidthFor(1024), 1024);
      expect(AppBreakpoints.contentMaxWidthFor(1366), 1200);
      expect(AppBreakpoints.contentMaxWidthFor(1440), 1200);
      expect(AppBreakpoints.contentMaxWidthFor(1920), 1200);
      expect(AppBreakpoints.contentMaxWidthFor(2560), 1200);
    });

    test('does not exceed a caller-provided maximum', () {
      expect(AppBreakpoints.contentMaxWidthFor(1920, maxWidth: 800), 800);
    });
  });
}
