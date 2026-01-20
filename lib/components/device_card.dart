import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/device.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/format.dart';
import 'status_badge.dart';

class DeviceCard extends StatefulWidget {
  final Device device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Theme.of(context).colorScheme.surface.withOpacity(0.3),
                      Theme.of(context).colorScheme.surface.withOpacity(0.1),
                    ]
                  : [
                      Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      Theme.of(context).colorScheme.surface.withOpacity(0.7),
                    ],
            ),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.cardGradient.colors.first.withOpacity(0.4),
                      width: 4,
                    ),
                  ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cardGradient.colors.first.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.device.deviceId,
                              style: AppTypography.h3(context).copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              widget.device.patientName,
                              style: AppTypography.body1(context),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.device.location,
                              style: AppTypography.body2(context),
                            ),
                          ],
                        ),
                        StatusBadge(status: widget.device.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            icon: Icons.water_drop,
                            label: 'Drip Rate',
                            value: FormatUtils.formatDripRate(widget.device.dripRate),
                            color: AppColors.teal,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s16),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            icon: _getBatteryIcon(widget.device.batteryLevel),
                            label: 'Battery',
                            value: FormatUtils.formatBattery(widget.device.batteryLevel),
                            color: _getBatteryColor(widget.device.batteryLevel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Active: ${FormatUtils.formatActiveTime(widget.device.lastUpdated)}',
                                style: AppTypography.caption(context).copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (widget.device.status == 'critical' || widget.device.dripRate == 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.stop_circle,
                                  size: 14,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Deactive: ${FormatUtils.formatDeactiveTime(widget.device.lastUpdated)}',
                                  style: AppTypography.caption(context).copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption(context),
              ),
            ],
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

