import 'dart:async';
import 'package:flutter/material.dart';

class TransitionLoadingScreen extends StatefulWidget {
  final Widget targetPage;
  const TransitionLoadingScreen({super.key, required this.targetPage});

  @override
  State<TransitionLoadingScreen> createState() => _TransitionLoadingScreenState();
}

class _TransitionLoadingScreenState extends State<TransitionLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a short loading delay for professional feel
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.targetPage),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 80,
              errorBuilder: (context, error, stack) => Icon(Icons.fitness_center, color: const Color(0xFF2D6A4F), size: 50),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              color: const Color(0xFF2D6A4F),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing your dashboard...',
              style: TextStyle(
                color: const Color(0xFF2D6A4F),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
