import '../models/user_model.dart';
import '../utils/api_client.dart';

class UserService {
  // Cache untuk menyimpan user data (seperti di frontend website)
  static final Map<int, InvGateUser> _userCache = {};

  /// Get user by ID dengan caching
  /// GET /api/v1/users/:id
  Future<InvGateUser> getUserById(int userId) async {
    // Check cache dulu
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    final response = await ApiClient.get('/users/$userId');

    if (response.statusCode == 200) {
      final json = ApiClient.parseResponse(response);
      final user = InvGateUser.fromJson(json);
      // Simpan ke cache
      _userCache[userId] = user;
      return user;
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Failed to fetch user');
    }
  }

  /// Clear cache (optional, untuk testing atau refresh)
  static void clearCache() {
    _userCache.clear();
  }

  /// Get cached user (jika ada)
  static InvGateUser? getCachedUser(int userId) {
    return _userCache[userId];
  }
}

