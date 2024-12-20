// notification_widget.dart
import 'package:flutter/material.dart';
import 'package:notification_app/helpers.dart';
import 'package:notification_app/widgets/custom_text.dart';

class NotificationWidget extends StatelessWidget {
  final String appName;
  final String title;
  final String body;
  final String status;
  final String severity;
  final String time;
  final VoidCallback onPressed;

  const NotificationWidget({
    super.key,
    required this.appName,
    required this.title,
    required this.body,
    required this.status,
    required this.severity,
    required this.time,
    required this.onPressed,
  });



  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colors = getColorsBySeverity(severity);
    final icons = getIconsByStatus(status);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onPressed,
            child: Container(
              height: screenHeight * 0.19,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withAlpha(100),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.apps, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            EtzTest(
                              text: appName,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            EtzTest(
                              text: severity,
                              color: Colors.red.shade700,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: EtzTest(
                            text: title,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        EtzTest(
                          text: time,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    EtzTest(
                      text: body,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Row(
              children: [
                // const Icon(
                //   Icons.info,
                //   color: Colors.yellow,
                //   size: 20,
                // ),
                icons,
                const SizedBox(width: 8),
                EtzTest(text: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
