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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _hasUser = false;
  bool _ready = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _initialize();
  }

  Future<void> _initialize() async {
    final storage = StorageService();
    await storage.init();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _hasUser = !storage.isFirstLaunch();
        _ready = true;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _hasUser
          ? const AppShell()
          : const OnboardingScreen(),
    );
  }
}
