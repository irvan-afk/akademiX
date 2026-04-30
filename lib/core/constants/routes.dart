import 'package:flutter/material.dart';
// Screen imports
import 'package:akademiX/features/onboarding/onboarding_view.dart';
import 'package:akademiX/features/auth/presentation/login_screen.dart';
import 'package:akademiX/features/dashboard-mahasiswa/presentation/dashboard_screen.dart';


class Routes {
  static const String onboarding = '/';
  static const String login = '/login';

  // Mahasiswa
  static const String mahasiswaHome = '/mahasiswa/home';
  static const String ujian = '/mahasiswa/ujian';

  // Dosen
  static const String dosenHome = '/dosen/home';
  static const String kelolaUjian = '/dosen/ujian';

}



class AppPages {
  static Map<String, WidgetBuilder> get routes => {
    Routes.onboarding: (context) => const OnboardingView(),
    Routes.login: (context) => const LoginScreen(),
    
    // Mahasiswa
    Routes.mahasiswaHome: (context) => const DashboardMahasiswaScreen(),

    // Dosen (Ganti Placeholder ini dengan class screen dosenmu nanti)
    Routes.dosenHome: (context) => const Scaffold(body: Center(child: Text("Home Dosen"))),
    Routes.kelolaUjian: (context) => const Scaffold(body: Center(child: Text("Kelola Ujian"))),
  };
}