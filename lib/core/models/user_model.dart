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
    final String roleRaw = json['role']?.toString() ?? '';

    return UserModel(
      id: json['id'],
      role: UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == roleRaw.toLowerCase(),
        orElse: () => UserRole.mahasiswa,
      ),
      username: json['username'] ?? '',
      deviceId: json['device_id'],
    );
  }
}
