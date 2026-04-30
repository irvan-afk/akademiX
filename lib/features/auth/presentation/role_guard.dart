import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
import 'package:akademiX/features/onboarding/onboarding_view.dart';
import 'package:akademiX/core/constants/app_enums.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    // 1. Jika belum login, tetap di Onboarding
    if (authVM.currentUser == null) {
      return const OnboardingView();
    }

    // 2. Jika sudah login, tampilkan halaman sementara agar tidak merah/error
    final role = authVM.currentUser!.role;
    final username = authVM.currentUser!.username;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          role == UserRole.mahasiswa ? 'Home Mahasiswa' : 'Home Dosen',
        ),
        backgroundColor: const Color(0xFF2962FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authVM.logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text(
              'Berhasil Login sebagai $role',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Halo, $username!', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text(
              'Segera lakukan "git pull" untuk\nmelihat dashboard buatan temanmu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
