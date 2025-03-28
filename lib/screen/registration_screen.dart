import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

/// RegistrationScreen handles user registration with a multi-step form process
/// Collects user data and creates an account in Firebase
class RegistrationScreen extends StatefulWidget {
  // Required parameters for period tracking functionality
  final int periodLength; // Length of period in days
  final int cycleLength; // Length of menstrual cycle in days
  final DateTime dateOfBirth; // User's date of birth
  final DateTime lastPeriodStartDate; // Date when the last period started

  // Constructor requiring all period tracking parameters
  const RegistrationScreen({
    super.key,
    required this.periodLength,
    required this.cycleLength,
    required this.dateOfBirth,
    required this.lastPeriodStartDate,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for user input fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variable to store the last period date (initialized in initState)
  late DateTime _lastPeriodDate;

  // Track the current step in the registration process (0: name, 1: email, 2: password)
  int _currentStep = 0;

  // Password visibility
  bool _isPasswordVisible = false;

  // Error message variables for name and email validation
  String? _emailError;
  String? _nameError;

  // Firebase Auth instance for user registration
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore instance for storing additional user data
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Initialize last period date from the widget property
    _lastPeriodDate = widget.lastPeriodStartDate;
  }

  // Regular expression for validating email format
  final RegExp _emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

  // Regular expression for password validation (at least 8 characters and 1 symbol)
  final RegExp _passwordRegExp = RegExp(r'^(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$');

  /// Validates email format
  /// Returns null if valid, or an error message if invalid
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password requirements
  /// Checks for minimum length and special character requirements
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long and contain at least one symbol';
    }
    if (!_passwordRegExp.hasMatch(value)) {
      return 'Please enter a valid password';
    }
    return null;
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles user registration with Firebase Auth and Firestore
  /// Creates a new user account and stores additional user data
  Future<void> _registerUser() async {
    try {
      // Create user with email and password in Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

      // After successful registration, store additional user data in Firestore
      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'email': user.email,
          'dateOfBirth': widget.dateOfBirth,
          'lastPeriodStartDate': _lastPeriodDate,
          'periodLength': widget.periodLength,
          'cycleLength': widget.cycleLength,
        });
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors with a dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Registration Failed'),
              content: Text(
                e.message ?? 'An error occurred during registration',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCurrentStep()),
              const SizedBox(height: 20),
              // Next/Register button at the bottom
              ElevatedButton(
                onPressed: () async {
                  if (_currentStep < 2) {
                    if (_validateCurrentStep()) {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  } else {
                    // Final step (password), validate and submit registration
                    if (_formKey.currentState!.validate()) {
                      // Register user with Firebase
                      await _registerUser();

                      // After successful registration, navigate to Dashboard
                      // Remove all previous routes so user can't go back to registration
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DashboardScreen(
                                name: _nameController.text,
                                email: _emailController.text,
                                periodLength: widget.periodLength,
                                cycleLength: widget.cycleLength,
                                dateOfBirth: widget.dateOfBirth,
                                lastPeriodDate: _lastPeriodDate,
                              ),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
                child: Text(_currentStep < 2 ? 'Next' : 'Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Validates the current step before proceeding to the next
  /// Returns true if validation passes, false otherwise
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.isEmpty) {
          setState(() {
            _nameError = 'Please enter your name';
          });
          return false;
        }
        return true;
      case 1:
        final emailError = _validateEmail(_emailController.text);
        setState(() {
          _emailError = emailError;
        });
        return emailError == null;
      default:
        return true;
    }
  }

  /// Returns the appropriate widget for the current registration step
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildPasswordStep();
      default:
        return Container();
    }
  }

  /// Builds the UI for the name input step (first step)
  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your name',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            errorText: _nameError,
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            setState(() {
              _nameError = value.isEmpty ? 'Please enter your name' : null;
            });
          },
        ),
      ],
    );
  }

  /// Builds the UI for the email input step (second step)
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your email (e.g. hey@gmail.com)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 8),
        // Explanation text
        Text(
          'To make sure you do not lose your data and can use the app on any device please create an account',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 40),
        // Email input field
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'E-mail',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            errorText: _emailError, // Show error if validation fails
          ),
          keyboardType: TextInputType.emailAddress, // Show email keyboard
          textInputAction: TextInputAction.next,
          // Real-time validation as user types
          onChanged: (value) {
            setState(() {
              _emailError = _validateEmail(value);
            });
          },
        ),
        const SizedBox(height: 16),
        // Privacy reassurance text
        Text(
          'Keeping your account and information safe is our top priority and we promise never to spam you with unsolicited e-mails!',
          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
        ),
      ],
    );
  }

  /// Builds UI for the password input step (final step)
  Widget _buildPasswordStep() {
    return Form(
      key: _formKey, // Form key for validation
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          // Password requirements explanation
          const Text(
            'The length should be at least 8 symbols and contain at least one symbol',
            style: TextStyle(fontSize: 14, color: Colors.pink),
          ),
          const SizedBox(height: 40),
          // Password input field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              // Toggle button for password visibility
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            obscureText: !_isPasswordVisible, // Hide password when not visible
            validator: _validatePassword, // Use validator function
            onFieldSubmitted: (value) {
              setState(() {
                _passwordController.text = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
