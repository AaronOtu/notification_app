import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/notification_model.dart';

class NotificationFilters {
  final String? appName;
  final String? severity;
  final String? channel;
  final String? createdAt;
  final bool? toAllRecipient;

  NotificationFilters({
    this.appName,
    this.severity,
    this.channel,
    this.createdAt,
    this.toAllRecipient,
  });

  NotificationFilters copyWith({
    String? appName,
    String? severity,
    String? status,
    String? channel,
    String? createdAt,
    bool? toAllRecipient,
  }) {
    return NotificationFilters(
      appName: appName ?? this.appName,
      severity: severity ?? this.severity,
      channel: channel ?? this.channel,
      createdAt: createdAt ?? this.createdAt,
      toAllRecipient: toAllRecipient ?? this.toAllRecipient,
    );
  }
}

// Create a provider for the filters
final notificationFiltersProvider =
    StateNotifierProvider<NotificationFiltersNotifier, NotificationFilters>(
        (ref) {
  return NotificationFiltersNotifier();
});

class NotificationFiltersNotifier extends StateNotifier<NotificationFilters> {
  NotificationFiltersNotifier() : super(NotificationFilters());

  void updateAppName(String? appName) {
    state = state.copyWith(appName: appName);
  }

  void updateSeverity(String? severity) {
    state = state.copyWith(severity: severity);
  }

  void updateChannel(String? channel) {
    state = state.copyWith(channel: channel);
  }

  void updateCreatedAt(String? createdAt) {
    state = state.copyWith(createdAt: createdAt);
  }

  void updateToAllRecipient(bool? toAllRecipient) {
    state = state.copyWith(toAllRecipient: toAllRecipient);
  }

  void clearFilters() {
    state = NotificationFilters();
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());


Timer? _debounceTimer;

final notificationSearchProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final filters = ref.watch(notificationFiltersProvider);
  final apiService = ref.watch(apiServiceProvider);


  _debounceTimer?.cancel();


  return Future.delayed(const Duration(milliseconds: 300), () async {
    try {
      final results = await apiService.searchNotification(
        appName: filters.appName?.trim(), // Trim whitespace
        severity: filters.severity,
        channel: filters.channel,
        createdAt: filters.createdAt,
        toAllRecipient: filters.toAllRecipient,
      );

      
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return results;
    } catch (e) {
      // Handle errors gracefully
      return [];
    }
  });
});
