import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/device.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../components/device_card.dart';
import '../../components/app_logo.dart';
import '../../utils/format.dart';
import '../../services/auth_service.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Device> _devices = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedTabIndex = 0;
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadDevices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      '/nurse/device-detail',
      arguments: device.deviceId,
    );
  }

  void _onBottomNavTap(int index) {
    if (_currentBottomNavIndex == index) return;
    setState(() {
      _currentBottomNavIndex = index;
    });
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/nurse/alerts');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/nurse/profile');
        break;
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentBottomNavIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const SizedBox.shrink(); // Will navigate to alerts
      case 2:
        return const SizedBox.shrink(); // Will navigate to profile
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return _isLoading
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
        : Column(
            children: [
              // Tabs
              Container(
                margin: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTypography.body1(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: AppTypography.body1(context).copyWith(
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'All Devices'),
                    Tab(text: 'Active'),
                    Tab(text: 'Inactive'),
                  ],
                ),
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDevicesList(_devices),
                    _buildDevicesList(_getActiveDevices()),
                    _buildDevicesList(_getInactiveDevices()),
                  ],
                ),
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Already on dashboard, allow normal back behavior
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Consumer<AuthService>(
                builder: (context, authService, child) {
                  final userName = authService.userName ?? 'Nurse';
                  String profileImage = authService.userProfileImage ?? 
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=0D8ABC&color=fff';
                  
                  // Add cache-busting for network images (not base64 or default)
                  if (!profileImage.contains('data:image') && !profileImage.contains('ui-avatars.com')) {
                    final separator = profileImage.contains('?') ? '&' : '?';
                    profileImage = '$profileImage${separator}t=${DateTime.now().millisecondsSinceEpoch}';
                  }
                  
                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    backgroundImage: NetworkImage(profileImage),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Image load error - fallback handled by CircleAvatar
                      print('Header image load error: $exception');
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nurse Dashboard',
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
                  Navigator.of(context).pushNamed('/nurse/alerts');
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
        ],
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentBottomNavIndex,
          onDestinationSelected: _onBottomNavTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primaryBlue.withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
    );
  }

  List<Device> _getActiveDevices() {
    return _devices.where((d) => d.status == 'good' || d.status == 'warning').toList();
  }

  List<Device> _getInactiveDevices() {
    return _devices.where((d) => d.status == 'critical' || d.dripRate == 0).toList();
  }

  Widget _buildDevicesList(List<Device> devices) {
    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s8,
              ),
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
                          _selectedTabIndex == 0
                              ? 'All Devices'
                              : _selectedTabIndex == 1
                                  ? 'Active Devices'
                                  : 'Inactive Devices',
                          style: AppTypography.h3(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${devices.length} devices',
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
            sliver: devices.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            'No devices found',
                            style: AppTypography.h3(context).copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final device = devices[index];
                        return Column(
                          children: [
                            DeviceCard(
                              device: device,
                              onTap: () => _navigateToDeviceDetail(device),
                            ),
                            // Active/Deactive Time Info
                            Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.s16,
                                left: AppSpacing.s8,
                                right: AppSpacing.s8,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.s12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: AppSpacing.s8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Active: ${FormatUtils.formatActiveTime(device.lastUpdated)}',
                                          style: AppTypography.caption(context).copyWith(
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (device.status == 'critical' || device.dripRate == 0)
                                          Text(
                                            'Deactive: ${FormatUtils.formatDeactiveTime(device.lastUpdated)}',
                                            style: AppTypography.caption(context).copyWith(
                                              fontSize: 11,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      childCount: devices.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.s24),
          ),
        ],
      ),
    );
  }
}

