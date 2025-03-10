// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:notification_app/api/models/email_response_model.dart';
import 'package:notification_app/api/models/error_response_model.dart' as error;
import 'package:notification_app/api/models/notification_model.dart';
import 'dart:developer';

import 'package:notification_app/api/models/sms_response.dart';
import 'package:notification_app/api/models/telegram_respone.dart';
import 'package:pretty_logger/pretty_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:logger/logger.dart';

class ApiService {
  final String endpoint = 'https://sandbox-api.etranzact.com.gh/notify/api';
  //final String endpoint = 'http://192.168.56.1:3000/api';

  static const String _notificationsCacheKey = 'cached_notifications';

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
          final List<NotificationModel> notification = data
              .map((item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();

          //cache notifications
          await _cacheNotifications(notification);

          return notification;
        } else {
          throw Exception('Invalid JSON structure: missing "response" key');
        }
      } else {
        return await _getCachedNotifications();
        //throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching alerts: $e');
      return await _getCachedNotifications();
      //throw Exception('Error fetching alerts: $e');
    }
  }

  // Cache notifications to SharedPreferences
  Future<void> _cacheNotifications(
      List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = notifications.map((n) => n.toJson()).toList();
    await prefs.setString(
        _notificationsCacheKey, jsonEncode(notificationsJson));
  }

  // Retrieve cached notifications
  Future<List<NotificationModel>> _getCachedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedNotificationsJson = prefs.getString(_notificationsCacheKey);

    if (cachedNotificationsJson != null) {
      final List<dynamic> cachedData = jsonDecode(cachedNotificationsJson);
      return cachedData
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    }

    // Return empty list if no cached data
    return [];
  }

  // get all errors
  Future<List<error.ErrorModel>> fetchErrorLogs() async {
    try {
      final response = await http.get(Uri.parse('$endpoint/errorLogs'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = jsonDecode(response.body);
        //log(response.body);
        //Logger(level: Level.verbose, printer:PrettyPrinter()).i(response.body);
        PLog.green(response.body);

        if (decodedBody.containsKey('response')) {
          final List<dynamic> data = decodedBody['response'];
          return data
              .map((item) =>
                  error.ErrorModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid JSON structure: missing "response" key');
        }
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching errorLogs alerts: $e');
      throw Exception('Error fetching alerts: $e');
    }
  }

  Future<NotificationModel?> resolveAlert(String id) async {
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
        // Parse the response into a NotificationModel
        final notification = NotificationModel.fromJson(data['response']);
        log('Alert with ID $id is resolved');
        return notification;
      } else {
        log('Failed to resolve alert. Status Code: ${response.statusCode}');
        log('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error resolving alert with ID $id: $e');
      return null;
    }
  }

  //reset Scheduler
  Future<bool> resetScheduler(bool status) async {
    try {
      final response = await http.patch(
        Uri.parse('$endpoint/scheduler/toggle'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final bool notificationData = data['response']['status'] as bool;
        log('Scheduler status is $notificationData');
        return true;
      } else {
        log('Failed to reset scheduler. Status Code: ${response.statusCode}');
        log('Response Body: ${response.body}');
        return false;
      }
    } catch (e) {
      log('Error resetting scheduler: $e');
      return false;
    }
  }

  Future<List<Response>> fetchEmails() async {
    try {
      final response = await http.get(Uri.parse('$endpoint/email'));

      if (response.statusCode == 200) {
        log('Response Body: ${response.body}');
        final EmailModel emailModel = emailModelFromJson(response.body);
        final emails = emailModel.response ?? [];
        await _cacheEmails(emails);

        return emails;
      } else {
        return await _getCachedEmails();
      }

      // throw Exception('Failed to fetch emails: ${response.statusCode}');
    } catch (e) {
      log('Error fetching emails: $e');
      //rethrow;
      return await _getCachedEmails();
    }
  }

// Cache emails to SharedPreferences
  Future<void> _cacheEmails(List<Response> emails) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert each Response to a JSON map first
    final List<Map<String, dynamic>> emailsJsonList =
        emails.map((email) => email.toJson()).toList();
    // Then encode the entire list
    await prefs.setString('_emailsCacheKey', jsonEncode(emailsJsonList));
  }

// Retrieve cached emails
  Future<List<Response>> _getCachedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedEmailsJson = prefs.getString('_emailsCacheKey');

    if (cachedEmailsJson != null) {
      // Decode the JSON string to a List first
      final List<dynamic> cachedData = jsonDecode(cachedEmailsJson);
      // Then map each item to a Response object
      return cachedData
          .map((item) => Response.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Return empty list if no cached data
    return [];
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
        final sms = smsModel.response ?? [];
        await _cacheSms(sms);
        return sms;
      } else {
        return await _getCachedSms();
      }

      //throw Exception('Failed to fetch sms: ${response.statusCode}');
    } catch (e) {
      log('Error fetching sms: $e');
      // rethrow;
      return await _getCachedSms();
    }
  }

  Future<void> _cacheSms(List<ResponseSms> sms) async {
    final prefs = await SharedPreferences.getInstance();

    final List<Map<String, dynamic>> smsJsonList =
        sms.map((sms) => sms.toJson()).toList();

    await prefs.setString('_smsCacheKey', jsonEncode(smsJsonList));
  }

  Future<List<ResponseSms>> _getCachedSms() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSmsJson = prefs.getString('_smsCacheKey');

    if (cachedSmsJson != null) {
      // Decode the JSON string to a List first
      final List<dynamic> cachedData = jsonDecode(cachedSmsJson);
      // Then map each item to a Response object
      return cachedData
          .map((item) => ResponseSms.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Return empty list if no cached data
    return [];
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
        final telegram = telegramModel.response ?? [];
        await _cacheTelegram(telegram);
        return telegram;
      } else {
        return _getCachedTelegram();
      }

      //throw Exception('Failed to fetch telegram messages: ${response.statusCode}');
    } catch (e) {
      log('Error fetching telegram messages: $e');
      //rethrow;
      return _getCachedTelegram();
    }
  }

  Future<void> _cacheTelegram(List<ResponseTelegram> telegram) async {
    final prefs = await SharedPreferences.getInstance();

    final List<Map<String, dynamic>> telegramJsonList =
        telegram.map((telegram) => telegram.toJson()).toList();

    await prefs.setString('_telegramCacheKey', jsonEncode(telegramJsonList));
  }

  Future<List<ResponseTelegram>> _getCachedTelegram() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTelegramJson = prefs.getString('_telegramCacheKey');

    if (cachedTelegramJson != null) {
      // Decode the JSON string to a List first
      final List<dynamic> cachedData = jsonDecode(cachedTelegramJson);
      // Then map each item to a Response object
      return cachedData
          .map(
              (item) => ResponseTelegram.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Return empty list if no cached data
    return [];
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

  Future<List<NotificationModel>> searchNotification({
    String? appName,
    String? severity,
    String? channel,
    String? createdAt,
    bool? toAllRecipient,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (appName != null && appName.isNotEmpty) {
        queryParams['appName'] = appName;
      }
      if (severity != null && severity.isNotEmpty) {
        queryParams['severity'] = severity;
      }
      if (channel != null && channel.isNotEmpty) {
        queryParams['channel'] = channel;
      }
      if (createdAt != null && createdAt.isNotEmpty) {
        queryParams['createdAt'] = createdAt;
      }
      if (toAllRecipient != null) {
        queryParams['toAllRecipient'] = toAllRecipient.toString();
      }

      final uri =
          Uri.parse('$endpoint/search').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedBody = json.decode(response.body);

        if (decodedBody.containsKey('response')) {
          final List<dynamic> data = decodedBody['response'];
          return data
              .map((item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          log('Unexpected JSON structure: $decodedBody');
          throw Exception('Unexpected response format: missing "response" key');
        }
      }

      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    } catch (e) {
      log('Error fetching notifications for filtering: $e');
      rethrow;
    }
  }
}
