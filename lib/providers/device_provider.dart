import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/telemetry.dart';

/// Provider for managing device and telemetry state
class DeviceProvider extends ChangeNotifier {
  List<Device> _devices = [];
  Map<String, List<Telemetry>> _telemetry = {}; // deviceId -> telemetry list
  Map<String, Device?> _deviceMap = {}; // deviceId -> device

  // Getters
  List<Device> get devices => List.unmodifiable(_devices);
  Map<String, List<Telemetry>> get telemetry => Map.unmodifiable(_telemetry);
  Map<String, Device?> get deviceMap => Map.unmodifiable(_deviceMap);

  /// Get telemetry for a specific device
  List<Telemetry> getTelemetryForDevice(String deviceId) {
    return _telemetry[deviceId] ?? [];
  }

  /// Get device by ID
  Device? getDevice(String deviceId) {
    return _deviceMap[deviceId];
  }

  /// Update device from socket event
  void updateDevice(Map<String, dynamic> data) {
    try {
      final deviceId = data['deviceId'] as String?;
      final deviceData = data['device'] as Map<String, dynamic>?;

      if (deviceId != null && deviceData != null) {
        // Convert backend format to Device model format
        final deviceJson = {
          'deviceId': deviceId,
          'patientId': deviceData['assignedPatient'] ?? deviceData['patientId'] ?? '',
          'patientName': deviceData['patientName'] ?? 'Unknown',
          'dripRate': deviceData['dripRate'] ?? 0.0,
          'batteryLevel': deviceData['batteryLevel'] ?? 100,
          'status': deviceData['status'] ?? 'good',
          'lastUpdated': deviceData['lastSeen'] ?? DateTime.now().toIso8601String(),
          'location': deviceData['location'] ?? '',
        };
        
        final device = Device.fromJson(deviceJson);
        _deviceMap[deviceId] = device;

        // Update in devices list
        final index = _devices.indexWhere((d) => d.deviceId == deviceId);
        if (index >= 0) {
          _devices[index] = device;
        } else {
          _devices.add(device);
        }

        debugPrint('✅ Device updated: $deviceId');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error updating device: $e');
    }
  }

  /// Update telemetry from socket event
  void updateTelemetry(Map<String, dynamic> data) {
    try {
      final deviceId = data['deviceId'] as String?;
      final telemetryData = data['telemetry'] as Map<String, dynamic>?;

      if (deviceId != null && telemetryData != null) {
        // Convert backend format to Telemetry model format
        // Backend sends: dripRate, flowStatus, bottleLevel, timestamp
        String timestampStr;
        try {
          final timestamp = telemetryData['timestamp'];
          if (timestamp is String) {
            timestampStr = timestamp;
          } else if (timestamp != null) {
            // Handle Date object from backend (ISO string)
            timestampStr = timestamp.toString();
            if (!timestampStr.contains('T')) {
              timestampStr = DateTime.now().toIso8601String();
            }
          } else {
            timestampStr = DateTime.now().toIso8601String();
          }
        } catch (e) {
          timestampStr = DateTime.now().toIso8601String();
        }
        
        final telemetryJson = {
          'deviceId': deviceId,
          'timestamp': timestampStr,
          'dripRate': telemetryData['dripRate'] ?? 0.0,
          'batteryLevel': telemetryData['bottleLevel'] ?? 100, // Backend uses bottleLevel
          'temperature': telemetryData['temperature'] ?? 25.0, // Default room temperature
          'pressure': telemetryData['pressure'] ?? (telemetryData['flowStatus'] == 'flowing' ? 1.0 : 0.0),
        };
        
        final telemetry = Telemetry.fromJson(telemetryJson);

        // Add to telemetry list for this device
        if (!_telemetry.containsKey(deviceId)) {
          _telemetry[deviceId] = [];
        }
        _telemetry[deviceId]!.insert(0, telemetry);

        // Keep only last 100 telemetry entries per device
        if (_telemetry[deviceId]!.length > 100) {
          _telemetry[deviceId] = _telemetry[deviceId]!.take(100).toList();
        }

        debugPrint('✅ Telemetry updated for device: $deviceId');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error updating telemetry: $e');
    }
  }

  /// Add new alert
  void addAlert(Map<String, dynamic> data) {
    try {
      final alertData = data['alert'] as Map<String, dynamic>?;
      if (alertData != null) {
        final deviceId = alertData['deviceId'] as String?;
        if (deviceId != null) {
          debugPrint('🚨 New alert for device: $deviceId');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Error adding alert: $e');
    }
  }

  /// Set initial devices list
  void setDevices(List<Device> devices) {
    _devices = devices;
    for (var device in devices) {
      _deviceMap[device.deviceId] = device;
    }
    notifyListeners();
  }
}

