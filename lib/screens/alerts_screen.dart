import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/alert.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/format.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final String response = await rootBundle.loadString('lib/data/alerts.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _alerts = data.map((json) => Alert.fromJson(json)).toList();
        _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getAlertIcon(String type) {
    return type == 'critical' ? Icons.error : Icons.warning;
  }

  Color _getAlertColor(String type) {
    return type == 'critical' ? AppColors.danger : AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Alerts',
                  style: AppTypography.h3(context).copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_alerts.length} notifications',
                  style: AppTypography.caption(context).copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            )
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        'No alerts',
                        style: AppTypography.h3(context).copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      return _buildAlertCard(context, alert);
                    },
                  ),
                ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Alert alert) {
    final alertColor = _getAlertColor(alert.type);
    final alertIcon = _getAlertIcon(alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alertColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                alertIcon,
                color: alertColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.type.toUpperCase(),
                          style: AppTypography.caption(context).copyWith(
                            color: alertColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (alert.acknowledged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ACK',
                            style: AppTypography.caption(context).copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    alert.message,
                    style: AppTypography.body1(context),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      Icon(
                        Icons.devices,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        alert.deviceId,
                        style: AppTypography.caption(context),
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        FormatUtils.formatRelativeTime(alert.timestamp),
                        style: AppTypography.caption(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

