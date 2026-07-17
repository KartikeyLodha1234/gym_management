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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2D6A4F),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Initializing your dashboard...',
              style: TextStyle(
                color: Color(0xFF2D6A4F),
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
