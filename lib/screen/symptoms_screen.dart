import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// SymptomsScreen allows users to log their symptoms and notes
/// The screen color can be customized based on the current phase of the cycle
class SymptomsScreen extends StatefulWidget {
  final Color? phaseColor;
  final List<String>? existingSymptoms;
  final String? existingNotes;

  const SymptomsScreen({
    super.key,
    this.phaseColor,
    this.existingSymptoms,
    this.existingNotes,
  });

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  // List of symptom categories for organization
  final List<String> _symptomCategories = [
    'Physical',
    'Sex',
    'Mood',
    'Symptoms',
    'Vaginal discharge',
    'Type of vaginal discharge',
    'Other',
  ];

  // Map of categories to their associated symptoms
  final Map<String, List<String>> _symptoms = {
    'Physical': [
      'Cramps',
      'Headache',
      'Tender breasts',
      'Acne',
      'Bloating',
      'Backache',
      'Nausea',
    ],
    'Sex': [
      'No sex',
      'Protected sex',
      'Unprotected sex',
      'Masturbation',
      'Increased desire',
    ],
    'Mood': ['Productive', 'Energetic', 'Calm', 'Sad', 'Irritable'],
    'Symptoms': ['OK', 'Cramps', 'Tender breasts', 'Headache', 'Fatigue'],
    'Vaginal discharge': ['None', 'Heavy', 'Medium', 'Light'],
    'Type of vaginal discharge': [
      'Watery',
      'Mucoid',
      'Creamy',
      'Jelly-like',
      'Spotting',
    ],
    'Other': ['Stress', 'Sickness', 'Travel'],
  };

  // Map of selected symptoms for tracking user choices
  final Map<String, bool> _selectedSymptoms = {};

  // Controller for the notes text field
  late TextEditingController _notesController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.existingNotes ?? '');

    // Initialize with existing symptoms if provided
    if (widget.existingSymptoms != null) {
      for (String symptom in widget.existingSymptoms!) {
        _selectedSymptoms[symptom] = true;
      }
      _isLoading = false;
    } else {
      // Load symptoms from Firestore if not provided
      _loadExistingSymptoms();
    }
  }

  // Load existing symptoms from Firestore
  Future<void> _loadExistingSymptoms() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;

          if (data['loggedSymptoms'] != null) {
            setState(() {
              // Mark existing symptoms as selected
              List<dynamic> symptoms = data['loggedSymptoms'];
              for (String symptom in symptoms.cast<String>()) {
                _selectedSymptoms[symptom] = true;
              }
            });
          }

          if (data['symptomNotes'] != null && _notesController.text.isEmpty) {
            setState(() {
              _notesController.text = data['symptomNotes'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading symptoms: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = widget.phaseColor ?? Colors.pink;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Symptoms')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Symptoms'),
        // Add save button in the app bar for quick access
        actions: [
          TextButton(
            onPressed: () {
              _handleSaveSymptoms(context);
            },
            child: Text(
              'Save',
              style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header instruction text
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select symptoms you are experiencing today:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // If there are already selected symptoms, show a summary
          if (_selectedSymptoms.entries.any((entry) => entry.value))
            _buildSelectedSymptomsSummary(activeColor),

          // Generate UI for each symptom category
          ..._symptomCategories.map((category) {
            if (_symptoms.containsKey(category) &&
                _symptoms[category]!.isNotEmpty) {
              return _buildCategorySection(category, activeColor);
            } else {
              return const SizedBox.shrink();
            }
          }),

          const SizedBox(height: 24),

          // Notes section for additional information
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Multi-line text field for detailed notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Add additional notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: activeColor),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),

          // Save button at the bottom of the screen
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _handleSaveSymptoms(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Save Symptoms',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Show a summary of currently selected symptoms
  Widget _buildSelectedSymptomsSummary(Color activeColor) {
    final selectedSymptomsList =
        _selectedSymptoms.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currently Selected Symptoms (${selectedSymptomsList.length}):',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                selectedSymptomsList.map((symptom) {
                  return Chip(
                    label: Text(symptom),
                    backgroundColor: activeColor.withAlpha(50),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedSymptoms[symptom] = false;
                      });
                    },
                  );
                }).toList(),
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  /// Builds a section for a specific symptom category
  /// Includes a header and a wrap of symptom chips
  Widget _buildCategorySection(String category, Color activeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[200],
          width: double.infinity,
          child: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            children:
                _symptoms[category]!.map((symptom) {
                  return _buildSymptomChip(symptom, activeColor);
                }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Builds an individual symptom chip that can be toggled on/off
  Widget _buildSymptomChip(String symptom, Color activeColor) {
    final isSelected = _selectedSymptoms[symptom] ?? false;

    return FilterChip(
      label: Text(symptom),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSymptoms[symptom] = selected;
        });
      },
      // Visual styling based on selection state
      selectedColor: activeColor.withAlpha(50), // Lighter color when selected
      checkmarkColor: activeColor,
      backgroundColor: Colors.grey[100],
      side: BorderSide(color: isSelected ? activeColor : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: true,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? activeColor : Colors.black87,
      ),
    );
  }

  /// Handles saving the selected symptoms to Firestore
  void _handleSaveSymptoms(BuildContext context) async {
    // Extract only the selected symptoms from the map
    final List<String> selectedSymptoms =
        _selectedSymptoms.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    final String notes = _notesController.text;

    try {
      // Pass back the selected symptoms and notes to the dashboard
      Navigator.pop(context, {'symptoms': selectedSymptoms, 'notes': notes});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving symptoms: $e')));
    }
  }
}
