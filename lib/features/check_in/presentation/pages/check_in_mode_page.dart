import 'dart:io';

import 'package:event_scan/core/theme/app_colors.dart';
import 'package:event_scan/core/theme/responsive.dart';
import 'package:event_scan/core/error/exceptions.dart';
import 'package:event_scan/features/check_in/data/services/check_in_pdf_export_service.dart';
import 'package:event_scan/features/check_in/domain/usecases/confirm_check_in.dart';
import 'package:event_scan/features/check_in/domain/usecases/get_attendee_by_uid.dart';
import 'package:event_scan/features/check_in/presentation/pages/check_in_page.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckInModePage extends StatefulWidget {
  const CheckInModePage({
    super.key,
    required this.attendeeGetAttendeeByUid,
    required this.attendeeConfirmCheckIn,
    required this.staffGetAttendeeByUid,
    required this.staffConfirmCheckIn,
    this.exportAttendeesPdf,
    this.exportStaffPdf,
  });

  final GetAttendeeByUidUseCase attendeeGetAttendeeByUid;
  final ConfirmCheckInUseCase attendeeConfirmCheckIn;
  final GetAttendeeByUidUseCase staffGetAttendeeByUid;
  final ConfirmCheckInUseCase staffConfirmCheckIn;
  final Future<void> Function(void Function(String stage) onStageChanged)?
  exportAttendeesPdf;
  final Future<void> Function(void Function(String stage) onStageChanged)?
  exportStaffPdf;

  @override
  State<CheckInModePage> createState() => _CheckInModePageState();
}

class _CheckInModePageState extends State<CheckInModePage> {
  bool _exportingAttendees = false;
  bool _exportingStaff = false;
  String _exportStageMessage =
      'Generando y descargando el listado en PDF.\nEspera unos segundos...';

  bool get _isExportingAny => _exportingAttendees || _exportingStaff;

  Future<void> _exportPdf({
    required bool isStaff,
    required Future<void> Function(void Function(String stage) onStageChanged)?
    action,
  }) async {
    if (action == null) {
      return;
    }

    setState(() {
      _exportStageMessage = 'Preparando exportación...';
      if (isStaff) {
        _exportingStaff = true;
      } else {
        _exportingAttendees = true;
      }
    });

    try {
      await action((stage) {
        if (!mounted) {
          return;
        }
        setState(() => _exportStageMessage = stage);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF guardado y abierto.')));
    } catch (error) {
      if (!mounted) return;
      debugPrint('[PDF] Export failed at "$_exportStageMessage": $error');
      final message = switch (error) {
        ServerException(:final message) => message,
        NetworkException(:final message) => message,
        NotFoundException(:final message) => message,
        PdfOpenException(:final message) => message,
        FileSystemException(:final message) => message,
        _ => error.toString(),
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isStaff) {
            _exportingStaff = false;
          } else {
            _exportingAttendees = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final isSmall = Responsive.isSmall(context);
    final badgeSize = isSmall ? 44.0 : 54.0;
    final sectionSpacing = isSmall ? 12.0 : 16.0;
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isExportingAny,
      child: Scaffold(
        appBar: AppBar(title: const Text('Event Scan')),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: _isExportingAny,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                              Responsive.cardPadding(context) + 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: badgeSize,
                                  height: badgeSize,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.qr_code_2,
                                    color: AppColors.primary,
                                    size: isSmall ? 22 : 28,
                                  ),
                                ),
                                SizedBox(height: isSmall ? 8 : 12),
                                Text(
                                  'Control de Acceso',
                                  style: isSmall
                                      ? theme.textTheme.titleLarge
                                      : theme.textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Selecciona el flujo de check-in y gestiona tus listados PDF.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: sectionSpacing),
                          Text(
                            'Selecciona tipo de check-in',
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmall ? 14 : 20),
                          _ModeCard(
                            title: 'Asistentes',
                            description:
                                'Valida y confirma check-in de asistentes con información completa del evento.',
                            buttonLabel: 'Ingresar como Asistentes',
                            exportButtonLabel: 'Descargar listado PDF',
                            isExporting: _exportingAttendees,
                            isDisabled: _isExportingAny,
                            icon: Icons.groups,
                            onExportPressed: () => _exportPdf(
                              isStaff: false,
                              action: widget.exportAttendeesPdf,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BlocProvider(
                                    create: (_) => CheckInBloc(
                                      getAttendeeByUid:
                                          widget.attendeeGetAttendeeByUid,
                                      confirmCheckIn:
                                          widget.attendeeConfirmCheckIn,
                                    ),
                                    child: const CheckInPage(
                                      title: 'Check-in de Asistentes',
                                      showWorkshops: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _ModeCard(
                            title: 'Staff',
                            description:
                                'Valida y confirma check-in del staff por RUT o código de inscripción.',
                            buttonLabel: 'Ingresar como Staff',
                            exportButtonLabel: 'Descargar listado PDF',
                            isExporting: _exportingStaff,
                            isDisabled: _isExportingAny,
                            icon: Icons.badge,
                            onExportPressed: () => _exportPdf(
                              isStaff: true,
                              action: widget.exportStaffPdf,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BlocProvider(
                                    create: (_) => CheckInBloc(
                                      getAttendeeByUid:
                                          widget.staffGetAttendeeByUid,
                                      confirmCheckIn:
                                          widget.staffConfirmCheckIn,
                                    ),
                                    child: const CheckInPage(
                                      title: 'Check-in de Staff',
                                      showWorkshops: false,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isExportingAny) ...[
                const ModalBarrier(dismissible: false, color: Colors.black38),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: _ExportProgressContent(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportProgressContent extends StatelessWidget {
  const _ExportProgressContent();

  IconData _iconForMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('consultando')) {
      return Icons.cloud_download;
    }
    if (normalized.contains('generando')) {
      return Icons.picture_as_pdf;
    }
    if (normalized.contains('guardando')) {
      return Icons.save_alt;
    }
    if (normalized.contains('abriendo')) {
      return Icons.open_in_new;
    }
    return Icons.hourglass_top;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_CheckInModePageState>();
    final message =
        state?._exportStageMessage ??
        'Generando y descargando el listado en PDF.\nEspera unos segundos...';
    final icon = _iconForMessage(message);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.infoContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.info, size: 28),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.exportButtonLabel,
    required this.isExporting,
    required this.isDisabled,
    required this.icon,
    required this.onPressed,
    required this.onExportPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final String exportButtonLabel;
  final bool isExporting;
  final bool isDisabled;
  final IconData icon;
  final VoidCallback onPressed;
  final VoidCallback onExportPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: isDisabled ? null : onPressed,
              child: Text(buttonLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
              ),
              onPressed: isExporting || isDisabled ? null : onExportPressed,
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(isExporting ? 'Generando PDF...' : exportButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
