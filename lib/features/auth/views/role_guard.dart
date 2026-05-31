import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/auth/controllers/auth_controller.dart';
import 'package:akademix/features/onboarding/onboarding_view.dart';
import 'package:akademix/features/dashboard/views/dashboard_view.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthController>();

    if (authVM.currentUser == null) {
      return const OnboardingView();
    }

    // Role detection and navigation is now handled in DashboardView
    return const DashboardView();
  }
}
