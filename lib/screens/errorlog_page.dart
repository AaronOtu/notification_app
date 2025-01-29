import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/error_response_model.dart';
import 'package:notification_app/helpers.dart';
import 'package:notification_app/screens/errordisplay_page.dart';
import 'package:notification_app/widgets/custom_container.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:notification_app/widgets/loader.dart';

final apiProvider = Provider<ApiService>((ref) => ApiService());

final notificationStateProvider = StateNotifierProvider<
    NotificationStateNotifier, AsyncValue<List<ErrorModel>>>((ref) {
  final apiService = ref.watch(apiProvider);
  return NotificationStateNotifier(apiService);
});

// --------------------------- State Management ---------------------------

class NotificationStateNotifier
    extends StateNotifier<AsyncValue<List<ErrorModel>>> {
  final ApiService _apiService;

  NotificationStateNotifier(this._apiService)
      : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _apiService.fetchErrorLogs();
      state = AsyncValue.data(notifications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}



class ErrorlogPage extends ConsumerStatefulWidget {
  const ErrorlogPage({super.key});

  @override
  ConsumerState<ErrorlogPage> createState() => _ErrorlogPageState();
}

class _ErrorlogPageState extends ConsumerState<ErrorlogPage> {
   Future<void> handleRefresh() async {
    //ref.invalidate(notificationSearchProvider);
    await ref.read(notificationStateProvider.notifier).loadNotifications();
  }

void _navigateToNotificationDetails(ErrorModel notification) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ErrorDisplayPage(
          appName: notification.appName,
          severity: notification.severity,
          status: notification.status,
          title: notification.title,
          body: notification.body,
          time: formatTime(notification.createdAt),
          id: notification.id,
          timeCreated: notification.createdAt,
          timeResolved: notification.updatedAt,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await handleRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
     final notificationsState = ref.watch(notificationStateProvider);

    return  XcelLoader(
      isLoading:notificationsState is AsyncLoading,
      child: Scaffold(
          appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const EtzText(
            text: 'Error Logs',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
         body: LiquidPullToRefresh(
          onRefresh: handleRefresh,
          child: 
           notificationsState.when(
            data: (notifications) =>  notifications.isEmpty ? buildEmptyState()
            
             :ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationWidget(
                    appName: notification.appName,
                    severity: notification.severity,
                    status: notification.status,
                    title: notification.title,
                    body: notification.body,
                    time: formatTime(notification.createdAt),
                    timeCreated: notification.createdAt,
                    onPressed: () => _navigateToNotificationDetails(notification),
                  );
                },
              ),
              error: (error, stackTrace) => Center(child: Text(error.toString())),
              loading: () => const SizedBox.shrink())
      
         )
      
      
        
        ),
    );
  }

 Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(
            image: AssetImage('assets/empty_notification.png'),
            height: 64,
            width: 64,
          ),
          const SizedBox(height: 16),
          EtzText(
            text: 'No Error Log notifications',
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }



}

