import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nisController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isCheckingNis = false;

  Student? _verifiedStudent;
  String? _nisCheckStatus; // 'valid', 'invalid', or null

  List<Student> _masterStudents = [];

  @override
  void initState() {
    super.initState();
    _loadMasterStudents();
  }

  Future<void> _loadMasterStudents() async {
    final list = await DatabaseHelper.instance.getAllMasterStudents();
    if (mounted) {
      setState(() {
        _masterStudents = list.where((s) => s.nis != 'admin').toList();
      });
    }
  }

  @override
  void dispose() {
    _nisController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyNis(String nis) async {
    final cleanNis = nis.trim();
    if (cleanNis.isEmpty) {
      setState(() {
        _verifiedStudent = null;
        _nisCheckStatus = null;
      });
      return;
    }

    setState(() => _isCheckingNis = true);
    final student = await DatabaseHelper.instance.getStudentByNis(cleanNis);

    if (!mounted) return;
    setState(() {
      _isCheckingNis = false;
      if (student != null) {
        _verifiedStudent = student;
        _nisCheckStatus = 'valid';
      } else {
        _verifiedStudent = null;
        _nisCheckStatus = 'invalid';
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showDialog(
        title: 'Kata Sandi Berbeda',
        message: 'Konfirmasi kata sandi tidak cocok dengan kata sandi yang dimasukkan.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await DatabaseHelper.instance.registerUser(
        nis: _nisController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        final student = res['student'] as Student?;
        _showSuccessDialog(
          title: 'Pendaftaran Berhasil!',
          message: 'Akun untuk ${student?.name ?? 'Siswa'} dengan NIS ${_nisController.text} berhasil dibuat. Silakan login untuk mulai mencatat aktivitas.',
        );
      } else {
        _showDialog(
          title: 'Pendaftaran Gagal!',
          message: res['message'] ?? 'NIS tidak ditemukan di database.',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showDialog(
        title: 'Terjadi Kesalahan',
        message: 'Error: $e',
        isSuccess: false,
      );
    }
  }

  void _showDialog({required String title, required String message, required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSuccess ? AppTheme.accentGreen : AppTheme.errorColor,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? AppTheme.accentGreen : AppTheme.primaryColor,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text('Pendaftaran Berhasil!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman Login
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
            child: const Text('Ke Halaman Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Siswa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ilustrasi header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo_smanda.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Validasi Siswa SMANDA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Hanya siswa terdaftar SMA Negeri 2 Metro yang dapat membuat akun.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Field NIS
                const Text(
                  'Nomor Induk Siswa (NIS)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nisController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    if (val.length >= 4) {
                      _verifyNis(val);
                    } else {
                      setState(() {
                        _verifiedStudent = null;
                        _nisCheckStatus = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Masukkan NIS resmi sekolah',
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryColor),
                    suffixIcon: _isCheckingNis
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search_rounded),
                            tooltip: 'Periksa NIS di Database',
                            onPressed: () => _verifyNis(_nisController.text),
                          ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'NIS wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Indikator Status Cek NIS
                if (_nisCheckStatus == 'valid' && _verifiedStudent != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✓ NIS Ditemukan: ${_verifiedStudent!.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              Text(
                                'Kelas: ${_verifiedStudent!.className}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_nisCheckStatus == 'invalid')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.cancel_rounded, color: AppTheme.errorColor, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '✗ NIS tidak ditemukan di database sekolah. Pendaftaran akan ditolak.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // Password
                const Text(
                  'Buat Kata Sandi',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimal 4 karakter',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Kata sandi tidak boleh kosong';
                    }
                    if (val.length < 4) {
                      return 'Kata sandi minimal 4 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Konfirmasi Password
                const Text(
                  'Konfirmasi Kata Sandi',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Ketik ulang kata sandi',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Konfirmasi kata sandi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 26),

                // Tombol Daftar
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Daftar Akun Sekarang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),

                // Info Bantuan / Daftar NIS Resmi di Database (Bisa di klik untuk langsung isi)
                Card(
                  elevation: 0,
                  color: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.borderLight),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    leading: const Icon(Icons.menu_book_rounded, color: AppTheme.secondaryColor, size: 20),
                    title: const Text(
                      'Lihat Contoh NIS Resmi di Database',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor),
                    ),
                    subtitle: const Text(
                      'Klik salah satu untuk mencoba pendaftaran',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          children: _masterStudents.map((s) {
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${s.name} (${s.className})',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: Text('NIS: ${s.nis}', style: const TextStyle(fontSize: 12)),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  _nisController.text = s.nis;
                                  _verifyNis(s.nis);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryLight,
                                  foregroundColor: AppTheme.primaryDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Gunakan'),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
