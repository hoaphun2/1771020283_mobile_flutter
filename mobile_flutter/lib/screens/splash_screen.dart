// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/providers/auth_provider.dart';
import 'package:mobile_flutter/screens/login_screen.dart';
import 'package:mobile_flutter/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Sử dụng WidgetsBinding để đảm bảo context được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.token != null && authProvider.currentUser != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_tennis,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'CLB Pickleball\nVọt Thủ Phổ Núi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}