import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:periodtracker_1/firebase_options.dart';
import 'screen/welcome_screen.dart';
import 'screen/registration_screen.dart';
import 'screen/login_screen.dart';
import 'screen/dashboard_screen.dart';

// Main entry point of the application
// The function is marked as async to allow for Firebase initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PeriodTrackerApp());
}

// Root widget of the application (stateless as it doesn't need to maintain state)
class PeriodTrackerApp extends StatelessWidget {
  const PeriodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Period Tracker', // Application title

      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25), // Rounded corners
            ),
          ),
        ),

        // Style for outlined buttons
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.pink,
            side: const BorderSide(color: Colors.pink),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),

      // Home screen with authentication state management
      home: StreamBuilder<User?>(
        // Listen to Firebase authentication state changes
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Check if authentication state connection is active
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              // Navigate to dashboard with default parameters
              return DashboardScreen(
                periodLength: 5, // Default period length in days
                cycleLength: 28, // Default cycle length in days
                dateOfBirth: DateTime.now(),
                lastPeriodDate: DateTime.now().subtract(
                  const Duration(days: 15),
                ),
              );
            } else {
              // If not logged in, show welcome screen
              return const WelcomeScreen();
            }
          }
          // Show loading indicator while waiting for authentication state
          return const Center(child: CircularProgressIndicator());
        },
      ),

      // Named routes for navigation
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/register':
            (context) => RegistrationScreen(
              // Default parameters for registration
              periodLength: 5,
              cycleLength: 28,
              dateOfBirth: DateTime.now(),
              lastPeriodStartDate: DateTime.now().subtract(
                const Duration(days: 15),
              ),
            ),
        '/login': (context) => const LoginScreen(),
        '/dashboard':
            (context) => DashboardScreen(
              // Default parameters for dashboard
              periodLength: 5,
              cycleLength: 28,
              dateOfBirth: DateTime.now(),
              lastPeriodDate: DateTime.now().subtract(const Duration(days: 15)),
            ),
      },
    );
  }
}
