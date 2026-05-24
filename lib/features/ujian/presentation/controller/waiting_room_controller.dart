import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/database/local_db_service.dart';

class WaitingRoomController extends ChangeNotifier {
  // ============ STATE ============
  bool _isOffline = false;
  String? _pinBenar;
  String? _errorMessage;
  bool _isLoading = false;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // ============ GETTERS ============
  bool get isOffline => _isOffline;
  String? get pinBenar => _pinBenar;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // ============ INITIALIZATION ============
  WaitingRoomController() {
    _initConnectivity();
  }

  // ============ LOAD EXAM PIN FROM DATABASE ============
  /// Load PIN dari local database
  Future<void> loadExamPin(int ujianId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dataLokal = await LocalDbService.instance.getUjianLokal(ujianId);
      if (dataLokal != null) {
        _pinBenar = dataLokal['pin_mulai'];
        _errorMessage = null;
      } else {
        _errorMessage = 'Data ujian tidak ditemukan';
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat PIN: $e';
      debugPrint('WaitingRoomController.loadExamPin error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ CONNECTIVITY MONITORING ============
  /// Initialize connectivity monitoring
  void _initConnectivity() async {
    try {
      // Check initial connectivity status
      final List<ConnectivityResult> initialResult = await Connectivity()
          .checkConnectivity();
      _updateConnectionStatus(initialResult);

      // Listen to connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        List<ConnectivityResult> result,
      ) {
        _updateConnectionStatus(result);
      });
    } catch (e) {
      debugPrint('WaitingRoomController._initConnectivity error: $e');
    }
  }

  /// Update offline status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    bool isCurrentlyOffline =
        !result.contains(ConnectivityResult.mobile) &&
        !result.contains(ConnectivityResult.wifi);

    if (_isOffline != isCurrentlyOffline) {
      _isOffline = isCurrentlyOffline;
      notifyListeners();
    }
  }

  // ============ PIN VERIFICATION ============
  /// Verify if PIN input is correct
  bool verifyPin(String input) {
    if (_pinBenar == null) {
      _errorMessage = 'PIN belum dimuat';
      return false;
    }
    return input.trim() == _pinBenar;
  }

  // ============ CLEANUP ============
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
