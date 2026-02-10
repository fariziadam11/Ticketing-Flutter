import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Centralized error handling utility
class ErrorHandler {
  ErrorHandler._(); // Private constructor

  /// Show error snackbar
  static void showError(
    BuildContext context,
    dynamic error, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    String message;
    if (error is String) {
      message = error;
    } else {
      final errorString = error.toString();
      // Remove "Exception: " prefix if present
      message = errorString.replaceFirst(RegExp(r'^Exception:\s*'), '');
      
      // Use default message if error is not informative
      if (message.isEmpty || message == errorString) {
        message = AppConstants.errorUnknown;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration ?? AppConstants.snackBarDuration,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration ?? AppConstants.snackBarDuration,
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: duration ?? AppConstants.snackBarDuration,
      ),
    );
  }

  /// Show warning snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: duration ?? AppConstants.longSnackBarDuration,
      ),
    );
  }
}

