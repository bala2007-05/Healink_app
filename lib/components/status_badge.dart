import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  
  const StatusBadge({
    super.key,
    required this.status,
  });
  
  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'critical':
        return AppColors.danger;
      case 'warning':
        return AppColors.warning;
      case 'good':
      default:
        return AppColors.success;
    }
  }
  
  String get _statusText {
    switch (status.toLowerCase()) {
      case 'critical':
        return 'Critical';
      case 'warning':
        return 'Warning';
      case 'good':
      default:
        return 'Good';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _statusText,
            style: AppTypography.caption(context).copyWith(
              color: _statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

