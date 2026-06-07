import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/auth/controllers/auth_controller.dart';
import 'package:akademix/core/constants/routes.dart';
import 'package:akademix/core/constants/app_enums.dart';
import 'package:image_picker/image_picker.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthController>();
    final userData = authVm.userData;
    final isDosen = authVm.currentUser?.role == UserRole.dosen;
    final avatarUrl = userData?['avatar_url']?.toString();
    final isHttp = avatarUrl != null && avatarUrl.startsWith('http');
    final isBase64 = avatarUrl != null && avatarUrl.startsWith('data:image');

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AuthController>().refreshUserData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
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
                            const SizedBox(width: 48), // Spacer to balance the logout button
                            const Text(
                              "Profil Saya",
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
                               onPressed: () => _showLogoutConfirmationDialog(context, authVm),
                               tooltip: "Logout",
                             ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Foto Profil
                      Center(
                        child: InkWell(
                          onTap: () => _pickAvatarFromGallery(context, authVm),
                          borderRadius: BorderRadius.circular(60),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white24,
                                backgroundImage: isHttp
                                    ? NetworkImage(avatarUrl)
                                    : (isBase64
                                        ? MemoryImage(base64Decode(avatarUrl.split(',').last))
                                        : null),
                                child: (isHttp || isBase64)
                                    ? null
                                    : const Icon(
                                        Icons.person_outline,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                              ),
                              const CircleAvatar(
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

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("INFORMASI PRIBADI"),
                  _buildProfileField(
                    "NAMA LENGKAP",
                    userData?['nama'] ?? (isDosen ? "Nama Dosen" : "Nama Mahasiswa"),
                    Icons.person_outline,
                  ),
                  _buildProfileField(
                    isDosen ? "NIP" : "NIM",
                    isDosen
                        ? (userData?['nip'] ?? "NIP Dosen")
                        : (userData?['nim'] ?? "241511001"),
                    Icons.badge_outlined,
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle("KONTAK"),
                  _buildProfileField(
                    "EMAIL",
                    userData?['email'] ?? (isDosen ? "dosen@gmail.com" : "mahasiswa@gmail.com"),
                    Icons.mail_outline,
                    onTap: () => _showEditFieldDialog(
                      context,
                      authVm,
                      "Email",
                      userData?['email'] ?? (isDosen ? "dosen@gmail.com" : "mahasiswa@gmail.com"),
                      (val) => authVm.updateEmail(val),
                    ),
                  ),
                  _buildProfileField(
                    "NOMOR HP",
                    userData?['no_hp'] ?? "089011133251",
                    Icons.phone_outlined,
                    onTap: () => _showEditFieldDialog(
                      context,
                      authVm,
                      "Nomor HP",
                      userData?['no_hp'] ?? "089011133251",
                      (val) => authVm.updateNoHp(val),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle("KEAMANAN"),
                  _buildProfileField(
                    "PASSWORD",
                    "••••••",
                    Icons.lock_outline,
                    onTap: () => _showChangePasswordDialog(context, authVm),
                  ),

                  const SizedBox(height: 40),
                  // Tombol Logout Merah
                  Center(
                    child: InkWell(
                      onTap: () => _showLogoutConfirmationDialog(context, authVm),
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

  Widget _buildProfileField(String label, String value, IconData icon, {VoidCallback? onTap}) {
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
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatarFromGallery(BuildContext context, AuthController authVm) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64.encode(bytes)}';
        await authVm.updateAvatar(base64String);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memilih gambar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditFieldDialog(
    BuildContext context,
    AuthController authVm,
    String fieldName,
    String currentValue,
    Future<bool> Function(String) onSave,
  ) {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();
    final isEmail = fieldName.toLowerCase().contains("email");
    final icon = isEmail ? Icons.mail_outline : Icons.phone_outlined;
    final subtitle = isEmail
        ? "Ubah alamat email Anda untuk menerima notifikasi penting."
        : "Ubah nomor telepon Anda untuk kontak darurat.";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2962FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 28, color: const Color(0xFF2962FF)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Ubah $fieldName",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller,
                      keyboardType: isEmail
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: fieldName,
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFF2962FF), width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return "Wajib diisi";
                        if (isEmail) {
                          final emailRegExp = RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (!emailRegExp.hasMatch(val.trim())) {
                            return "Format email tidak valid";
                          }
                        } else {
                          if (val.trim().length < 9) {
                            return "Nomor HP minimal 9 karakter";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2962FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final success = await onSave(controller.text.trim());
                          if (success) {
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("$fieldName berhasil diubah!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Gagal mengubah $fieldName."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          "Simpan",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthController authVm) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2962FF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.lock_outline, size: 28, color: Color(0xFF2962FF)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Ubah Kata Sandi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Silakan masukkan kata sandi lama dan baru Anda.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // Old Password
                        TextFormField(
                          controller: oldPasswordController,
                          obscureText: obscureOld,
                          decoration: InputDecoration(
                            labelText: "Kata Sandi Lama",
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2962FF), width: 1.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                              onPressed: () => setState(() => obscureOld = !obscureOld),
                            ),
                          ),
                          validator: (val) => (val == null || val.isEmpty) ? "Wajib diisi" : null,
                        ),
                        const SizedBox(height: 12),

                        // New Password
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: "Kata Sandi Baru",
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2962FF), width: 1.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                              onPressed: () => setState(() => obscureNew = !obscureNew),
                            ),
                          ),
                          validator: (val) => (val == null || val.length < 6) ? "Minimal 6 karakter" : null,
                        ),
                        const SizedBox(height: 12),

                        // Confirm New Password
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: "Konfirmasi Kata Sandi Baru",
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFF2962FF), width: 1.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                              onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                            ),
                          ),
                          validator: (val) {
                            if (val != newPasswordController.text) {
                              return "Konfirmasi kata sandi tidak cocok";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2962FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              
                              final success = await authVm.changePassword(
                                oldPasswordController.text.trim(),
                                newPasswordController.text.trim(),
                              );

                              if (success) {
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Kata sandi berhasil diubah!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(authVm.errorMessage ?? "Gagal mengubah kata sandi."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Simpan",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context, AuthController authVm) {
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