import 'package:flutter/widgets.dart';

class Responsive {
  const Responsive._();

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static double horizontalPadding(BuildContext context) =>
      isCompact(context) ? 16 : 24;
}
