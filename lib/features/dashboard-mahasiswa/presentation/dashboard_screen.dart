import 'package:flutter/material.dart';

class DashboardMahasiswaScreen extends StatelessWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header: Nama Mahasiswa
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello,", 
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 16)),
                      const Text("Mahasiswa", 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
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
                        // Navigasi ke Halaman Masukkan Kode
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinUjianScreen()));
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
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(Icons.access_time, "Riwayat", false),
            _buildNavItem(Icons.person_outline, "Profile", false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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