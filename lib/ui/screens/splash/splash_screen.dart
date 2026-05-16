import 'dart:async';
import 'package:flutter/material.dart';
import 'package:birdle/data/services/storage_service.dart';
import 'package:birdle/ui/screens/onboarding/onboarding_screen.dart';
import 'package:birdle/ui/screens/app_shell/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final storage = StorageService();
    await storage.init();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _hasUser = !storage.isFirstLaunch();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasUser) {
      return const OnboardingScreen();
    }
    return const AppShell();
  }
}
