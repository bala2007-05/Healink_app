class Telemetry {
  final String deviceId;
  final DateTime timestamp;
  final double dripRate;
  final int batteryLevel;
  final double temperature;
  final double pressure;

  Telemetry({
    required this.deviceId,
    required this.timestamp,
    required this.dripRate,
    required this.batteryLevel,
    required this.temperature,
    required this.pressure,
  });

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      deviceId: json['deviceId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      dripRate: (json['dripRate'] as num).toDouble(),
      batteryLevel: json['batteryLevel'] as int,
      temperature: (json['temperature'] as num).toDouble(),
      pressure: (json['pressure'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'dripRate': dripRate,
      'batteryLevel': batteryLevel,
      'temperature': temperature,
      'pressure': pressure,
    };
  }
}

