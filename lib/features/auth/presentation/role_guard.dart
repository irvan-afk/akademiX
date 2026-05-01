import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/auth/view_models/auth_view_model.dart';
import 'package:akademix/features/onboarding/onboarding_view.dart';
import 'package:akademix/core/constants/app_enums.dart';
import 'package:akademix/features/dashboard-dosen/presentation/dashboard_dosen_screen.dart';
import 'package:akademix/features/dashboard-mahasiswa/presentation/dashboard_screen.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    if (authVM.currentUser == null) {
      return const OnboardingView();
    }

    final role = authVM.currentUser!.role;

    //  LOGIKA NAVIGASI BERDASARKAN ROLE
    if (role == UserRole.mahasiswa) {
      return const DashboardMahasiswaScreen();
    } else if (role == UserRole.dosen) {
      return const DashboardDosenScreen();
    } else {
      return const Scaffold(
        body: Center(child: Text("Error: Role tidak dikenali")),
      );
    }
  }
}
