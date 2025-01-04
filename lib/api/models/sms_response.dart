import 'dart:convert';

SmsModel smsModelFromJson(String str) =>
    SmsModel.fromJson(json.decode(str));

String smsModelToJson(SmsModel data) => json.encode(data.toJson());

class SmsModel {
  bool? status;
  String? message;
  List<ResponseSms>? response;

  SmsModel({
    this.status,
    this.message,
    this.response,
  });

  factory SmsModel.fromJson(Map<String, dynamic> json) => SmsModel(
        status: json["status"] as bool,
        message: json["message"],
        response: json["response"] == null
            ? []
            : List<ResponseSms>.from(
                json["response"]!.map((x) => ResponseSms.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "response": response == null
            ? []
            : List<dynamic>.from(response!.map((x) => x.toJson())),
      };
}

class ResponseSms {
  String? id;
  String? sms;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  ResponseSms({
    this.id,
    this.sms,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory ResponseSms.fromJson(Map<String, dynamic> json) => ResponseSms(
        id: json["_id"],
        sms: json["sms"],
        status: json["status"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "sms": sms,
        "status": status,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
      };
}