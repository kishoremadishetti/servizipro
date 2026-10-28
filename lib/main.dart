import 'package:flutter/material.dart';
import 'core/environment.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Select environment at build/run time:
  //   flutter run --dart-define=ENV=test
  //   flutter run --dart-define=ENV=qa
  //   flutter run --dart-define=ENV=prod
  const envName = String.fromEnvironment('ENV', defaultValue: 'test');
  final env = switch (envName.toLowerCase()) {
    'prod' => Environment.prod,
    'qa' => Environment.qa,
    _ => Environment.test,
  };
  EnvironmentConfig.init(env);

  runApp(const ServiziproApp());
}

class ServiziproApp extends StatelessWidget {
  const ServiziproApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EnvironmentConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
