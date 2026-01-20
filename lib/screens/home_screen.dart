import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SocketService>(
      builder: (context, socket, child) {
        final telemetry = socket.lastTelemetry;
        final device = socket.lastDeviceUpdate;
        final alert = socket.lastAlert;

        // Extract values safely
        final dripRate = telemetry?['telemetry']?['dripRate'] ??
            telemetry?['dripRate'] ??
            '-';

        final bottleLevel = telemetry?['telemetry']?['bottleLevel'] ??
            telemetry?['bottleLevel'] ??
            '-';

        final flowStatus = telemetry?['telemetry']?['flowStatus'] ??
            telemetry?['flowStatus'] ??
            'normal';

        final deviceId =
            device?['deviceId'] ?? telemetry?['deviceId'] ?? "IV001";

        final nurseName =
            device?['assignedTo']?['name'] ?? 
            device?['assignedNurse']?['name'] ??
            device?['nurseName'] ??
            "Nurse Assigned";

        return Scaffold(
          backgroundColor: const Color(0xffF7F9FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text(
              "HEALINK Dashboard",
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              Icon(
                socket.connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: socket.connected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =======================
                // DEVICE HEADER CARD
                // =======================
                _deviceHeader(deviceId, nurseName),
                const SizedBox(height: 20),

                // =======================
                // TELEMETRY CARDS (LIVE)
                // =======================
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        "Drip Rate",
                        "$dripRate drops/min",
                        Icons.water_drop,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        "Bottle Level",
                        "$bottleLevel g",
                        Icons.local_drink,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        "Flow Status",
                        "$flowStatus",
                        Icons.sync_rounded,
                        flowStatus == "reverse"
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // =======================
                // ALERT SECTION (LIVE)
                // =======================
                const Text(
                  "Alerts",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                alert != null
                    ? _alertTile(alert)
                    : _noAlertWidget(),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    socket.connected
                        ? "LIVE DATA • Connected to IV001"
                        : "OFFLINE • Waiting for connection...",
                    style: TextStyle(
                      color: socket.connected
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================
  //   DEVICE HEADER UI
  // ============================
  Widget _deviceHeader(String deviceId, String nurseName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue.shade50,
            child: const Icon(
              Icons.medical_services,
              size: 40,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Device ID: $deviceId",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Assigned Nurse: $nurseName",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================
  //   METRIC CARD UI
  // ============================
  Widget _metricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  //   ALERT TILE UI
  // ============================
  Widget _alertTile(Map<String, dynamic> alert) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 32,
            color: Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['message'] ?? alert['alert']?['message'] ?? "Alert",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert['timestamp'] ?? alert['alert']?['timestamp'] ?? "",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  //   NO ALERT UI
  // ============================
  Widget _noAlertWidget() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 30,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          Text(
            "No active alerts",
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

