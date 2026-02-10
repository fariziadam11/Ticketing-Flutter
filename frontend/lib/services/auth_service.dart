import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_model.dart';
import '../utils/api_client.dart';

class AuthService {
  static const String _tokenKey = 'token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userLastNameKey = 'user_lastname';
  static const String _lastLoginEmailKey = 'last_login_email';

  // Secure storage untuk password (hanya untuk biometric login)
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const String _securePasswordKey = 'biometric_password';
  static const String _secureEmailKey = 'biometric_email';

  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await ApiClient.post(
      '/auth/register',
      body: request.toJson(),
      includeAuth: false,
    );

    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(
        ApiClient.parseResponse(response),
      );
      await _saveAuthData(authResponse);
      return authResponse;
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Registration failed');
    }
  }

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await ApiClient.post(
        '/auth/login',
        body: request.toJson(),
        includeAuth: false,
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(
          ApiClient.parseResponse(response),
        );
        await _saveAuthData(authResponse);
        // Simpan password secara aman untuk biometric login (opsional)
        await _saveBiometricCredentials(request.email, request.password);
        return authResponse;
      } else {
        // Parse error response
        Map<String, dynamic> error = {};
        try {
          error = ApiClient.parseResponse(response);
        } catch (e) {
          // If parsing fails, use default message
        }

        String errorMessage =
            (error['error']?.toString() ??
                    error['message']?.toString() ??
                    error['detail']?.toString() ??
                    '')
                .trim();

        // Check error message content first (regardless of status code)
        final lowerErrorMessage = errorMessage.toLowerCase();
        if (lowerErrorMessage.contains('invalid password') ||
            lowerErrorMessage.contains('incorrect password') ||
            lowerErrorMessage.contains('wrong password') ||
            lowerErrorMessage.contains('invalid credentials') ||
            lowerErrorMessage.contains('incorrect credentials') ||
            lowerErrorMessage.contains('authentication failed') ||
            lowerErrorMessage.contains('login attempt with invalid password') ||
            lowerErrorMessage.contains('user not found') ||
            lowerErrorMessage.contains('email not found')) {
          errorMessage = 'Email atau password salah. Silakan coba lagi.';
        } else {
          // Handle specific status codes if error message doesn't indicate invalid credentials
          if (response.statusCode == 401 || response.statusCode == 403) {
            errorMessage = 'Email atau password salah. Silakan coba lagi.';
          } else if (response.statusCode == 400) {
            if (errorMessage.isEmpty) {
              errorMessage = 'Data yang dimasukkan tidak valid.';
            }
          } else if (response.statusCode >= 500) {
            // Only show server error if it's not an authentication error
            if (errorMessage.isEmpty ||
                (!lowerErrorMessage.contains('password') &&
                    !lowerErrorMessage.contains('credential') &&
                    !lowerErrorMessage.contains('authentication'))) {
              errorMessage = 'Server error. Silakan coba lagi nanti.';
            } else {
              // Even if status is 500, if message indicates auth error, treat as invalid credentials
              errorMessage = 'Email atau password salah. Silakan coba lagi.';
            }
          } else if (errorMessage.isEmpty) {
            errorMessage = 'Login gagal. Silakan coba lagi.';
          }
        }

        // Ensure we have a message
        if (errorMessage.isEmpty) {
          errorMessage = 'Email atau password salah. Silakan coba lagi.';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw with proper message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login gagal. Silakan coba lagi.');
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await ApiClient.post(
      '/auth/refresh',
      body: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
      includeAuth: false,
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(
        ApiClient.parseResponse(response),
      );
      await _saveAuthData(authResponse);
      return authResponse;
    } else {
      final error = ApiClient.parseResponse(response);
      throw Exception(error['error'] ?? 'Token refresh failed');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null) {
      try {
        await ApiClient.post('/auth/revoke', includeAuth: true);
      } catch (e) {
        // Ignore errors during logout
      }
    }

    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userLastNameKey);

    // Jangan hapus biometric credentials saat logout
    // Biometric credentials akan tetap tersimpan untuk login berikutnya
  }

  /// Hapus biometric credentials (untuk disable biometric login)
  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _securePasswordKey);
    await _secureStorage.delete(key: _secureEmailKey);
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Simpan semua data dengan await untuk memastikan tersimpan
      final futures = <Future<bool>>[
        prefs.setString(_tokenKey, authResponse.token),
        prefs.setString(_userEmailKey, authResponse.email),
        prefs.setString(_userNameKey, authResponse.name),
        prefs.setString(_userLastNameKey, authResponse.lastname),
        prefs.setString(_lastLoginEmailKey, authResponse.email),
      ];

      // Tambahkan refresh token jika ada
      if (authResponse.refreshToken != null) {
        futures.add(
          prefs.setString(_refreshTokenKey, authResponse.refreshToken!),
        );
      }

      final results = await Future.wait(futures);

      // Verify that all saves were successful
      if (results.any((result) => result == false)) {
        throw Exception('Failed to save some authentication data');
      }
    } catch (e) {
      // Re-throw error untuk di-handle oleh caller
      throw Exception('Failed to save authentication data: $e');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<String?> getUserLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userLastNameKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get last login email (for biometric login)
  Future<String?> getLastLoginEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLoginEmailKey);
  }

  /// Check if user has previously logged in (for biometric login)
  Future<bool> hasPreviousLogin() async {
    // Cek apakah ada biometric credentials yang tersimpan
    final email = await _secureStorage.read(key: _secureEmailKey);
    return email != null && email.isNotEmpty;
  }

  /// Simpan kredensial untuk biometric login
  Future<void> _saveBiometricCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: _secureEmailKey, value: email);
      await _secureStorage.write(key: _securePasswordKey, value: password);
    } catch (e) {
      // Ignore errors saat menyimpan credentials
      // Biometric login akan tetap tersedia jika token masih valid
    }
  }

  /// Ambil kredensial untuk biometric login
  Future<Map<String, String>?> getBiometricCredentials() async {
    try {
      final email = await _secureStorage.read(key: _secureEmailKey);
      final password = await _secureStorage.read(key: _securePasswordKey);

      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Login menggunakan kredensial yang tersimpan (untuk biometric login)
  Future<AuthResponse> loginWithBiometricCredentials() async {
    final credentials = await getBiometricCredentials();
    if (credentials == null) {
      throw Exception('Biometric credentials tidak ditemukan');
    }

    final request = LoginRequest(
      email: credentials['email']!,
      password: credentials['password']!,
    );

    return await login(request);
  }
}
