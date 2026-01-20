import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/telemetry.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../components/telemetry_chart.dart';
import '../components/status_badge.dart';
import '../utils/format.dart';
import '../providers/telemetry_provider.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  Device? _device;
  List<Telemetry> _telemetry = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load device
      final String devicesResponse = await rootBundle.loadString('lib/data/devices.json');
      final List<dynamic> devicesData = json.decode(devicesResponse);
      final deviceJson = devicesData.firstWhere(
        (d) => d['deviceId'] == widget.deviceId,
      );
      _device = Device.fromJson(deviceJson);

      // Load telemetry
      final String telemetryResponse = await rootBundle.loadString('lib/data/telemetry.json');
      final List<dynamic> telemetryData = json.decode(telemetryResponse);
      _telemetry = telemetryData
          .where((t) => t['deviceId'] == widget.deviceId)
          .map((json) => Telemetry.fromJson(json))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _triggerBuzzer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Buzzer triggered (mock)'),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
    if (_isLoading || _device == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.deviceId),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.primaryBlue,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s8),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _device!.deviceId,
                    style: AppTypography.h3(context).copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Device Details',
                    style: AppTypography.caption(context).copyWith(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.s20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.cardGradient,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _device!.patientName,
                          style: AppTypography.h3(context),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          _device!.patientId,
                          style: AppTypography.body2(context),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          _device!.location,
                          style: AppTypography.caption(context),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: _device!.status),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            // Chart
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  'Drip Rate Trend',
                  style: AppTypography.h3(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            TelemetryChart(
              telemetryData: _telemetry,
              deviceId: widget.deviceId,
            ),
            const SizedBox(height: AppSpacing.s24),
            // Stats Grid
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  'Current Status',
                  style: AppTypography.h3(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Consumer<TelemetryProvider>(
              builder: (context, telemetryProvider, child) {
                // Use real-time telemetry data if available, otherwise fallback to device data
                final dripRate = telemetryProvider.dripRate > 0 
                    ? telemetryProvider.dripRate 
                    : _device!.dripRate;
                final bottleLevel = telemetryProvider.bottleLevel > 0 
                    ? telemetryProvider.bottleLevel.toInt() 
                    : _device!.batteryLevel;
                final flowStatus = telemetryProvider.flowStatus.isNotEmpty 
                    ? telemetryProvider.flowStatus 
                    : _device!.status;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Real-time Telemetry Alert
                    if (telemetryProvider.alertMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        margin: const EdgeInsets.only(bottom: AppSpacing.s16),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.danger.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: AppColors.danger,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Text(
                                '⚠ ${telemetryProvider.alertMessage}',
                                style: AppTypography.body2(context).copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Real-time Status Indicator
                    if (telemetryProvider.dripRate > 0 || telemetryProvider.bottleLevel > 0)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        margin: const EdgeInsets.only(bottom: AppSpacing.s16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wifi,
                              color: AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Text(
                              'Live: Drip ${telemetryProvider.dripRate.toStringAsFixed(1)} ml/hr | Bottle ${telemetryProvider.bottleLevel.toStringAsFixed(2)} g',
                              style: AppTypography.caption(context).copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.s16,
                      mainAxisSpacing: AppSpacing.s16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.water_drop,
                          label: 'Drip Rate',
                          value: FormatUtils.formatDripRate(dripRate),
                          color: AppColors.teal,
                        ),
                        _buildStatCard(
                          context,
                          icon: _getBatteryIcon(bottleLevel),
                          label: 'Bottle Level',
                          value: '${bottleLevel.toStringAsFixed(1)} g',
                          color: _getBatteryColor(bottleLevel),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.access_time,
                          label: 'Last Updated',
                          value: FormatUtils.formatRelativeTime(_device!.lastUpdated),
                          color: AppColors.primaryBlue,
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.info_outline,
                          label: 'Flow Status',
                          value: flowStatus.toUpperCase(),
                          color: flowStatus == 'normalFlow' || flowStatus == 'good'
                              ? AppColors.success
                              : flowStatus == 'slowFlow' || flowStatus == 'warning'
                                  ? AppColors.warning
                                  : AppColors.danger,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.s32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.s24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.danger, AppColors.danger.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _triggerBuzzer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_active, size: 22),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'Trigger Buzzer',
                    style: AppTypography.button(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ],
      ),
    );
  }
}

