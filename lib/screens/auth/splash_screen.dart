import 'package:flutter/material.dart';
import 'phone_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1B3A6B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bloodtype, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text('RaktSetu', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 6),
            Text('Every donor, every drop, connected.',
                style: TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
