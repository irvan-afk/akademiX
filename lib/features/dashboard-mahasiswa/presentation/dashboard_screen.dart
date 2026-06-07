import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/auth/view_models/auth_view_model.dart';
import 'package:akademix/core/constants/routes.dart';
import 'package:akademix/features/auth/presentation/profile_screen.dart';
import '../../ujian/presentation/join_ujian_screen.dart';
import '../../ujian/presentation/riwayat_mahasiswa_view.dart';
import '../../ujian/presentation/waiting_room_screen.dart';
import 'package:akademix/features/ujian/view_models/mahasiswa_ujian_view_model.dart';
import 'package:akademix/core/database/local_db_service.dart';

class DashboardMahasiswaScreen extends StatefulWidget {
  const DashboardMahasiswaScreen({super.key});

  @override
  State<DashboardMahasiswaScreen> createState() =>
      _DashboardMahasiswaScreenState();
}

class _DashboardMahasiswaScreenState extends State<DashboardMahasiswaScreen> {
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthViewModel>();
      final mahasiswaId = authVm.mahasiswaId;
      context.read<MahasiswaUjianViewModel>().checkOfflineSubmission(mahasiswaId: mahasiswaId);
    });
  }

  List<Widget> _buildPages(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final mahasiswaId = authVM.userData?['id'] as int? ?? 0;

    return [
      _RiwayatPage(mahasiswaId: mahasiswaId),
      const BerandaContent(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: _buildPages(context)[_currentIndex],

      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.history, "Riwayat", 0),
              _buildCenterNavItem(Icons.home, "Beranda", 1),
              _buildNavItem(Icons.person, "Profile", 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF2962FF) : Colors.grey[400],
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF2962FF) : Colors.grey[400],
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterNavItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF2962FF).withOpacity(0.10)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: active ? const Color(0xFF2962FF) : Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF2962FF) : Colors.grey[400],
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiwayatPage extends StatelessWidget {
  final int mahasiswaId;

  const _RiwayatPage({required this.mahasiswaId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF2962FF),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Riwayat Ujian",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Lihat seluruh ujian yang sudah kamu selesaikan",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(child: RiwayatMahasiswaView(mahasiswaId: mahasiswaId)),
      ],
    );
  }
}

class BerandaContent extends StatelessWidget {
  const BerandaContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final ujianVm = context.watch<MahasiswaUjianViewModel>();

    final String namaMahasiswa = authVm.userData?['nama'] ?? "Mahasiswa";
    final String? avatarUrl = authVm.userData?['avatar_url']?.toString();

    return Column(
      children: [
        _buildHeader(namaMahasiswa, avatarUrl, context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final authVm = context.read<AuthViewModel>();
              await context.read<MahasiswaUjianViewModel>().checkOfflineSubmission(mahasiswaId: authVm.mahasiswaId);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20,
                ),
              child: Column(
                children: [
                  if (ujianVm.activeUjian != null)
                    if (ujianVm.status == SubmissionStatus.offlineSaved)
                      _buildTungguSinkronCard(context, ujianVm)
                    else
                      _buildPaketTerunduhCard(context, ujianVm.activeUjian!)
                  else
                    _buildJoinCard(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildHeader(String nama, String? avatarUrl, BuildContext context) {
    final isHttp = avatarUrl != null && avatarUrl.startsWith('http');
    final isBase64 = avatarUrl != null && avatarUrl.startsWith('data:image');

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
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white24,
                    backgroundImage: isHttp
                        ? NetworkImage(avatarUrl)
                        : (isBase64
                            ? MemoryImage(base64Decode(avatarUrl.split(',').last))
                            : null),
                    child: (isHttp || isBase64)
                        ? null
                        : const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      final authVm = context.read<AuthViewModel>();
                      _showLogoutConfirmationDialog(context, authVm);
                    },
                    tooltip: "Logout",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MASUKKAN KODE",
            style: TextStyle(
              color: Color(0xFF2962FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Join Ujian Sekarang",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JoinUjianScreen(),
                ),
              ),
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: const Text("Mulai Sekarang"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2962FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaketTerunduhCard(BuildContext context, dynamic ujian) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "PAKET TERUNDUH",
                style: TextStyle(
                  color: Color(0xFF2962FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: "Hapus Ujian Lokal",
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Hapus Ujian Lokal?"),
                        content: const Text(
                          "Apakah Anda yakin ingin menghapus ujian ini dari perangkat? Lakukan ini jika ujian error atau sudah dihapus oleh Dosen.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await LocalDbService.instance.clearAllLokalData();
                      if (context.mounted) {
                        final authVm = context.read<AuthViewModel>();
                        context.read<MahasiswaUjianViewModel>().checkOfflineSubmission(mahasiswaId: authVm.mahasiswaId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Data ujian lokal berhasil dihapus.")),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (ujian.judulUjian ?? "UJIAN").toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                if (ujian.statusLokal == 'WAITING') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WaitingRoomScreen(ujianId: ujian.id),
                    ),
                  );
                } else {
                  Navigator.pushNamed(context, '/ujian', arguments: ujian.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2962FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "MULAI PENGERJAAN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          // Removed the large OutlinedButton from here
        ],
      ),
    );
  }

  Widget _buildTungguSinkronCard(BuildContext context, MahasiswaUjianViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MENUNGGU SINKRONISASI",
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (vm.activeUjian?.judulUjian ?? "UJIAN").toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Jawaban tersimpan di perangkat. Tekan tombol di bawah saat Anda memiliki koneksi internet.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                await vm.submitUjian();
                if (context.mounted && vm.status == SubmissionStatus.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Berhasil disinkronkan ke server!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        vm.lastErrorMessage != null 
                            ? "Gagal: ${vm.lastErrorMessage}"
                            : "Masih gagal, pastikan internet Anda aktif."
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: vm.status == SubmissionStatus.loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "SINKRONKAN SEKARANG",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.sync),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context, AuthViewModel authVm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Konfirmasi Keluar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari akun Anda?",
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Tutup dialog
              authVm.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (route) => false,
              );
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }
}