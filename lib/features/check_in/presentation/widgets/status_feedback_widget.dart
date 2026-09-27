import 'package:event_scan/core/theme/app_colors.dart';
import 'package:event_scan/features/check_in/presentation/state/check_in_state.dart';
import 'package:flutter/material.dart';

class StatusFeedbackWidget extends StatelessWidget {
  const StatusFeedbackWidget({
    super.key,
    required this.message,
    required this.type,
  });

  final String message;
  final FeedbackType type;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    late final IconData icon;

    switch (type) {
      case FeedbackType.success:
        background = AppColors.successContainer;
        foreground = AppColors.success;
        icon = Icons.check_circle;
      case FeedbackType.error:
        background = AppColors.errorContainer;
        foreground = AppColors.error;
        icon = Icons.error;
      case FeedbackType.info:
        background = AppColors.infoContainer;
        foreground = AppColors.info;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
