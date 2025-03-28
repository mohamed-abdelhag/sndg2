import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Landing Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Welcome to the Sandoog App!'),
            ElevatedButton(
              onPressed: () {
                // Add navigation logic here if needed
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
} 