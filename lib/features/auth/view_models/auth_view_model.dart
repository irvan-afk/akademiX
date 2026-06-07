import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:akademix/core/models/user_model.dart';
import 'package:akademix/features/auth/model/auth_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthUsecase _authUsecase;
  Timer? _sessionTimer;

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
        
        // Load avatar, email, and no_hp from local Hive
        final settingsBox = Hive.box('settings');
        final localAvatar = settingsBox.get('avatar_${_currentUser!.id}');
        if (localAvatar != null && _userData != null) {
          _userData!['avatar_url'] = localAvatar;
        }
        final localEmail = settingsBox.get('email_${_currentUser!.id}');
        if (localEmail != null && _userData != null) {
          _userData!['email'] = localEmail;
        }
        final localNoHp = settingsBox.get('no_hp_${_currentUser!.id}');
        if (localNoHp != null && _userData != null) {
          _userData!['no_hp'] = localNoHp;
        }

        _startSessionTimer();
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
    _stopSessionTimer();
    _currentUser = null;
    _userData = null;
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) {
      _errorMessage = "Sesi tidak aktif.";
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _authUsecase.changePassword(_currentUser!.id, oldPassword, newPassword);
      if (!success) {
        _errorMessage = "Kata sandi lama salah atau gagal diubah.";
      }
      return success;
    } catch (e) {
      _errorMessage = "Terjadi kesalahan: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAvatar(String avatarUrl) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // 1. Simpan di Hive
      final settingsBox = Hive.box('settings');
      await settingsBox.put('avatar_${_currentUser!.id}', avatarUrl);
      
      // 2. Update local state
      if (_userData != null) {
        _userData!['avatar_url'] = avatarUrl;
      }
      
      // 3. Update remote database (async safe)
      await _authUsecase.updateAvatar(_currentUser!.id, _currentUser!.role, avatarUrl);
      
      return true;
    } catch (e) {
      debugPrint("updateAvatar error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEmail(String email) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // 1. Simpan di Hive
      final settingsBox = Hive.box('settings');
      await settingsBox.put('email_${_currentUser!.id}', email);
      
      // 2. Update local state
      if (_userData != null) {
        _userData!['email'] = email;
      }
      
      return true;
    } catch (e) {
      debugPrint("updateEmail error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNoHp(String noHp) async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // 1. Simpan di Hive
      final settingsBox = Hive.box('settings');
      await settingsBox.put('no_hp_${_currentUser!.id}', noHp);
      
      // 2. Update local state
      if (_userData != null) {
        _userData!['no_hp'] = noHp;
      }
      
      return true;
    } catch (e) {
      debugPrint("updateNoHp error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshUserData() async {
    if (_currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final detail = await _authUsecase.getUserDetail(_currentUser!);
      if (detail != null) {
        _userData = detail;
        
        // Load avatar, email, and no_hp from local Hive
        final settingsBox = Hive.box('settings');
        final localAvatar = settingsBox.get('avatar_${_currentUser!.id}');
        if (localAvatar != null) {
          _userData!['avatar_url'] = localAvatar;
        }
        final localEmail = settingsBox.get('email_${_currentUser!.id}');
        if (localEmail != null) {
          _userData!['email'] = localEmail;
        }
        final localNoHp = settingsBox.get('no_hp_${_currentUser!.id}');
        if (localNoHp != null) {
          _userData!['no_hp'] = localNoHp;
        }
      }
      return true;
    } catch (e) {
      debugPrint("refreshUserData error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startSessionTimer() {
    _stopSessionTimer();
    // Cek setiap 10 detik apakah akun login di device lain
    _sessionTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_currentUser == null || _currentUser!.deviceId == null) return;
      
      final isValid = await _authUsecase.verifySession(_currentUser!.id, _currentUser!.deviceId!);
      if (!isValid) {
        print("Sesi tidak valid (login di device lain). Logout otomatis.");
        logout();
      }
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }
}
