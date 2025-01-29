import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/telegram_respone.dart';


class TelegramNotifier extends StateNotifier<List<ResponseTelegram>> {
  TelegramNotifier() : super([]);

  final ApiService _apiService = ApiService();

  Future<void> fetchTelegram() async {
        try {
        final List<ResponseTelegram> telegrams = await _apiService.fetchTelegram();
        state = telegrams;
      } catch (e) {
        debugPrint('Error fetching telegram messages: $e');
      }
    
  }

  Future<void> addTelegram(String telegram) async {
    try {
      final TelegramModel newTelegram = await _apiService.addTelegram(telegram);
      if (newTelegram.response?.isNotEmpty ?? false) {
        state = [...state, newTelegram.response!.first];
      }
    } catch (e) {
      debugPrint('Error adding telegram message: $e');
    }
  }

  Future<void> deleteTelegram(String id) async {
    try {
      await _apiService.deleteTelegram(id);
      state = state.where((telegram) => telegram.id != id).toList();
      await _apiService.fetchTelegram();
    } catch (e) {
      debugPrint('Error deleting telegram message: $e');
    }
  }
}

final telegramProvider = StateNotifierProvider<TelegramNotifier, List<ResponseTelegram>>((ref) {
  return TelegramNotifier();
});
