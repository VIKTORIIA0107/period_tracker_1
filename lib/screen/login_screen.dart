import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';

/// LoginScreen widget that handles user authentication
/// Provides UI for users to enter their credentials and sign in
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the text input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables to manage UI states
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the login process using Firebase Authentication
  /// Validates form, authenticates user, and navigates to dashboard if successful
  Future<void> _handleLogin() async {
    // Only proceed if form validation passes
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      setState(() => _isLoading = true);

      try {
        // Attempt to sign in with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

        // Check if user authentication was successful
        User? user = userCredential.user;
        if (user != null) {
          // Navigate to the dashboard if login was successful
          // Replace the current screen with the dashboard to prevent going back
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DashboardScreen(
                    email: user.email!,
                    // Default period and cycle values
                    periodLength: 5,
                    cycleLength: 28,
                    // Default date of birth (20 years ago)
                    dateOfBirth: DateTime.now().subtract(
                      const Duration(days: 365 * 20),
                    ),
                    // Default last period date (15 days ago)
                    lastPeriodDate: DateTime.now().subtract(
                      const Duration(days: 15),
                    ),
                  ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Handle different authentication errors with appropriate messages
        String errorMessage = 'Login failed';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided for that user.';
        }
        // Show error message to the user
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        // Allows scrolling if the screen is too small for the content
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            // Form with validation capabilities
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                // Email input field with validation
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType:
                      TextInputType.emailAddress, // Shows email keyboard
                  validator:
                      (value) => value!.isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),

                // Password input field with validation
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    // Button to show/hide password
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                    ),
                  ),
                  obscureText:
                      !_isPasswordVisible, // Hide text when not visible
                  validator:
                      (value) => value!.isEmpty ? 'Enter your password' : null,
                ),
                const SizedBox(height: 8),

                // Forgot password button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Login button or loading indicator
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.pink),
                    )
                    : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                const SizedBox(height: 16),

                // Sign up redirect for new users
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
