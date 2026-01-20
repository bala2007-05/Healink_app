import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Socket.IO service for real-time communication with HEALINK backend
/// Singleton pattern for global access
class SocketService extends ChangeNotifier {
  static const String _baseUrl = 'https://healink-backend.onrender.com';
  
  // Singleton instance
  static final SocketService instance = SocketService._internal();
  
  // Private constructor
  SocketService._internal();
  
  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentToken;
  String? _currentDeviceId;
  
  // Last received data (for HomeScreen and other widgets)
  Map<String, dynamic>? _lastTelemetry;
  Map<String, dynamic>? _lastDeviceUpdate;
  Map<String, dynamic>? _lastAlert;
  
  // Stream controller for telemetry updates
  final _telemetryController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Getters
  bool get isConnected => _isConnected;
  bool get connected => _isConnected; // Alias for HomeScreen compatibility
  bool get isConnecting => _isConnecting;
  IO.Socket? get socket => _socket;
  Stream<Map<String, dynamic>> get onTelemetry => _telemetryController.stream;
  
  // Last received data getters
  Map<String, dynamic>? get lastTelemetry => _lastTelemetry;
  Map<String, dynamic>? get lastDeviceUpdate => _lastDeviceUpdate;
  Map<String, dynamic>? get lastAlert => _lastAlert;

  // Callbacks for events (kept for backward compatibility)
  Function(Map<String, dynamic>)? onDeviceUpdate;
  Function(Map<String, dynamic>)? onTelemetryUpdate;
  Function(Map<String, dynamic>)? onAlertNew;

  /// Initialize and connect to Socket.IO server with authentication token
  void connect(String token, {String deviceId = 'IV001'}) {
    // Prevent duplicate connection attempts
    if (_isConnecting) {
      debugPrint('⚠️ Connection already in progress, skipping...');
      return;
    }
    
    // If already connected with same token, just ensure device room is joined
    if (_isConnected && _currentToken == token) {
      debugPrint('✅ Already connected with same token');
      if (_currentDeviceId != deviceId) {
        joinDeviceRoom(deviceId);
      }
      return;
    }
    
    // If token changed, disconnect first
    if (_isConnected && _currentToken != token) {
      debugPrint('🔄 Token changed, reconnecting...');
      disconnect();
      // Small delay before reconnecting
      Future.delayed(const Duration(milliseconds: 500), () {
        _connectWithToken(token, deviceId);
      });
      return;
    }

    _connectWithToken(token, deviceId);
  }
  
  /// Connect with token (alias for HomeScreen compatibility)
  void connectWithToken(String token) {
    // Prevent duplicate connections
    if (_isConnecting) {
      debugPrint('⚠️ Connection already in progress, skipping...');
      return;
    }
    
    if (_isConnected && _currentToken == token) {
      debugPrint('✅ Already connected with same token');
      return;
    }
    
    connect(token, deviceId: 'IV001');
  }
  
  /// Join device room (can be called separately)
  void joinDeviceRoom(String deviceId) {
    _currentDeviceId = deviceId;
    if (_socket != null && _isConnected) {
      debugPrint('📡 Joining device room: device:$deviceId');
      _socket!.emit('joinDeviceRoom', {'deviceId': deviceId});
    } else {
      debugPrint('⚠️ Cannot join room: Socket not connected');
    }
  }
  
  /// Internal method to connect with token
  void _connectWithToken(String token, String deviceId) {
    // Don't reconnect if already connecting or connected with same token
    if (_isConnecting) {
      debugPrint('🔌 Already connecting, skipping...');
      return;
    }
    
    if (_isConnected && _currentToken == token) {
      debugPrint('🔌 Already connected with same token, skipping...');
      return;
    }
    
    _isConnecting = true;
    _currentToken = token;
    _currentDeviceId = deviceId;
    debugPrint('🔌 Connecting to Socket.IO server: $_baseUrl');
    debugPrint('   Device ID: $deviceId');
    debugPrint('   Timeout: 60s (for Render cold starts)');

    try {
      // Dispose existing socket if any
      if (_socket != null) {
        _socket!.dispose();
        _socket = null;
      }
      
      _socket = IO.io(
        _baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect() // Don't auto-connect, we'll do it manually
            .enableReconnection() // Enable reconnection
            .setReconnectionAttempts(100) // 100 reconnection attempts
            .setReconnectionDelay(2000) // Start with 2 seconds
            .setReconnectionDelayMax(10000) // Max 10 seconds between attempts
            .setTimeout(60000) // 60 seconds timeout for Render cold starts
            .setExtraHeaders({'User-Agent': 'HEALINK-Mobile-App/1.0'})
            .build(),
      );

      _setupEventHandlers();
      
      // Add small delay before connecting to avoid immediate timeout
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_socket != null && !_isConnected) {
          debugPrint('🔌 Attempting connection...');
          _socket!.connect();
        }
      });
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Setup all Socket.IO event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      debugPrint('✅ Socket.IO Connected to $_baseUrl');
      
      // Emit authentication token after connection
      if (_currentToken != null) {
        debugPrint('🔐 Authenticating with token...');
        _socket!.emit('authenticate', {'token': _currentToken});
      }
      
      // Join device room after authentication
      if (_currentDeviceId != null) {
        debugPrint('📡 Joining device room: device:$_currentDeviceId');
        _socket!.emit('joinDeviceRoom', {'deviceId': _currentDeviceId});
      }
      
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _isConnecting = false;
      debugPrint('⚠️ Socket.IO Disconnected');
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      _isConnecting = false;
      debugPrint('❌ Socket.IO Connection Error: $error');
      
      // Don't spam errors - only log significant ones
      if (error.toString().contains('timeout')) {
        debugPrint('⏳ Connection timeout - Render backend may be cold starting');
        debugPrint('   Will retry automatically...');
      } else {
        debugPrint('   Error details: $error');
      }
      
      notifyListeners();
    });

    _socket!.onReconnect((attempt) {
      _isConnected = true;
      _isConnecting = false;
      debugPrint('🔄 Socket.IO Reconnected (attempt $attempt)');
      
      // Re-authenticate and rejoin room after reconnection
      if (_currentToken != null) {
        debugPrint('🔐 Re-authenticating with token...');
        _socket!.emit('authenticate', {'token': _currentToken});
      }
      
      if (_currentDeviceId != null) {
        debugPrint('📡 Re-joining device room: device:$_currentDeviceId');
        _socket!.emit('joinDeviceRoom', {'deviceId': _currentDeviceId});
      }
      
      notifyListeners();
    });

    _socket!.onReconnectAttempt((attempt) {
      // Only log every 5th attempt to reduce spam
      if (attempt % 5 == 0 || attempt <= 3) {
        debugPrint('🔄 Socket.IO Reconnection attempt $attempt');
      }
    });

    _socket!.onReconnectError((error) {
      // Only log non-timeout errors to reduce spam
      if (!error.toString().contains('timeout')) {
        debugPrint('❌ Socket.IO Reconnection Error: $error');
      }
    });

    _socket!.onReconnectFailed((_) {
      debugPrint('❌ Socket.IO Reconnection Failed');
      _isConnecting = false;
      notifyListeners();
    });

    // Application events
    _socket!.on('device:update', (data) {
      debugPrint('📡 Received device:update event');
      debugPrint('   Data: $data');
      
      if (data is Map<String, dynamic>) {
        _lastDeviceUpdate = data;
        onDeviceUpdate?.call(data);
        notifyListeners();
      } else if (data is Map) {
        _lastDeviceUpdate = Map<String, dynamic>.from(data);
        onDeviceUpdate?.call(_lastDeviceUpdate!);
        notifyListeners();
      } else {
        debugPrint('⚠️ Invalid device:update data format');
      }
    });

    // Listen for telemetry event (backend emits "telemetry")
    _socket!.on('telemetry', (data) {
      debugPrint('📡 Received telemetry event');
      debugPrint('   Data type: ${data.runtimeType}');
      debugPrint('   Data: $data');
      
      try {
        Map<String, dynamic> telemetryMap;
        
        // Handle different data formats
        if (data is Map<String, dynamic>) {
          telemetryMap = data;
        } else if (data is Map) {
          telemetryMap = Map<String, dynamic>.from(data);
        } else {
          debugPrint('⚠️ Invalid telemetry data format: ${data.runtimeType}');
          return;
        }
        
        debugPrint('✅ Processing telemetry data:');
        debugPrint('   Keys: ${telemetryMap.keys.join(", ")}');
        if (telemetryMap.containsKey('dripRate')) {
          debugPrint('   DripRate: ${telemetryMap['dripRate']}');
        }
        if (telemetryMap.containsKey('bottleLevel')) {
          debugPrint('   BottleLevel: ${telemetryMap['bottleLevel']}');
        }
        if (telemetryMap.containsKey('flowStatus')) {
          debugPrint('   FlowStatus: ${telemetryMap['flowStatus']}');
        }
        
        // Store last telemetry data
        _lastTelemetry = telemetryMap;
        
        // Emit to stream
        _telemetryController.add(telemetryMap);
        
        // Call callback for backward compatibility
        onTelemetryUpdate?.call(telemetryMap);
        notifyListeners();
      } catch (e) {
        debugPrint('❌ Error processing telemetry data: $e');
      }
    });
    
    // Keep telemetry:update for backward compatibility
    _socket!.on('telemetry:update', (data) {
      debugPrint('📡 Received telemetry:update event (legacy)');
      debugPrint('   Data: $data');
      
      if (data is Map<String, dynamic>) {
        // Emit to stream
        _telemetryController.add(data);
        
        // Call callback
        onTelemetryUpdate?.call(data);
        notifyListeners();
      } else {
        debugPrint('⚠️ Invalid telemetry:update data format');
      }
    });

    _socket!.on('alert:new', (data) {
      debugPrint('🚨 Received alert:new event');
      debugPrint('   Data: $data');
      
      if (data is Map<String, dynamic>) {
        _lastAlert = data;
        onAlertNew?.call(data);
        notifyListeners();
      } else if (data is Map) {
        _lastAlert = Map<String, dynamic>.from(data);
        onAlertNew?.call(_lastAlert!);
        notifyListeners();
      } else {
        debugPrint('⚠️ Invalid alert:new data format');
      }
    });

    // Error handling
    _socket!.onError((error) {
      debugPrint('❌ Socket.IO Error: $error');
    });
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      debugPrint('🔌 Disconnecting Socket.IO...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Emit an event to the server
  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      debugPrint('📤 Emitting event: $event');
      debugPrint('   Data: $data');
      _socket!.emit(event, data);
    } else {
      debugPrint('⚠️ Cannot emit event: Socket not connected');
    }
  }

  /// Subscribe to a custom event
  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
      debugPrint('👂 Subscribed to event: $event');
    }
  }

  /// Unsubscribe from an event
  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
      debugPrint('🔇 Unsubscribed from event: $event');
    }
  }

  @override
  void dispose() {
    disconnect();
    _telemetryController.close();
    super.dispose();
  }
}

