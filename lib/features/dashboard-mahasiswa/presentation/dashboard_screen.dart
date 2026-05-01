import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
import 'package:akademiX/core/constants/routes.dart';
import 'package:akademiX/features/auth/presentation/profile_screen.dart';
// UPDATE IMPORT:
import '../../ujian/presentation/join_ujian_screen.dart';
import '../../ujian/presentation/riwayat_mahasiswa_view.dart'; // File baru kita

class DashboardMahasiswaScreen extends StatefulWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  State<DashboardMahasiswaScreen> createState() =>
      _DashboardMahasiswaScreenState();
}

class _DashboardMahasiswaScreenState extends State<DashboardMahasiswaScreen> {
  int _currentIndex = 0;

  List<Widget> _buildPages(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final mahasiswaId = authVM.userData?['id'] as int? ?? 0;

    return [
      const BerandaContent(),
      const Center(child: Text("Halaman Jadwal")),
      // Gunakan class baru hasil pemisahan SRP
      RiwayatMahasiswaView(mahasiswaId: mahasiswaId),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan halaman sesuai indeks yang dipilih
      body: _buildPages(context)[_currentIndex],

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, "Beranda", 0),
              _buildNavItem(Icons.calendar_today_outlined, "Jadwal", 1),
              const SizedBox(width: 40), // Ruang untuk FloatingActionButton
              _buildNavItem(Icons.access_time, "Riwayat", 2),
              _buildNavItem(Icons.person_outlined, "Profile", 3),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Tombol tambah cepat atau aksi lainnya
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.blueAccent : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blueAccent : Colors.grey,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk isi konten Beranda agar Dashboard tidak kepanjangan
class BerandaContent extends StatelessWidget {
  const BerandaContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final String namaMahasiswa = authVm.userData?['nama'] ?? "Mahasiswa";
    final String nimMahasiswa = authVm.userData?['nim'] ?? "";

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello,",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      namaMahasiswa,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    if (nimMahasiswa.isNotEmpty)
                      Text(
                        nimMahasiswa,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.orangeAccent,
                      child: Icon(Icons.face, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.blueAccent),
                      onPressed: () {
                        final authVm = context.read<AuthViewModel>();
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
              ],
            ),
            const SizedBox(height: 30),
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
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Masukkan Kode\nuntuk Join Ujian",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JoinUjianScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.vpn_key_outlined, size: 18),
                    label: const Text("Join Sekarang"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
}
