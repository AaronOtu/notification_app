// notification_widget.dart
// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notification_app/helpers.dart';
import 'package:notification_app/widgets/custom_text.dart';

class NotificationWidget extends StatelessWidget {
  final String appName;
  final String title;
  final String body;
  final String status;
  final String severity;
  final String time;
  final DateTime timeCreated;

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
    required this.timeCreated,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final colors = getColorsBySeverity(severity);
    final statusIcons = getIconsByStatus(status);
    final imageIcon = getImageBySeverity(severity);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onPressed,
            child: Container(
              height: screenHeight * 0.19,
              //width: screenWidth * 1.0,
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
                            FittedBox(
                              child: SizedBox(
                                height: 30,
                                width: 30,
                                child: Image(
                                  image: AssetImage('assets/app.png'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            EtzText(
                              text: appName,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            FittedBox(
                                child: SizedBox(
                                    height: 20, width: 20, child: imageIcon)),
                            const SizedBox(width: 8),
                            EtzText(
                              text: severity,
                              color: Colors.black,
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
                          child: EtzText(
                              text: title,
                              fontSize: 16,
                              maxLines: 1,
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis),
                        ),
                        EtzText(
                          text: time,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    EtzText(
                      text: body,
                      color: Colors.grey.shade700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 16,
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
                FittedBox(
                    child: SizedBox(height: 20, width: 20, child: statusIcons)),
                const SizedBox(width: 8),
                EtzText(text: status),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Row(
              children: [
                EtzText(
                    text:
                        DateFormat('dd MMM yyyy hh:mm a').format(timeCreated)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
