import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student.dart';
import '../models/activity_log.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final Student student;

  const StudentHomeScreen({super.key, required this.student});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<ActivityLog> _studentLogs = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoadingLogs = true);
    final logs = await DatabaseHelper.instance.getActivitiesForStudent(widget.student.nis);
    if (mounted) {
      setState(() {
        _studentLogs = logs;
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _recordActivity(String activityType, {String note = ''}) async {
    final now = DateTime.now();
    final timestampIso = now.toIso8601String();

    final newLog = ActivityLog(
      nis: widget.student.nis,
      studentName: widget.student.name,
      activityType: activityType,
      timestamp: timestampIso,
      notes: note,
    );

    await DatabaseHelper.instance.insertActivityLog(newLog);

    if (!mounted) return;

    // Refresh daftar riwayat
    await _loadLogs();

    // Tampilkan dialog konfirmasi pencatatan aktivitas
    final formattedTime = DateFormat('HH:mm:ss', 'id_ID').format(now);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    _showRecordedDialog(
      activityType: activityType,
      time: '$formattedTime WIB',
      date: formattedDate,
    );
  }

  void _showRecordedDialog({
    required String activityType,
    required String time,
    required String date,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.accentGreen,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aktivitas Tersimpan!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  _infoRow('Nama Siswa:', widget.student.name, isBold: true),
                  const Divider(height: 16),
                  _infoRow('NIS:', widget.student.nis),
                  const Divider(height: 16),
                  _infoRow('Aktivitas:', activityType, color: AppTheme.primaryColor, isBold: true),
                  const Divider(height: 16),
                  _infoRow('Waktu Simpan:', time, color: AppTheme.accentGreen, isBold: true),
                  const Divider(height: 16),
                  _infoRow('Tanggal:', date),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showActivityOptionsModal(String category) {
    List<String> options = [];
    IconData icon;
    Color color;

    if (category == 'Belajar') {
      options = [
        'Belajar Mandiri',
        'Mengerjakan Tugas / PR',
        'Belajar di Ruang Kelas',
        'Membaca Buku Perpustakaan',
        'Belajar Kelompok',
      ];
      icon = Icons.auto_stories_rounded;
      color = AppTheme.secondaryColor;
    } else if (category == 'Sholat') {
      options = [
        'Sholat Dzuhur',
        'Sholat Dhuha',
        'Sholat Ashar',
        'Sholat Berjamaah di Masjid',
        'Sholat Subuh / Tahajud',
      ];
      icon = Icons.mosque_rounded;
      color = AppTheme.primaryColor;
    } else {
      options = [
        'Olahraga / Senam Pagi',
        'Kegiatan Ekstrakurikuler',
        'Gotong Royong / Piket Kelas',
        'Upacara Bendera',
      ];
      icon = Icons.star_rounded;
      color = AppTheme.accentAmber;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Pilih Jenis $category',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...options.map((opt) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(Icons.check_rounded, size: 16, color: color),
                  ),
                  title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    _recordActivity(opt);
                  },
                )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Anda akan keluar dari sesi siswa saat ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // NAMA SISWA SESUAI NIS DI POJOK KIRI ATAS (Sesuai Permintaan)
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            widget.student.name.isNotEmpty ? widget.student.name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selamat Datang,',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Nama Siswa Sesuai NIS (Pojok Kiri Atas)
                              Text(
                                widget.student.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'NIS: ${widget.student.nis} • ${widget.student.className}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tombol Logout di Kanan Atas
                  IconButton(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                    tooltip: 'Keluar',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Info Waktu Hari Ini
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Catat Aktivitas Harian Anda',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Bagian Tombol Aktivitas
              const Text(
                'Tekan Tombol untuk Mencatat Aktivitas:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Data waktu otomatis disimpan bersama nama siswa Anda',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),

              // TOMBOL AKTIVITAS BELAJAR
              _buildBigActionButton(
                title: 'Aktivitas Belajar',
                subtitle: 'Klik saat memulai / sedang belajar',
                icon: Icons.menu_book_rounded,
                gradientColors: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                onDirectClick: () => _recordActivity('Belajar'),
                onOptionsClick: () => _showActivityOptionsModal('Belajar'),
              ),
              const SizedBox(height: 14),

              // TOMBOL AKTIVITAS SHOLAT
              _buildBigActionButton(
                title: 'Aktivitas Sholat',
                subtitle: 'Klik saat melaksanakan ibadah sholat',
                icon: Icons.mosque_rounded,
                gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
                onDirectClick: () => _recordActivity('Sholat'),
                onOptionsClick: () => _showActivityOptionsModal('Sholat'),
              ),
              const SizedBox(height: 14),

              // TOMBOL AKTIVITAS LAINNYA
              _buildBigActionButton(
                title: 'Aktivitas Lainnya',
                subtitle: 'Ekskul, literasi, atau olahraga',
                icon: Icons.star_rounded,
                gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                onDirectClick: () => _recordActivity('Aktivitas Positif'),
                onOptionsClick: () => _showActivityOptionsModal('Lainnya'),
              ),
              const SizedBox(height: 28),

              // RIWAYAT AKTIVITAS HARI INI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Aktivitas Tersimpan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_studentLogs.length} Catatan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List Riwayat
              if (_isLoadingLogs)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_studentLogs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.history_rounded, size: 40, color: AppTheme.textSecondary),
                      SizedBox(height: 10),
                      Text(
                        'Belum Ada Catatan Aktivitas',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tekan salah satu tombol di atas untuk mencatat aktivitas belajar atau sholat Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _studentLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final log = _studentLogs[index];
                    DateTime? dt;
                    try {
                      dt = DateTime.parse(log.timestamp);
                    } catch (_) {}

                    final timeStr = dt != null
                        ? DateFormat('HH:mm:ss', 'id_ID').format(dt)
                        : log.timestamp;
                    final dateStr = dt != null
                        ? DateFormat('d MMM yyyy', 'id_ID').format(dt)
                        : '';

                    final isSholat = log.activityType.toLowerCase().contains('sholat');
                    final isBelajar = log.activityType.toLowerCase().contains('belajar');

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSholat
                                  ? const Color(0xFFECFDF5)
                                  : (isBelajar ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSholat
                                  ? Icons.mosque_rounded
                                  : (isBelajar ? Icons.menu_book_rounded : Icons.star_rounded),
                              color: isSholat
                                  ? AppTheme.accentGreen
                                  : (isBelajar ? AppTheme.secondaryColor : AppTheme.accentAmber),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.activityType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tersimpan untuk: ${log.studentName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$timeStr WIB',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (dateStr.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onDirectClick,
    required VoidCallback onOptionsClick,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDirectClick,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tombol Pilihan Jenis Detail
                IconButton(
                  onPressed: onOptionsClick,
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.white, size: 24),
                  tooltip: 'Pilih jenis spesifik',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
