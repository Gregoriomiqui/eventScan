class BrandConfigException implements Exception {
  const BrandConfigException(this.message, {this.path});

  final String message;
  final String? path;

  @override
  String toString() {
    final location = path == null ? '' : ' ($path)';
    return 'Brand configuration error$location: $message';
  }
}

class BrandIdentity {
  const BrandIdentity({
    required this.id,
    required this.appName,
    required this.applicationId,
    required this.primaryLogo,
    required this.locale,
    required this.themeMode,
    required this.logo,
    required this.home,
  });

  final String id;
  final String appName;
  final String applicationId;
  final String primaryLogo;
  final String locale;
  final String themeMode;
  final Map<String, dynamic> logo;
  final Map<String, dynamic> home;
}

class BrandConfig {
  BrandConfig._({
    required this.brand,
    required this.theme,
    required this.entities,
  });

  final BrandIdentity brand;
  final Map<String, dynamic> theme;
  final Map<String, dynamic> entities;

  factory BrandConfig.fromJson({
    required String brandId,
    required Map<String, dynamic> brand,
    required Map<String, dynamic> theme,
    required Map<String, dynamic> entities,
  }) {
    final id = _requiredString(brand, 'id', 'brand.json');
    if (id != brandId) {
      throw BrandConfigException(
        'Brand ID "$id" does not match folder "$brandId".',
        path: 'brand.json:id',
      );
    }

    final android = _requiredObject(brand['android'], 'brand.json:android');
    final logo = _requiredObject(brand['logo'], 'brand.json:logo');
    final primaryLogo = _requiredString(
      logo,
      'primary',
      'brand.json:logo',
    );
    final locale = _requiredString(brand, 'locale', 'brand.json');
    if (locale != 'es' && locale != 'en') {
      throw BrandConfigException(
        'Unsupported locale "$locale". Supported locales are es and en.',
        path: 'brand.json:locale',
      );
    }

    final themeMode = brand['themeMode'] ?? 'light';
    if (themeMode is! String ||
        !const {'light', 'dark', 'system'}.contains(themeMode)) {
      throw BrandConfigException(
        'themeMode must be light, dark, or system.',
        path: 'brand.json:themeMode',
      );
    }

    _requiredString(android, 'applicationId', 'brand.json:android');
    _requiredObject(theme['color'], 'theme.json:color');
    if ((themeMode == 'dark' || themeMode == 'system') &&
        theme['colorDark'] is! Map<String, dynamic>) {
      throw const BrandConfigException(
        'theme.json must define colorDark when themeMode is dark or system.',
        path: 'theme.json:colorDark',
      );
    }
    _requiredTable(entities, 'attendees');
    _requiredTable(entities, 'staff');

    final frozenBrand = _freezeMap(brand, 'brand.json');
    final frozenTheme = _freezeMap(theme, 'theme.json');
    final frozenEntities = _freezeMap(entities, 'entities.json');
    final frozenLogo = frozenBrand['logo'] as Map<String, dynamic>;
    final frozenHome = frozenBrand['home'] is Map<String, dynamic>
        ? frozenBrand['home'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return BrandConfig._(
      brand: BrandIdentity(
        id: id,
        appName: _requiredString(brand, 'appName', 'brand.json'),
        applicationId: _requiredString(
          android,
          'applicationId',
          'brand.json:android',
        ),
        primaryLogo: primaryLogo,
        locale: locale,
        themeMode: themeMode,
        logo: frozenLogo,
        home: frozenHome,
      ),
      theme: frozenTheme,
      entities: frozenEntities,
    );
  }
}

String _requiredString(
  Map<String, dynamic> values,
  String key,
  String path,
) {
  final value = values[key];
  if (value is! String || value.trim().isEmpty) {
    throw BrandConfigException(
      '"$key" must be a non-empty string.',
      path: '$path:$key',
    );
  }
  return value;
}

Map<String, dynamic> _requiredObject(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw BrandConfigException('Expected a JSON object.', path: path);
  }
  return value;
}

void _requiredTable(Map<String, dynamic> entities, String module) {
  final config = _requiredObject(entities[module], 'entities.json:$module');
  _requiredString(config, 'table', 'entities.json:$module');
}

Map<String, dynamic> _freezeMap(Map<String, dynamic> value, String path) {
  return Map<String, dynamic>.unmodifiable({
    for (final entry in value.entries)
      entry.key: _freezeValue(entry.value, '$path:${entry.key}'),
  });
}

Object? _freezeValue(Object? value, String path) {
  if (value is Map) {
    final typed = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw BrandConfigException('Object keys must be strings.', path: path);
      }
      final key = entry.key as String;
      typed[key] = _freezeValue(entry.value, '$path:$key');
    }
    return Map<String, dynamic>.unmodifiable(typed);
  }
  if (value is List) {
    return List<Object?>.unmodifiable([
      for (var index = 0; index < value.length; index++)
        _freezeValue(value[index], '$path[$index]'),
    ]);
  }
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  throw BrandConfigException('Unsupported JSON value.', path: path);
}