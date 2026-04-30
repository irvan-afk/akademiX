import 'package:flutter/material.dart';
import 'package:akademiX/core/models/user_model.dart';
import 'package:akademiX/features/auth/model/auth_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthUsecase _authUsecase;

  AuthViewModel(this._authUsecase);

  UserModel? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;
  String? get errorMessage => _errorMessage;

  Future<bool> loginProcess(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authUsecase.login(username, password);

      // --- DEBUGGING LOG ---
      print("--- HASIL LOGIN SUPABASE ---");
      print("Login Sukses: ${result.isSuccess}");

      if (result.isSuccess) {
        _currentUser = result.user;

        // KRUSIAL: Pastikan result.detail dari Usecase tidak kosong
        _userData = result.detail;

        print("Role Terdeteksi: ${_currentUser?.role}");
        print("Username: ${_currentUser?.username}");
        // Jika ini masih null di log, cek query join di AuthRepository/Usecase kamu
        print("Detail Data (Dosen ID): ${_userData?['id']}");

        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage;
        notifyListeners(); // Pastikan notify agar UI tahu ada error
        return false;
      }
    } catch (e) {
      print("Exception Error: $e");
      _errorMessage = "Terjadi kesalahan sistem: $e";
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _userData = null;
    notifyListeners();
  }
}
