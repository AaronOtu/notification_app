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