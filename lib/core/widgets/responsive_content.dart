import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../responsive/app_breakpoints.dart';

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        if (viewportWidth < AppBreakpoints.mobile) return child;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidthFor(
                viewportWidth,
                maxWidth: maxWidth,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}
