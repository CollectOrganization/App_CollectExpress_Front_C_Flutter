abstract final class AppBreakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;
  static const desktop = 1440.0;

  static const tabletContentMaxWidth = 960.0;
  static const desktopContentMaxWidth = 1200.0;
  static const largeDesktopContentMaxWidth = 1200.0;

  static double contentMaxWidthFor(
    double viewportWidth, {
    double maxWidth = desktopContentMaxWidth,
  }) {
    final categoryMaxWidth = switch (viewportWidth) {
      < mobile => viewportWidth,
      < tablet => tabletContentMaxWidth,
      < desktop => desktopContentMaxWidth,
      _ => largeDesktopContentMaxWidth,
    };
    final effectiveMaxWidth = maxWidth < categoryMaxWidth
        ? maxWidth
        : categoryMaxWidth;
    return viewportWidth < effectiveMaxWidth
        ? viewportWidth
        : effectiveMaxWidth;
  }
}
