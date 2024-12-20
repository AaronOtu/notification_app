// ignore_for_file: unused_local_variable
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/widgets/custom_container.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:buttons_tabbar/buttons_tabbar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final List<Map<String, String>> notifications = [
    {
      'appName': 'PayFluid',
      'severity': 'High',
      'status': 'Pending',
      'title': 'Service not provided',
      'body':
          'The customer\'s account has been debited but no value has been given',
      'time': '5h ago',
    },
    {
      'appName': 'PayFluid',
      'severity': 'Medium',
      'status': 'Resolved',
      'title': 'Transaction delay',
      'body': 'Transaction took over 2 hours to process successfully',
      'time': '2d ago',
    },
    {
      'appName': 'PayFluid',
      'severity': 'Medium',
      'status': 'Pending',
      'title': 'Transaction delay',
      'body': 'Transaction took over 2 hours to process successfully',
      'time': '2d ago',
    },
    {
      'appName': 'PayFluid',
      'severity': 'Low',
      'status': 'Resolved',
      'title': 'Service not provided',
      'body':
          'The customer\'s account has been debited but no value has been given',
      'time': '5h ago',
    },
    {
      'appName': 'PayFluid',
      'severity': 'Low',
      'status': 'Resolved',
      'title': 'Service not provided',
      'body':
          'The customer\'s account has been debited but no value has been given',
      'time': '5h ago',
    },
    {
      'appName': 'PayFluid',
      'severity': 'Low',
      'status': 'Resolved',
      'title': 'Service not provided',
      'body':
          'The customer\'s account has been debited but no value has been given',
      'time': '5h ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateNotificationStatus();
  }

  void _updateNotificationStatus() {
    for (var notification in notifications) {
      if (notification['status'] == 'View All') {
        notification['status'] =
            notification['severity'] == 'High' ? 'Pending' : 'Resolved';
      }
    }
  }

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
        // actions: [
        //   IconButton(
        //     onPressed: () => Navigator.of(context).pop(),
        //     icon: const Icon(Icons.close, color: Colors.black),
        //   ),
        // ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.home),
              title: Text("Email"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text("SMS"),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.home),
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
    final filteredNotifications = status == 'View All'
        ? notifications
            .where((notification) =>
                notification['status'] == 'Pending' ||
                notification['status'] == 'Resolved')
            .toList()
        : notifications
            .where((notification) => notification['status'] == status)
            .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return NotificationWidget(
          appName: notification['appName']!,
          severity: notification['severity']!,
          status: notification['status']!,
          title: notification['title']!,
          body: notification['body']!,
          time: notification['time']!,
        );
      },
    );
  }
}
