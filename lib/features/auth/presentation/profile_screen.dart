import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
import 'package:akademiX/core/constants/routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final userData = authVm.userData;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Melengkung Biru
            Stack(
              children: [
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2962FF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(100),
                      bottomRight: Radius.circular(100),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              "Edit Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                authVm.logout();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  Routes.login,
                                  (route) => false,
                                );
                              },
                              tooltip: "Logout",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Foto Profil
                      const Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                Icons.person_outline,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Color(0xFF2962FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "ketuk untuk mengganti foto profil",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Form Informasi (Read-only sesuai gambar)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("INFORMASI PRIBADI"),
                  _buildProfileField(
                    "NAMA LENGKAP",
                    userData?['nama'] ?? "Nama Mahasiswa",
                    Icons.person_outline,
                  ),
                  _buildProfileField(
                    "NIM",
                    userData?['nim'] ?? "241511001",
                    Icons.badge_outlined,
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle("KONTAK"),
                  _buildProfileField(
                    "EMAIL",
                    userData?['email'] ?? "mahasiswa@gmail.com",
                    Icons.mail_outline,
                  ),
                  _buildProfileField(
                    "NOMOR HP",
                    "089011133251",
                    Icons.phone_outlined,
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle("KEAMANAN"),
                  _buildProfileField("PASSWORD", "••••••", Icons.lock_outline),

                  const SizedBox(height: 40),
                  // Tombol Logout Merah
                  Center(
                    child: InkWell(
                      onTap: () {
                        authVm.logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.login,
                          (route) => false,
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            "Keluar",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey),
                const SizedBox(width: 10),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
