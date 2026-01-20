import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/telemetry.dart';
import '../theme/colors.dart';
import '../utils/format.dart';

class TelemetryChart extends StatelessWidget {
  final List<Telemetry> telemetryData;
  final String deviceId;

  const TelemetryChart({
    super.key,
    required this.telemetryData,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    if (telemetryData.isEmpty) {
      return const Center(
        child: Text('No telemetry data available'),
      );
    }

    final spots = telemetryData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.dripRate);
    }).toList();

    final minY = telemetryData.map((t) => t.dripRate).reduce((a, b) => a < b ? a : b) - 10;
    final maxY = telemetryData.map((t) => t.dripRate).reduce((a, b) => a > b ? a : b) + 10;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.primaryBlue.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < telemetryData.length) {
                    final time = telemetryData[value.toInt()].timestamp;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        FormatUtils.formatTime(time),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          minX: 0,
          maxX: (telemetryData.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: AppColors.cardGradient,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.3),
                    AppColors.primaryBlue.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

