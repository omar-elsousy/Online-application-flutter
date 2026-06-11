import 'package:flutter/material.dart';

import 'controllers/app_scope.dart';
import 'controllers/app_state.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MansourApp(state: AppState()));
}

class MansourApp extends StatelessWidget {
  const MansourApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Mansour',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: state.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
