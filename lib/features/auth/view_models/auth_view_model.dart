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

      // --- DEBUGGING AREA ---
      print("--- HASIL LOGIN SUPABASE ---");
      print("Login Sukses: ${result.isSuccess}");
      if (result.isSuccess) {
        print("Role Terdeteksi: ${result.user?.role}");
        print("Username: ${result.user?.username}");
      } else {
        print("Error Message: ${result.errorMessage}");
      }
      // -----------------------

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
      print("Exception Error: $e"); // Debug jika ada crash
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
