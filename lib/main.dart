import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = await AppState.load();
  runApp(ChangeNotifierProvider.value(value: appState, child: const WalnutFarmApp()));
}

class WalnutFarmApp extends StatelessWidget {
  const WalnutFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'Walnut Farm',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: !state.initialized
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : state.logged
              ? MainShell(key: ValueKey(state.userEmail))
              : AuthScreen(onLogin: (email, refCode) => state.login(email, refCode)),
    );
  }
}
