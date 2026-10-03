import 'package:event_scan/features/check_in/data/services/check_in_pdf_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps minimum PDF page limit for small lists', () {
    expect(CheckInPdfExportService.maxPagesForRowCount(10), 50);
  });

  test('scales PDF page limit with large table row count', () {
    expect(CheckInPdfExportService.maxPagesForRowCount(1000), 1010);
  });

  test('omits shared columns and attendee workshop IDs for attendee PDF', () {
    final columns = CheckInPdfExportService.columnsForRows(
      _sampleRow,
      additionalExcludedColumns: const {'ID_TALLER_AM', 'ID_TALLER_PM'},
    );

    expect(columns, ['RUT', 'NOMBRE_APELLIDO', 'CORREO']);
  });

  test('omits shared columns but keeps workshop IDs for staff PDF', () {
    final columns = CheckInPdfExportService.columnsForRows(_sampleRow);

    expect(
      columns,
      ['RUT', 'NOMBRE_APELLIDO', 'CORREO', 'ID_TALLER_AM', 'ID_TALLER_PM'],
    );
  });
}

const _sampleRow = [
  {
    'ID_REGISTRO': '1',
    'CODIGO_INSCRIPCIÓN': 'code',
    'URL_CODIGO_QR': 'url',
    'ESTADO_PAGO': 'PAGADO',
    'CONTACTO_PRINCIPAL': 'contact',
    'ID_TRANSACCION_BANCARIA': 'transaction',
    'FECHA_ACTUALIZACION': '2026-09-27',
    'FECHA_INSCRIPCION': '2026-09-20',
    'RUT': '10467097-0',
    'NOMBRE_APELLIDO': 'Ana Diaz',
    'CORREO': 'ana@example.com',
    'ID_TALLER_AM': '11',
    'ID_TALLER_PM': '22',
  },
];
