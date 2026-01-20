import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'status_badge.dart';

class PatientStatusCard extends StatelessWidget {
  final double dripRate;
  final double mlPerHour;
  final int batteryLevel;
  final String status;

  const PatientStatusCard({
    super.key,
    required this.dripRate,
    required this.mlPerHour,
    required this.batteryLevel,
    required this.status,
  });

  IconData _getBatteryIcon(int level) {
    if (level > 75) return Icons.battery_full;
    if (level > 50) return Icons.battery_6_bar;
    if (level > 25) return Icons.battery_4_bar;
    if (level > 10) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return AppColors.success;
    if (level > 25) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.teal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Drip Rate Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dripRate.toStringAsFixed(1),
                style: AppTypography.h1(context).copyWith(
                  fontSize: 64,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 8),
                child: Text(
                  'ml/hr',
                  style: AppTypography.body1(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s32),
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.water_drop,
                  label: 'Drip Rate',
                  value: '${mlPerHour.toStringAsFixed(1)} ml/hr',
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: _getBatteryIcon(batteryLevel),
                  label: 'Battery',
                  value: '$batteryLevel%',
                  color: _getBatteryColor(batteryLevel),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          StatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.s8),
          Text(
            label,
            style: AppTypography.caption(context),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            value,
            style: AppTypography.body1(context).copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

