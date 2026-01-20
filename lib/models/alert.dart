class Alert {
  final String id;
  final String deviceId;
  final String patientId;
  final String type; // 'warning', 'critical'
  final String message;
  final DateTime timestamp;
  final bool acknowledged;

  Alert({
    required this.id,
    required this.deviceId,
    required this.patientId,
    required this.type,
    required this.message,
    required this.timestamp,
    this.acknowledged = false,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      patientId: json['patientId'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'patientId': patientId,
      'type': type,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }
}

