import 'package:flutter/material.dart';

class CycleUtils {
  //Returns a list of common symptoms for the given menstrual cycle phase
  static List<String> getPhaseSymptoms(String phase) {
    switch (phase) {
      case "Menstruation":
        return ["Cramps", "Fatigue", "Bloating", "Headache", "Lower back pain"];
      case "Follicular":
        return [
          "Energy increase",
          "Improved mood",
          "Increased focus",
          "Creativity",
        ];
      case "Fertile Window":
        return [
          "Increased libido",
          "Clear skin",
          "Cervical mucus changes",
          "Slight temperature rise",
        ];
      case "Ovulation":
        return [
          "Mittelschmerz (ovulation pain)",
          "Increased energy",
          "Heightened senses",
          "Peak libido",
        ];
      case "Luteal":
        return [
          "Slight fatigue",
          "Increased appetite",
          "Stable mood",
          "Possible breast tenderness",
        ];
      case "Luteal (PMS)":
        return [
          "Mood swings",
          "Bloating",
          "Breast tenderness",
          "Food cravings",
          "Acne",
          "Fatigue",
        ];
      default:
        return [];
    }
  }

  // Returns a description for the given menstrual cycle phase
  static String getPhaseDescription(String phase) {
    switch (phase) {
      case "Menstruation":
        return "During your period, your body sheds the uterine lining. Rest and self-care are important now.";
      case "Follicular":
        return "After your period, estrogen rises as your body prepares for ovulation. Energy levels often increase during this phase.";
      case "Fertile Window":
        return "These are your most fertile days when pregnancy is possible. Cervical mucus becomes clearer and more slippery.";
      case "Ovulation":
        return "An egg is released from the ovary. This is your most fertile day and energy levels are typically high.";
      case "Luteal":
        return "After ovulation, progesterone rises. Your body prepares for a possible pregnancy.";
      case "Luteal (PMS)":
        return "The days before your period when hormone levels begin to drop. You may experience mood changes and physical symptoms.";
      default:
        return "";
    }
  }

  // Returns the full name of the month based on its number (1-12)
  static String getMonthName(int month) {
    const List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }

  // Calculates the current cycle phase based on cycle day and other parameters
  static Map<String, dynamic> calculateCyclePhase({
    required int cycleDay,
    required bool isInPeriod,
    required bool isInFertileWindow,
    required int daysUntilOvulation,
    required int daysUntilNextPeriod,
  }) {
    String currentPhase = "";
    Color phaseColor;

    if (isInPeriod) {
      currentPhase = "Menstruation";
      phaseColor = Colors.pink;
    } else if (cycleDay < 7) {
      currentPhase = "Follicular";
      phaseColor = Colors.purple.shade300;
    } else if (isInFertileWindow) {
      currentPhase = "Fertile Window";
      phaseColor = Colors.green;
    } else if (daysUntilOvulation <= 0 && daysUntilOvulation >= -1) {
      currentPhase = "Ovulation";
      phaseColor = Colors.green.shade700;
    } else if (daysUntilNextPeriod < 7) {
      currentPhase = "Luteal (PMS)";
      phaseColor = Colors.orange;
    } else {
      currentPhase = "Luteal";
      phaseColor = Colors.amber;
    }

    return {'phase': currentPhase, 'color': phaseColor};
  }
}
