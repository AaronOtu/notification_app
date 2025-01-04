import 'dart:convert';

EmailModel emailModelFromJson(String str) =>
    EmailModel.fromJson(json.decode(str));

String emailModelToJson(EmailModel data) => json.encode(data.toJson());

class EmailModel {
  bool? status;
  String? message;
  List<Response>? response;

  EmailModel({
    this.status,
    this.message,
    this.response,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) => EmailModel(
        status: json["status"] as bool,
        message: json["message"],
        response: json["response"] == null
            ? []
            : List<Response>.from(
                json["response"]!.map((x) => Response.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "response": response == null
            ? []
            : List<dynamic>.from(response!.map((x) => x.toJson())),
      };
}

class Response {
  String? id;
  String? email;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  Response({
    this.id,
    this.email,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Response.fromJson(Map<String, dynamic> json) => Response(
        id: json["_id"],
        email: json["email"],
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
        "email": email,
        "status": status,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
      };
}