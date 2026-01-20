import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../components/patient_status_card.dart';
import '../../components/telemetry_chart.dart';
import '../../models/telemetry.dart';
import '../../components/app_logo.dart';
import '../../utils/format.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../providers/telemetry_provider.dart';
import '../../services/socket_service.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _deviceData;
  Map<String, dynamic>? _userData;
  List<Telemetry> _telemetry = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final String deviceResponse = await rootBundle.loadString('lib/data/patient_device.json');
      _deviceData = json.decode(deviceResponse);

      final String telemetryResponse = await rootBundle.loadString('lib/data/telemetry.json');
      final List<dynamic> telemetryData = json.decode(telemetryResponse);
      _telemetry = telemetryData
          .where((t) => t['deviceId'] == _deviceData!['deviceId'])
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

  Future<void> _loadUserData() async {
    try {
      final response = await ApiService.getCurrentUser();
      if (mounted && response['success'] == true) {
        setState(() {
          _userData = response['data'] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      // Silently fail - user data is optional for display
      print('Error loading user data: $e');
    }
  }

  void _onBottomNavTap(int index) {
    if (_currentBottomNavIndex == index) return;
    setState(() {
      _currentBottomNavIndex = index;
    });
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/patient/profile');
        break;
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentBottomNavIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const SizedBox.shrink(); // Will navigate to profile
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return _isLoading || _deviceData == null
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
              // Welcome Message
              Container(
                margin: const EdgeInsets.all(AppSpacing.s16),
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
                        Icons.favorite,
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
                            'Hello, ${_userData?['name'] ?? _deviceData!['patientName']}',
                            style: AppTypography.h3(context),
                          ),
                          if (_userData?['roomNumber'] != null || _deviceData!['room'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Room ${_userData?['roomNumber'] ?? _deviceData!['room']}',
                                style: AppTypography.body2(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
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
                    Tab(text: 'IV Status'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatusTab(),
                    _buildHistoryTab(),
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
          // Already on home, allow normal back behavior
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
            const AppLogo(size: 40),
            const SizedBox(width: AppSpacing.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'My IV Status',
                  style: AppTypography.h3(context).copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Real-time monitoring',
                  style: AppTypography.caption(context).copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s16),
            child: Consumer<AuthService>(
              builder: (context, authService, child) {
                final userName = authService.userName ?? 'User';
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
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
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

  Widget _buildStatusTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Consumer2<TelemetryProvider, SocketService>(
          builder: (context, telemetryProvider, socketService, child) {
            // ALWAYS prioritize real-time data when socket is connected
            // Only use mocked data if socket is NOT connected
            final useRealTime = socketService.isConnected;
            
            final dripRate = useRealTime
                ? telemetryProvider.dripRate 
                : (_deviceData!['dripRate'] as num).toDouble();
            final bottleLevel = useRealTime
                ? telemetryProvider.bottleLevel.toInt() 
                : _deviceData!['batteryLevel'] as int;
            final flowStatus = useRealTime && telemetryProvider.flowStatus.isNotEmpty
                ? telemetryProvider.flowStatus 
                : _deviceData!['status'] as String;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real-time Telemetry Display - Show connection status
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  margin: const EdgeInsets.only(bottom: AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: socketService.isConnected 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: socketService.isConnected 
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.warning.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        socketService.isConnected ? Icons.wifi : Icons.wifi_off,
                        color: socketService.isConnected ? AppColors.success : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              socketService.isConnected 
                                  ? '✅ Real-time Updates Active (Live Data)'
                                  : '⚠️ Using Mocked Data (Socket Disconnected)',
                              style: AppTypography.body2(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: socketService.isConnected ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            if (socketService.isConnected && telemetryProvider.alertMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '⚠ ${telemetryProvider.alertMessage}',
                                  style: AppTypography.caption(context).copyWith(
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            if (socketService.isConnected)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Drip: ${telemetryProvider.dripRate.toStringAsFixed(1)} ml/hr | Bottle: ${telemetryProvider.bottleLevel.toStringAsFixed(2)} g',
                                  style: AppTypography.caption(context).copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Card
                PatientStatusCard(
                  dripRate: dripRate,
                  mlPerHour: dripRate, // Assuming mlPerHour equals dripRate
                  batteryLevel: bottleLevel,
                  status: flowStatus,
                ),
                // Real-time Telemetry Details - Show when socket is connected
                if (socketService.isConnected)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    margin: const EdgeInsets.only(top: AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Telemetry',
                          style: AppTypography.h3(context),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        _buildTelemetryRow(
                          context,
                          'Drip Rate',
                          '${telemetryProvider.dripRate.toStringAsFixed(1)} ml/hr',
                          AppColors.teal,
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        _buildTelemetryRow(
                          context,
                          'Bottle Level',
                          '${telemetryProvider.bottleLevel.toStringAsFixed(2)} g',
                          AppColors.primaryBlue,
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        _buildTelemetryRow(
                          context,
                          'Flow Status',
                          telemetryProvider.flowStatus,
                          _getFlowStatusColor(telemetryProvider.flowStatus),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.s24),
            // Active/Deactive Time Info
            Container(
              padding: const EdgeInsets.all(AppSpacing.s20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Text(
                        'Device Timeline',
                        style: AppTypography.h3(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _buildTimeInfoRow(
                    context,
                    'Active Time',
                    FormatUtils.formatActiveTime(
                      DateTime.parse(_deviceData!['lastUpdated'] as String),
                    ),
                    AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  if (_deviceData!['status'] == 'critical' || _deviceData!['dripRate'] == 0)
                    _buildTimeInfoRow(
                      context,
                      'Deactive Time',
                      FormatUtils.formatDeactiveTime(
                        DateTime.parse(_deviceData!['lastUpdated'] as String),
                      ),
                      AppColors.danger,
                    ),
                ],
              ),
            ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildTelemetryRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body2(context),
        ),
        Text(
          value,
          style: AppTypography.body1(context).copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Color _getFlowStatusColor(String flowStatus) {
    switch (flowStatus.toLowerCase()) {
      case 'normalflow':
      case 'flowing':
        return AppColors.success;
      case 'slowflow':
      case 'warning':
        return AppColors.warning;
      case 'noflow':
      case 'critical':
        return AppColors.danger;
      default:
        return AppColors.primaryBlue;
    }
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  'Drip Rate History',
                  style: AppTypography.h3(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            TelemetryChart(
              telemetryData: _telemetry,
              deviceId: _deviceData!['deviceId'] as String,
            ),
            const SizedBox(height: AppSpacing.s24),
            // History List
            Text(
              'Recent Readings',
              style: AppTypography.h3(context),
            ),
            const SizedBox(height: AppSpacing.s16),
            ..._telemetry.take(10).map((telemetry) => _buildHistoryItem(context, telemetry)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfoRow(
    BuildContext context,
    String label,
    String time,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: color,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption(context),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTypography.body1(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Telemetry telemetry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.water_drop,
              color: AppColors.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FormatUtils.formatDripRate(telemetry.dripRate),
                  style: AppTypography.body1(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FormatUtils.formatDateAndTime(telemetry.timestamp),
                  style: AppTypography.caption(context),
                ),
              ],
            ),
          ),
          Text(
            '${telemetry.batteryLevel}%',
            style: AppTypography.body2(context).copyWith(
              color: telemetry.batteryLevel > 50
                  ? AppColors.success
                  : telemetry.batteryLevel > 25
                      ? AppColors.warning
                      : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

