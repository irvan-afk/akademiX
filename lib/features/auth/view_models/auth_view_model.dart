import 'package:flutter/material.dart';
import 'package:akademix/core/models/user_model.dart';
import 'package:akademix/features/auth/model/auth_usecase.dart';

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

  int? get mahasiswaId => _userData != null ? _userData!['id'] as int? : null;

  Future<bool> loginProcess(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authUsecase.login(username, password);

      // --- DEBUGGING AREA ---
      print("--- HASIL LOGIN SUPABASE ---");
      print("Login Sukses: ${result.isSuccess}");
      if (result.isSuccess) {
        print("Role Terdeteksi: ${result.user?.role}");
        print("Username: ${result.user?.username}");
      } else {
        print("Error Message: ${result.errorMessage}");
      }

      if (result.isSuccess) {
        _currentUser = result.user;
        _userData = result.detail;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage;
        return false;
      }
    } catch (e) {
      print("Exception Error: $e");
      _errorMessage = "Terjadi kesalahan sistem: $e";
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
