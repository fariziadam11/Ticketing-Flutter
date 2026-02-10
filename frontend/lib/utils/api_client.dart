import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';
import '../services/auth_service.dart';

class ApiClient {
  // Base URL diambil dari AppConfig
  // Edit lib/utils/app_config.dart untuk mengubah konfigurasi
  static String get baseUrl => AppConfig.baseUrl;
  
  // HTTP client dengan timeout configuration
  static final http.Client _httpClient = http.Client();
  static const Duration _timeoutDuration = Duration(seconds: 30);
  
  static final AuthService _authService = AuthService();
  static bool _isRefreshing = false;
  
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Public helper untuk mendapatkan auth headers (digunakan di multipart).
  static Future<Map<String, String>> getAuthHeaders() async {
    return _getHeaders(includeAuth: true);
  }
  
  // Auto refresh token jika dapat 401
  static Future<http.Response> _handleResponse(
    http.Response response,
    Future<http.Response> Function() retryRequest,
    String endpoint,
  ) async {
    // Skip auto refresh untuk endpoint auth (login, register, refresh, revoke)
    final isAuthEndpoint = endpoint.startsWith('/auth/');
    if (isAuthEndpoint || response.statusCode != 401) {
      return response;
    }
    
    // Cegah multiple refresh calls bersamaan
    if (_isRefreshing) {
      // Tunggu sampai refresh selesai, lalu retry
      while (_isRefreshing) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return retryRequest();
    }
    
    _isRefreshing = true;
    try {
      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        // Coba refresh token
        try {
          await _authService.refreshToken(refreshToken);
          // Token berhasil di-refresh, retry request
          _isRefreshing = false;
          return retryRequest();
        } catch (e) {
          // Refresh token gagal, mungkin expired
          // Clear tokens dan return response 401
          await _authService.logout();
          _isRefreshing = false;
          return response;
        }
      } else {
        // Tidak ada refresh token
        _isRefreshing = false;
        return response;
      }
    } catch (e) {
      _isRefreshing = false;
      return response;
    }
  }

  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );
    
    Future<http.Response> makeRequest() async {
      try {
        return await _httpClient
            .get(
              uri,
              headers: await _getHeaders(includeAuth: includeAuth),
            )
            .timeout(_timeoutDuration);
      } on SocketException {
        throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
      } on HttpException {
        throw Exception('Terjadi kesalahan saat berkomunikasi dengan server.');
      } on FormatException {
        throw Exception('Format data tidak valid.');
      } catch (e) {
        if (e.toString().contains('TimeoutException') || 
            e.toString().contains('timeout')) {
          throw Exception('Request timeout. Silakan coba lagi.');
        }
        rethrow;
      }
    }
    
    final response = await makeRequest();
    return await _handleResponse(response, makeRequest, endpoint);
  }

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    Future<http.Response> makeRequest() async {
      try {
        return await _httpClient
            .post(
              uri,
              headers: await _getHeaders(includeAuth: includeAuth),
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(_timeoutDuration);
      } on SocketException {
        throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
      } on HttpException {
        throw Exception('Terjadi kesalahan saat berkomunikasi dengan server.');
      } on FormatException {
        throw Exception('Format data tidak valid.');
      } catch (e) {
        if (e.toString().contains('TimeoutException') || 
            e.toString().contains('timeout')) {
          throw Exception('Request timeout. Silakan coba lagi.');
        }
        rethrow;
      }
    }
    
    final response = await makeRequest();
    return await _handleResponse(response, makeRequest, endpoint);
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    Future<http.Response> makeRequest() async {
      return await http.put(
        uri,
        headers: await _getHeaders(includeAuth: includeAuth),
        body: body != null ? jsonEncode(body) : null,
      );
    }
    
    final response = await makeRequest();
    return await _handleResponse(response, makeRequest, endpoint);
  }

  static Future<http.Response> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    Future<http.Response> makeRequest() async {
      return await http.delete(
        uri,
        headers: await _getHeaders(includeAuth: includeAuth),
      );
    }
    
    final response = await makeRequest();
    return await _handleResponse(response, makeRequest, endpoint);
  }

  static Future<http.StreamedResponse> postMultipart(
    String endpoint,
    http.MultipartRequest request, {
    bool includeAuth = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    headers.remove('Content-Type'); // Let multipart set it
    request.headers.addAll(headers);
    
    final response = await request.send();
    return response;
  }

  static Map<String, dynamic> parseResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static List<dynamic> parseListResponse(http.Response response) {
    if (response.body.isEmpty) {
      return [];
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  /// Parser mentah dari JSON string (tanpa memerlukan http.Response),
  /// berguna untuk multipart response.
  static Map<String, dynamic> parseRawJson(String body) {
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

}

