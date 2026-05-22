import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/akademix_card.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../ujian/view_models/dosen_ujian_view_model.dart';
import 'buat_bank_soal_screen.dart';

/// Bank Soal List Screen: Shows list of ujian created via bank soal feature.
/// Dosen can create new ujian or open existing one to edit/view bank soal.
/// This is separate from PublishBankSoalScreen (publish-only view).
class BankSoalListScreen extends StatefulWidget {
  const BankSoalListScreen({super.key});

  @override
  State<BankSoalListScreen> createState() => _BankSoalListScreenState();
}

class _BankSoalListScreenState extends State<BankSoalListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dosenId = context.read<AuthViewModel>().userData?['id'];
      if (dosenId != null) {
        context.read<DosenUjianViewModel>().fetchUjianForDosen(dosenId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final dosenId = context.read<AuthViewModel>().userData?['id'];
    if (dosenId != null) {
      await context.read<DosenUjianViewModel>().fetchUjianForDosen(
        dosenId as int,
      );
    }
  }

  Future<void> _openCreatePage({
    bool startFresh = false,
    int? remoteUjianId,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuatBankSoalScreen(
          startFresh: startFresh,
          idremoteUjian: remoteUjianId,
        ),
      ),
    );
    if (mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DosenUjianViewModel>();
    final filteredUjian = vm.allUjianDosen.where((u) {
      return u.judulUjian.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bank Soal',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari ujian...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF2962FF),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF2962FF),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openCreatePage(startFresh: true),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Tambah Ujian'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DAFTAR UJIAN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      _buildBadge('${filteredUjian.length} item', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filteredUjian.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUjian.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final ujian = filteredUjian[index];
                        final isDraft =
                            ujian.statusUjian.name.toLowerCase() == 'draft';
                        return AkademixCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDraft
                                          ? Colors.orange[50]
                                          : Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isDraft
                                          ? Icons.edit_document
                                          : Icons.cloud_done,
                                      color: isDraft
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ujian.judulUjian,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${ujian.durasiMenit} menit',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildBadge(
                                    isDraft ? 'DRAFT' : 'PUBLISHED',
                                    isDraft ? Colors.orange : Colors.green,
                                  ),
                                  TextButton(
                                    onPressed: () => _openCreatePage(
                                      remoteUjianId: ujian.id,
                                    ),
                                    child: const Text('Buka Bank Soal'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada ujian yang dibuat',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tekan tombol Tambah Ujian untuk mulai membuat bank soal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openCreatePage(startFresh: true),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Ujian'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2962FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
