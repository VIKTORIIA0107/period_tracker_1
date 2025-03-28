import 'package:flutter/material.dart';
import 'registration_screen.dart';

/// OnboardingScreen collects initial cycle data from the user
/// Uses a step-by-step process to gather period information before registration
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Current step index in the onboarding process
  int _currentStep = 0;

  // Default values for period tracking parameters
  int _periodLength = 5;
  int _cycleLength = 28;
  DateTime _dateOfBirth = DateTime.now();
  DateTime _lastPeriodStartDate = DateTime.now();

  /// Builds a horizontal scrollable number selector
  Widget _buildNumberSelector(
    int min, // - min: Minimum selectable number
    int max, // - max: Maximum selectable number
    String unit, // - unit: Unit of measurement (e.g., 'days')
    bool
    isPeriodLength, // - isPeriodLength: Flag to determine if selecting period length or cycle length
  ) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: max - min + 1,
        itemBuilder: (context, index) {
          final number = min + index;
          final value = number;

          // Check if this number is currently selected
          final isSelected =
              isPeriodLength ? _periodLength == value : _cycleLength == value;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  // Update the appropriate state variable based on selection
                  if (isPeriodLength) {
                    _periodLength = value;
                  } else {
                    _cycleLength = value;
                  }
                });
              },
              // Style the button differently if selected
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSelected ? Theme.of(context).primaryColor : null,
                foregroundColor: isSelected ? Colors.white : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(60, 50),
              ),
              child: Text('$number', style: const TextStyle(fontSize: 18)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Questions')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => RegistrationScreen(
                      // Pass all collected data to the registration screen
                      periodLength: _periodLength,
                      cycleLength: _cycleLength,
                      dateOfBirth: _dateOfBirth,
                      lastPeriodStartDate: _lastPeriodStartDate,
                    ),
              ),
            );
          }
        },

        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },

        // Define the steps in the onboarding process
        steps: [
          // Step 1: Period Length Selection
          Step(
            title: const Text('What is your average period length?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select number of days:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 9),
                _buildNumberSelector(1, 9, 'days', true),
                const SizedBox(height: 9),
                // Display the currently selected value
                Text(
                  'Selected: $_periodLength',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Step 2: Cycle Length Selection
          Step(
            title: const Text('What is your average cycle length?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select number of days:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 9),
                // Range covers most common cycle lengths
                _buildNumberSelector(21, 35, 'days', false),
                const SizedBox(height: 9),
                // Display the currently selected value
                Text(
                  'Selected: $_cycleLength',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Step 3: Date of Birth Selection
          Step(
            title: const Text('Enter your date of birth'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      // Default to 20 years ago as initial selection
                      initialDate: DateTime.now().subtract(
                        const Duration(days: 365 * 20),
                      ),
                      firstDate: DateTime(
                        1900,
                      ), // Reasonable minimum birth year
                      lastDate: DateTime.now(), // Can't be born in the future
                    );
                    // Update state if a date was selected
                    if (date != null) setState(() => _dateOfBirth = date);
                  },
                  child: const Text('Select Date'),
                ),
                const SizedBox(height: 9),
                // Display the currently selected date
                Text(
                  'Selected date: ${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Step 4: Last Period Start Date Selection
          Step(
            title: const Text('When did your last period start?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(), // Default to today
                      // Allow selection from up to 2 years ago
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365 * 2),
                      ),
                      lastDate: DateTime.now(),
                    );
                    // Update state if a date was selected
                    if (date != null) {
                      setState(() => _lastPeriodStartDate = date);
                    }
                  },
                  child: const Text('Select Date'),
                ),
                const SizedBox(height: 9),
                // Display the currently selected date
                Text(
                  'Selected date: ${_lastPeriodStartDate.day}/${_lastPeriodStartDate.month}/${_lastPeriodStartDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
