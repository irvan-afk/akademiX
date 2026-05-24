import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

/// Controller untuk menangani security dan lifecycle logic selama exam
class SesiUjianController extends ChangeNotifier {
  // ============ STATE ============
  int _violationCount = 0;
  bool _isInternetDialogShowing = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // ============ GETTERS ============
  int get violationCount => _violationCount;
  bool get isInternetDialogShowing => _isInternetDialogShowing;

  // ============ INITIALIZATION ============
  /// Initialize security features saat exam dimulai
  Future<void> initializeSecurityFeatures() async {
    try {
      // 1. Clear clipboard
      await Clipboard.setData(const ClipboardData(text: ''));

      // 2. Enable screen protection
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithBlur(); // For iOS

      // 3. Monitor connectivity
      _monitorConnectivity();
    } catch (e) {
      debugPrint('SesiUjianController.initializeSecurityFeatures error: $e');
    }
  }

  // ============ CONNECTIVITY MONITORING ============
  /// Monitor connectivity changes during exam
  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final hasInternet =
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi);

      if (hasInternet) {
        // Internet detected - trigger warning
        _isInternetDialogShowing = true;
        notifyListeners();
      } else {
        // Internet turned off - close warning if showing
        if (_isInternetDialogShowing) {
          _isInternetDialogShowing = false;
          notifyListeners();
        }
      }
    });
  }

  // ============ INTERNET WARNING ============
  /// Mark internet dialog as shown
  void setInternetDialogShowing(bool isShowing) {
    _isInternetDialogShowing = isShowing;
    notifyListeners();
  }

  // ============ APP LIFECYCLE HANDLING ============
  /// Handle app lifecycle changes (pause/resume)
  /// Returns true if violation occurred
  bool handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Clear clipboard when app resumes
        Clipboard.setData(const ClipboardData(text: ''));
        return false;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // User left exam (home button, switch app, etc)
        _violationCount++;
        return true;

      case AppLifecycleState.detached:
        return false;

      case AppLifecycleState.hidden:
        return false;
    }
  }

  // ============ CLEANUP ============
  /// Disable security features when exam is done
  Future<void> disableSecurityFeatures() async {
    try {
      await _connectivitySubscription.cancel();
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageWithBlurOff();
    } catch (e) {
      debugPrint('SesiUjianController.disableSecurityFeatures error: $e');
    }
  }

  @override
  void dispose() {
    try {
      _connectivitySubscription.cancel();
    } catch (e) {
      debugPrint('Error canceling subscription in dispose: $e');
    }
    super.dispose();
  }
}
