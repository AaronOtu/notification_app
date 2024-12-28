import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notification_app/api/notification_model.dart';
import 'dart:developer';


class ApiService {
  final String endpoint = 'https://sandbox-api.etranzact.com.gh/notify/api/';

// send notification
  Future<NotificationModel?> sendNotification({
    required String appName,
    required String title,
    required String body,
    required String channel,
    String? severity,
    bool? toAllRecipient,
    Recipients? recipients,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        "appName": appName,
        "title": title,
        "body": body,
        "channel": channel,
        "severity": severity ?? "LOW",
        "toAllRecipient": toAllRecipient ?? true,
        "recipients": recipients?.toJson(),
      };

      final http.Response response = await http.post(
        Uri.parse('$endpoint/notify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return NotificationModel.fromJson(responseData);
      } else {
        log('Failed to send notification. Status Code: ${response.statusCode}');
        log('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error sending notification: $e');
      return null;
    }
  }

//get all notification
Future<List<NotificationModel>> fetchAlerts() async {
  try {
    final response = await http.get(Uri.parse('$endpoint/alerts'));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedBody = jsonDecode(response.body);
      log(response.body);
      if (decodedBody.containsKey('response')) {
        final List<dynamic> data = decodedBody['response'];
        return data.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Invalid JSON structure: missing "response" key');
      }
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  } catch (e) {
    log('Error fetching alerts: $e');
    throw Exception('Error fetching alerts: $e');
  }
}

}




