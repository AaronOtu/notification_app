import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/notification_model.dart';
import 'package:notification_app/screens/display_page.dart';
import 'package:notification_app/screens/email_page.dart';
import 'package:notification_app/screens/sms_page.dart';
import 'package:notification_app/screens/telegram_page.dart';
import 'package:notification_app/widgets/custom_container.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:notification_app/widgets/loader.dart';
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

// --------------------------- Providers ---------------------------

final apiProvider = Provider<ApiService>((ref) => ApiService());

final notificationStateProvider = StateNotifierProvider<NotificationStateNotifier,
    AsyncValue<List<NotificationModel>>>((ref) {
  final apiService = ref.watch(apiProvider);
  return NotificationStateNotifier(apiService);
});

// --------------------------- State Management ---------------------------

class NotificationStateNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final ApiService _apiService;

  NotificationStateNotifier(this._apiService)
      : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _apiService.fetchAlerts();
      state = AsyncValue.data(notifications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// --------------------------- Home Page ---------------------------

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _handleRefresh() async {
    return ref.read(notificationStateProvider.notifier).loadNotifications();
  }

  // --------------------------- Navigation Methods ---------------------------
  
  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _navigateToNotificationDetails(NotificationModel notification) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DisplayPage(
          appName: notification.appName,
          severity: notification.severity,
          status: notification.status,
          title: notification.title,
          body: notification.body,
          time: _formatTime(notification.createdAt),
          id: notification.id,
          timeCreated: notification.createdAt,
        ),
      ),
    );

    // Refresh the homepage if resolution was successful
    if (shouldRefresh == true && mounted) {
      await _handleRefresh();
    }
  }

String _formatTime(DateTime? dateTime) {
  if (dateTime == null) return 'N/A';

  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return difference.inSeconds == 1 ? '1 second ago' : '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return difference.inMinutes == 1 ? '1 minute ago' : '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return difference.inHours == 1 ? '1 hour ago' : '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return difference.inDays == 1 ? '1 day ago' : '${difference.inDays} days ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return months == 1 ? '1 month ago' : '$months months ago';
  } else {
    final years = (difference.inDays / 365).floor();
    return years == 1 ? '1 year ago' : '$years years ago';
  }
}
  // --------------------------- Build Methods ---------------------------

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationStateProvider);
    
    return XcelLoader(
      isLoading: notificationsState is AsyncLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          child: SafeArea(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        _buildNotificationList('View All'),
                        _buildNotificationList('Pending'),
                        _buildNotificationList('Resolved'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const EtzText(
        text: 'Notification',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildDrawer() {
    final drawerItems = [
      {'icon': const AssetImage('assets/mail.png'), 'title': 'Email', 'screen': const EmailPage()},
      {'icon': const AssetImage('assets/chat.png'), 'title': 'SMS', 'screen': const SmsPage()},
      {'icon': const AssetImage('assets/telegram.png'), 'title': 'Telegram', 'screen': const TelegramPage()},
    ];

    return Drawer(
      backgroundColor: Colors.white,

      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                ' Settings',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ...drawerItems.map((item) => ListTile(
                //leading: Icon(item['icon'] as IconData),
                leading: Image(image: item['icon'] as AssetImage, width: 24, height:24,),
                title: Text(item['title'] as String),
                onTap: () => _navigateToScreen(item['screen'] as Widget),
              )),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ButtonsTabBar(
        decoration: const BoxDecoration(color: Colors.white),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        unselectedBackgroundColor: Colors.grey.shade200,
        unselectedLabelStyle: const TextStyle(color: Colors.black),
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 31, 27, 27),
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(text: 'View All'),
          Tab(text: 'Pending'),
          Tab(text: 'Resolved'),
        ],
      ),
    );
  }

  Widget _buildNotificationList(String status) {
    return Consumer(
      builder: (context, ref, child) {
        final notificationsState = ref.watch(notificationStateProvider);

        return notificationsState.when(
          data: (notifications) => _buildNotificationListContent(
            notifications,
            status,
          ),
          loading: () => const SizedBox(),
          error: (error, stackTrace) => _buildErrorWidget(error),
        );
      },
    );
  }

  Widget _buildNotificationListContent(
    List<NotificationModel> notifications,
    String status,
  ) {
    final filteredNotifications = status == 'View All'
        ? notifications
        : notifications
            .where((notification) =>
                notification.status.toUpperCase() == status.toUpperCase())
            .toList();

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return NotificationWidget(
          appName: notification.appName,
          severity: notification.severity,
          status: notification.status,
          title: notification.title,
          body: notification.body,
          time: _formatTime(notification.createdAt),
          timeCreated: notification.createdAt,
          onPressed: () => _navigateToNotificationDetails(notification),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No ${status.toLowerCase()} notifications',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading notifications\n${error.toString()}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}