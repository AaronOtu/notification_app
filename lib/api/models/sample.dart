/*
{
  "user": {
    "id": 101,
    "name": "Jane Doe",
    "email": "jane.doe@example.com",
    "profile": {
      "age": 28,
      "gender": "female",
      "interests": ["reading", "traveling", "coding"]
    }
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
  "expires_in": 3600
}
*/

class UserResponseModel {
  final User? user;
  final String? token;
  final int? expiresIn;

  UserResponseModel({this.user, this.token, this.expiresIn});

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
        user: json['user'] != null ? User.fromJson(json['user']) : null,
        token: json['token']?.toString(),
        expiresIn: json['expires_in']?.toInt());
  }
  Map<String, dynamic> toJson() =>
      {'user': user?.toJson(), 'token': token, 'expires_in': expiresIn};
}

class User {
  final int? id;
  final String? name;
  final String? email;
  final Profile? profile;

  User({this.id, this.name, this.email, this.profile});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        id: json['id']?.toInt(),
        name: json['name']?.toString(),
        email: json['email']?.toString(),
        profile:
            json['profile'] != null ? Profile.fromJson(json['profile']) : null);
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'email': email, 'profile': profile?.toJson()};
}

class Profile {
  final int? age;
  final String? gender;
  final List<String>? interests;

  Profile({this.age, this.gender, this.interests});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
        age: json['age']?.toInt(),
        gender: json['gender']?.toString(),
        interests: json['interests'] != null
            ? List<String>.from(json['interests'].map((x) => x))
            : null);
  }

  Map<String, dynamic> toJson() =>
      {'age': age, 'gender': gender, 'interests': interests};
}
