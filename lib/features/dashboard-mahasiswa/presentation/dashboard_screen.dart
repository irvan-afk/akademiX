import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Wajib tambah ini
import 'package:akademiX/features/auth/view_models/auth_view_model.dart'; // Import ViewModel
import 'package:akademiX/core/constants/routes.dart'; // Gunakan Routes agar lebih rapi

class DashboardMahasiswaScreen extends StatelessWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Ambil data dari AuthViewModel menggunakan Provider
    final authVm = context.watch<AuthViewModel>();
    
    // 2. Ambil nama dari Map userData (hasil query join di repository kamu)
    final String namaMahasiswa = authVm.userData?['nama'] ?? "Mahasiswa";
    final String nimMahasiswa = authVm.userData?['nim'] ?? "";

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header: Nama Mahasiswa Dinamis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello,", 
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 16)),
                      Text(
                        namaMahasiswa,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      if (nimMahasiswa.isNotEmpty)
                        Text(nimMahasiswa, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.face, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Card: Join Ujian
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Masukkan Kode\nuntuk Join Ujian",
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigasi menggunakan Routes yang sudah kita buat di main.dart
                        Navigator.pushNamed(context, Routes.ujian);
                      },
                      icon: const Icon(Icons.vpn_key_outlined, size: 18),
                      label: const Text("Join Sekarang"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, "Beranda", true),
            const SizedBox(width: 40), 
            _buildNavItem(Icons.access_time, "Riwayat", false),
            _buildNavItem(Icons.person_outline, "Profile", false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Contoh Logout untuk tes sesi
          // context.read<AuthViewModel>().logout();
          // Navigator.pushReplacementNamed(context, Routes.login);
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.blueAccent : Colors.grey),
        Text(label, style: TextStyle(color: isActive ? Colors.blueAccent : Colors.grey, fontSize: 12)),
      ],
    );
  }
}