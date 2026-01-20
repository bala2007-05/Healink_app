import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _tokenKey = 'HEALINK_TOKEN';

  /// Save authentication token securely
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      print('Error saving token: $e');
      rethrow;
    }
  }

  /// Read authentication token
  static Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print('Error reading token: $e');
      return null;
    }
  }

  /// Delete authentication token
  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      print('Error deleting token: $e');
      rethrow;
    }
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    try {
      final token = await readToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

