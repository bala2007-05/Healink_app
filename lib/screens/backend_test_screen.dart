import 'package:flutter/material.dart';
import '../services/backend_health_check.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  Map<String, dynamic>? _testResults;
  bool _isTesting = false;

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResults = null;
    });

    try {
      final results = await BackendHealthCheck.runAllChecks();
      setState(() {
        _testResults = results;
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'error': e.toString(),
        };
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Health Check'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Backend URL Info
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backend URL:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    BackendHealthCheck.baseUrl,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${BackendHealthCheck.apiBase}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // Test Button
            ElevatedButton(
              onPressed: _isTesting ? null : _runTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isTesting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Testing Backend...'),
                      ],
                    )
                  : const Text(
                      'Run Backend Health Check',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // Test Results
            if (_testResults != null) ...[
              const Text(
                'Test Results:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),

              // Backend Health
              _buildResultCard(
                'Backend Health',
                _testResults!['backendHealth'],
                Icons.cloud,
              ),
              const SizedBox(height: AppSpacing.s12),

              // API Endpoint
              _buildResultCard(
                'API Endpoint',
                _testResults!['apiEndpoint'],
                Icons.api,
              ),
              const SizedBox(height: AppSpacing.s12),

              // Socket.IO
              _buildResultCard(
                'Socket.IO',
                _testResults!['socketIO'],
                Icons.wifi,
              ),
              const SizedBox(height: AppSpacing.s16),

              // Summary
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: _testResults!['summary']?['allOnline'] == true
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _testResults!['summary']?['allOnline'] == true
                        ? AppColors.success
                        : AppColors.warning,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResults!['summary']?['allOnline'] == true
                          ? Icons.check_circle
                          : Icons.warning,
                      color: _testResults!['summary']?['allOnline'] == true
                          ? AppColors.success
                          : AppColors.warning,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResults!['summary']?['message'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _testResults!['summary']?['allOnline'] == true
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, Map<String, dynamic>? result, IconData icon) {
    if (result == null) {
      return const SizedBox.shrink();
    }

    final isOnline = result['status'] == 'online' || result['status'] == 'reachable';
    final statusCode = result['statusCode'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.success.withOpacity(0.1)
            : AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withOpacity(0.3)
              : AppColors.danger.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isOnline ? AppColors.success : AppColors.danger,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (statusCode > 0)
            Text(
              'Status Code: $statusCode',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            result['message'] ?? 'No message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

