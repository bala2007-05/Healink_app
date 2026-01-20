import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';
import 'theme/spacing.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_detail_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/nurse/nurse_dashboard.dart';
import 'screens/nurse/nurse_device_detail.dart';
import 'screens/nurse/nurse_alerts.dart';
import 'screens/nurse/nurse_profile.dart';
import 'screens/patient/patient_home.dart';
import 'screens/patient/patient_profile.dart';
import 'screens/backend_test_screen.dart';
import 'navigation/bottom_nav.dart';
import 'components/app_logo.dart';
import 'services/auth_service.dart';

class HealinkApp extends StatefulWidget {
  const HealinkApp({super.key});

  @override
  State<HealinkApp> createState() => _HealinkAppState();
}

class _HealinkAppState extends State<HealinkApp> {
  int _currentIndex = 0;
  bool _isDarkMode = false;

  void toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }


  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const AlertsScreen();
      case 2:
        return _buildProfileScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildProfileScreen() {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            'Profile',
            style: AppTypography.h2(context).copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        body: Builder(
          builder: (scaffoldContext) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              children: [
              const SizedBox(height: AppSpacing.s40),
              const AppLogo(size: 120),
              const SizedBox(height: AppSpacing.s24),
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
                child: Column(
                  children: [
                    Text(
                      'Medical Staff',
                      style: AppTypography.h3(context),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'staff@healink.com',
                      style: AppTypography.body2(context),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Divider(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Row(
                        children: [
                          Icon(
                            Icons.dark_mode,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          SizedBox(width: AppSpacing.s12),
                          Text('Dark Mode'),
                        ],
                      ),
                      value: _isDarkMode,
                      onChanged: toggleDarkMode,
                      activeThumbColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Container(
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
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      Icons.info_outline,
                      'App Version',
                      '1.0.0',
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    _buildInfoRow(
                      context,
                      Icons.medical_services,
                      'System Status',
                      'Operational',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Container(
                width: double.infinity,
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
                  onPressed: () async {
                    try {
                      final authService = Provider.of<AuthService>(scaffoldContext, listen: false);
                      await authService.logout();
                      if (!mounted) return;
                      
                      Navigator.of(scaffoldContext, rootNavigator: true).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text('Logout error: $e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
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
                      const Icon(Icons.logout, size: 22),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        'Logout',
                        style: AppTypography.button(scaffoldContext),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            selectedIndex: 2,
            onDestinationSelected: (index) {
              if (_currentIndex == index) return;
              setState(() {
                _currentIndex = index;
              });
              if (!mounted) return;
              switch (index) {
                case 0:
                  Navigator.of(context).pushReplacementNamed('/dashboard');
                  break;
                case 1:
                  Navigator.of(context).pushReplacementNamed('/alerts');
                  break;
                case 2:
                  // Already on profile
                  break;
              }
            },
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

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body2(context),
          ),
        ),
        Text(
          value,
          style: AppTypography.body1(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEALINK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.lightColorScheme,
        primarySwatch: AppColors.primarySwatch,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryBlue),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightBlue.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.darkColorScheme,
        primarySwatch: AppColors.primarySwatch,
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryBlue),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/nurse/dashboard': (context) => const NurseDashboardScreen(),
        '/nurse/device-detail': (context) {
          final deviceId = ModalRoute.of(context)!.settings.arguments as String;
          return NurseDeviceDetailScreen(deviceId: deviceId);
        },
        '/nurse/alerts': (context) => const NurseAlertsScreen(),
        '/nurse/profile': (context) => const NurseProfileScreen(),
        '/patient/home': (context) => const PatientHomeScreen(),
        '/patient/profile': (context) => const PatientProfileScreen(),
        '/backend-test': (context) => const BackendTestScreen(),
        '/dashboard': (context) => PopScope(
              canPop: false,
              onPopInvoked: (didPop) {
                if (!didPop) {
                  SystemNavigator.pop();
                }
              },
              child: Builder(
                builder: (ctx) => Scaffold(
                  body: _getCurrentScreen(),
                  bottomNavigationBar: BottomNav(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      if (_currentIndex == index) return;
                      setState(() {
                        _currentIndex = index;
                      });
                      if (!mounted) return;
                      switch (index) {
                        case 0:
                          // Already on dashboard
                          break;
                        case 1:
                          Navigator.of(ctx).pushReplacementNamed('/alerts');
                          break;
                        case 2:
                          // Profile is handled by _getCurrentScreen
                          break;
                      }
                    },
                  ),
                ),
              ),
            ),
        '/device-detail': (context) {
          final deviceId = ModalRoute.of(context)!.settings.arguments as String;
          return DeviceDetailScreen(deviceId: deviceId);
        },
        '/alerts': (context) => Builder(
              builder: (ctx) => Scaffold(
                body: const AlertsScreen(),
                bottomNavigationBar: BottomNav(
                  currentIndex: 1,
                  onTap: (index) {
                    if (index == 1) return; // Already on alerts
                    switch (index) {
                      case 0:
                        Navigator.of(ctx).pushReplacementNamed('/dashboard');
                        break;
                      case 2:
                        Navigator.of(ctx).pushReplacementNamed('/dashboard');
                        break;
                    }
                  },
                ),
              ),
            ),
      },
    );
  }
}
