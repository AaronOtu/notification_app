// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:notification_app/api/models/email_response_model.dart';
import 'package:notification_app/api/models/notification_model.dart';
import 'dart:developer';

import 'package:notification_app/api/models/sms_response.dart';
import 'package:notification_app/api/models/telegram_respone.dart';
import 'package:pretty_logger/pretty_logger.dart';
//import 'package:logger/logger.dart';

class ApiService {
  final String endpoint = 'https://sandbox-api.etranzact.com.gh/notify/api';

  Future<T?> _handleNetworkCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on SocketException catch (e) {
      log('Network Error: ${e.message}');
      if (e.message.contains('Failed host lookup')) {
        log('Cannot reach the server. Please check:\n'
            '1. Your internet connection\n'
            '2. The API endpoint URL is correct\n'
            '3. The server is accessible');
      }
      rethrow;
    } on HttpException catch (e) {
      log('HTTP Error: ${e.message}');
      rethrow;
    } on FormatException catch (e) {
      log('Data Format Error: ${e.message}');
      rethrow;
    } catch (e) {
      log('Unexpected Error: $e');
      rethrow;
    }
  }

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
        //log(response.body);
        //Logger(level: Level.verbose, printer:PrettyPrinter()).i(response.body);
        PLog.cyan(response.body);

        if (decodedBody.containsKey('response')) {
          final List<dynamic> data = decodedBody['response'];
          return data
              .map((item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();
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

  Future<bool> resolveAlert(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$endpoint/alert-toggle/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'RESOLVED'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String notificationData = data['response']['status'];
        log('Alert with ID $id is $notificationData');
        return true;
      } else {
        log('Failed to resolve alert. Status Code: ${response.statusCode}');
        log('Response Body: ${response.body}');
        return false;
      }
    } catch (e) {
      log('Error resolving alert with ID $id: $e');
      return false;
    }
  }

  Future<List<Response>> fetchEmails() async {
    try {
      final response = await http.get(Uri.parse('$endpoint/email'));

      if (response.statusCode == 200) {
        log('Response Body: ${response.body}');
        final EmailModel emailModel = emailModelFromJson(response.body);
        return emailModel.response ?? [];
      }

      throw Exception('Failed to fetch emails: ${response.statusCode}');
    } catch (e) {
      log('Error fetching emails: $e');
      rethrow;
    }
  }

  /// Add a new email
  Future<EmailModel> addEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'value': email}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        log('Email added: ${response.body}');
        return EmailModel.fromJson(data);
      }

      throw Exception('Failed to add email: ${response.statusCode}');
    } catch (e) {
      log('Error adding email: $e');
      rethrow;
    }
  }

  /// Delete an email by ID
  Future<void> deleteEmail(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$endpoint/email/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        log('Email with ID $id deleted successfully');
        return;
      }

      throw Exception('Failed to delete email: ${response.statusCode}');
    } catch (e) {
      log('Error deleting email: $e');
      rethrow;
    }
  }

//get all SMS
  Future<List<ResponseSms>> fetchSms() async {
    try {
      final response = await http.get(Uri.parse('$endpoint/sms'));

      if (response.statusCode == 200) {
        log('Response Body: ${response.body}');
        final SmsModel smsModel = smsModelFromJson(response.body);
        return smsModel.response ?? [];
      }

      throw Exception('Failed to fetch sms: ${response.statusCode}');
    } catch (e) {
      log('Error fetching sms: $e');
      rethrow;
    }
  }

  /// Add a new SMS
  Future<SmsModel> addSms(String sms) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/sms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'value': sms}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        log('Sms added: ${response.body}');
        return SmsModel.fromJson(data);
      }

      throw Exception('Failed to add sms: ${response.statusCode}');
    } catch (e) {
      log('Error adding sms: $e');
      rethrow;
    }
  }

  /// Delete an SMS by ID
  Future<void> deleteSms(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$endpoint/sms/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        log('Sms with ID $id deleted successfully');
        return;
      }

      throw Exception('Failed to delete sms: ${response.statusCode}');
    } catch (e) {
      log('Error deleting sms: $e');
      rethrow;
    }
  }

// Get all Telegram messages
  Future<List<ResponseTelegram>> fetchTelegram() async {
    try {
      final response = await http.get(Uri.parse('$endpoint/telegram'));

      if (response.statusCode == 200) {
        log('Response Body: ${response.body}');
        final TelegramModel telegramModel =
            telegramModelFromJson(response.body);
        return telegramModel.response ?? [];
      }

      throw Exception(
          'Failed to fetch telegram messages: ${response.statusCode}');
    } catch (e) {
      log('Error fetching telegram messages: $e');
      rethrow;
    }
  }

  /// Add a new Telegram message
  Future<TelegramModel> addTelegram(String telegram) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/telegram'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'value': telegram}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        log('Telegram message added: ${response.body}');
        return TelegramModel.fromJson(data);
      }

      throw Exception('Failed to add telegram message: ${response.statusCode}');
    } catch (e) {
      log('Error adding telegram message: $e');
      rethrow;
    }
  }

  /// Delete a Telegram message by ID
  Future<void> deleteTelegram(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$endpoint/telegram/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        log('Telegram message with ID $id deleted successfully');
        return;
      }

      throw Exception(
          'Failed to delete telegram message: ${response.statusCode}');
    } catch (e) {
      log('Error deleting telegram message: $e');
      rethrow;
    }
  }
//search by severity,status and appName

//Future<List<NotificationModel>> 




}
