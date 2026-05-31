import 'package:flutter/material.dart';
// Screen imports
import 'package:akademix/features/onboarding/onboarding_view.dart';
import 'package:akademix/features/auth/views/login_view.dart';
import 'package:akademix/features/dashboard/views/dashboard_view.dart';

class Routes {
  static const String onboarding = '/';
  static const String login = '/login';

  // Unified Dashboard
  static const String dashboard = '/dashboard';

  // Specific features
  static const String ujian = '/mahasiswa/ujian';
  static const String kelolaUjian = '/dosen/ujian';
}

class AppPages {
  static Map<String, WidgetBuilder> get routes => {
    Routes.onboarding: (context) => const OnboardingView(),
    Routes.login: (context) => const LoginView(),
    Routes.dashboard: (context) => const DashboardView(),

    Routes.kelolaUjian: (context) =>
        const Scaffold(body: Center(child: Text("Kelola Ujian"))),
  };
}
