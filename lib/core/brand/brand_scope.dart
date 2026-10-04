import 'package:flutter/widgets.dart';

import 'brand_config.dart';

class BrandScope extends InheritedWidget {
  const BrandScope({
    required this.config,
    required super.child,
    super.key,
  });

  final BrandConfig config;

  static BrandConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BrandScope>();
    assert(scope != null, 'BrandScope.of() called without a BrandScope.');
    return scope!.config;
  }

  static BrandConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BrandScope>()?.config;
  }

  @override
  bool updateShouldNotify(BrandScope oldWidget) => config != oldWidget.config;
}