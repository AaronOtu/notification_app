import 'dart:convert';

NotificationModel notificationModelFromJson(String str) =>
    NotificationModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationModel data) =>
    json.encode(data.toJson());

class NotificationModel {
  String? id;
  String appName;
  String title;
  String body;
  String severity;
  String? channel;
  dynamic recipients;
  bool? toAllRecipients;
  String status;

  NotificationModel({
    this.id,
    required this.appName,
    required this.title,
    required this.body,
    required this.severity,
    this.channel,
    this.recipients,
    this.toAllRecipients,
    required this.status,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    dynamic recipientsData;
    if (json["recipients"] is String) {
      recipientsData = json["recipients"];
    } else if (json["recipients"] is Map) {
      recipientsData =
          Recipients.fromJson(json["recipients"] as Map<String, dynamic>);
    }

    return NotificationModel(
      id: json["_id"]?.toString(),
      appName: json["appName"]?.toString() ?? '',
      title: json["title"]?.toString() ?? '',
      body: json["body"]?.toString() ?? '',
      severity: json["severity"]?.toString() ?? '',
      channel: json["channel"]?.toString(),
      recipients: recipientsData,
      toAllRecipients: json["toAllRecipients"] as bool?,
      status: json["status"]?.toString() ?? '',
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
      "status": status,
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
