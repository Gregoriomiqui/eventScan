import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'brand_config.dart';

String brandIdForFlavor(String? flavor) {
  return flavor == null || flavor.isEmpty ? 'default' : flavor;
}

class BrandLoader {
  const BrandLoader();

  Future<BrandConfig> load({
    required String brandId,
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final brandPath = 'brands/$brandId/brand.json';
    final themePath = 'brands/$brandId/theme.json';
    final entitiesPath = 'brands/$brandId/entities.json';

    final brandJson = await _loadObject(assets, brandPath, brandId);
    final themeJson = await _loadObject(assets, themePath, brandId);
    final entitiesJson = await _loadObject(assets, entitiesPath, brandId);

    try {
      return BrandConfig.fromJson(
        brandId: brandId,
        brand: brandJson,
        theme: themeJson,
        entities: entitiesJson,
      );
    } on BrandConfigException catch (error) {
      throw BrandConfigException(
        error.message,
        path: 'brands/$brandId/${error.path ?? 'brand.json'}',
      );
    }
  }

  Future<Map<String, dynamic>> _loadObject(
    AssetBundle bundle,
    String path,
    String brandId,
  ) async {
    try {
      final source = await bundle.loadString(path);
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw BrandConfigException(
          'Expected a JSON object for brand "$brandId".',
          path: path,
        );
      }
      return decoded;
    } on BrandConfigException {
      rethrow;
    } on FormatException catch (error) {
      throw BrandConfigException(
        'Invalid JSON for brand "$brandId": ${error.message}',
        path: path,
      );
    } on FlutterError catch (error) {
      throw BrandConfigException(
        'Could not load config for brand "$brandId": ${error.message}',
        path: path,
      );
    }
  }
}