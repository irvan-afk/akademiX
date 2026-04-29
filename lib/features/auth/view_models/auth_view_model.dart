import 'package:flutter/material.dart'; // Digunakan untuk ChangeNotifier dan debugPrint
import 'package:akademiX/core/models/user_model.dart'; // Sesuaikan dengan letak UserModel kamu
import 'package:akademiX/features/auth/data/auth_repository_impl.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepositoryImpl _authRepo = AuthRepositoryImpl();
  
  UserModel? _currentUser;
  Map<String, dynamic>? _userData; // Menyimpan detail Mahasiswa/Dosen
  bool _isLoading = false;

  // Getter untuk digunakan di UI
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  UserModel? get currentUser => _currentUser;

  /// Fungsi Login
  /// Mengembalikan [bool] agar UI tahu kapan harus pindah halaman (navigasi)
  Future<bool> loginProcess(String username, String password) async {
    _isLoading = true;
    notifyListeners(); 

    try {
      // Langkah 1: Login untuk dapatkan data User dasar
      final user = await _authRepo.login(username, password);

      if (user != null) {
        _currentUser = user;
        
        // Langkah 2: Ambil detail (Mahasiswa/Dosen) berdasarkan role
        _userData = await _authRepo.getUserDetail(user);
        
        return true; // Login Berhasil
      } else {
        return false; // Login Gagal (User tidak ditemukan)
      }
    } catch (e) {
      debugPrint("Error login: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  /// Fungsi Logout untuk membersihkan sesi di memori
  void logout() {
    _currentUser = null;
    _userData = null;
    notifyListeners();
  }
}