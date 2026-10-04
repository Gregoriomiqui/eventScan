import 'package:event_scan/core/brand/brand_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrandConfig.fromJson', () {
    test('parses the identity and both required modules', () {
      final config = BrandConfig.fromJson(
        brandId: 'default',
        brand: _brandJson(),
        theme: _themeJson(),
        entities: _entitiesJson(),
      );

      expect(config.brand.id, 'default');
      expect(config.brand.appName, 'Event Scan');
      expect(config.brand.applicationId, 'com.example.event_scan');
      expect(config.brand.locale, 'es');
      expect(config.brand.themeMode, 'light');
      expect(config.entities['attendees']['table'], 'registered');
      expect(config.entities['staff']['table'], 'staff');
    });

    test('rejects an ID that differs from the requested brand folder', () {
      expect(
        () => BrandConfig.fromJson(
          brandId: 'another',
          brand: _brandJson(),
          theme: _themeJson(),
          entities: _entitiesJson(),
        ),
        throwsA(isA<BrandConfigException>()),
      );
    });

    test('rejects missing app name, application ID, logo, or locale', () {
      for (final key in ['appName', 'android', 'logo', 'locale']) {
        final brand = _brandJson()..remove(key);
        expect(
          () => BrandConfig.fromJson(
            brandId: 'default',
            brand: brand,
            theme: _themeJson(),
            entities: _entitiesJson(),
          ),
          throwsA(isA<BrandConfigException>()),
          reason: 'missing $key must be rejected',
        );
      }
    });

    test('rejects wrong field types and missing theme/module sections', () {
      final wrongType = _brandJson()..['appName'] = 42;
      expect(
        () => BrandConfig.fromJson(
          brandId: 'default',
          brand: wrongType,
          theme: _themeJson(),
          entities: _entitiesJson(),
        ),
        throwsA(isA<BrandConfigException>()),
      );

      expect(
        () => BrandConfig.fromJson(
          brandId: 'default',
          brand: _brandJson(),
          theme: <String, dynamic>{},
          entities: _entitiesJson(),
        ),
        throwsA(isA<BrandConfigException>()),
      );

      expect(
        () => BrandConfig.fromJson(
          brandId: 'default',
          brand: _brandJson(),
          theme: _themeJson(),
          entities: <String, dynamic>{'attendees': _entitiesJson()['attendees']},
        ),
        throwsA(isA<BrandConfigException>()),
      );
    });

    test('requires a dark palette for dark and system theme modes', () {
      for (final mode in ['dark', 'system']) {
        final brand = _brandJson()..['themeMode'] = mode;
        expect(
          () => BrandConfig.fromJson(
            brandId: 'default',
            brand: brand,
            theme: _themeJson(),
            entities: _entitiesJson(),
          ),
          throwsA(isA<BrandConfigException>()),
          reason: '$mode mode requires colorDark',
        );
      }
    });

    test('deeply freezes config maps and nested lists', () {
      final entities = _entitiesJson();
      final config = BrandConfig.fromJson(
        brandId: 'default',
        brand: _brandJson(),
        theme: _themeJson(),
        entities: entities,
      );

      expect(
        () => config.theme['color']['primary'] = '#000000',
        throwsUnsupportedError,
      );
      expect(
        () => config.entities['attendees']['display']['fields'].add('extra'),
        throwsUnsupportedError,
      );
    });
  });
}

Map<String, dynamic> _brandJson() => {
  'id': 'default',
  'appName': 'Event Scan',
  'android': {'applicationId': 'com.example.event_scan'},
  'logo': {'primary': 'assets/logo.svg'},
  'locale': 'es',
};

Map<String, dynamic> _themeJson() => {
  'color': {'primary': '#D91C7A'},
};

Map<String, dynamic> _entitiesJson() => {
  'attendees': {
    'table': 'registered',
    'display': {
      'fields': ['RUT'],
    },
  },
  'staff': {'table': 'staff'},
};