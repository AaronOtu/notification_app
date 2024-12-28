// ignore_for_file: unused_local_variable, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/notification_model.dart';
import 'package:notification_app/screens/display_page.dart';
import 'package:notification_app/widgets/custom_container.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:buttons_tabbar/buttons_tabbar.dart';

final apiProvider = Provider<ApiService>((ref) => ApiService());
final notificationData = FutureProvider<List<NotificationModel>>(
    (ref) => ref.watch(apiProvider).fetchAlerts());

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const EtzTest(
          text: 'Notification',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.email),
              title: Text("Email"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.sms),
              title: Text("SMS"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.telegram),
              title: Text("Telegram"),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
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
              ),
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
    );
  }


 Widget _buildNotificationList(String status) {
    final asyncNotifications = ref.watch(notificationData);

    return asyncNotifications.when(
      data: (notifications) {
       
        print('All notifications: ${notifications.length}');
        
        final filteredNotifications = status == 'View All'
            ? notifications  
            : notifications
                .where((notification) => 
                    notification.status.toUpperCase() == status.toUpperCase())
                .toList();

       
        print('Filtered notifications for $status: ${filteredNotifications.length}');

        if (filteredNotifications.isEmpty) {
          return const Center(
            child: Text('No notifications found.'),
          );
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
              time: '5hr',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DisplayPage()),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
} 
}
