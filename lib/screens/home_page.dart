import 'dart:async';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
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

// --------------------------- Providers ---------------------------

final apiProvider = Provider<ApiService>((ref) => ApiService());

final schedulerStatusProvider =
    StateNotifierProvider.autoDispose<SchedulerStatusNotifier, SchedulerState>(
        (ref) {
  final apiService = ref.watch(apiProvider);
  return SchedulerStatusNotifier(apiService);
});

final notificationStateProvider = StateNotifierProvider<
    NotificationStateNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final apiService = ref.watch(apiProvider);
  return NotificationStateNotifier(apiService);
});

final notificationSearchProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final filters = ref.watch(notificationFiltersProvider);
  final apiService = ref.watch(apiServiceProvider);

  try {
    final results = await apiService.fetchAlerts();

    // Apply filters
    var filtered = results;

    if (filters.appName?.isNotEmpty ?? false) {
      filtered = filtered
          .where((notification) => notification.appName
              .toLowerCase()
              .contains(filters.appName!.toLowerCase()))
          .toList();
    }

    // Apply other filters...

    return filtered;
  } catch (e) {
    return [];
  }
});

// --------------------------- State Management ---------------------------

class SchedulerState {
  final bool
      isActive; // Represents the toggle state (true for ON, false for OFF)
  final bool isLoading; // Represents the loading state

  SchedulerState({
    required this.isActive,
    this.isLoading = false,
  });

  SchedulerState copyWith({
    bool? isActive,
    bool? isLoading,
  }) {
    return SchedulerState(
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SchedulerStatusNotifier extends StateNotifier<SchedulerState> {
  final ApiService _apiService;
  final TextEditingController appNameController = TextEditingController();

  SchedulerStatusNotifier(this._apiService)
      : super(SchedulerState(isActive: true));

  Future<void> toggleScheduler() async {
    try {
      state = state.copyWith(isLoading: true);

      // Call API to toggle scheduler
      final success = await _apiService.resetScheduler(!state.isActive);

      if (success) {
        state = state.copyWith(
          isActive: !state.isActive,
          isLoading: false,
        );
      } else {
        throw Exception('Failed to toggle scheduler');
      }
    } catch (error) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

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
  final List<String> severityOptions = ['High', 'Medium', 'Low'];
  final List<String> channelOptions = ['Email', 'SMS', 'Telegram'];
  final List<String> recipientOptions = ['Yes', 'No'];
  final TextEditingController appNameController = TextEditingController();
  Timer? _refreshTimer;
  // --------------------------- Refresh Methods ---------------------------

  @override
  void initState() {
    super.initState();
    // // Set up timer for automatic refresh every 10 seconds
    // _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
    //   if (mounted) {
    //     _handleRefresh();
    //   }
    // });
  }

  @override
  void dispose() {
    appNameController.dispose();
    _refreshTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(notificationSearchProvider);
    await ref.read(notificationStateProvider.notifier).loadNotifications();
  }

  Future<void> showResolveDialog() async {
    final schedulerNotifier = ref.read(schedulerStatusProvider.notifier);

    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Alert'),
          content: const Text('Are you sure you want to reset all alert?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      try {
        await schedulerNotifier.toggleScheduler();
        final apiService = ref.read(apiProvider);
        final success = await apiService
            .resetScheduler(!ref.read(schedulerStatusProvider).isActive);

        if (success && mounted) {
          await ref
              .read(notificationStateProvider.notifier)
              .loadNotifications();
          if (mounted) {
            _showSnackBar('Alert reset successfully!');
          }
        } else if (mounted) {
          throw Exception('Failed to reset alert');
        }
      } catch (error) {
        if (mounted) {
          _showSnackBar('Failed to reset alert: ${error.toString()}');
        }
      } finally {
        if (mounted) {
          await schedulerNotifier.toggleScheduler();
        }
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor:
            message.contains('successfully') ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --------------------------- Filter Methods ---------------------------

  void _showFilterDialog() {
    appNameController.text =
        ref.read(notificationFiltersProvider).appName ?? '';

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
                    TextField(
                      controller: appNameController,
                      decoration: const InputDecoration(
                        labelText: 'Search by App Name',
                        hintText: 'Enter app name',
                      ),
                      onChanged: (value) {
                        ref
                            .read(notificationFiltersProvider.notifier)
                            .updateAppName(value.isEmpty ? null : value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFilterDropdown(
                      'Severity',
                      severityOptions,
                      filters.severity,
                      (value) {
                        ref
                            .read(notificationFiltersProvider.notifier)
                            .updateSeverity(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFilterDropdown(
                      'Channel',
                      channelOptions,
                      filters.channel,
                      (value) {
                        ref
                            .read(notificationFiltersProvider.notifier)
                            .updateChannel(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFilterDropdown(
                      'To All Recipients',
                      recipientOptions,
                      filters.toAllRecipient == null
                          ? null
                          : filters.toAllRecipient!
                              ? 'Yes'
                              : 'No',
                      (value) {
                        ref
                            .read(notificationFiltersProvider.notifier)
                            .updateToAllRecipient(value == 'Yes');
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref
                        .read(notificationFiltersProvider.notifier)
                        .clearFilters();
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
              child: EtzText(
                text: 'Settings',
                color: Colors.black,
                fontSize: 24,
              ),
            ),
          ),
          ...drawerItems.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
              child: ListTile(
                leading: Image(
                  image: item['icon'] as AssetImage,
                  width: 24,
                  height: 24,
                ),
                title: EtzText(text: item['title'] as String, fontSize: 16),
                onTap: () => _navigateToScreen(item['screen'] as Widget),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
            child: _buildSchedulerSwitch(),
          )
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

//   Widget _buildNotificationList(String tabStatus) {
//   return Consumer(
//     builder: (context, ref, child) {
//       final searchResults = ref.watch(notificationSearchProvider);
//       final filters = ref.watch(notificationFiltersProvider);

//       return searchResults.when(
//         data: (notifications) {
//           // Sort notifications by createdAt timestamp in descending order (newest first)
//           final sortedNotifications = List<NotificationModel>.from(notifications)
//             ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

//           final filteredByStatus = tabStatus == 'View All'
//               ? sortedNotifications
//               : sortedNotifications
//                   .where((n) => n.status.toUpperCase() == tabStatus.toUpperCase())
//                   .toList();

//           if (filteredByStatus.isEmpty) {
//             return _buildEmptyState(tabStatus);
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(8.0),
//             itemCount: filteredByStatus.length,
//             itemBuilder: (context, index) {
//               final notification = filteredByStatus[index];
//               return NotificationWidget(
//                 appName: notification.appName,
//                 severity: notification.severity,
//                 status: notification.status,
//                 title: notification.title,
//                 body: notification.body,
//                 time: formatTime(notification.createdAt),
//                 timeCreated: notification.createdAt,
//                 onPressed: () => _navigateToNotificationDetails(notification),
//               );
//             },
//           );
//         },
//         loading: () => const SizedBox.shrink(),
//         error: (error, stack) => _buildErrorWidget(error),
//       );
//     },
//   );
// }

  Widget _buildNotificationList(String tabStatus) {
    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(notificationSearchProvider);
        final filters = ref.watch(notificationFiltersProvider);

        return searchResults.when(
          data: (notifications) {
            var filteredNotifications =
                List<NotificationModel>.from(notifications);

            // Apply app name filter
            if (filters.appName != null && filters.appName!.isNotEmpty) {
              filteredNotifications = filteredNotifications
                  .where((n) => n.appName
                      .toLowerCase()
                      .contains(filters.appName!.toLowerCase()))
                  .toList();
            }

            // Sort by createdAt
            filteredNotifications
                .sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Apply status filter
            final filteredByStatus = tabStatus == 'View All'
                ? filteredNotifications
                : filteredNotifications
                    .where((n) =>
                        n.status.toUpperCase() == tabStatus.toUpperCase())
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
          loading: () => const SizedBox.shrink(),
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
  // Future<void> _showSystemErrorDialog() async {
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(15),
  //         ),
  //         title: Column(
  //           children: [
  //             const Icon(
  //               Icons.error_outline,
  //               color: Colors.red,
  //               size: 48,
  //             ),
  //             const SizedBox(height: 12),
  //             const Text(
  //               'System Error',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         content: const Text(
  //           'Please try again later.',
  //           textAlign: TextAlign.center,
  //         ),
  //         actions: [
  //           Center(
  //             child: TextButton(
  //               style: TextButton.styleFrom(
  //                 backgroundColor: Colors.blue,
  //                 padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(20),
  //                 ),
  //               ),
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text(
  //                 'OK',
  //                 style: TextStyle(color: Colors.white),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildSchedulerSwitch() {
    final schedulerState = ref.watch(schedulerStatusProvider);
    return ListTile(
      leading: const Image(
        image: AssetImage('assets/schedule.png'),
        width: 24,
        height: 24,
      ),
      title: const EtzText(
        text: 'Scheduler',
        fontSize: 16,
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          activeColor: Colors.white,
          activeTrackColor: Colors.blue,
          inactiveTrackColor: Colors.grey.shade200,
          value: schedulerState.isActive,
          onChanged: schedulerState.isLoading
              ? null
              : (bool value) async {
                  // Show confirmation dialog based on the intended state
                  final shouldChange =
                      await _showSchedulerConfirmationDialog(value);
                  if (shouldChange && mounted) {
                    try {
                      await ref
                          .read(schedulerStatusProvider.notifier)
                          .toggleScheduler();
                      if (mounted) {
                        _showSnackBar(
                          'Scheduler ${value ? 'activated' : 'deactivated'} successfully!',
                        );
                      }
                    } catch (error) {
                      if (mounted) {
                        _showSnackBar(
                            'Failed to toggle scheduler: ${error.toString()}');
                      }
                    }
                  }
                },
        ),
      ),
    );
  }

  Future<bool> _showSchedulerConfirmationDialog(bool newState) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title:
                  EtzText(text: '${newState ? 'Disable' : 'Enable'} Scheduler'),
              content: EtzText(
                  text:
                      'Are you sure you want to ${newState ? 'disable' : 'enable'} the scheduler?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const EtzText(text: 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: EtzText(text: newState ? 'Disable' : 'Enable'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
