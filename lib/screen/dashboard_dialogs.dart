import 'package:flutter/material.dart';
import 'cycle_utils.dart';

// DashboardDialogs is a utility class that contains static methods to build common dialog widgets used throughout the dashboard screen
// This approach centralizes dialog creation for better maintainability
class DashboardDialogs {
  // Builds a dialog for logging period start date
  static Widget buildPeriodLogDialog(
    BuildContext context,
    DateTime lastPeriodDate,
    Color phaseColor,
  ) {
    DateTime selectedDate = lastPeriodDate;
    final today = DateTime.now();

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(
            'Log Period Start Date',
            style: TextStyle(color: phaseColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select when your period started:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedDate.day} ${CycleUtils.getMonthName(selectedDate.month)} ${selectedDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: today.subtract(
                          const Duration(days: 365 * 2),
                        ),
                        lastDate: today,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: phaseColor,
                                onPrimary: Colors.white,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: phaseColor,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Change Date'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () {
                // Return the selected date to update in parent widget
                Navigator.pop(context, selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: phaseColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
