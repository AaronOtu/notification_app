import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/notification_model.dart';
import 'package:notification_app/api/notifiers/alerts_notifiers.dart';
import 'package:notification_app/helpers.dart';
import 'package:notification_app/screens/display_page.dart';
import 'package:notification_app/screens/email_page.dart';
import 'package:notification_app/screens/errorlog_page.dart';
import 'package:notification_app/screens/sms_page.dart';
import 'package:notification_app/screens/telegram_page.dart';
import 'package:notification_app/widgets/custom_container.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:notification_app/widgets/loader.dart';
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

// --------------------------- Providers ---------------------------

final apiProvider = Provider<ApiService>((ref) => ApiService());

final notificationStateProvider = StateNotifierProvider<
    NotificationStateNotifier, AsyncValue<List<NotificationModel>>>((ref) {
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
  final List<String> severityOptions = ['Critical', 'High', 'Medium', 'Low'];
  final List<String> channelOptions = ['Email', 'SMS', 'Telegram'];
  final List<String> recipientOptions = ['Yes', 'No'];

  // --------------------------- Refresh Methods ---------------------------

  Future<void> _handleRefresh() async {
    ref.invalidate(notificationSearchProvider);
    await ref.read(notificationStateProvider.notifier).loadNotifications();
  }

  // --------------------------- Filter Methods ---------------------------

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filters = ref.watch(notificationFiltersProvider);
            
            return AlertDialog(
              title: const Text('Filter Notifications'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterDropdown(
                      'Severity',
                      severityOptions,
                      filters.severity,
                      (value) {
                        ref.read(notificationFiltersProvider.notifier)
                            .updateSeverity(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFilterDropdown(
                      'Channel',
                      channelOptions,
                      filters.channel,
                      (value) {
                        ref.read(notificationFiltersProvider.notifier)
                            .updateChannel(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFilterDropdown(
                      'To All Recipients',
                      recipientOptions,
                      filters.toAllRecipient == null 
                          ? null 
                          : filters.toAllRecipient! ? 'Yes' : 'No',
                      (value) {
                        ref.read(notificationFiltersProvider.notifier)
                            .updateToAllRecipient(value == 'Yes');
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(notificationFiltersProvider.notifier).clearFilters();
                    ref.invalidate(notificationSearchProvider);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear Filters'),
                ),
                TextButton(
                  onPressed: () {
                    ref.invalidate(notificationSearchProvider);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDropdown(
    String label,
    List<String> options,
    String? currentValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: currentValue,
          hint: Text('Select $label'),
          isExpanded: true,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
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
          time: formatTime(notification.createdAt),
          id: notification.id,
          timeCreated: notification.createdAt,
          timeResolved: notification.updatedAt,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _handleRefresh();
    }
  }

  // --------------------------- Build Methods ---------------------------

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationStateProvider);
    return XcelLoader(
        isLoading:notificationsState is AsyncLoading,
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
                  _buildFilterRow(),
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

  Widget _buildFilterRow() {
    final filters = ref.watch(notificationFiltersProvider);
    final activeFilters = [
      filters.severity,
      filters.channel,
      filters.toAllRecipient,
    ].where((filter) => filter != null).length;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: _showFilterDialog,
            child: const FittedBox(
              child: SizedBox(
                height: 20,
                width: 20,
                child: Image(
                  image: AssetImage('assets/dr_down.png'),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const EtzText(text: 'Filtered by'),
          const SizedBox(width: 8),
          EtzText(
            text: activeFilters > 0 ? '$activeFilters filters active' : 'None',
            color: activeFilters > 0 
                ? Colors.blue 
                : const Color.fromARGB(255, 219, 215, 215),
          ),
        ],
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
      {
        'icon': const AssetImage('assets/mail.png'),
        'title': 'Email',
        'screen': const EmailPage()
      },
      {
        'icon': const AssetImage('assets/chat.png'),
        'title': 'SMS',
        'screen': const SmsPage()
      },
      {
        'icon': const AssetImage('assets/telegram.png'),
        'title': 'Telegram',
        'screen': const TelegramPage()
      },
      {
        'icon': const AssetImage('assets/error.png'),
        'title': 'Error Logs',
        'screen': const ErrorlogPage()
      },
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
                'Settings',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          ...drawerItems.map((item) => ListTile(
                leading: Image(
                  image: item['icon'] as AssetImage,
                  width: 24,
                  height: 24,
                ),
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

  Widget _buildNotificationList(String tabStatus) {
    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(notificationSearchProvider);

        return searchResults.when(
          data: (notifications) {
            final filteredByStatus = tabStatus == 'View All'
                ? notifications
                : notifications
                    .where((n) => n.status.toUpperCase() == tabStatus.toUpperCase())
                    .toList();

            if (filteredByStatus.isEmpty) {
              return _buildEmptyState(tabStatus);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredByStatus.length,
              itemBuilder: (context, index) {
                final notification = filteredByStatus[index];
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
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
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
            text: 'No ${status.toLowerCase()} notifications',
            color: Colors.grey.shade600,
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
          Center(
            child: EtzText(
              text: 'Error loading notifications\n${error.toString()}',
              color: Colors.red,
            ),
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