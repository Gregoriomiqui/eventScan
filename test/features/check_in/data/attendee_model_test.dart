import 'package:event_scan/features/check_in/data/models/attendee_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const map = {
    'rut': '1-9',
    'nombre': 'Ana',
    'apellido': 'Diaz',
    'email': 'ana@test.com',
    'telefono': '+56911111111',
    'distrito': 'Centro',
    'iglesia': 'Luz',
    'taller_am': 'Oracion',
    'taller_pm': 'Servicio',
  };

  test('fromJson parses attendee payload', () {
    final model = AttendeeModel.fromJson(map);

    expect(model.rut, '1-9');
    expect(model.nombre, 'Ana');
    expect(model.tallerPm, 'Servicio');
  });

  test('toJson serializes attendee payload', () {
    final model = AttendeeModel.fromJson(map);

    expect(model.toJson(), map);
  });

  test('fromJson uses CODIGO_INSCRIPCION when rut is missing', () {
    const payload = {
      'CODIGO_INSCRIPCION': 'A1B2-C3D4',
      'nombre': 'Ana',
      'apellido': 'Diaz',
      'email': 'ana@test.com',
      'telefono': '+56911111111',
      'distrito': 'Centro',
      'iglesia': 'Luz',
      'taller_am': 'Oracion',
      'taller_pm': 'Servicio',
    };

    final model = AttendeeModel.fromJson(payload);

    expect(model.rut, 'A1B2-C3D4');
  });

  test('fromJson supports uppercase database keys', () {
    const payload = {
      'CODIGO_INSCRIPCION': 'A1B2-C3D4',
      'NOMBRE_APELLIDO': 'Ana Diaz',
      'APELLIDO': 'Diaz',
      'CORREO': 'ana@test.com',
      'TELEFONO': '+56911111111',
      'DISTRITO': 'Centro',
      'IGLESIA': 'Luz',
      'TALLER_AM': 'Oracion',
      'TALLER_PM': 'Servicio',
      'ESTADO_PAGO': 'PENDIENTE',
    };

    final model = AttendeeModel.fromJson(payload);

    expect(model.nombre, 'Ana Diaz');
    expect(model.apellido, 'Diaz');
    expect(model.email, 'ana@test.com');
    expect(model.tallerPm, 'Servicio');
    expect(model.estadoPago, 'PENDIENTE');
    expect(model.isPagoPendiente, isTrue);
  });
}
