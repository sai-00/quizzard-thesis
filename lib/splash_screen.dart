import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Remove all previous routes and push the profile screen so no back button is shown
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/quizzard_logo.PNG',
          width: 280,
          height: 280,
          fit: BoxFit.contain,
          semanticLabel: 'Quizzard logo',
        ),
      ),
    );
  }
}
