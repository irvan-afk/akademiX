import '../constants/app_enums.dart';

class UserModel {
  final int id;
  final UserRole role;
  final String username;
  final String? deviceId;

  UserModel({
    required this.id,
    required this.role,
    required this.username,
    this.deviceId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      role: UserRole.values.firstWhere(
        (e) => e.name.toUpperCase() == json['role'].toString().toUpperCase(),
      ),
      username: json['username'],
      deviceId: json['device_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name.toUpperCase(),
      'username': username,
      'device_id': deviceId,
    };
  }
}