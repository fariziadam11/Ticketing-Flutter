import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../models/auth_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLoginWithBiometric>(_onLoginWithBiometric);
    on<AuthLogout>(_onLogout);
    on<AuthRefreshToken>(_onRefreshToken);
    on<AuthCheckBiometricAvailability>(_onCheckBiometricAvailability);
    on<AuthCheckPreviousLogin>(_onCheckPreviousLogin);

    // Auto-check authentication status on initialization
    // This ensures the app checks for stored tokens when it starts
    add(const AuthCheckStatus());
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // Tambahkan sedikit delay untuk memastikan SharedPreferences sudah siap
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      // Cek apakah token tersimpan
      final token = await _authService.getToken();
      final userEmail = await _authService.getUserEmail();
      final userName = await _authService.getUserName();

      if (token != null && token.isNotEmpty) {
        // Token ada, ambil user info dan set authenticated
        // Token akan divalidasi otomatis oleh ApiClient saat ada API call
        // Jika token expired, ApiClient akan auto-refresh menggunakan refresh token
        final userLastName = await _authService.getUserLastName();

        // Pastikan user info juga tersimpan
        if (userEmail != null && userEmail.isNotEmpty) {
          final authState = AuthAuthenticated(
            authResponse: AuthResponse(
              token: token,
              name: userName ?? '',
              lastname: userLastName ?? '',
              email: userEmail,
            ),
            userName: userName,
            userEmail: userEmail,
          );

          emit(authState);
        } else {
          // Token ada tapi user info tidak ada, kemungkinan data corrupt
          // Clear dan minta login lagi
          await _authService.logout();
          emit(const AuthUnauthenticated());
        }
      } else {
        // Tidak ada token, user belum login
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      // Jika ada error saat cek status, anggap user tidak authenticated
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final authResponse = await _authService.login(event.request);
      final userName = await _authService.getUserName();
      final userEmail = await _authService.getUserEmail();
      emit(
        AuthAuthenticated(
          authResponse: authResponse,
          userName: userName,
          userEmail: userEmail,
        ),
      );
    } catch (e) {
      // Extract meaningful error message
      String errorMessage = e.toString();

      // Clean up error message
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '').trim();
      }

      errorMessage = errorMessage.trim();

      // If error is empty or generic, provide default message
      if (errorMessage.isEmpty ||
          errorMessage == 'null' ||
          errorMessage.toLowerCase() == 'exception' ||
          errorMessage.toLowerCase().contains('login failed')) {
        errorMessage = 'Email atau password salah. Silakan coba lagi.';
      }

      // Ensure error message is not empty before emitting
      final finalMessage = errorMessage.isNotEmpty
          ? errorMessage
          : 'Email atau password salah. Silakan coba lagi.';

      // Always emit error state
      emit(AuthError(finalMessage));
    }
  }

  Future<void> _onRegister(AuthRegister event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final authResponse = await _authService.register(event.request);
      final userName = await _authService.getUserName();
      final userEmail = await _authService.getUserEmail();
      emit(
        AuthAuthenticated(
          authResponse: authResponse,
          userName: userName,
          userEmail: userEmail,
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoginWithBiometric(
    AuthLoginWithBiometric event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Authenticate with biometric first
      final authenticated = await BiometricService.authenticate(
        localizedReason:
            'Gunakan sidik jari untuk login ke aplikasi Werk Ticketing',
      );

      if (!authenticated) {
        // User membatalkan autentikasi
        emit(const AuthUnauthenticated());
        return;
      }

      // Try refresh token first
      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await _authService.refreshToken(refreshToken);
          final userName = await _authService.getUserName();
          final userEmail = await _authService.getUserEmail();
          emit(
            AuthAuthenticated(
              authResponse: AuthResponse(
                token: await _authService.getToken() ?? '',
                name: userName ?? '',
                lastname: await _authService.getUserLastName() ?? '',
                email: userEmail ?? '',
              ),
              userName: userName,
              userEmail: userEmail,
            ),
          );
          return;
        } catch (e) {
          // Refresh failed, try login with saved credentials
        }
      }

      // Try login with saved credentials
      try {
        final authResponse = await _authService.loginWithBiometricCredentials();
        final userName = await _authService.getUserName();
        final userEmail = await _authService.getUserEmail();
        emit(
          AuthAuthenticated(
            authResponse: authResponse,
            userName: userName,
            userEmail: userEmail,
          ),
        );
      } catch (e) {
        emit(const AuthError('Session expired. Silakan login dengan password'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authService.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRefreshToken(
    AuthRefreshToken event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authResponse = await _authService.refreshToken(event.refreshToken);
      final userName = await _authService.getUserName();
      final userEmail = await _authService.getUserEmail();
      emit(
        AuthAuthenticated(
          authResponse: authResponse,
          userName: userName,
          userEmail: userEmail,
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckBiometricAvailability(
    AuthCheckBiometricAvailability event,
    Emitter<AuthState> emit,
  ) async {
    if (Platform.isAndroid) {
      final isAvailable = await BiometricService.isBiometricAvailable();
      final hasPrevious = await _authService.hasPreviousLogin();
      final lastEmail = await _authService.getLastLoginEmail();
      emit(
        AuthBiometricAvailable(
          isAvailable: isAvailable,
          hasPreviousLogin: hasPrevious,
          lastLoginEmail: lastEmail,
        ),
      );
    } else {
      emit(
        const AuthBiometricAvailable(
          isAvailable: false,
          hasPreviousLogin: false,
        ),
      );
    }
  }

  Future<void> _onCheckPreviousLogin(
    AuthCheckPreviousLogin event,
    Emitter<AuthState> emit,
  ) async {
    final hasPrevious = await _authService.hasPreviousLogin();
    if (hasPrevious) {
      final credentials = await _authService.getBiometricCredentials();
      final email =
          credentials?['email'] ?? await _authService.getLastLoginEmail();
      emit(
        AuthBiometricAvailable(
          isAvailable: Platform.isAndroid,
          hasPreviousLogin: true,
          lastLoginEmail: email,
        ),
      );
    }
  }
}
