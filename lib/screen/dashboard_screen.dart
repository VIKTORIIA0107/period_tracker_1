import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'calendar_view_screen.dart';
import 'symptoms_screen.dart';
import 'settings_screen.dart';
import 'cycle_progress_widget.dart';
import 'cycle_utils.dart';
import 'dashboard_dialogs.dart';

/// DashboardScreen is the main screen of the period tracking app
/// Displays cycle information, phase details, symptoms, and provides navigation
class DashboardScreen extends StatefulWidget {
  final String? name;
  final String? email;
  final int periodLength;
  final int cycleLength;
  final DateTime dateOfBirth;
  final DateTime lastPeriodDate;
  final List<String>? loggedSymptoms; // Add a parameter for logged symptoms
  final String? symptomNotes; // Add a parameter for symptom notes

  const DashboardScreen({
    super.key,
    this.name,
    this.email,
    required this.periodLength,
    required this.cycleLength,
    required this.dateOfBirth,
    required this.lastPeriodDate,
    this.loggedSymptoms,
    this.symptomNotes,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Start with home/dashboard selected
  bool _showCalendar = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isLoading = true; // Initialize loading state

  // Store user data locally
  List<String>? _loggedSymptoms;
  String? _symptomNotes;
  late DateTime _lastPeriodDate;
  late int _periodLength;
  late int _cycleLength;
  late DateTime _dateOfBirth;

  @override
  void initState() {
    super.initState();
    // Initialize with widget values first
    _lastPeriodDate = widget.lastPeriodDate;
    _periodLength = widget.periodLength;
    _cycleLength = widget.cycleLength;
    _dateOfBirth = widget.dateOfBirth;
    _loggedSymptoms = widget.loggedSymptoms;
    _symptomNotes = widget.symptomNotes;

    // Then load from Firestore
    _loadUserDataFromFirestore();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _loadUserDataFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        // Getting data from Firestore
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final data = snapshot.data()!;

          // Loading all user data from Firestore
          setState(() {
            if (data['loggedSymptoms'] != null) {
              _loggedSymptoms = List<String>.from(data['loggedSymptoms']);
            }

            if (data['symptomNotes'] != null) {
              _symptomNotes = data['symptomNotes'];
            }

            // Update period info from Firestore if available
            if (data['lastPeriodStartDate'] != null) {
              _lastPeriodDate =
                  (data['lastPeriodStartDate'] as Timestamp).toDate();
            }

            if (data['periodLength'] != null) {
              _periodLength = data['periodLength'];
            }

            if (data['cycleLength'] != null) {
              _cycleLength = data['cycleLength'];
            }

            if (data['dateOfBirth'] != null) {
              _dateOfBirth = (data['dateOfBirth'] as Timestamp).toDate();
            }

            _isLoading = false; // Completing the loading
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Finishing the loading process in case of an error
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Calculate next period start date based on last period and cycle length
    final DateTime today = DateTime.now();

    // Calculate next period start date
    DateTime nextPeriodStartDate = _lastPeriodDate;
    while (nextPeriodStartDate.isBefore(today)) {
      nextPeriodStartDate = nextPeriodStartDate.add(
        Duration(days: _cycleLength),
      );
    }

    // Calculate previous period start date
    DateTime previousPeriodStartDate = _lastPeriodDate;
    while (previousPeriodStartDate.isAfter(today) ||
        previousPeriodStartDate == today) {
      previousPeriodStartDate = previousPeriodStartDate.subtract(
        Duration(days: _cycleLength),
      );
    }

    // Calculate fertile window (typically 5 days before ovulation and ovulation day)
    final DateTime ovulationDate = nextPeriodStartDate.subtract(
      const Duration(days: 14),
    );
    final DateTime fertileWindowStart = ovulationDate.subtract(
      const Duration(days: 5),
    );
    final DateTime fertileWindowEnd = ovulationDate;

    // Calculate days until next period
    final int daysUntilNextPeriod =
        nextPeriodStartDate.difference(today).inDays;
    // Calculate days until or since ovulation
    final int daysUntilOvulation = ovulationDate.difference(today).inDays;

    // Calculate if currently in period
    final bool isInPeriod =
        today.difference(previousPeriodStartDate).inDays < _periodLength;

    // Calculate if currently in fertile window
    final bool isInFertileWindow =
        today.isAfter(fertileWindowStart.subtract(const Duration(days: 1))) &&
        today.isBefore(fertileWindowEnd.add(const Duration(days: 1)));

    // Calculate cycle day
    final int cycleDay = today.difference(previousPeriodStartDate).inDays + 1;

    // Calculate current cycle phase
    final phaseData = CycleUtils.calculateCyclePhase(
      cycleDay: cycleDay,
      isInPeriod: isInPeriod,
      isInFertileWindow: isInFertileWindow,
      daysUntilOvulation: daysUntilOvulation,
      daysUntilNextPeriod: daysUntilNextPeriod,
    );

    final String currentPhase = phaseData['phase'];
    final Color phaseColor = phaseData['color'];

    return Scaffold(
      body: SafeArea(
        child:
            _showCalendar
                ? // Calendar view when calendar is shown
                CalendarView(
                  cycleLengthDays: _cycleLength,
                  periodLengthDays: _periodLength,
                  lastPeriodDate: _lastPeriodDate,
                  onPeriodDateChanged: (newDate) {
                    // Handle the period date change
                    _handlePeriodDateUpdate(newDate);
                  },
                )
                : // Main dashboard view
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Current date display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${today.day} ${CycleUtils.getMonthName(today.month)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Cycle Day $cycleDay',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: phaseColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Menstrual cycle visualization
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: CycleProgressWidget(
                              cycleLength: _cycleLength,
                              periodLength: _periodLength,
                              currentCycleDay: cycleDay,
                              animation: _animation.value,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Current phase card
                      _buildPhaseCard(
                        context,
                        currentPhase,
                        phaseColor,
                        isInPeriod,
                        isInFertileWindow,
                        _periodLength,
                        today,
                        previousPeriodStartDate,
                        fertileWindowEnd,
                        daysUntilNextPeriod,
                        daysUntilOvulation,
                      ),

                      // Display logged symptoms if available
                      if (_loggedSymptoms != null &&
                          _loggedSymptoms!.isNotEmpty)
                        _buildSymptomsCard(context, phaseColor),
                      const SizedBox(height: 20),

                      // Log/Change Button
                      _buildLogChangeButton(
                        context,
                        phaseColor,
                        previousPeriodStartDate,
                      ),

                      // Add symptoms button for period view
                      _buildAddSymptomsButton(context, phaseColor),

                      // Predicted symptoms for non-period phases when no symptoms are logged
                      if (!isInPeriod &&
                          (_loggedSymptoms == null || _loggedSymptoms!.isEmpty))
                        _buildPredictedSymptomsSection(
                          context,
                          currentPhase,
                          phaseColor,
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) {
              _showCalendar = true;
            } else if (index == 1) {
              _showCalendar = false;
            } else if (index == 2) {
              // Show account options
              _showAccountOptions(context);
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  // Build the phase information card
  Widget _buildPhaseCard(
    BuildContext context,
    String currentPhase,
    Color phaseColor,
    bool isInPeriod,
    bool isInFertileWindow,
    int periodLengthDays,
    DateTime today,
    DateTime previousPeriodStartDate,
    DateTime fertileWindowEnd,
    int daysUntilNextPeriod,
    int daysUntilOvulation,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: phaseColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentPhase,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: phaseColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                CycleUtils.getPhaseDescription(currentPhase),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              isInPeriod
                  ? _buildInfoRow(
                    'Period ends in',
                    '${periodLengthDays - today.difference(previousPeriodStartDate).inDays} days',
                  )
                  : isInFertileWindow
                  ? _buildInfoRow(
                    'Fertile window ends in',
                    '${fertileWindowEnd.difference(today).inDays + 1} days',
                  )
                  : _buildInfoRow(
                    'Next period begins in',
                    '$daysUntilNextPeriod days',
                  ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Next ovulation will start in',
                '$daysUntilOvulation days',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a row with label and value
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Build the symptoms card
  Widget _buildSymptomsCard(BuildContext context, Color phaseColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_information, color: phaseColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Your Logged Symptoms',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: phaseColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _loggedSymptoms!.map((symptom) {
                      return Chip(
                        label: Text(symptom),
                        backgroundColor: phaseColor.withAlpha(51),
                        side: BorderSide(color: phaseColor.withAlpha(128)),
                      );
                    }).toList(),
              ),
              if (_symptomNotes != null && _symptomNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _symptomNotes!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Build the log/change button
  Widget _buildLogChangeButton(
    BuildContext context,
    Color phaseColor,
    DateTime previousPeriodStartDate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        child: ElevatedButton(
          onPressed: () async {
            // Show options for logging
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Update Period Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: phaseColor,
                          ),
                          title: const Text('Log period start date'),
                          subtitle: const Text('Set when your period started'),
                          onTap: () async {
                            Navigator.pop(context);

                            final DateTime? result = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return DashboardDialogs.buildPeriodLogDialog(
                                  context,
                                  previousPeriodStartDate,
                                  phaseColor,
                                );
                              },
                            );
                            if (result != null) {
                              // Update the last period date and navigate to updated dashboard
                              _handlePeriodDateUpdate(result);
                            }
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.check_circle_outline,
                            color: phaseColor,
                          ),
                          title: const Text('My period started today'),
                          subtitle: const Text(
                            'Set today as your period start',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // Update the last period date to today
                            _handlePeriodDateUpdate(DateTime.now());
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: phaseColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text('Log/Change', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  // Build the add symptoms button
  Widget _buildAddSymptomsButton(BuildContext context, Color phaseColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        child: OutlinedButton(
          onPressed: () {
            _navigateToSymptomsScreen(context, phaseColor);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: phaseColor,
            side: BorderSide(color: phaseColor),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text('+ ADD SYMPTOMS', style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  // Build the predicted symptoms section
  Widget _buildPredictedSymptomsSection(
    BuildContext context,
    String currentPhase,
    Color phaseColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common symptoms during $currentPhase:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                CycleUtils.getPhaseSymptoms(currentPhase).map((symptom) {
                  return Chip(
                    label: Text(symptom),
                    backgroundColor: phaseColor.withAlpha(51),
                    side: BorderSide(color: phaseColor.withAlpha(128)),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Method to show account options
  void _showAccountOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.pink[100],
                  child: const Icon(Icons.person, size: 40, color: Colors.pink),
                ),
                const SizedBox(height: 16),
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'Email',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to the settings screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SettingsScreen(
                              name:
                                  FirebaseAuth
                                      .instance
                                      .currentUser
                                      ?.displayName,
                              email: FirebaseAuth.instance.currentUser?.email,
                              periodLength: _periodLength,
                              cycleLength: _cycleLength,
                              dateOfBirth: _dateOfBirth,
                              lastPeriodDate: _lastPeriodDate,
                            ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    try {
                      // Exit from Firebase
                      await FirebaseAuth.instance.signOut();
                      // Navigate to the Welcome Screen
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/welcome',
                        (route) => false,
                      );
                    } catch (e) {
                      // Error handling
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error logging out: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Updated method to handle symptoms navigation and return values
  void _navigateToSymptomsScreen(BuildContext context, Color phaseColor) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SymptomsScreen(
              phaseColor: phaseColor,
              existingSymptoms: _loggedSymptoms,
              existingNotes: _symptomNotes,
            ),
      ),
    );

    if (result != null && mounted) {
      // Extract symptoms and notes from result
      if (result is Map<String, dynamic>) {
        List<String> symptoms = List<String>.from(result['symptoms'] ?? []);
        String notes = result['notes'] ?? '';

        // Update state
        setState(() {
          _loggedSymptoms = symptoms;
          _symptomNotes = notes;
        });

        // Also update Firestore
        _updateSymptomsInFirestore(symptoms, notes);

        // Show a snackbar with the result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Symptoms saved successfully'),
            backgroundColor: phaseColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Helper method to update symptoms in Firestore
  Future<void> _updateSymptomsInFirestore(
    List<String> symptoms,
    String notes,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'loggedSymptoms': symptoms, 'symptomNotes': notes});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving symptoms: $e')));
      }
    }
  }

  // Helper method to handle period date updates
  Future<void> _handlePeriodDateUpdate(DateTime newPeriodDate) async {
    // Update local state
    setState(() {
      _lastPeriodDate = newPeriodDate;
    });

    // Update Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'lastPeriodStartDate': Timestamp.fromDate(newPeriodDate)});
      }

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Period start date updated'),
            backgroundColor: Colors.pink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating period date: $e')),
        );
      }
    }
  }
}
