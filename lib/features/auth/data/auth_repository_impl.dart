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

      debugPrint("DEBUG REPO LOGIN SUCCESS: $data");
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

        debugPrint("DEBUG REPO DETAIL MAHASISWA: $result");
        return result;
      } else if (user.role == UserRole.dosen) {
        final result = await supabase
            .from('DOSEN')
            .select('*, JURUSAN(nama)')
            .eq('user_id', user.id)
            .single();

        debugPrint("DEBUG REPO DETAIL DOSEN: $result");
        return result;
      }
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
}
