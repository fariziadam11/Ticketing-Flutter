import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learnflutter/blocs/auth/auth_state.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/ticket/ticket_bloc.dart';
import 'blocs/article/article_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/carbon_theme.dart';

void main() {
  // Optimasi untuk performa
  WidgetsFlutterBinding.ensureInitialized();

  // Disable debug banner di release
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc tetap ada untuk digunakan oleh login screen dan screen lainnya
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(create: (context) => TicketBloc()),
        BlocProvider(create: (context) => ArticleBloc()),
      ],
      child: MaterialApp(
        title: 'Werk Ticketing',
        debugShowCheckedModeBanner: false,
        theme: CarbonTheme.light(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show loading for initial state or explicit loading
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show main app if authenticated
        if (state is AuthAuthenticated) {
          return const MainNavigationScreen();
        }

        // Show login screen for unauthenticated or error states
        return const LoginScreen();
      },
    );
  }
}
