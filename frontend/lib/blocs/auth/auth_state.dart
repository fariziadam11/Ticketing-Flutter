import 'package:equatable/equatable.dart';
import '../../models/auth_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthResponse authResponse;
  final String? userName;
  final String? userEmail;

  const AuthAuthenticated({
    required this.authResponse,
    this.userName,
    this.userEmail,
  });

  @override
  List<Object?> get props => [authResponse, userName, userEmail];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthBiometricAvailable extends AuthState {
  final bool isAvailable;
  final bool hasPreviousLogin;
  final String? lastLoginEmail;

  const AuthBiometricAvailable({
    required this.isAvailable,
    required this.hasPreviousLogin,
    this.lastLoginEmail,
  });

  @override
  List<Object?> get props => [isAvailable, hasPreviousLogin, lastLoginEmail];
}

