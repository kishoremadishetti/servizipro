import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'dashboard_screen.dart';
import 'registration_screen.dart';

/// Decides where to land the user: Registration (first-time / logged out)
/// or Dashboard (already verified previously).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    final isRegistered = await StorageService().isRegistered();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => isRegistered ? const DashboardScreen() : const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
