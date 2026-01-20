import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/secure_storage.dart';

class AuthService extends ChangeNotifier {
  static const String _userRoleKey = 'user_role';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userProfileImageKey = 'user_profile_image';
  
  String? _token;
  String? _userRole;
  String? _userName;
  String? _userEmail;
  String? _userProfileImage;
  
  String? get token => _token;
  String? get userRole => _userRole;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userProfileImage => _userProfileImage;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  
  AuthService() {
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      _token = await SecureStorage.readToken();
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString(_userRoleKey);
      _userName = prefs.getString(_userNameKey);
      _userEmail = prefs.getString(_userEmailKey);
      _userProfileImage = prefs.getString(_userProfileImageKey);
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      _token = null;
      _userRole = null;
      _userName = null;
      _userEmail = null;
      _userProfileImage = null;
      notifyListeners();
    }
  }
  
  Future<void> saveToken(String token, String role) async {
    try {
      // Save token to secure storage
      await SecureStorage.saveToken(token);
      
      // Save role to SharedPreferences (for backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, role);
      
      _token = token;
      _userRole = role;
      notifyListeners();
    } catch (e) {
      print('Error saving token: $e');
      rethrow;
    }
  }
  
  /// Save complete user data after login/registration
  Future<void> saveUserData({
    required String token,
    required String role,
    required String name,
    required String email,
    String? profileImage,
  }) async {
    try {
      // Save token to secure storage
      await SecureStorage.saveToken(token);
      
      // Save all user data to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, role);
      await prefs.setString(_userNameKey, name);
      await prefs.setString(_userEmailKey, email);
      if (profileImage != null && profileImage.isNotEmpty) {
        await prefs.setString(_userProfileImageKey, profileImage);
      } else {
        await prefs.remove(_userProfileImageKey);
      }
      
      // Update in-memory state
      _token = token;
      _userRole = role;
      _userName = name;
      _userEmail = email;
      _userProfileImage = profileImage;
      
      print('✅ User data saved:');
      print('   - Name: $name');
      print('   - Email: $email');
      print('   - Role: $role');
      print('   - Profile Image: ${profileImage ?? 'Default'}');
      
      notifyListeners();
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }
  
  Future<void> clearToken() async {
    try {
      await SecureStorage.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userRoleKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userProfileImageKey);
      
      _token = null;
      _userRole = null;
      _userName = null;
      _userEmail = null;
      _userProfileImage = null;
      notifyListeners();
    } catch (e) {
      print('Error clearing token: $e');
      _token = null;
      _userRole = null;
      _userName = null;
      _userEmail = null;
      _userProfileImage = null;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    await clearToken();
    notifyListeners();
  }
  
  Future<bool> hasToken() async {
    try {
      return await SecureStorage.hasToken();
    } catch (e) {
      return false;
    }
  }

  /// Update profile image locally (after successful API update)
  Future<void> updateProfileImage(String profileImageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileImageKey, profileImageUrl);
      
      _userProfileImage = profileImageUrl;
      
      print('✅ Profile image updated locally: $profileImageUrl');
      notifyListeners();
    } catch (e) {
      print('Error updating profile image locally: $e');
      rethrow;
    }
  }
}

