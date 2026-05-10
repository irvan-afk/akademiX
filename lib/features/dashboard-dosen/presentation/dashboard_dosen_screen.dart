import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/auth/view_models/auth_view_model.dart';
import 'package:akademix/features/auth/presentation/profile_screen.dart';
import 'package:akademix/core/constants/routes.dart';
import '../../ujian/presentation/publish_bank_soal_screen.dart';
import '../../ujian/presentation/pilih_ujian_view.dart';
import '../../ujian/view_models/dosen_ujian_view_model.dart';
import '../../ujian/presentation/monitoring_ujian_screen.dart';

class DashboardDosenScreen extends StatefulWidget {
  const DashboardDosenScreen({super.key});

  @override
  State<DashboardDosenScreen> createState() => _DashboardDosenScreenState();
}

class _DashboardDosenScreenState extends State<DashboardDosenScreen> {
  int _currentIndex = 0;

  List<Widget> _buildPages(BuildContext context) {
    return [
      _buildBerandaPage(context),
      _buildJadwalPage(),
      _buildRiwayatPage(),
      const ProfileScreen(),
    ];
  }

  Widget _buildBerandaPage(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final String namaDosen = authVm.userData?['nama'] ?? "Dosen";

    return Column(
      children: [
        _buildHeader(namaDosen),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Column(
                children: [
                  // Grid Menu
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildMenuItem(Icons.add_circle_outline, "Bank Soal"),
                      _buildMenuItem(
                        Icons.file_download_outlined,
                        "Rekap Nilai",
                        onTap: () {
                          // Kita arahkan ke PilihUjianView dulu untuk memilih sesi ujian
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PilihUjianView(isForRekap: true),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        Icons.assignment_turned_in_outlined,
                        "Koreksi Essai",
                        onTap: () => _showUjianSelector(context),
                      ),
                      _buildMenuItem(
                        Icons.language_outlined,
                        "Publish",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PublishBankSoalScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJadwalPage() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2962FF),
            child: const Row(
              children: [
                SizedBox(width: 8),
                Text(
                  "Jadwal Mengajar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          const Expanded(
            child: Center(
              child: Text(
                "Fitur Jadwal akan segera hadir",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatPage() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2962FF),
            child: const Row(
              children: [
                SizedBox(width: 8),
                Text(
                  "Riwayat Aktivitas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          const Expanded(
            child: Center(
              child: Text(
                "Fitur Riwayat akan segera hadir",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: _buildPages(context)[_currentIndex],
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF2962FF),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(String nama) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2962FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hello,",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    Text(
                      nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),

                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFFFFA000),
                    child: Icon(Icons.face, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
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
          const SizedBox(height: 24),
          // Card Monitoring Live
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "MONITORING LIVE",
                  style: TextStyle(
                    color: Color(0xFF2962FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),
                const Icon(Icons.search, size: 50, color: Colors.black12),
                const SizedBox(height: 10),
                const Text(
                  "Tidak ada sesi aktif. Pilih ujian untuk dimulai atau masukkan kode pengawas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showJoinPengawasanDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "IKUT MENGAWAS SESI",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: const Color(0xFF2962FF), size: 35),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2962FF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      notchMargin: 8,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavIcon(Icons.home, "Beranda", 0),
            _buildNavIcon(Icons.calendar_today, "Jadwal", 1),
            const SizedBox(width: 40),
            _buildNavIcon(Icons.history, "Riwayat", 2),
            _buildNavIcon(Icons.person, "Profile", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, int index) {
    bool active = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF2962FF) : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF2962FF) : Colors.grey[400],
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showUjianSelector(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PilihUjianView()),
    );
  }

  void _showJoinPengawasanDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ikut Mengawas"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Masukkan Kode Pengawasan dari dosen pembuat soal untuk ikut memantau sesi ujian ini.",
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: "Contoh: M-12345",
                filled: true,
                fillColor: const Color(0xFFF1F4FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;

              Navigator.pop(dialogContext); // Tutup dialog

              final vm = context.read<DosenUjianViewModel>();
              final ujian = await vm.joinPengawasan(code);

              if (context.mounted) {
                if (ujian != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MonitoringUjianScreen(
                        ujianId: ujian['id'],
                        judulUjian: ujian['judul_ujian'],
                        pinMulai: ujian['pin_mulai'] ?? '-',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Kode Pengawasan tidak ditemukan atau salah."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Join Sesi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
