import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../controller/sesi_ujian_controller.dart';
import '../../../ujian/view_models/mahasiswa_ujian_view_model.dart';

class SesiUjianView extends StatefulWidget {
  final int ujianId;

  const SesiUjianView({super.key, required this.ujianId});

  @override
  State<SesiUjianView> createState() => _SesiUjianViewState();
}

class _SesiUjianViewState extends State<SesiUjianView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      // ✅ Initialize security & lifecycle handling
      context.read<SesiUjianController>().initializeSecurityFeatures();

      // ✅ Start exam
      context.read<MahasiswaUjianViewModel>().startUjian(widget.ujianId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<SesiUjianController>().disableSecurityFeatures();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ DELEGATE TO CONTROLLER
    final controller = context.read<SesiUjianController>();
    final ujianVm = context.read<MahasiswaUjianViewModel>();

    final isViolation = controller.handleAppLifecycleChange(state);

    // If violation occurred, immediately submit
    if (isViolation) {
      ujianVm.submitUjian();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/submission-result');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MahasiswaUjianViewModel>();
    final controller = context.watch<SesiUjianController>();

    // ✅ Show internet warning if needed
    if (controller.isInternetDialogShowing && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInternetWarningDialog(context, controller);
      });
    }

    const brightBlue = Color(0xFF2962FF);

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vm.daftarSoal.isEmpty) {
      return const Scaffold(body: Center(child: Text("Soal tidak ditemukan.")));
    }

    final soal = vm.daftarSoal[vm.currentIndex];
    final isLastSoal = vm.currentIndex == vm.daftarSoal.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, vm, brightBlue),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (vm.currentIndex + 1) / vm.daftarSoal.length,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(brightBlue),
            minHeight: 2,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Pertanyaan ${vm.currentIndex + 1} dari ${vm.daftarSoal.length}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (vm.isRagu(soal.id))
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Ragu-ragu",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ✅ QUESTION TEXT
                  Text(
                    soal.teksSoal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ✅ ANSWER OPTIONS
                  soal.tipeSoal.toLowerCase().contains("essai")
                      ? _buildEssayInput(vm, soal)
                      : _buildMultipleChoice(vm, soal, brightBlue),
                ],
              ),
            ),
          ),

          _buildBottomNav(context, vm, brightBlue, isLastSoal),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MahasiswaUjianViewModel vm,
    Color color,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ TIMER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_filled, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  vm.timerString,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ✅ QUESTION MAP BUTTON
          GestureDetector(
            onTap: () => _showPetaSoal(context, vm, color),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.black54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MULTIPLE CHOICE OPTIONS
  Widget _buildMultipleChoice(
    MahasiswaUjianViewModel vm,
    dynamic soal,
    Color color,
  ) {
    return Column(
      children: soal.opsiJawaban.entries.map<Widget>((entry) {
        final isSelected = vm.getJawabanTerpilih(soal.id) == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => vm.simpanJawaban(soal.id, entry.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? color.withOpacity(0.05)
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: isSelected ? color : Colors.white,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ✅ ESSAY INPUT
  Widget _buildEssayInput(MahasiswaUjianViewModel vm, dynamic soal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            key: ValueKey("essay_${soal.id}"),
            controller:
                TextEditingController(
                    text: vm.getJawabanTerpilih(soal.id) ?? "",
                  )
                  ..selection = TextSelection.fromPosition(
                    TextPosition(
                      offset: (vm.getJawabanTerpilih(soal.id) ?? "").length,
                    ),
                  ),
            maxLines: 8,
            enableInteractiveSelection: false,
            contextMenuBuilder: (context, editableTextState) {
              return const SizedBox.shrink();
            },
            decoration: const InputDecoration(
              hintText: "Ketik jawaban Anda di sini...",
              border: InputBorder.none,
            ),
            onChanged: (val) => vm.simpanJawaban(soal.id, val),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Jawaban tersimpan secara otomatis setiap kali Anda mengetik.",
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ BOTTOM NAVIGATION
  Widget _buildBottomNav(
    BuildContext context,
    MahasiswaUjianViewModel vm,
    Color color,
    bool isLast,
  ) {
    final soalId = vm.daftarSoal[vm.currentIndex].id;
    final isRagu = vm.isRagu(soalId);

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
      child: Row(
        children: [
          // Previous button
          _circleNavButton(
            Icons.chevron_left,
            Colors.grey.shade200,
            Colors.black54,
            () {
              if (vm.currentIndex > 0) vm.setIndex(vm.currentIndex - 1);
            },
          ),
          const SizedBox(width: 15),

          // Ragu-ragu button
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => vm.toggleRagu(soalId),
                icon: Icon(
                  Icons.flag_rounded,
                  color: isRagu ? Colors.white : Colors.grey,
                  size: 18,
                ),
                label: Text(
                  "Ragu-ragu",
                  style: TextStyle(
                    color: isRagu ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isRagu ? Colors.orange : Colors.white,
                  side: BorderSide(
                    color: isRagu ? Colors.orange : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Next / Finish button
          isLast
              ? _actionButton(
                  "Selesai",
                  Colors.green,
                  Icons.send_rounded,
                  () => _showKonfirmasiSelesai(context, vm),
                )
              : _circleNavButton(
                  Icons.chevron_right,
                  Colors.black,
                  Colors.white,
                  () {
                    vm.setIndex(vm.currentIndex + 1);
                  },
                ),
        ],
      ),
    );
  }

  Widget _circleNavButton(
    IconData icon,
    Color bg,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color bg,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      label: Icon(icon, color: Colors.white, size: 18),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // ✅ QUESTION MAP BOTTOM SHEET
  void _showPetaSoal(
    BuildContext context,
    MahasiswaUjianViewModel vm,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Peta Soal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
            const SizedBox(height: 25),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(vm.daftarSoal.length, (index) {
                final id = vm.daftarSoal[index].id;
                final isRagu = vm.isRagu(id);
                final isCurrent = index == vm.currentIndex;

                return GestureDetector(
                  onTap: () {
                    vm.setIndex(index);
                    Navigator.pop(context);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCurrent ? color : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isRagu)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _statusIndicator(color, "Dijawab"),
                const SizedBox(width: 15),
                _statusIndicator(Colors.orange, "Ragu-ragu"),
                const SizedBox(width: 15),
                _statusIndicator(Colors.grey.shade300, "Belum Dijawab"),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Kembali ke Soal",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ✅ FINISH CONFIRMATION DIALOG
  void _showKonfirmasiSelesai(
    BuildContext context,
    MahasiswaUjianViewModel vm,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Selesai Ujian?"),
        content: const Text(
          "Pastikan semua jawaban sudah terisi. Jawaban yang sudah dikirim tidak dapat diubah kembali.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              await vm.submitUjian();

              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/submission-result');
              }
            },
            child: const Text(
              "Ya, Kirim",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ INTERNET WARNING DIALOG
  void _showInternetWarningDialog(
    BuildContext context,
    SesiUjianController controller,
  ) {
    if (!controller.isInternetDialogShowing || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("Koneksi Internet Terdeteksi!"),
          content: const Text(
            "Harap matikan WiFi atau Data Seluler Anda untuk melanjutkan ujian offline ini.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final results = await Connectivity().checkConnectivity();
                if (!results.contains(ConnectivityResult.mobile) &&
                    !results.contains(ConnectivityResult.wifi)) {
                  if (mounted) {
                    controller.setInternetDialogShowing(false);
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                }
              },
              child: const Text("Saya Sudah Mematikan Internet."),
            ),
          ],
        ),
      ),
    );
  }
}
