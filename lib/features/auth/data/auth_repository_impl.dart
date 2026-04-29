import 'package:akademiX/core/constants/supabase_constants.dart';
import 'package:akademiX/core/models/user_model.dart';
import 'package:akademiX/core/constants/app_enums.dart';

class AuthRepositoryImpl {

  // Login dengan username + password
  Future<UserModel?> login(String username, String password) async {
  try {
    final data = await supabase
        .from('USERS')
        .select()
        .eq('username', username)
        .eq('password_hash', password) // langsung compare
        .single();

    return UserModel.fromJson(data);
  } catch (e) {
    return null;
  }
}

  // Ambil detail berdasarkan role
  Future<Map<String, dynamic>?> getUserDetail(UserModel user) async {
    try {
      switch (user.role) {
        case UserRole.mahasiswa:
          return await supabase
              .from('mahasiswa')
              .select('*, kelas(nama, angkatan, prodi(nama))')
              .eq('user_id', user.id)
              .single();

        case UserRole.dosen:
          return await supabase
              .from('dosen')
              .select('*, jurusan(nama)')
              .eq('user_id', user.id)
              .single();
      }
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Cek session
  bool isLoggedIn() {
    return supabase.auth.currentSession != null;
  }
}