import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/auth/controllers/auth_controller.dart';
import 'package:akademix/core/constants/app_enums.dart';

import 'dosen_dashboard.dart';
import 'mahasiswa_dashboard.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final role = authController.currentUser?.role;

    if (role == UserRole.dosen) {
      return const DashboardDosenView();
    } else if (role == UserRole.mahasiswa) {
      return const DashboardMahasiswaView();
    } else {
      // Fallback
      return const Scaffold(
        body: Center(child: Text("Role tidak dikenali")),
      );
    }
  }
}
