import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/auth/controllers/auth_controller.dart';
import 'package:akademix/core/constants/app_enums.dart';
import 'package:akademix/core/constants/routes.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  void _loadRememberedCredentials() {
    final settingsBox = Hive.box('settings');
    final bool rememberMe = settingsBox.get('remember_me', defaultValue: false) as bool;
    if (rememberMe) {
      final savedUsername = settingsBox.get('saved_username', defaultValue: '') as String;
      setState(() {
        _rememberMe = true;
        _usernameController.text = savedUsername;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthController>();

    final success = await authVm.loginProcess(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Simpan kredensial jika "Remember me" dicentang
      final settingsBox = Hive.box('settings');
      if (_rememberMe) {
        settingsBox.put('remember_me', true);
        settingsBox.put('saved_username', _usernameController.text.trim());
      } else {
        settingsBox.put('remember_me', false);
        settingsBox.delete('saved_username');
      }

      final role = authVm.currentUser?.role;

      if (role == UserRole.mahasiswa || role == UserRole.dosen) {
        Navigator.pushReplacementNamed(context, Routes.dashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Gagal: Periksa NIP/NIM dan Kata Sandi'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthController>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF2962FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // KUNCINYA DI SINI: Menghilangkan tombol back otomatis
        automaticallyImplyLeading: false,
        title: const Text(
          'Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(key: _formKey, child: _buildForm(isLoading)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 8),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_document,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'akademiX',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            'E-Exam & Offline Submission',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selamat Datang',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Silahkan masuk untuk\nmemulai ujian',
          style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 28),

        // NIP/NIM Field
        const Text(
          'NIP/NIM',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          decoration: _inputDecoration('Masukkan NIP/NIM'),
          validator: (val) => (val == null || val.trim().isEmpty)
              ? 'NIP/NIM wajib diisi'
              : null,
        ),

        const SizedBox(height: 16),

        // Password Field
        const Text(
          'Kata Sandi',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration('••••••••••').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (val) => (val == null || val.length < 6)
              ? 'Kata sandi minimal 6 karakter'
              : null,
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (val) => setState(() => _rememberMe = val!),
                  activeColor: const Color(0xFF2962FF),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text(
                'Lupa Kata Sandi?',
                style: TextStyle(fontSize: 13, color: Color(0xFF2962FF)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Masuk Sekarang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
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
                    child: const Icon(Icons.lock_reset, size: 28, color: Color(0xFF2962FF)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Lupa Kata Sandi?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Untuk melakukan reset kata sandi, silakan hubungi bagian Administrasi Akademik atau Unit IT SISFO Kampus dengan membawa bukti identitas Anda (KTM/Kartu Pegawai).",
                    style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: "admin@akademix.ac.id"));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Email Admin berhasil disalin!"),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2962FF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Salin Email Admin",
                            style: TextStyle(
                              color: Color(0xFF2962FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1.5),
      ),
    );
  }
}
