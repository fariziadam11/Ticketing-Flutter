import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometrics are available (enrolled)
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;

      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication successful, false otherwise
  /// Throws exception with error message if there's an error
  static Future<bool> authenticate({
    String localizedReason = 'Please authenticate to login',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication is not available on this device');
      }
      
      final didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: false, // Allow fallback to device credentials (PIN/Pattern)
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric Login',
            cancelButton: 'Batal',
            biometricHint: 'Sentuh sensor sidik jari',
            biometricNotRecognized: 'Sidik jari tidak dikenali. Coba lagi.',
            biometricSuccess: 'Berhasil',
            deviceCredentialsRequiredTitle: 'Kredensial Perangkat Diperlukan',
            deviceCredentialsSetupDescription: 'Gunakan PIN atau Pattern untuk autentikasi',
          ),
        ],
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      // Handle platform-specific errors
      String errorMessage = 'Terjadi kesalahan saat autentikasi';
      
      // Check error code (case-insensitive untuk kompatibilitas)
      final errorCode = e.code.toLowerCase();
      
      if (errorCode == 'notavailable') {
        errorMessage = 'Autentikasi biometric tidak tersedia di perangkat ini';
        throw Exception(errorMessage);
      } else if (errorCode == 'notenrolled') {
        errorMessage = 'Belum ada sidik jari yang terdaftar. Silakan daftarkan sidik jari di pengaturan perangkat';
        throw Exception(errorMessage);
      } else if (errorCode == 'lockedout' || errorCode == 'permanentlylockedout') {
        errorMessage = 'Autentikasi biometric terkunci. Silakan coba lagi nanti atau gunakan PIN/Pattern';
        throw Exception(errorMessage);
      } else if (errorCode == 'usercancel' || errorCode == 'user_cancel') {
        // User membatalkan, jangan throw exception, return false
        return false;
      } else {
        // Error lainnya
        errorMessage = 'Error: ${e.message ?? e.code}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Re-throw jika sudah Exception, atau wrap dalam Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Stop authentication (if in progress)
  static Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      // Ignore errors
    }
  }
}

