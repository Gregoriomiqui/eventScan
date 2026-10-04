import 'dart:convert';

import 'package:event_scan/core/brand/brand_config.dart';
import 'package:event_scan/core/brand/brand_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrandLoader.load', () {
    test('uses default only when no flavor was supplied', () {
      expect(brandIdForFlavor(null), 'default');
      expect(brandIdForFlavor('demo'), 'demo');
    });

    test('loads identity, theme, and entity config for the requested brand', () async {
      final loader = BrandLoader();
      final config = await loader.load(
        brandId: 'demo',
        bundle: _MemoryAssetBundle(_assetsFor('demo')),
      );

      expect(config.brand.id, 'demo');
      expect(config.brand.appName, 'Demo Check-in');
      expect(config.theme['color']['primary'], '#123456');
      expect(config.entities['attendees']['table'], 'demo_attendees');
    });

    test('reports a missing asset with its brand and path', () async {
      final loader = BrandLoader();

      await expectLater(
        loader.load(brandId: 'missing', bundle: _MemoryAssetBundle({})),
        throwsA(
          isA<BrandConfigException>()
              .having((error) => error.message, 'message', contains('missing'))
              .having((error) => error.path, 'path', contains('brand.json')),
        ),
      );
    });

    test('reports malformed JSON with the asset path', () async {
      final assets = _assetsFor('demo')..['brands/demo/theme.json'] = '{';

      await expectLater(
        BrandLoader().load(
          brandId: 'demo',
          bundle: _MemoryAssetBundle(assets),
        ),
        throwsA(
          isA<BrandConfigException>().having(
            (error) => error.path,
            'path',
            'brands/demo/theme.json',
          ),
        ),
      );
    });
  });
}

Map<String, String> _assetsFor(String brandId) => {
  'brands/$brandId/brand.json': jsonEncode({
    'id': brandId,
    'appName': 'Demo Check-in',
    'android': {'applicationId': 'cl.demo.checkin'},
    'logo': {'primary': 'assets/logo.svg'},
    'locale': 'en',
  }),
  'brands/$brandId/theme.json': jsonEncode({
    'color': {'primary': '#123456'},
  }),
  'brands/$brandId/entities.json': jsonEncode({
    'attendees': {'table': 'demo_attendees'},
    'staff': {'table': 'demo_staff'},
  }),
};

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}