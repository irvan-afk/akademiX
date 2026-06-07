import 'package:akademix/core/models/user_model.dart';
import 'package:akademix/features/auth/data/auth_repository_impl.dart';

import 'package:akademix/core/constants/app_enums.dart';

class AuthUsecase {
  final AuthRepositoryImpl _repo;

  AuthUsecase(this._repo);

  Future<AuthResult> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return AuthResult.error('Username dan password wajib diisi');
    }

    final user = await _repo.login(username, password);

    if (user == null) {
      return AuthResult.error('Username atau password salah');
    }

    final detail = await _repo.getUserDetail(user);

    return AuthResult.success(user, detail);
  }

  Future<bool> verifySession(int userId, String currentDeviceId) async {
    return await _repo.verifySession(userId, currentDeviceId);
  }

  Future<Map<String, dynamic>?> getUserDetail(UserModel user) async {
    return await _repo.getUserDetail(user);
  }

  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    return await _repo.changePassword(userId, oldPassword, newPassword);
  }

  Future<bool> updateAvatar(int userId, UserRole role, String avatarUrl) async {
    return await _repo.updateAvatar(userId, role, avatarUrl);
  }
}

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;
  final Map<String, dynamic>? detail;

  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.user,
    this.detail,
  });

  factory AuthResult.success(UserModel user, Map<String, dynamic>? detail) {
    return AuthResult._(isSuccess: true, user: user, detail: detail);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
