import 'package:equatable/equatable.dart';
import '../../models/auth_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

class AuthLogin extends AuthEvent {
  final LoginRequest request;

  const AuthLogin(this.request);

  @override
  List<Object?> get props => [request];
}

class AuthRegister extends AuthEvent {
  final RegisterRequest request;

  const AuthRegister(this.request);

  @override
  List<Object?> get props => [request];
}

class AuthLoginWithBiometric extends AuthEvent {
  const AuthLoginWithBiometric();
}

class AuthLogout extends AuthEvent {
  const AuthLogout();
}

class AuthRefreshToken extends AuthEvent {
  final String refreshToken;

  const AuthRefreshToken(this.refreshToken);

  @override
  List<Object?> get props => [refreshToken];
}

class AuthCheckBiometricAvailability extends AuthEvent {
  const AuthCheckBiometricAvailability();
}

class AuthCheckPreviousLogin extends AuthEvent {
  const AuthCheckPreviousLogin();
}

