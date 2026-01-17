import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String name;

  UserModel({required this.id, required this.email, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'name': name};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}

class AuthResponse {
  final UserModel user;
  final String token;

  AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromMap(Map<String, dynamic> map) {
    return AuthResponse(
      user: UserModel.fromMap(map['user']),
      token: map['token'] ?? '',
    );
  }

  factory AuthResponse.fromJson(String source) =>
      AuthResponse.fromMap(json.decode(source));
}
