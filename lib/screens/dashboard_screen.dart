import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/device.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../components/device_card.dart';
import '../components/app_logo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Device> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final String response = await rootBundle.loadString('lib/data/devices.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _devices = data.map((json) => Device.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToDeviceDetail(Device device) {
    Navigator.of(context).pushNamed(
      '/device-detail',
      arguments: device.deviceId,
    );
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
            const AppLogo(size: 40),
            const SizedBox(width: AppSpacing.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HEALINK',
                  style: AppTypography.h3(context).copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'IV Monitoring',
                  style: AppTypography.caption(context).copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.of(context).pushNamed('/alerts');
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () {
              // Toggle dark mode would be implemented here
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLogo(size: 100),
                  SizedBox(height: AppSpacing.s24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(AppSpacing.s24),
                      padding: const EdgeInsets.all(AppSpacing.s20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryBlue.withOpacity(0.1),
                            AppColors.teal.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.s12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.devices,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Devices',
                                  style: AppTypography.h3(context),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_devices.length} devices monitoring',
                                  style: AppTypography.body2(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return DeviceCard(
                            device: _devices[index],
                            onTap: () => _navigateToDeviceDetail(_devices[index]),
                          );
                        },
                        childCount: _devices.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.s24),
                  ),
                ],
              ),
            ),
    );
  }
}

