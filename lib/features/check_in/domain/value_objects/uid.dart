import 'package:event_scan/core/utils/uid_validator.dart';

class Uid {
  const Uid._(this.value);

  final String value;

  static bool isValid(String raw) => UidValidator.isValid(raw);

  static String normalize(String raw) => UidValidator.normalize(raw);

  static Uid? tryParse(String raw) {
    final cleaned = normalize(raw);
    if (!isValid(cleaned)) {
      return null;
    }
    return Uid._(cleaned);
  }
}
