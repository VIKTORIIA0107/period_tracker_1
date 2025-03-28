import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Registration of a new user
  Future<void> registerUser({
    required String userId,
    required String name,
    required String email,
    required DateTime dateOfBirth,
    required int periodLength,
    required int cycleLength,
    required DateTime lastPeriodDate,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'periodLength': periodLength,
        'cycleLength': cycleLength,
        'lastPeriodDate': lastPeriodDate.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      rethrow;
    }
  }

  // Getting user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot snapshot =
          await _db.collection('users').doc(userId).get();
      if (snapshot.exists) {
        // Ensure correct data types when parsing from Firestore
        var data = snapshot.data() as Map<String, dynamic>;

        // Parse date strings back to DateTime objects
        if (data['dateOfBirth'] != null) {
          data['dateOfBirth'] = DateTime.parse(data['dateOfBirth']);
        }
        if (data['lastPeriodDate'] != null) {
          data['lastPeriodDate'] = DateTime.parse(data['lastPeriodDate']);
        }

        // Parse periodLength and cycleLength to int if necessary
        if (data['periodLength'] != null) {
          data['periodLength'] =
              int.tryParse(data['periodLength'].toString()) ?? 0;
        }
        if (data['cycleLength'] != null) {
          data['cycleLength'] =
              int.tryParse(data['cycleLength'].toString()) ?? 0;
        }

        return data;
      } else {
        print('No user data found');
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> saveSymptoms({
    required String userId,
    required List<String> symptoms,
    required String notes,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('users').doc(userId).update({
        'loggedSymptoms': symptoms,
        'symptomNotes': notes,
      });
    } catch (e) {
      debugPrint('Error saving symptoms: $e');
    }
  }

  // Updating user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      // Ensure that 'periodLength' and 'cycleLength' are integers
      if (data['periodLength'] is String) {
        data['periodLength'] = int.tryParse(data['periodLength']) ?? 0;
      }
      if (data['cycleLength'] is String) {
        data['cycleLength'] = int.tryParse(data['cycleLength']) ?? 0;
      }

      // Convert DateTime values back to ISO8601 string format if necessary
      if (data['dateOfBirth'] is DateTime) {
        data['dateOfBirth'] =
            (data['dateOfBirth'] as DateTime).toIso8601String();
      }
      if (data['lastPeriodDate'] is DateTime) {
        data['lastPeriodDate'] =
            (data['lastPeriodDate'] as DateTime).toIso8601String();
      }

      await _db.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user data: $e');
    }
  }
}
