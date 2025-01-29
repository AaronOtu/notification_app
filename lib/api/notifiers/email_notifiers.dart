import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/email_response_model.dart';

class EmailNotifier extends StateNotifier<List<Response>> {
  EmailNotifier() : super([]);

  final ApiService _apiService = ApiService();

  Future<void> fetchEmails() async {
    try {
      final List<Response> emails = await _apiService.fetchEmails();
      state = emails;
    } catch (e) {
      debugPrint('Error fetching emails: $e');
    }
  }

  Future<void> addEmail(String email) async {
    try {
      final EmailModel newEmail = await _apiService.addEmail(email);
      if (newEmail.response?.isNotEmpty ?? false) {
        state = [...state, newEmail.response!.first];
      }
    } catch (e) {
      debugPrint('Error adding email: $e');
    }
  }

  Future<void> deleteEmail(String id) async {
    try {
      await _apiService.deleteEmail(id);
      state = state.where((email) => email.id != id).toList();
      await _apiService.fetchEmails();
    } catch (e) {
      debugPrint('Error deleting email: $e');
    }
  }
}

final emailsProvider = StateNotifierProvider<EmailNotifier, List<Response>>((ref) {
  return EmailNotifier();
});
