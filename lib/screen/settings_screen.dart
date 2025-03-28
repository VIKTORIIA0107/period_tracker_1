import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

/// SettingsScreen allows users to view and modify their account settings
/// Includes personal information and password management
class SettingsScreen extends StatefulWidget {
  final String? name;
  final String? email;
  final int periodLength;
  final int cycleLength;
  final DateTime dateOfBirth;
  final DateTime lastPeriodDate;

  const SettingsScreen({
    super.key,
    this.name,
    this.email,
    required this.periodLength,
    required this.cycleLength,
    required this.dateOfBirth,
    required this.lastPeriodDate,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  // State variables
  late DateTime _selectedDateOfBirth;

  // Password visibility toggles
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Editing mode flags
  bool _editingPersonalInfo = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current values
    _nameController = TextEditingController(text: widget.name ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Initialize other state variables
    _selectedDateOfBirth = widget.dateOfBirth;
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Information Section
                      _buildSectionHeader('Account Information'),
                      _buildPersonalInfoSection(),

                      const SizedBox(height: 24),

                      // Password Change Section
                      _buildSectionHeader('Security'),
                      _buildPasswordSection(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                enabled: _editingPersonalInfo,
              ),
              validator: (value) {
                if (_editingPersonalInfo && (value == null || value.isEmpty)) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                enabled: _editingPersonalInfo,
              ),
              validator: (value) {
                if (_editingPersonalInfo && (value == null || value.isEmpty)) {
                  return 'Please enter your email';
                }
                if (_editingPersonalInfo && !value!.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date of Birth:', style: TextStyle(fontSize: 16)),
                _editingPersonalInfo
                    ? TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateOfBirth,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDateOfBirth = date;
                          });
                        }
                      },
                      child: Text(
                        '${_selectedDateOfBirth.day}/${_selectedDateOfBirth.month}/${_selectedDateOfBirth.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                    : Text(
                      '${_selectedDateOfBirth.day}/${_selectedDateOfBirth.month}/${_selectedDateOfBirth.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 16),

            // Edit/Save button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (_editingPersonalInfo)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // Reset to original values
                        _nameController.text = widget.name ?? '';
                        _emailController.text = widget.email ?? '';
                        _selectedDateOfBirth = widget.dateOfBirth;
                        _editingPersonalInfo = false;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(90, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () {
                    if (_editingPersonalInfo) {
                      // Validate and save
                      if (_formKey.currentState!.validate()) {
                        // Save the data to backend/database
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Personal information updated'),
                          ),
                        );
                        setState(() {
                          _editingPersonalInfo = false;
                        });
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DashboardScreen(
                                  name: _nameController.text,
                                  email: _emailController.text,
                                  periodLength: widget.periodLength,
                                  cycleLength: widget.cycleLength,
                                  dateOfBirth: _selectedDateOfBirth,
                                  lastPeriodDate: widget.lastPeriodDate,
                                ),
                          ),
                        );
                      }
                    } else {
                      // Enter edit mode
                      setState(() {
                        _editingPersonalInfo = true;
                      });
                    }
                  },
                  child: Text(_editingPersonalInfo ? 'Save' : 'Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Added to ensure proper sizing
          children: [
            if (!_changingPassword)
              SizedBox(
                height: 36, // Fixed height for consistency
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _changingPassword = true;
                    });
                  },
                  icon: const Icon(Icons.lock),
                  label: const Text('Change Password'),
                ),
              ),
            if (_changingPassword) ...[
              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_isCurrentPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm New Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save/Cancel buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max, // Ensure proper sizing
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _changingPassword = false;
                        _currentPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 36), // Provide minimum size
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Here you would update the password in your backend/database
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully'),
                          ),
                        );
                        setState(() {
                          _changingPassword = false;
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        });
                      }
                    },
                    child: const Text('Update Password'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
