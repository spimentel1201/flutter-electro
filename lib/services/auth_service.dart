import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/services/api_service.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage;
  User? _currentUser;

  AuthService({
    required ApiService apiService,
    FlutterSecureStorage? secureStorage,
  }) : 
    _apiService = apiService,
    _secureStorage = secureStorage ?? const FlutterSecureStorage();

  User? get currentUser => _currentUser;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    return token != null;
  }

  // Login user
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post('auth/login', data: {
        'email': email,
        'password': password,
      });

      // Save token
      await _apiService.setToken(response['token']);
      
      // Save user data
      final user = User.fromJson(response['user']);
      _currentUser = user;
      
      // Store user ID securely
      await _secureStorage.write(key: 'user_id', value: user.id);
      
      return user;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Register new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'TECHNICIAN',
  }) async {
    try {
      final response = await _apiService.post('auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      });

      // Save token if registration also logs in the user
      if (response['token'] != null) {
        await _apiService.setToken(response['token']);
      }
      
      // Save user data
      final user = User.fromJson(response['user']);
      _currentUser = user;
      
      return user;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint if needed
      await _apiService.post('auth/logout');
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      // Clear token and user data
      await _apiService.clearToken();
      await _secureStorage.delete(key: 'user_id');
      _currentUser = null;
    }
  }

  // Get current user profile
  Future<User> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser!;
    }

    try {
      final response = await _apiService.get('auth/user');
      final user = User.fromJson(response);
      _currentUser = user;
      return user;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiService.put('auth/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      await _apiService.post('auth/password/reset', data: {
        'email': email,
      });
    } catch (e) {
      throw Exception('Failed to request password reset: ${e.toString()}');
    }
  }
}