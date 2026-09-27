class UidValidator {
  const UidValidator._();

  static final RegExp _uuidV4Regex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static final RegExp _rutRegex = RegExp(
    r'^\d{7,8}-[0-9K]$',
  );

  static final RegExp _uuidV4InTextRegex = RegExp(
    r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})',
  );

  static final RegExp _rutInTextRegex = RegExp(
    r'(\d{1,2}\.?\d{3}\.?\d{3}-[0-9K]|\d{7,8}-[0-9K]|\d{7,8}[0-9K])',
  );

  static String normalize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (_uuidV4Regex.hasMatch(trimmed)) {
      return trimmed;
    }

    final uuidMatch = _uuidV4InTextRegex.firstMatch(trimmed);
    if (uuidMatch != null) {
      return uuidMatch.group(1)!;
    }

    final upperInput = trimmed.toUpperCase();
    final rutMatch = _rutInTextRegex.firstMatch(upperInput);
    if (rutMatch != null) {
      final matched = rutMatch.group(1)!;
      return _normalizeRutToken(matched);
    }

    // Normalize RUT-like inputs: remove dots/spaces and uppercase verifier.
    final compact = trimmed.replaceAll('.', '').replaceAll(' ', '').toUpperCase();
    final normalizedRut = _normalizeRutToken(compact);
    if (normalizedRut != compact || _rutRegex.hasMatch(normalizedRut)) {
      return normalizedRut;
    }

    return compact;
  }

  static String _normalizeRutToken(String token) {
    final compact = token.replaceAll('.', '').replaceAll(' ', '').toUpperCase();
    if (compact.contains('-')) {
      return compact;
    }

    if (RegExp(r'^\d{7,8}[0-9K]$').hasMatch(compact)) {
      final body = compact.substring(0, compact.length - 1);
      final verifier = compact.substring(compact.length - 1);
      return '$body-$verifier';
    }

    return compact;
  }

  static bool isValid(String input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) {
      return false;
    }

    return _uuidV4Regex.hasMatch(normalized) || _rutRegex.hasMatch(normalized);
  }
}
