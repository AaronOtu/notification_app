import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/sms_response.dart';

class SmsNotifier extends StateNotifier<List<ResponseSms>> {
  SmsNotifier() : super([]);

  final ApiService _apiService = ApiService();

  Future<void> fetchSms() async {
    try {
      final List<ResponseSms> sms = await _apiService.fetchSms();
      state = sms;
    } catch (e) {
      debugPrint('Error fetching sms: $e');
    }
  }

  Future<void> addSms(String sms) async {
    try {
      final SmsModel newSms = await _apiService.addSms(sms);
      if (newSms.response?.isNotEmpty ?? false) {
        state = [...state, newSms.response!.first];
      }
    } catch (e) {
      debugPrint('Error adding sms: $e');
    }
  }

  Future<void> deleteSms(String id) async {
    try {
      await _apiService.deleteSms(id);
      state = state.where((sms) => sms.id != id).toList();
      await _apiService.fetchSms();
    } catch (e) {
      debugPrint('Error deleting sms: $e');
    }
  }
}

final smsProvider =
    StateNotifierProvider<SmsNotifier, List<ResponseSms>>((ref) {
  return SmsNotifier();
});
