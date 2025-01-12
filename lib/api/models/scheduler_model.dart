// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

SchedulerModel welcomeFromJson(String str) => SchedulerModel.fromJson(json.decode(str));

String welcomeToJson(SchedulerModel data) => json.encode(data.toJson());

class SchedulerModel {
    bool? status;
    String? message;
    List<Response>? response;

    SchedulerModel({
        this.status,
        this.message,
        this.response,
    });

    factory SchedulerModel.fromJson(Map<String, dynamic> json) => SchedulerModel(
        status: json["status"],
        message: json["message"],
        response: json["response"] == null ? [] : List<Response>.from(json["response"]!.map((x) => Response.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "response": response == null ? [] : List<dynamic>.from(response!.map((x) => x.toJson())),
    };
}

class Response {
    String? id;
    bool? status;
    DateTime? createdAt;
    DateTime? updatedAt;
    int? v;

    Response({
        this.id,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.v,
    });

    factory Response.fromJson(Map<String, dynamic> json) => Response(
        id: json["_id"],
        status: json["status"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "status": status,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
    };
}
