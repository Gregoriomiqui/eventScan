import 'package:event_scan/core/error/failures.dart';
import 'package:event_scan/core/error/result.dart';
import 'package:event_scan/features/check_in/domain/repositories/check_in_repository.dart';
import 'package:event_scan/features/check_in/domain/usecases/confirm_check_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCheckInRepository extends Mock implements CheckInRepository {}

void main() {
  late _MockCheckInRepository repository;
  late ConfirmCheckInUseCase useCase;

  setUp(() {
    repository = _MockCheckInRepository();
    useCase = ConfirmCheckInUseCase(repository);
  });

  test('returns validation failure for invalid UID', () async {
    final result = await useCase(
      uid: 'invalid',
      checkedInAt: DateTime(2026),
    );

    expect(result, isA<Error<void>>());
    expect((result as Error<void>).failure, isA<ValidationFailure>());
    verifyNever(() => repository.confirmCheckIn(uid: any(named: 'uid'), checkedInAt: any(named: 'checkedInAt')));
  });

  test('calls repository when UID is valid', () async {
    const uid = '550e8400-e29b-41d4-a716-446655440000';
    final time = DateTime(2026, 1, 1, 12, 0);
    when(() => repository.confirmCheckIn(uid: uid, checkedInAt: time)).thenAnswer(
      (_) async => const Success<void>(null),
    );

    final result = await useCase(uid: uid, checkedInAt: time);

    expect(result, isA<Success<void>>());
    verify(() => repository.confirmCheckIn(uid: uid, checkedInAt: time)).called(1);
  });
}
