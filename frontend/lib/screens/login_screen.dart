import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../models/auth_model.dart';
import '../widgets/password_field.dart';
import '../widgets/loading_button.dart';
import '../utils/validators.dart';
import '../utils/biometric_preferences.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
    // Check biometric availability and previous login
    context.read<AuthBloc>().add(const AuthCheckBiometricAvailability());
    context.read<AuthBloc>().add(const AuthCheckPreviousLogin());
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await BiometricPreferences.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    context.read<AuthBloc>().add(AuthLogin(request));
  }

  void _loginWithBiometric() {
    context.read<AuthBloc>().add(const AuthLoginWithBiometric());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          // Tampilkan error message yang lebih user-friendly
          String errorMessage = state.message.trim();
          
          // Clean up error message
          if (errorMessage.contains('Exception: ')) {
            errorMessage = errorMessage.replaceFirst('Exception: ', '').trim();
          }
          
          // Custom messages untuk error umum
          final lowerMessage = errorMessage.toLowerCase();
          if (lowerMessage.contains('invalid') || 
              lowerMessage.contains('incorrect') ||
              lowerMessage.contains('wrong') ||
              lowerMessage.contains('email atau password salah') ||
              lowerMessage.contains('unauthorized') ||
              lowerMessage.contains('forbidden') ||
              lowerMessage.contains('login failed') ||
              lowerMessage.contains('authentication failed') ||
              lowerMessage.contains('credentials')) {
            errorMessage = 'Email atau password salah. Silakan coba lagi.';
          } else if (lowerMessage.contains('network') ||
                     lowerMessage.contains('connection') ||
                     lowerMessage.contains('timeout') ||
                     lowerMessage.contains('failed host lookup') ||
                     lowerMessage.contains('socket')) {
            errorMessage = 'Koneksi gagal. Periksa koneksi internet Anda.';
          } else if (errorMessage.isEmpty || 
                     errorMessage == 'null' || 
                     errorMessage.toLowerCase() == 'exception') {
            errorMessage = 'Email atau password salah. Silakan coba lagi.';
          }
          
          // Pastikan context masih mounted sebelum menampilkan error
          if (mounted && context.mounted) {
            // Tampilkan error langsung
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }
        } else if (state is AuthAuthenticated) {
          // Show success message
          if (mounted && context.mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login berhasil!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }
          // AuthWrapper will automatically navigate to MainNavigationScreen via BlocBuilder
        } else if (state is AuthBiometricAvailable) {
          // Set email if available
          if (state.lastLoginEmail != null && 
              _emailController.text.isEmpty && 
              mounted) {
            _emailController.text = state.lastLoginEmail!;
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final biometricState = state is AuthBiometricAvailable
            ? state
            : null;
        final hasPreviousLogin = biometricState?.hasPreviousLogin ?? false;
        
        // Tampilkan error juga di builder untuk memastikan error terlihat
        if (state is AuthError && mounted && context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              String errorMessage = state.message.trim();
              if (errorMessage.contains('Exception: ')) {
                errorMessage = errorMessage.replaceFirst('Exception: ', '').trim();
              }
              final lowerMessage = errorMessage.toLowerCase();
              if (lowerMessage.contains('invalid') || 
                  lowerMessage.contains('incorrect') ||
                  lowerMessage.contains('wrong') ||
                  lowerMessage.contains('email atau password salah') ||
                  lowerMessage.contains('unauthorized') ||
                  lowerMessage.contains('forbidden') ||
                  lowerMessage.contains('login failed') ||
                  lowerMessage.contains('authentication failed') ||
                  lowerMessage.contains('credentials')) {
                errorMessage = 'Email atau password salah. Silakan coba lagi.';
              } else if (lowerMessage.contains('network') ||
                         lowerMessage.contains('connection') ||
                         lowerMessage.contains('timeout') ||
                         lowerMessage.contains('failed host lookup') ||
                         lowerMessage.contains('socket')) {
                errorMessage = 'Koneksi gagal. Periksa koneksi internet Anda.';
              } else if (errorMessage.isEmpty || 
                         errorMessage == 'null' || 
                         errorMessage.toLowerCase() == 'exception') {
                errorMessage = 'Email atau password salah. Silakan coba lagi.';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 400),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header with icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 48,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Welcome Back',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to your account',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'your.email@example.com',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: theme.colorScheme.primary,
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.error,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                  ),
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 20),
                                // Password field
                                PasswordField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  validator: Validators.password,
                                ),
                                const SizedBox(height: 32),
                                // Submit button
                                LoadingButton(
                                  onPressed: _login,
                                  isLoading: isLoading,
                                  text: 'Sign In',
                                ),
                                // Biometric login section (Android only)
                                if (Platform.isAndroid && 
                                    (biometricState?.isAvailable ?? false) && 
                                    hasPreviousLogin &&
                                    _biometricEnabled) ...[
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'atau',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  LoadingButton(
                                    onPressed: _loginWithBiometric,
                                    isLoading: isLoading,
                                    text: 'Login dengan Sidik Jari',
                                    icon: Icons.fingerprint,
                                    isOutlined: true,
                                  ),
                                ],
                                const SizedBox(height: 32),
                                // Footer
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
       },
     );
   }
 }
