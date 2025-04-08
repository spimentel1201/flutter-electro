import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/services/api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService({required ApiService apiService}) : _apiService = apiService;

  // Get all users
  Future<List<User>> getUsers({
    String? search,
    String? role,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      final response = await _apiService.get('users', queryParams: queryParams);
      final List<dynamic> usersJson = response['data'];
      return usersJson.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get users: ${e.toString()}');
    }
  }

  // Get user by ID
  Future<User> getUserById(String userId) async {
    try {
      final response = await _apiService.get('users/$userId', queryParams: {});
      return User.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Create a new user
  Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
    String role = 'TECHNICIAN',
  }) async {
    try {
      final data = {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      };

      if (address != null && address.isNotEmpty) {
        data['address'] = address;
      }

      final response = await _apiService.post('users', data: data);
      return User.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  // Update user
  Future<User> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      if (role != null) data['role'] = role;

      final response = await _apiService.put('users/$userId', data: data);
      return User.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _apiService.delete('users/$userId');
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // Get technicians (users with TECHNICIAN role)
  Future<List<User>> getTechnicians({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    return getUsers(
      search: search,
      role: 'TECHNICIAN',
      page: page,
      limit: limit,
    );
  }

  // Get admins (users with ADMIN role)
  Future<List<User>> getAdmins({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    return getUsers(
      search: search,
      role: 'ADMIN',
      page: page,
      limit: limit,
    );
  }
}