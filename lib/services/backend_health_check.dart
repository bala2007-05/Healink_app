import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service to check backend health and connectivity
class BackendHealthCheck {
  static const String baseUrl = 'https://healink-backend.onrender.com';
  static const String apiBase = '$baseUrl/api';
  
  /// Check if backend is responding
  static Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      debugPrint('🔍 Checking backend health...');
      debugPrint('   URL: $baseUrl');
      
      // Try to access root endpoint (if available) or a simple endpoint
      final response = await http.get(
        Uri.parse(baseUrl),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Backend health check timeout');
        },
      );
      
      debugPrint('   Status Code: ${response.statusCode}');
      debugPrint('   Response Length: ${response.body.length}');
      
      return {
        'status': 'online',
        'statusCode': response.statusCode,
        'message': 'Backend is responding',
        'responseTime': 'OK',
      };
    } catch (e) {
      debugPrint('❌ Backend health check failed: $e');
      return {
        'status': 'offline',
        'statusCode': 0,
        'message': 'Backend is not responding: ${e.toString()}',
        'responseTime': 'Timeout',
      };
    }
  }
  
  /// Test API endpoint
  static Future<Map<String, dynamic>> testApiEndpoint() async {
    try {
      debugPrint('🔍 Testing API endpoint...');
      debugPrint('   URL: $apiBase/auth/login');
      
      // Try a simple POST to login endpoint (will fail but shows if endpoint exists)
      final response = await http.post(
        Uri.parse('$apiBase/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': 'test@test.com',
          'password': 'test',
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('API endpoint test timeout');
        },
      );
      
      debugPrint('   Status Code: ${response.statusCode}');
      
      // Even if login fails, if we get a response, the endpoint is working
      if (response.statusCode == 400 || response.statusCode == 401) {
        return {
          'status': 'online',
          'statusCode': response.statusCode,
          'message': 'API endpoint is responding (authentication required)',
          'endpoint': 'Working',
        };
      }
      
      return {
        'status': 'online',
        'statusCode': response.statusCode,
        'message': 'API endpoint is responding',
        'endpoint': 'Working',
      };
    } catch (e) {
      debugPrint('❌ API endpoint test failed: $e');
      return {
        'status': 'offline',
        'statusCode': 0,
        'message': 'API endpoint is not responding: ${e.toString()}',
        'endpoint': 'Not Working',
      };
    }
  }
  
  /// Test Socket.IO connection
  static Future<Map<String, dynamic>> testSocketConnection() async {
    try {
      debugPrint('🔍 Testing Socket.IO connection...');
      debugPrint('   URL: $baseUrl');
      
      // Socket.IO test would require actual socket connection
      // For now, just check if the URL is reachable
      await http.get(
        Uri.parse(baseUrl),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Socket.IO test timeout');
        },
      );
      
      return {
        'status': 'reachable',
        'message': 'Socket.IO server URL is reachable',
        'socket': 'Can connect',
      };
    } catch (e) {
      debugPrint('❌ Socket.IO test failed: $e');
      return {
        'status': 'unreachable',
        'message': 'Socket.IO server URL is not reachable: ${e.toString()}',
        'socket': 'Cannot connect',
      };
    }
  }
  
  /// Run all health checks
  static Future<Map<String, dynamic>> runAllChecks() async {
    debugPrint('\n═══════════════════════════════════════');
    debugPrint('🔍 BACKEND HEALTH CHECK');
    debugPrint('═══════════════════════════════════════\n');
    
    final results = <String, dynamic>{};
    
    // Check 1: Backend Health
    debugPrint('1️⃣ Checking backend health...');
    results['backendHealth'] = await checkBackendHealth();
    await Future.delayed(const Duration(seconds: 1));
    
    // Check 2: API Endpoint
    debugPrint('\n2️⃣ Testing API endpoint...');
    results['apiEndpoint'] = await testApiEndpoint();
    await Future.delayed(const Duration(seconds: 1));
    
    // Check 3: Socket.IO
    debugPrint('\n3️⃣ Testing Socket.IO connection...');
    results['socketIO'] = await testSocketConnection();
    
    // Summary
    final allOnline = results['backendHealth']?['status'] == 'online' &&
        results['apiEndpoint']?['status'] == 'online' &&
        results['socketIO']?['status'] == 'reachable';
    
    results['summary'] = {
      'allOnline': allOnline,
      'message': allOnline
          ? '✅ All backend services are online'
          : '⚠️ Some backend services may be offline',
    };
    
    debugPrint('\n═══════════════════════════════════════');
    debugPrint('📊 SUMMARY');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Backend Health: ${results['backendHealth']?['status']}');
    debugPrint('API Endpoint: ${results['apiEndpoint']?['status']}');
    debugPrint('Socket.IO: ${results['socketIO']?['status']}');
    debugPrint('Overall: ${results['summary']?['message']}');
    debugPrint('═══════════════════════════════════════\n');
    
    return results;
  }
}

