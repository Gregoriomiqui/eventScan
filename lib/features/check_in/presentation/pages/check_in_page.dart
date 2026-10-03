import 'package:event_scan/core/theme/app_colors.dart';
import 'package:event_scan/core/theme/responsive.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_bloc.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_event.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_state.dart';
import 'package:event_scan/features/check_in/presentation/widgets/attendee_details_card.dart';
import 'package:event_scan/features/check_in/presentation/widgets/qr_scanner_widget.dart';
import 'package:event_scan/features/check_in/presentation/widgets/status_feedback_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({
    super.key,
    this.scannerOverride,
    this.title = 'Check-in de Asistentes',
    this.showWorkshops = true,
  });

  final Widget? scannerOverride;
  final String title;
  final bool showWorkshops;

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  late final TextEditingController _uidController;

  @override
  void initState() {
    super.initState();
    _uidController = TextEditingController();
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Color _snackBackground(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return AppColors.success;
      case FeedbackType.error:
        return AppColors.error;
      case FeedbackType.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckInBloc, CheckInState>(
      listenWhen: (previous, current) =>
          previous.feedbackId != current.feedbackId,
      listener: (context, state) {
        if (state.feedbackMessage == null || state.feedbackType == null) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: _snackBackground(state.feedbackType!),
              content: Text(
                state.feedbackMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );

        context.read<CheckInBloc>().add(const FeedbackConsumed());
      },
      child: BlocBuilder<CheckInBloc, CheckInState>(
        builder: (context, state) {
          if (_uidController.text != state.uid) {
            _uidController.text = state.uid;
          }

          final horizontalPadding = Responsive.horizontalPadding(context);

          return Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final isSmall = Responsive.isSmall(context);
                final cardPadding = Responsive.cardPadding(context);
                final badgeSize = Responsive.iconBadgeSize(context);
                final sectionSpacing = isSmall ? 12.0 : 16.0;
                final theme = Theme.of(context);

                final form = _FormSection(
                  uidController: _uidController,
                  state: state,
                );
                final scanner =
                    widget.scannerOverride ??
                    QrScannerWidget(
                      enabled: !state.isBusy,
                      height: Responsive.scannerHeight(context),
                      onDetect: (value) {
                        context.read<CheckInBloc>().add(QrDetected(value));
                      },
                    );

                return SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.all(cardPadding),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: badgeSize,
                                height: badgeSize,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.badge,
                                  color: AppColors.primary,
                                  size: isSmall ? 20 : 24,
                                ),
                              ),
                              SizedBox(width: isSmall ? 8 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Escanea o pega un código',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Valida identidad y confirma el check-in de forma segura.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionSpacing),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _ScannerPanel(child: scanner)),
                              const SizedBox(width: 16),
                              Expanded(child: form),
                            ],
                          )
                        else ...[
                          _ScannerPanel(child: scanner),
                          SizedBox(height: sectionSpacing),
                          form,
                        ],
                        if (state.attendee != null) ...[
                          SizedBox(height: sectionSpacing),
                          AttendeeDetailsCard(
                            attendee: state.attendee!,
                            showWorkshops: widget.showWorkshops,
                          ),
                        ],
                        if (state.canScanNext) ...[
                          SizedBox(height: sectionSpacing),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.infoContainer,
                              foregroundColor: AppColors.info,
                            ),
                            onPressed: () {
                              context.read<CheckInBloc>().add(
                                const ResetFlowRequested(),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Escanear siguiente QR'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.uidController, required this.state});

  final TextEditingController uidController;
  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final isSmall = Responsive.isSmall(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Código de inscripción o RUT',
              style: isSmall
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: uidController,
              enabled: !state.isBusy,
              decoration: const InputDecoration(
                hintText: 'Pega o escribe el código',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<CheckInBloc>().add(UidUpdated(value));
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () {
                      context.read<CheckInBloc>().add(
                        const ValidateRequested(),
                      );
                    },
              icon: state.isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_user),
              label: const Text('Validar'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  state.isBusy ||
                      state.attendee == null ||
                      state.attendee!.checkIn == true ||
                      state.attendee!.isPagoPendiente
                  ? null
                  : () {
                      context.read<CheckInBloc>().add(
                        const ConfirmCheckInRequested(),
                      );
                    },
              child: state.isConfirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirmar Check-in'),
            ),
            if (state.feedbackMessage != null &&
                state.feedbackType != null) ...[
              const SizedBox(height: 12),
              StatusFeedbackWidget(
                message: state.feedbackMessage!,
                type: state.feedbackType!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScannerPanel extends StatelessWidget {
  const _ScannerPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }
}
