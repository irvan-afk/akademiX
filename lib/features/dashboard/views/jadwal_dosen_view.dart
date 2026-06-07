import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/auth/controllers/auth_controller.dart';
import 'package:akademix/features/ujian/controllers/dosen_ujian_controller.dart';
import 'package:akademix/core/constants/app_enums.dart';
import 'package:akademix/features/ujian/models/ujian_model.dart';
import 'package:akademix/features/ujian/views/monitoring_ujian_view.dart';
import 'package:akademix/features/ujian/views/rekap_nilai_view.dart';
import 'package:akademix/features/ujian/views/publish_bank_soal_view.dart';

class JadwalDosenView extends StatefulWidget {
  const JadwalDosenView({super.key});

  @override
  State<JadwalDosenView> createState() => _JadwalDosenViewState();
}

class _JadwalDosenViewState extends State<JadwalDosenView> {
  int _selectedJadwalTab = 0; // 0 = Semua, 1 = Aktif, 2 = Draft, 3 = Selesai
  String _sortBy = 'default';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthController>();
      final dosenId = authVm.userData?['id'] as int? ?? 0;
      if (dosenId != 0) {
        context.read<DosenUjianController>().fetchUjianForDosen(dosenId);
      }
      context.read<DosenUjianController>().fetchPublishedExams();
    });
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime dt) {
    final months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agt", "Sep", "Okt", "Nov", "Des"];
    final days = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
    return "${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2962FF),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$label berhasil disalin!"),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(Icons.copy, size: 14, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJadwalFilterTab(int index, String label) {
    final active = _selectedJadwalTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedJadwalTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF2962FF) : Colors.grey[600],
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyJadwalState() {
    String text = "Belum ada jadwal ujian.";
    if (_selectedJadwalTab == 1) text = "Tidak ada ujian aktif/published.";
    if (_selectedJadwalTab == 2) text = "Tidak ada draf ujian.";
    if (_selectedJadwalTab == 3) text = "Belum ada ujian yang selesai.";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(UjianModel ujian) {
    Color indicatorColor = Colors.grey;
    String statusLabel = "SELESAI";
    Color statusBg = Colors.grey.shade100;
    Color statusText = Colors.grey.shade700;

    if (ujian.statusUjian == UjianStatus.published) {
      indicatorColor = const Color(0xFF2962FF);
      statusLabel = "AKTIF";
      statusBg = const Color(0xFFE3F2FD);
      statusText = const Color(0xFF2962FF);
    } else if (ujian.statusUjian == UjianStatus.draft) {
      indicatorColor = Colors.orange;
      statusLabel = "DRAFT";
      statusBg = const Color(0xFFFFF3E0);
      statusText = Colors.orange.shade800;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                "${ujian.durasiMenit} Menit",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ujian.judulUjian,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(ujian.waktuMulai),
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            "${_formatTime(ujian.waktuMulai)} - ${_formatTime(ujian.waktuSelesai)} WIB",
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                      if (ujian.statusUjian == UjianStatus.published && ujian.kodeUjian != null) ...[
                        const Divider(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE3F2FD)),
                          ),
                          child: Column(
                            children: [
                              _buildCredentialRow("Token Ujian", ujian.kodeUjian!),
                              const SizedBox(height: 8),
                              _buildCredentialRow("Token Pengawas", ujian.kodePengawasan ?? '-'),
                              const SizedBox(height: 8),
                              _buildCredentialRow("PIN Mulai", ujian.pinMulai ?? '-'),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (ujian.statusUjian == UjianStatus.published)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MonitoringUjianView(
                                    ujianId: ujian.id,
                                    judulUjian: ujian.judulUjian,
                                    pinMulai: ujian.pinMulai ?? '-',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.videocam_outlined, size: 18, color: Colors.white),
                            label: const Text(
                              "PANTAU LIVE",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2962FF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else if (ujian.statusUjian == UjianStatus.draft)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PublishBankSoalView(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.publish_outlined, size: 18, color: Color(0xFF2962FF)),
                            label: const Text(
                              "PUBLISH SEKARANG",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2962FF)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2962FF)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else if (ujian.statusUjian == UjianStatus.closed)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RekapNilaiView(
                                    ujianId: ujian.id,
                                    judulUjian: ujian.judulUjian,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bar_chart_outlined, size: 18, color: Color(0xFF2962FF)),
                            label: const Text(
                              "LIHAT REKAP NILAI",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2962FF)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE3F2FD),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DosenUjianController>();
    final filteredUjian = vm.allUjianDosen.where((ujian) {
      if (_selectedJadwalTab == 0) return true;
      if (_selectedJadwalTab == 1) return ujian.statusUjian == UjianStatus.published;
      if (_selectedJadwalTab == 2) return ujian.statusUjian == UjianStatus.draft;
      if (_selectedJadwalTab == 3) return ujian.statusUjian == UjianStatus.closed;
      return true;
    }).toList();

    final now = DateTime.now();
    final displayUjian = List<UjianModel>.from(filteredUjian);
    if (_sortBy == 'terdekat') {
      displayUjian.sort((a, b) {
        final diffA = a.waktuMulai.difference(now).abs();
        final diffB = b.waktuMulai.difference(now).abs();
        return diffA.compareTo(diffB);
      });
    }

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF2962FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  "Jadwal",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEFF9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildJadwalFilterTab(0, "Semua"),
                      _buildJadwalFilterTab(1, "Aktif"),
                      _buildJadwalFilterTab(2, "Draft"),
                      _buildJadwalFilterTab(3, "Selesai"),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _sortBy == 'terdekat'
                          ? "Jadwal Terdekat"
                          : "Urutan Default",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (String value) {
                        setState(() {
                          _sortBy = value;
                        });
                      },
                      offset: const Offset(0, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(
                                Icons.sort,
                                size: 18,
                                color: _sortBy == 'default' ? const Color(0xFF2962FF) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Urutan Default',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _sortBy == 'default' ? const Color(0xFF2962FF) : Colors.black87,
                                  fontWeight: _sortBy == 'default' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'terdekat',
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                size: 18,
                                color: _sortBy == 'terdekat' ? const Color(0xFF2962FF) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Jadwal Terdekat',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _sortBy == 'terdekat' ? const Color(0xFF2962FF) : Colors.black87,
                                  fontWeight: _sortBy == 'terdekat' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4FB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF2962FF).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tune_outlined,
                              size: 14,
                              color: Color(0xFF2962FF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _sortBy == 'terdekat' ? "Terdekat" : "Default",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2962FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayUjian.isEmpty
                    ? _buildEmptyJadwalState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          final authVm = context.read<AuthController>();
                          final dosenId = authVm.userData?['id'] as int? ?? 0;
                          if (dosenId != 0) {
                            await context.read<DosenUjianController>().fetchUjianForDosen(dosenId);
                          }
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: displayUjian.length,
                          itemBuilder: (context, index) {
                            final ujian = displayUjian[index];
                            return _buildJadwalCard(ujian);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
