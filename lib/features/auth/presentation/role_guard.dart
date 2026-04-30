import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
import 'package:akademiX/features/onboarding/onboarding_view.dart';
import 'package:akademiX/core/constants/app_enums.dart';
import 'package:akademiX/features/dashboard-mahasiswa/presentation/dashboard_screen.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch memastikan widget rebuild saat status login berubah
    final authVM = context.watch<AuthViewModel>();

    // 1. Jika sesi kosong (belum login), arahkan ke pintu awal
    if (authVM.currentUser == null) {
      return const OnboardingView();
    }

    // 2. Jika sudah login, arahkan ke dashboard asli
    final role = authVM.currentUser!.role;

    if (role == UserRole.mahasiswa) {
      return const DashboardMahasiswaScreen();
    } else if (role == UserRole.dosen) {
      return const Scaffold(
        body: Center(child: Text("Dashboard Dosen Belum Tersedia")),
      );
    } else {
      return const Scaffold(
        body: Center(child: Text("Error: Role tidak dikenali")),
      );
    }
  }
}
