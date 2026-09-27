import 'package:event_scan/features/check_in/domain/entities/attendee.dart';

class AttendeeModel extends Attendee {
  const AttendeeModel({
    required super.rut,
    required super.nombre,
    required super.apellido,
    required super.email,
    required super.telefono,
    required super.distrito,
    required super.iglesia,
    required super.tallerAm,
    required super.tallerPm,
    super.checkIn,
    super.estadoPago,
  });

  factory AttendeeModel.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key].toString();
        }
      }

      return '';
    }

    bool? readBool(List<String> keys) {
      for (final key in keys) {
        if (!json.containsKey(key) || json[key] == null) {
          continue;
        }

        final value = json[key];
        if (value is bool) {
          return value;
        }
        if (value is num) {
          return value != 0;
        }

        final normalized = value.toString().trim().toLowerCase();
        if (normalized == 'true' || normalized == 't' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == 'f' || normalized == '0') {
          return false;
        }
      }

      return null;
    }

    final fallbackRut = readString(['CODIGO_INSCRIPCION', 'codigo_inscripcion']);
    final fullName = readString([
      'NOMBRE_APELLIDO',
      'nombre_apellido',
    ]);
    final nombre =
        readString(['nombre', 'NOMBRE']).isNotEmpty
            ? readString(['nombre', 'NOMBRE'])
            : fullName;

    return AttendeeModel(
      rut: readString(['rut', 'RUT']).isNotEmpty
          ? readString(['rut', 'RUT'])
          : fallbackRut,
      nombre: nombre,
      apellido: readString(['apellido', 'APELLIDO']),
      email: readString(['email', 'EMAIL', 'correo', 'CORREO']),
      telefono: readString(['telefono', 'TELEFONO', 'TEL', 'TELEFONO_CONTACTO']),
      distrito: readString(['distrito', 'DISTRITO']),
      iglesia: readString(['iglesia', 'IGLESIA']),
      tallerAm: readString(['taller_am', 'TALLER_AM']),
      tallerPm: readString(['taller_pm', 'TALLER_PM']),
      checkIn: readBool(['CHECK_IN', 'check_in']),
      estadoPago: readString(['ESTADO_PAGO', 'estado_pago']),
    );
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'rut': rut,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'distrito': distrito,
      'iglesia': iglesia,
      'taller_am': tallerAm,
      'taller_pm': tallerPm,
    };

    final normalizedEstadoPago = estadoPago?.trim();
    if (normalizedEstadoPago != null && normalizedEstadoPago.isNotEmpty) {
      payload['estado_pago'] = normalizedEstadoPago;
    }

    return payload;
  }
}
