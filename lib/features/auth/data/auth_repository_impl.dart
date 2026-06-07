import 'package:akademix/core/constants/supabase_constants.dart';
import 'package:akademix/core/models/user_model.dart';
import 'package:akademix/core/constants/app_enums.dart';
import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthRepositoryImpl {
  // Login
  Future<UserModel?> login(String username, String password) async {
    try {
      final data = await supabase
          .from('USERS')
          .select()
          .eq('username', username)
          .single();

      final String storedHash = data['password_hash'];
      final bool isMatch = BCrypt.checkpw(password, storedHash);

      if (!isMatch) {
        debugPrint("DEBUG REPO LOGIN ERROR: Invalid password");
        return null;
      }

      final newDeviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await supabase
          .from('USERS')
          .update({'device_id': newDeviceId})
          .eq('id', data['id']);
      data['device_id'] = newDeviceId;

      debugPrint("DEBUG REPO LOGIN SUCCESS: ${_sanitizeForLog(data)}");
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint("DEBUG REPO LOGIN ERROR: $e");
      return null;
    }
  }

  // Get User Detail
  Future<Map<String, dynamic>?> getUserDetail(UserModel user) async {
    try {
      debugPrint(
        "DEBUG REPO FETCHING DETAIL FOR ID: ${user.id} WITH ROLE: ${user.role}",
      );

      if (user.role == UserRole.mahasiswa) {
        final result = await supabase
            .from('MAHASISWA')
            .select('*, KELAS(nama, angkatan, PRODI(nama))')
            .eq('user_id', user.id)
            .single();

        debugPrint("DEBUG REPO DETAIL MAHASISWA: ${_sanitizeForLog(result)}");
        return result;
      } else if (user.role == UserRole.dosen) {
        final result = await supabase
            .from('DOSEN')
            .select('*, JURUSAN(nama)')
            .eq('user_id', user.id)
            .single();

        debugPrint("DEBUG REPO DETAIL DOSEN: ${_sanitizeForLog(result)}");
        return result;
      }
      return null;
    } catch (e) {
      debugPrint("DEBUG REPO DETAIL ERROR: $e");
      return null;
    }
  }

  // Verify Session
  Future<bool> verifySession(int userId, String currentDeviceId) async {
    try {
      final data = await supabase
          .from('USERS')
          .select('device_id')
          .eq('id', userId)
          .single();
      
      return data['device_id'] == currentDeviceId;
    } catch (e) {
      debugPrint("DEBUG REPO VERIFY SESSION ERROR: $e");
      return true; // Keep logged in on network error
    }
  }

  // Change Password
  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    try {
      final data = await supabase
          .from('USERS')
          .select()
          .eq('id', userId)
          .single();

      final String storedHash = data['password_hash'];
      final bool isMatch = BCrypt.checkpw(oldPassword, storedHash);

      if (!isMatch) {
        debugPrint("DEBUG REPO CHANGE PASSWORD ERROR: Old password mismatch");
        return false;
      }

      final String newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await supabase
          .from('USERS')
          .update({'password_hash': newHash})
          .eq('id', userId);

      debugPrint("DEBUG REPO CHANGE PASSWORD SUCCESS");
      return true;
    } catch (e) {
      debugPrint("DEBUG REPO CHANGE PASSWORD ERROR: $e");
      return false;
    }
  }

  // Update Avatar
  Future<bool> updateAvatar(int userId, UserRole role, String avatarUrl) async {
    try {
      if (role == UserRole.mahasiswa) {
        await supabase
            .from('MAHASISWA')
            .update({'avatar_url': avatarUrl})
            .eq('user_id', userId);
      } else if (role == UserRole.dosen) {
        await supabase
            .from('DOSEN')
            .update({'avatar_url': avatarUrl})
            .eq('user_id', userId);
      }
      debugPrint("DEBUG REPO UPDATE AVATAR SUCCESS");
      return true;
    } catch (e) {
      debugPrint("DEBUG REPO UPDATE AVATAR ERROR (Safe fallback): $e");
      return false; // Safely catches column/table exceptions
    }
  }

  Map<String, dynamic> _sanitizeForLog(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is String && value.length > 100) {
        return MapEntry(key, "${value.substring(0, 100)}... (truncated)");
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _sanitizeForLog(value));
      }
      return MapEntry(key, value);
    });
  }
}
