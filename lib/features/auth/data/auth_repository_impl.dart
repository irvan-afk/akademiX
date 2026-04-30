import 'package:akademiX/core/constants/supabase_constants.dart';
import 'package:akademiX/core/models/user_model.dart';
import 'package:akademiX/core/constants/app_enums.dart';
import 'dart:developer'; // Untuk log yang lebih rapi
import 'package:flutter/foundation.dart'; // Untuk debugPrint

class AuthRepositoryImpl {
  // Login
  Future<UserModel?> login(String username, String password) async {
    try {
      final data = await supabase
          .from('USERS')
          .select()
          .eq('username', username)
          .eq('password_hash', password)
          .single();

      debugPrint("DEBUG REPO LOGIN SUCCESS: $data"); // Cek apakah user ketemu
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint("DEBUG REPO LOGIN ERROR: $e"); // Cek pesan errornya apa
      return null;
    }
  }

  // Get User Detail
  Future<Map<String, dynamic>?> getUserDetail(UserModel user) async {
    try {
      debugPrint("DEBUG REPO FETCHING DETAIL FOR ID: ${user.id} WITH ROLE: ${user.role}");

      if (user.role == UserRole.mahasiswa) {
        final result = await supabase
            .from('MAHASISWA')
            .select('*, KELAS(nama, angkatan, PRODI(nama))')
            .eq('user_id', user.id)
            .single();

        debugPrint("DEBUG REPO DETAIL MAHASISWA: $result"); // Lihat isi Map-nya
        return result;
      }
      // ... (Dosen sama juga)
    } catch (e) {
      debugPrint("DEBUG REPO DETAIL ERROR: $e"); 
      return null;
    }
  }
}