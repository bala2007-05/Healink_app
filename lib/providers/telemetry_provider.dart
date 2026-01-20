import 'package:flutter/foundation.dart';

/// Provider for managing real-time telemetry state
class TelemetryProvider extends ChangeNotifier {
  double _dripRate = 0.0;
  double _bottleLevel = 0.0;
  String _flowStatus = "normalFlow";
  String? _alertMessage;

  // Getters
  double get dripRate => _dripRate;
  double get bottleLevel => _bottleLevel;
  String get flowStatus => _flowStatus;
  String? get alertMessage => _alertMessage;

  /// Update telemetry from socket data
  /// Handles multiple formats:
  /// Format 1: { "dripRate": 31, "bottleLevel": 98.42, "flowStatus": "normalFlow", "alert": null }
  /// Format 2: { "deviceId": "IV001", "telemetry": { "dripRate": 31, ... } }
  void updateTelemetry(Map<String, dynamic> data) {
    try {
      bool hasChanges = false;
      
      // Handle nested format: { deviceId: "IV001", telemetry: { ... } }
      Map<String, dynamic> telemetryData = data;
      if (data.containsKey('telemetry') && data['telemetry'] is Map) {
        telemetryData = Map<String, dynamic>.from(data['telemetry'] as Map);
        debugPrint('📦 Extracted nested telemetry data');
      }

      // Update dripRate
      if (telemetryData.containsKey('dripRate')) {
        final newDripRate = (telemetryData['dripRate'] as num?)?.toDouble() ?? 0.0;
        if (_dripRate != newDripRate) {
          _dripRate = newDripRate;
          hasChanges = true;
        }
      }

      // Update bottleLevel
      if (telemetryData.containsKey('bottleLevel')) {
        final newBottleLevel = (telemetryData['bottleLevel'] as num?)?.toDouble() ?? 0.0;
        if (_bottleLevel != newBottleLevel) {
          _bottleLevel = newBottleLevel;
          hasChanges = true;
        }
      }

      // Update flowStatus
      if (telemetryData.containsKey('flowStatus')) {
        final newFlowStatus = telemetryData['flowStatus'] as String? ?? "normalFlow";
        if (_flowStatus != newFlowStatus) {
          _flowStatus = newFlowStatus;
          hasChanges = true;
        }
      }

      // Update alertMessage
      final alert = telemetryData['alert'];
      final newAlertMessage = alert != null ? alert.toString() : null;
      if (_alertMessage != newAlertMessage) {
        _alertMessage = newAlertMessage;
        hasChanges = true;
      }

      // Only notify listeners if there were actual changes
      if (hasChanges) {
        debugPrint('📊 Telemetry updated:');
        debugPrint('   Drip Rate: $_dripRate');
        debugPrint('   Bottle Level: $_bottleLevel');
        debugPrint('   Flow Status: $_flowStatus');
        if (_alertMessage != null) {
          debugPrint('   Alert: $_alertMessage');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error updating telemetry: $e');
    }
  }

  /// Reset telemetry to initial state
  void reset() {
    _dripRate = 0.0;
    _bottleLevel = 0.0;
    _flowStatus = "normalFlow";
    _alertMessage = null;
    notifyListeners();
  }
}

