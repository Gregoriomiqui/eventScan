import 'package:event_scan/core/brand/brand_config.dart';
import 'package:event_scan/core/brand/brand_scope.dart';
import 'package:event_scan/core/brand/config_error_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('provides the identical config to descendants', (tester) async {
    final config = _config();
    BrandConfig? found;

    await tester.pumpWidget(
      BrandScope(
        config: config,
        child: Builder(
          builder: (context) {
            found = BrandScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(identical(found, config), isTrue);
  });

  testWidgets('maybeOf returns null outside a brand scope', (tester) async {
    BrandConfig? found;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          found = BrandScope.maybeOf(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(found, isNull);
  });

  testWidgets('config errors render a readable startup screen', (tester) async {
    await tester.pumpWidget(
      const ConfigErrorApp(
        error: BrandConfigException(
          'Missing required appName.',
          path: 'brands/default/brand.json',
        ),
      ),
    );

    expect(find.textContaining('Missing required appName.'), findsOneWidget);
    expect(find.textContaining('brands/default/brand.json'), findsOneWidget);
  });
}

BrandConfig _config() => BrandConfig.fromJson(
  brandId: 'default',
  brand: {
    'id': 'default',
    'appName': 'Event Scan',
    'android': {'applicationId': 'com.example.event_scan'},
    'logo': {'primary': 'assets/logo.svg'},
    'locale': 'es',
  },
  theme: {'color': <String, dynamic>{}},
  entities: {
    'attendees': {'table': 'registered'},
    'staff': {'table': 'staff'},
  },
);