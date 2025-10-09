import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // After a short delay navigate to login
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'SU',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logo,
              const SizedBox(height: 20),
              const Text(
                'SettleUp',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Split bills, settle faster',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
