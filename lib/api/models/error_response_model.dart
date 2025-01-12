import 'dart:convert';

ErrorModel
 notificationModelFromJson(String str) =>
    ErrorModel
    .fromJson(json.decode(str));

String notificationModelToJson(ErrorModel
 data) =>
    json.encode(data.toJson());

class ErrorModel
 {
  String id;
  String appName;
  String title;
  String body;
  String severity;
  String? channel;
  dynamic recipients;
  bool? toAllRecipients;
  bool? errorLogs;
  String status;
  DateTime createdAt;
  DateTime updatedAt;

  ErrorModel
  ({
    required this.id,
    required this.appName,
    required this.title,
    required this.body,
    required this.severity,
    this.channel,
    this.recipients,
    this.toAllRecipients,
    this.errorLogs,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ErrorModel
  .fromJson(Map<String, dynamic> json) {
    dynamic recipientsData;
    if (json["recipients"] is String) {
      recipientsData = json["recipients"];
    } else if (json["recipients"] is Map) {
      recipientsData =
          Recipients.fromJson(json["recipients"] as Map<String, dynamic>);
    }
     DateTime parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now(); // Return current date if null or empty
    }

    try {
      // Attempt to parse the date in the ISO 8601 format
      return DateTime.parse(dateStr);
    } catch (e) {
      // If parsing fails, fallback to a custom format (e.g., without 'Z')
      try {
        return DateTime.parse(dateStr.replaceFirst('Z', '')); // Remove 'Z' for parsing
      } catch (_) {
        return DateTime.now(); // Return current date if both attempts fail
      }
    }
  }

    return ErrorModel
    (
      id: json["_id"]?.toString() ?? '',
      appName: json["appName"]?.toString() ?? '',
      title: json["title"]?.toString() ?? '',
      body: json["body"]?.toString() ?? '',
      severity: json["severity"]?.toString() ?? '',
      channel: json["channel"]?.toString(),
      recipients: recipientsData,
      toAllRecipients: json["toAllRecipients"] as bool?,
      errorLogs: json["errorLogs"] as bool?,
      status: json["status"]?.toString() ?? '',
      createdAt: //json["createdAt"] != null 
           parseDate(json["createdAt"].toString()),
          //: null,
      updatedAt: //json["updatedAt"] != null 
          parseDate(json["updatedAt"].toString())
          //: null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "_id": id,
      "appName": appName,
      "title": title,
      "body": body,
      "severity": severity,
      "channel": channel,
      "toAllRecipients": toAllRecipients,
      "errorLogs": errorLogs,
      "status": status,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };

    if (recipients is String) {
      data["recipients"] = recipients;
    } else if (recipients is Recipients) {
      data["recipients"] = (recipients as Recipients).toJson();
    }

    return data;
  }
}

class Recipients {
  String? email;
  String? telegram;
  String? sms;

  Recipients({
    this.email,
    this.telegram,
    this.sms,
  });

  factory Recipients.fromJson(Map<String, dynamic> json) {
    return Recipients(
      email: json["email"]?.toString(),
      telegram: json["telegram"]?.toString(),
      sms: json["sms"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        "email": email,
        "telegram": telegram,
        "sms": sms,
      };
}