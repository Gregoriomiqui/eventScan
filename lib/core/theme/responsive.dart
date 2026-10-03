import 'package:flutter/widgets.dart';

class Responsive {
  const Responsive._();

  // ~5" phones sit around 320-360 logical px wide; treat that as the floor.
  static const double smallWidthBreakpoint = 360;
  static const double smallHeightBreakpoint = 600;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isSmall(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < smallWidthBreakpoint ||
        size.height < smallHeightBreakpoint;
  }

  static double horizontalPadding(BuildContext context) {
    if (isSmall(context)) return 12;
    return isCompact(context) ? 16 : 24;
  }

  static double cardPadding(BuildContext context) {
    return isSmall(context) ? 12 : 16;
  }

  static double scannerHeight(BuildContext context) {
    if (isSmall(context)) return 160;
    return isCompact(context) ? 200 : 220;
  }

  static double iconBadgeSize(BuildContext context, {double base = 40}) {
    return isSmall(context) ? base - 8 : base;
  }
}
