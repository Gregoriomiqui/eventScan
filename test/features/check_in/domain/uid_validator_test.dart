import 'package:event_scan/core/utils/uid_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UidValidator', () {
    test('returns true for valid UUID v4', () {
      const uid = '550e8400-e29b-41d4-a716-446655440000';

      final result = UidValidator.isValid(uid);

      expect(result, isTrue);
    });

    test('returns false for malformed UID', () {
      const uid = 'not-a-uid';

      final result = UidValidator.isValid(uid);

      expect(result, isFalse);
    });

    test('returns true for valid RUT', () {
      const uid = '10467097-0';

      final result = UidValidator.isValid(uid);

      expect(result, isTrue);
    });

    test('returns true for valid RUT with dots and lowercase verifier', () {
      const uid = '10.467.097-k';

      final result = UidValidator.isValid(uid);

      expect(result, isTrue);
    });

    test('normalizes RUT with dots to canonical format', () {
      const uid = '10.467.097-k';

      final normalized = UidValidator.normalize(uid);

      expect(normalized, '10467097-K');
    });

    test('normalizes RUT without dash to canonical format', () {
      const uid = '104670970';

      final normalized = UidValidator.normalize(uid);

      expect(normalized, '10467097-0');
    });

    test('extracts RUT from noisy text payload', () {
      const uid = 'RUT: 10.467.097-0 | NOMBRE: Erica';

      final normalized = UidValidator.normalize(uid);

      expect(normalized, '10467097-0');
      expect(UidValidator.isValid(uid), isTrue);
    });

    test('extracts UUID from noisy text payload', () {
      const uid =
          'id=550e8400-e29b-41d4-a716-446655440000;source=qr';

      final normalized = UidValidator.normalize(uid);

      expect(normalized, '550e8400-e29b-41d4-a716-446655440000');
      expect(UidValidator.isValid(uid), isTrue);
    });

    test('returns false for empty UID', () {
      final result = UidValidator.isValid('   ');

      expect(result, isFalse);
    });
  });
}
