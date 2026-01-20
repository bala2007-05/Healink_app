import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/socket_service.dart';
import 'providers/device_provider.dart';
import 'providers/telemetry_provider.dart';
import '../utils/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.hasToken(); // Load token initially
  
  // Initialize providers
  final socketService = SocketService.instance;
  final deviceProvider = DeviceProvider();
  final telemetryProvider = TelemetryProvider();
  
  // Connect socket callbacks to providers
  socketService.onDeviceUpdate = (data) => deviceProvider.updateDevice(data);
  socketService.onTelemetryUpdate = (data) => deviceProvider.updateTelemetry(data);
  socketService.onAlertNew = (data) => deviceProvider.addAlert(data);
  
  // Listen to telemetry stream and update TelemetryProvider
  socketService.onTelemetry.listen((data) {
    telemetryProvider.updateTelemetry(data);
  });
  
  // Connect socket after user is authenticated
  if (await authService.hasToken()) {
    final token = await SecureStorage.readToken();
    if (token != null) {
      socketService.connect(token, deviceId: 'IV001');
    }
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<SocketService>.value(value: socketService),
        ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
        ChangeNotifierProvider<TelemetryProvider>.value(value: telemetryProvider),
      ],
      child: const HealinkApp(),
    ),
  );
}
