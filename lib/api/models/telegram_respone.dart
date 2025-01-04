import 'dart:convert';

TelegramModel telegramModelFromJson(String str) =>
    TelegramModel.fromJson(json.decode(str));

String telegramModelToJson(TelegramModel data) => json.encode(data.toJson());

class TelegramModel {
  bool? status;
  String? message;
  List<ResponseTelegram>? response;

  TelegramModel({
    this.status,
    this.message,
    this.response,
  });

  factory TelegramModel.fromJson(Map<String, dynamic> json) => TelegramModel(
        status: json["status"] as bool,
        message: json["message"],
        response: json["response"] == null
            ? []
            : List<ResponseTelegram>.from(
                json["response"]!.map((x) => ResponseTelegram.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "response": response == null
            ? []
            : List<dynamic>.from(response!.map((x) => x.toJson())),
      };
}

class ResponseTelegram {
  String? id;
  String? telegram;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  ResponseTelegram({
    this.id,
    this.telegram,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory ResponseTelegram.fromJson(Map<String, dynamic> json) => ResponseTelegram(
        id: json["_id"],
        telegram: json["telegram"],
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
        "telegram": telegram,
        "status": status,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
      };
}
