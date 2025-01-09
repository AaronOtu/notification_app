import 'package:flutter/material.dart';
import 'package:notification_app/constants/colors.dart';
import 'package:notification_app/constants/icons.dart';

List<Color> getColorsBySeverity(String severity) {
  switch (severity.toLowerCase()) {
    case 'high':
      return redList;
    case 'medium':
      return yellowList;
    case 'low':
      return greyList;
    default:
      return greyList;
  }
}

Image getIconsByStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return pendingIcon;
    case 'resolved':
      return resolvedIcon;
    default:
      return pendingIcon;
  }
}

Image getImageBySeverity(String severity){
  switch(severity.toLowerCase()){
    case 'high':
      return highIcon;
    case 'medium':
      return mediumIcon;
    case 'low':
       return lowIcon;
    default:
        return lowIcon;       

  }
}


String formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return difference.inSeconds == 1
          ? '1 second ago'
          : '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return difference.inDays == 1
          ? '1 day ago'
          : '${difference.inDays} days ago';
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