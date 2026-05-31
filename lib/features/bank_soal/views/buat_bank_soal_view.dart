import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../../core/widgets/akademix_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/bank_soal_model.dart';
import '../controllers/bank_soal_controller.dart';

class BuatBankSoalView extends StatefulWidget {
  final bool startFresh;
  final int? idremoteUjian;

  const BuatBankSoalView({
    super.key,
    this.startFresh = false,
    this.idremoteUjian,
  });

  @override
  State<BuatBankSoalView> createState() => _BuatBankSoalViewState();
}

class _BuatBankSoalViewState extends State<BuatBankSoalView> {
  final TextEditingController _mataKuliahController = TextEditingController();
  final TextEditingController _kelasPengampuController =
      TextEditingController();
  final TextEditingController _judulUjianController = TextEditingController();
  final TextEditingController _durasiController = TextEditingController();
  final TextEditingController _waktuMulaiController = TextEditingController();

  int? _selectedPengampuId;
  DateTime? _waktuMulai;

  void _syncHeaderToController() {
    if (!mounted) return;

    final vm = context.read<BankSoalController>();
    final authVm = context.read<AuthController>();
    final dosenId = authVm.userData?['id'] as int?;
    final pengampuText = _kelasPengampuController.text.trim();

    vm.setHeader(
      pengampuId: _selectedPengampuId,
      pengampuLabel: pengampuText.isEmpty ? null : pengampuText,
      mataKuliah: _mataKuliahController.text.trim(),
      judulUjian: _judulUjianController.text.trim(),
      durasiMenit: int.tryParse(_durasiController.text.trim()) ?? 0,
      waktuMulai: _waktuMulai,
      dosenId: dosenId,
    );
  }

  @override
  void initState() {
    super.initState();
    _mataKuliahController.addListener(_syncHeaderToController);
    _kelasPengampuController.addListener(_syncHeaderToController);
    _judulUjianController.addListener(_syncHeaderToController);
    _durasiController.addListener(_syncHeaderToController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _mataKuliahController.removeListener(_syncHeaderToController);
    _kelasPengampuController.removeListener(_syncHeaderToController);
    _judulUjianController.removeListener(_syncHeaderToController);
    _durasiController.removeListener(_syncHeaderToController);
    _waktuMulaiController.removeListener(_syncHeaderToController);
    _mataKuliahController.dispose();
    _kelasPengampuController.dispose();
    _judulUjianController.dispose();
    _durasiController.dispose();
    _waktuMulaiController.dispose();
    super.dispose();
  }

  void _syncControllerFromDraft() {
    final draft = context.read<BankSoalController>().draft;
    _mataKuliahController.text = draft.mataKuliah;
    _kelasPengampuController.text = draft.pengampuLabel ?? '';
    _judulUjianController.text = draft.judulUjian;
    _durasiController.text = draft.durasiMenit.toString();
    _waktuMulai = draft.waktuMulai;
    if (_waktuMulai != null) {
      _waktuMulaiController.text = 
          "${_waktuMulai!.year.toString().padLeft(4, '0')}-${_waktuMulai!.month.toString().padLeft(2, '0')}-${_waktuMulai!.day.toString().padLeft(2, '0')} ${_waktuMulai!.hour.toString().padLeft(2, '0')}:${_waktuMulai!.minute.toString().padLeft(2, '0')}";
    } else {
      _waktuMulaiController.text = "";
    }
    
    _selectedPengampuId = draft.pengampuId;
  }

  Future<void> _loadInitialData() async {
    final authVm = context.read<AuthController>();
    final dosenId = authVm.userData?['id'] as int?;
    final vm = context.read<BankSoalController>();

    if (dosenId != null) {
      await vm.loadPengampuForDosen(dosenId);
      if (widget.idremoteUjian != null) {
        final loaded = await vm.loadDraftForRemoteUjian(widget.idremoteUjian!);
        if (!loaded) {
          vm.resetDraft(dosenId: dosenId);
        }
      } else if (widget.startFresh) {
        vm.resetDraft(dosenId: dosenId);
      } else {
        await vm.loadLatestDraft(dosenId: dosenId);
      }
    } else {
      if (widget.idremoteUjian != null) {
        final loaded = await vm.loadDraftForRemoteUjian(widget.idremoteUjian!);
        if (!loaded) {
          vm.resetDraft();
        }
      } else if (widget.startFresh) {
        vm.resetDraft();
      } else {
        await vm.loadLatestDraft(dosenId: null);
      }
    }

    if (!mounted) return;
    _syncControllerFromDraft();
    _syncHeaderToController();
  }

  Future<void> _handleSave() async {
    final vm = context.read<BankSoalController>();

    final saved = await vm.saveBankSoal();
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
      return;
    }
    _showMessage(vm.lastActionMessage ?? (saved ? 'Draft tersimpan.' : ''));
  }

  Future<void> _handlePublish() async {
    final vm = context.read<BankSoalController>();

    final published = await vm.publishBankSoal();
    if (!mounted) return;
    _showMessage(vm.lastActionMessage ?? (published ? 'Dipublish.' : ''));
  }

  void _showMessage(String message) {
    if (message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BankSoalController>(
      builder: (context, vm, _) {
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
              'Buat Bank Soal',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Column(
                    children: [
                      _buildTopActionBar(vm),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          children: [
                            _buildSectionTitle('INFORMASI UJIAN'),
                            const SizedBox(height: 10),
                            AkademixCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Mata Kuliah'),
                                  const SizedBox(height: 6),
                                  _buildMataKuliahDropdown(vm),
                                  const SizedBox(height: 14),
                                  _buildFieldLabel('Kelas / Pengampu'),
                                  const SizedBox(height: 6),
                                  _buildPengampuField(vm),
                                  const SizedBox(height: 14),
                                  _buildFieldLabel('Tanggal & Waktu Ujian'),
                                  const SizedBox(height: 6),
                                  _buildWaktuMulaiField(context),
                                  const SizedBox(height: 14),
                                  _buildFieldLabel('Judul Ujian'),
                                  const SizedBox(height: 6),
                                  _buildInputField(
                                    controller: _judulUjianController,
                                    hintText:
                                        'Contoh: Ujian Tengah Semester - Basis Data',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildFieldLabel('Durasi'),
                                  const SizedBox(height: 6),
                                  _buildInputField(
                                    controller: _durasiController,
                                    hintText: '90',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: const Icon(
                                      Icons.timer_outlined,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle(
                                  'DAFTAR PERTANYAAN (${vm.draft.questions.length})',
                                ),
                                _buildPointSummary(vm),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (!vm.draft.hasValidHeader)
                              _buildHintBanner(
                                'Lengkapi mata kuliah, judul ujian, dan durasi sebelum menambah soal.',
                                Colors.orange.shade700,
                                Colors.orange.shade50,
                              ),
                            if (vm.draft.questions.isEmpty)
                              _buildEmptyQuestionState()
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: vm.draft.questions.length,
                                separatorBuilder: (context, _) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final question = vm.draft.questions[index];
                                  return _BankSoalItemCard(
                                    index: index + 1,
                                    question: question,
                                    onEdit: () async {
                                      final updated = await _showQuestionForm(
                                        context,
                                        initialQuestion: question,
                                      );
                                      if (updated != null && mounted) {
                                        vm.updateQuestion(updated);
                                      }
                                    },
                                    onDelete: () async {
                                      final yes = await _showDeleteConfirm(
                                        context,
                                      );
                                      if (yes == true && mounted) {
                                        vm.removeQuestion(question.localId);
                                      }
                                    },
                                  );
                                },
                              ),
                            const SizedBox(height: 12),
                            _buildQuestionTypeActions(vm),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildQuestionTypeActions(BankSoalController vm) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: vm.draft.hasValidHeader
                    ? () async {
                        final question = await _showQuestionForm(
                          context,
                          tipeSoal: 'pilihan_ganda',
                        );
                        if (question != null && mounted) {
                          vm.addQuestion(question);
                        }
                      }
                    : null,
                icon: const Icon(Icons.circle_outlined, size: 18),
                label: const Text('Pilihan Ganda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: vm.draft.hasValidHeader
                    ? () async {
                        final question = await _showQuestionForm(
                          context,
                          tipeSoal: 'essai',
                        );
                        if (question != null && mounted) {
                          vm.addQuestion(question);
                        }
                      }
                    : null,
                icon: const Icon(Icons.text_fields, size: 18),
                label: const Text('Essay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C4DFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionBar(BankSoalController vm) {
    final canPublish = vm.isReadyToPublish && !vm.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE3E8F2).withValues(alpha: 0.9),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: vm.isLoading ? null : _handleSave,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Simpan Draft'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canPublish ? _handlePublish : null,
                icon: const Icon(Icons.publish_outlined, size: 16),
                label: const Text('Publish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canPublish
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFF1F4FB),
                  foregroundColor: canPublish ? Colors.white : Colors.grey,
                  minimumSize: const Size.fromHeight(44),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: canPublish
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFE3E8F2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1.4),
        ),
      ),
    );
  }

  Widget _buildPengampuField(BankSoalController vm) {
    return _buildInputField(
      controller: _kelasPengampuController,
      hintText: 'Ketik kelas / pengampu',
      prefixIcon: const Icon(Icons.class_outlined, size: 18),
      readOnly: true,
    );
  }

  Widget _buildMataKuliahDropdown(BankSoalController vm) {
    if (vm.pengampuOptions.isEmpty) {
      return _buildInputField(
        controller: _mataKuliahController,
        hintText: 'Tidak ada mata kuliah tersedia',
        readOnly: true,
      );
    }
    
    // Pastikan _selectedPengampuId valid dalam opsi, jika tidak set null
    if (_selectedPengampuId != null && 
        !vm.pengampuOptions.any((o) => o.id == _selectedPengampuId)) {
      _selectedPengampuId = null;
    }

    return DropdownButtonFormField<int>(
      value: _selectedPengampuId,
      hint: const Text('Pilih Mata Kuliah'),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1.4),
        ),
      ),
      items: vm.pengampuOptions.map((option) {
        // Ambil nama matkul dari label (sebelum •)
        final parts = option.label.split(' • ');
        final matkulName = parts.isNotEmpty ? parts[0] : option.label;
        final kelasName = parts.length > 1 ? parts.sublist(1).join(' • ') : '';
        
        return DropdownMenuItem<int>(
          value: option.id,
          child: Text(
            '$matkulName ($kelasName)',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() {
          _selectedPengampuId = val;
          final opt = vm.pengampuOptions.firstWhere((o) => o.id == val);
          final parts = opt.label.split(' • ');
          final matkulName = parts.isNotEmpty ? parts[0] : opt.label;
          final kelasName = parts.length > 1 ? parts.sublist(1).join(' • ') : '';
          
          _mataKuliahController.text = matkulName;
          _kelasPengampuController.text = kelasName;
          
          // User request: Tambah angkatan. Kita tau bahwa label memang sudah diset 
          // ada angkatannya di view_model (contoh: 'Kelas 1A • Angkatan 2023').
          // Splitter di atas sudah menghandle sublist(1).join(' • ').
        });
        _syncHeaderToController();
      },
    );
  }

  Widget _buildWaktuMulaiField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _waktuMulai ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_waktuMulai ?? DateTime.now()),
          );
          if (time != null && mounted) {
            setState(() {
              _waktuMulai = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
              _waktuMulaiController.text = 
                  "${_waktuMulai!.year.toString().padLeft(4, '0')}-${_waktuMulai!.month.toString().padLeft(2, '0')}-${_waktuMulai!.day.toString().padLeft(2, '0')} ${_waktuMulai!.hour.toString().padLeft(2, '0')}:${_waktuMulai!.minute.toString().padLeft(2, '0')}";
            });
            _syncHeaderToController();
          }
        }
      },
      child: IgnorePointer(
        child: _buildInputField(
          controller: _waktuMulaiController,
          hintText: 'Pilih Tanggal & Waktu',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
      ),
    );
  }

  Widget _buildPointSummary(BankSoalController vm) {
    final isValid = vm.totalPoin == 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isValid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Poin ${vm.totalPoin}/100',
        style: TextStyle(
          color: isValid ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHintBanner(String text, Color foreground, Color background) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyQuestionState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFF7FAFF).withValues(alpha: 1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'Belum ada soal ditambahkan',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap tombol Pilihan Ganda atau Essay di bawah untuk mulai membuat soal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hapus soal?'),
          content: const Text(
            'Soal yang dihapus tidak bisa dikembalikan dari draft ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<BankSoalQuestionModel?> _showQuestionForm(
    BuildContext context, {
    String? tipeSoal,
    BankSoalQuestionModel? initialQuestion,
  }) {
    return showModalBottomSheet<BankSoalQuestionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _QuestionFormSheet(
          tipeSoal: tipeSoal ?? initialQuestion?.tipeSoal ?? 'pilihan_ganda',
          initialQuestion: initialQuestion,
        );
      },
    );
  }
}

class _BankSoalItemCard extends StatelessWidget {
  final int index;
  final BankSoalQuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BankSoalItemCard({
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AkademixCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: question.isPilihanGanda
                      ? const Color(0xFFE8F1FF)
                      : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  question.isPilihanGanda ? 'Pilihan Ganda' : 'Essay',
                  style: TextStyle(
                    color: question.isPilihanGanda
                        ? const Color(0xFF2962FF)
                        : const Color(0xFF9C4DFF),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE3E8F2)),
                ),
                child: Text(
                  'Poin: ${question.poin}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.teksSoal.isEmpty ? 'Pertanyaan kosong' : question.teksSoal,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (question.isPilihanGanda)
            ...question.opsiJawaban.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: entry.key == question.kunciJawaban
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFD8DEE9),
                    ),
                    color: entry.key == question.kunciJawaban
                        ? const Color(0xFFF1FBF6)
                        : Colors.white,
                  ),
                  child: Text('${entry.key}. ${entry.value}'),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3E8F2)),
              ),
              child: Text(
                question.catatan?.isNotEmpty == true
                    ? question.catatan!
                    : 'Panduan jawaban belum diisi',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionFormSheet extends StatefulWidget {
  final String tipeSoal;
  final BankSoalQuestionModel? initialQuestion;

  const _QuestionFormSheet({required this.tipeSoal, this.initialQuestion});

  @override
  State<_QuestionFormSheet> createState() => _QuestionFormSheetState();
}

class _QuestionFormSheetState extends State<_QuestionFormSheet> {
  late final TextEditingController _questionController;
  late final TextEditingController _catatanController;
  late final TextEditingController _pointController;
  late final Map<String, TextEditingController> _optionControllers;
  late String _selectedPoint;
  late String _selectedAnswer;

  final List<int> _pointOptions = const [
    1,
    2,
    5,
    10,
    15,
    20,
    25,
    30,
    40,
    50,
    100,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuestion;
    _questionController = TextEditingController(text: initial?.teksSoal ?? '');
    _catatanController = TextEditingController(text: initial?.catatan ?? '');
    _pointController = TextEditingController(
      text: (initial?.poin ?? 5).toString(),
    );
    _optionControllers = {
      'A': TextEditingController(text: initial?.opsiJawaban['A'] ?? ''),
      'B': TextEditingController(text: initial?.opsiJawaban['B'] ?? ''),
      'C': TextEditingController(text: initial?.opsiJawaban['C'] ?? ''),
      'D': TextEditingController(text: initial?.opsiJawaban['D'] ?? ''),
      'E': TextEditingController(text: initial?.opsiJawaban['E'] ?? ''),
    };
    _selectedPoint = (initial?.poin ?? 5).toString();
    _selectedAnswer = initial?.kunciJawaban.isNotEmpty == true
        ? initial!.kunciJawaban
        : (widget.tipeSoal == 'pilihan_ganda' ? 'A' : '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _catatanController.dispose();
    _pointController.dispose();
    for (final controller in _optionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPilihanGanda = widget.tipeSoal == 'pilihan_ganda';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPilihanGanda
                                  ? 'Tambah Pilihan Ganda'
                                  : 'Tambah Essay',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Isi detail soal lalu simpan ke draft bank soal.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 128,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE3E8F2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _pointController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Poin',
                              suffixText: 'poin',
                              suffixStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              isDense: true,
                              suffixIcon: Builder(
                                builder: (ctx) {
                                  return GestureDetector(
                                    onTap: () async {
                                      final RenderBox box =
                                          ctx.findRenderObject() as RenderBox;
                                      final Offset offset = box.localToGlobal(
                                        Offset.zero,
                                      );
                                      final selected = await showMenu<String>(
                                        context: ctx,
                                        position: RelativeRect.fromLTRB(
                                          offset.dx,
                                          offset.dy + box.size.height,
                                          offset.dx + box.size.width,
                                          offset.dy,
                                        ),
                                        items: _pointOptions
                                            .map(
                                              (v) => PopupMenuItem<String>(
                                                value: v.toString(),
                                                child: Text('$v poin'),
                                              ),
                                            )
                                            .toList(),
                                      );
                                      if (selected != null) {
                                        setState(() {
                                          _selectedPoint = selected;
                                          _pointController.text = selected;
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _selectedPoint = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    label: 'Teks Soal',
                    controller: _questionController,
                    maxLines: 4,
                    hintText: 'Ketik pertanyaan di sini...',
                  ),
                  const SizedBox(height: 16),
                  if (isPilihanGanda) ...[
                    const Text(
                      'Opsi Jawaban',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final letter in ['A', 'B', 'C', 'D', 'E']) ...[
                      _buildOptionField(letter),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAnswer,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
                      iconSize: 22,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Kunci Jawaban',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE3E8F2),
                          ),
                        ),
                      ),
                      items: ['A', 'B', 'C', 'D', 'E']
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedAnswer = value);
                      },
                    ),
                  ] else ...[
                    _buildField(
                      label: 'Panduan / Kunci Jawaban',
                      controller: _catatanController,
                      maxLines: 5,
                      hintText: 'Isi panduan jawaban atau rubrik penilaian...',
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.initialQuestion == null
                            ? 'Tambah Soal'
                            : 'Simpan Perubahan',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required int maxLines,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2962FF),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionField(String letter) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            letter,
            style: const TextStyle(
              color: Color(0xFF2962FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _optionControllers[letter],
            decoration: InputDecoration(
              hintText: 'Pilihan $letter',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE3E8F2)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Teks soal masih kosong.')));
      return;
    }

    final poin = int.tryParse(_selectedPoint) ?? 0;

    if (widget.tipeSoal == 'pilihan_ganda') {
      final options = <String, String>{};
      for (final letter in ['A', 'B', 'C', 'D', 'E']) {
        final value = _optionControllers[letter]!.text.trim();
        if (value.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Opsi $letter masih kosong.')));
          return;
        }
        options[letter] = value;
      }

      Navigator.pop(
        context,
        BankSoalQuestionModel(
          localId:
              widget.initialQuestion?.localId ??
              DateTime.now().microsecondsSinceEpoch,
          tipeSoal: 'pilihan_ganda',
          teksSoal: questionText,
          opsiJawaban: options,
          kunciJawaban: _selectedAnswer,
          poin: poin,
          catatan: null,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      BankSoalQuestionModel(
        localId:
            widget.initialQuestion?.localId ??
            DateTime.now().microsecondsSinceEpoch,
        tipeSoal: 'essai',
        teksSoal: questionText,
        opsiJawaban: const {},
        kunciJawaban: _catatanController.text.trim(),
        poin: poin,
        catatan: _catatanController.text.trim().isEmpty
            ? null
            : _catatanController.text.trim(),
      ),
    );
  }
}
