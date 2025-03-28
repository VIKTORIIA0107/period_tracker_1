import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

/// WelcomeScreen is the initial screen users when opening the app
/// It provides options to start the onboarding process or login
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Period Tracker!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To make predictions accurate please answer a few questions.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              // Primary action button to start onboarding
              ElevatedButton(
                onPressed: () {
                  // Navigate to OnboardingScreen with a new route
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen(),
                    ),
                  );
                },
                child: const Text('Start'),
              ),
              const SizedBox(height: 16),
              // Secondary action button for existing users
              TextButton(
                onPressed: () {
                  // Navigate to LoginScreen with a new route
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('LOG IN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
