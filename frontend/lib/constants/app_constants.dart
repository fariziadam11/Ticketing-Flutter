/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // API Configuration
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;
  
  // Ticket Defaults
  static const int defaultSourceId = 2;
  static const int defaultCreatorId = 157;
  static const int defaultCustomerId = 157;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;
  static const double cardPadding = 16.0;
  static const double buttonHeight = 48.0;
  
  // Timeouts
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration longSnackBarDuration = Duration(seconds: 4);
  
  // Error Messages
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorUnknown = 'An unexpected error occurred. Please try again.';
  static const String errorLogin = 'Login failed. Please check your credentials.';
  static const String errorRegister = 'Registration failed. Please try again.';
  static const String errorLoadData = 'Failed to load data. Please try again.';
  
  // Success Messages
  static const String successLogin = 'Login successful';
  static const String successRegister = 'Registration successful';
  static const String successTicketCreated = 'Ticket created successfully';
  static const String successTicketUpdated = 'Ticket updated successfully';
}

