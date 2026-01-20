class Device {
  final String deviceId;
  final String patientId;
  final String patientName;
  final double dripRate;
  final int batteryLevel;
  final String status; // 'good', 'warning', 'critical'
  final DateTime lastUpdated;
  final String location;

  Device({
    required this.deviceId,
    required this.patientId,
    required this.patientName,
    required this.dripRate,
    required this.batteryLevel,
    required this.status,
    required this.lastUpdated,
    required this.location,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['deviceId'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      dripRate: (json['dripRate'] as num).toDouble(),
      batteryLevel: json['batteryLevel'] as int,
      status: json['status'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'patientId': patientId,
      'patientName': patientName,
      'dripRate': dripRate,
      'batteryLevel': batteryLevel,
      'status': status,
      'lastUpdated': lastUpdated.toIso8601String(),
      'location': location,
    };
  }
}

