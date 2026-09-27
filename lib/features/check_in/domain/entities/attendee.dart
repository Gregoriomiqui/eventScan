import 'package:equatable/equatable.dart';

class Attendee extends Equatable {
  const Attendee({
    required this.rut,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.distrito,
    required this.iglesia,
    required this.tallerAm,
    required this.tallerPm,
    this.checkIn,
    this.estadoPago,
  });

  final String rut;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String distrito;
  final String iglesia;
  final String tallerAm;
  final String tallerPm;
  final bool? checkIn;
  final String? estadoPago;

  String get fullName => '$nombre $apellido'.trim();
  bool get isPagoPendiente => (estadoPago ?? '').trim().toUpperCase() == 'PENDIENTE';

  @override
  List<Object?> get props => [
    rut,
    nombre,
    apellido,
    email,
    telefono,
    distrito,
    iglesia,
    tallerAm,
    tallerPm,
    checkIn,
    estadoPago,
  ];
}
