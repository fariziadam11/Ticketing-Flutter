import 'package:shared_preferences/shared_preferences.dart';

/// Utility untuk menyimpan preferensi biometric login
class BiometricPreferences {
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Cek apakah biometric login enabled
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? true; // Default: enabled
  }

  /// Enable biometric login
  static Future<void> enableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
  }

  /// Disable biometric login
  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
  }

  /// Toggle biometric login
  static Future<bool> toggleBiometric() async {
    final current = await isBiometricEnabled();
    if (current) {
      await disableBiometric();
      return false;
    } else {
      await enableBiometric();
      return true;
    }
  }
}

