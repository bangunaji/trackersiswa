import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_log.dart';
import '../services/database_helper.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'master_students_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  bool _isExporting = false;

  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Belajar', 'Sholat'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final logs = await DatabaseHelper.instance.getAllActivities(
      searchQuery: _searchQuery,
      activityFilter: _selectedFilter == 'Semua' ? null : _selectedFilter,
    );

    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleExportExcel() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data aktivitas siswa untuk diekspor ke Excel.'),
          backgroundColor: AppTheme.accentAmber,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final filePath = await ExcelService.exportActivityLogsToExcel(_logs);

      if (!mounted) return;
      setState(() => _isExporting = false);

      if (filePath != null) {
        // Tampilkan dialog berhasil export dan tawarkan untuk share/buka
        _showExportSuccessDialog(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengekspor file Excel. Silakan coba lagi.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ekspor Excel: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.description_rounded, color: Color(0xFF107C41), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ekspor Excel Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File Excel (.xlsx) berhasil dibuat dengan data lengkap nama siswa dan waktu pencatatan.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lokasi File Tersimpan:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    filePath,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ExcelService.shareExcelFile(filePath);
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Kirim / Bagikan File'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF107C41)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSingleLog(int id, String studentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Hapus catatan aktivitas untuk $studentName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteActivityLog(id);
      _loadData();
    }
  }

  Future<void> _clearAllLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Semua Log?'),
        content: const Text('Seluruh data aktivitas siswa yang tersimpan akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.clearAllActivities();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua log aktivitas telah dibersihkan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBelajar = _logs.where((l) => l.activityType.toLowerCase().contains('belajar')).length;
    final totalSholat = _logs.where((l) => l.activityType.toLowerCase().contains('sholat')).length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panel Admin SMANDA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Rekap & Ekspor Data Aktivitas Siswa', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            tooltip: 'Kelola Master Siswa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MasterStudentsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNER PROMINENT: EXPORT KE EXCEL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF107C41), Color(0xFF15803D)], // Excel Green
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF107C41).withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.table_view_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ekspor Data ke Excel (.xlsx)',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Download rekap waktu & nama siswa',
                                style: TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExporting ? null : _handleExportExcel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF107C41),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF107C41)),
                              )
                            : const Icon(Icons.file_download_rounded, size: 20),
                        label: Text(
                          _isExporting ? 'Mengekspor ke Excel...' : 'Ekspor ${_logs.length} Data ke Excel',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KARTU STATISTIK RINGKASAN
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Log',
                      value: '${_logs.length}',
                      icon: Icons.list_alt_rounded,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Belajar',
                      value: '$totalBelajar',
                      icon: Icons.menu_book_rounded,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Sholat',
                      value: '$totalSholat',
                      icon: Icons.mosque_rounded,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // FILTER DAN PENCARIAN
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  _searchQuery = val;
                  _loadData();
                },
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama siswa atau NIS...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _loadData();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // Kategori Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('Semua'),
                    const SizedBox(width: 8),
                    _filterChip('Belajar'),
                    const SizedBox(width: 8),
                    _filterChip('Sholat'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // DAFTAR LOG AKTIVITAS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Aktivitas Siswa (${_logs.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  if (_logs.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAllLogs,
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppTheme.errorColor),
                      label: const Text('Hapus Semua', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_logs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.inbox_rounded, size: 48, color: AppTheme.textSecondary),
                      SizedBox(height: 10),
                      Text(
                        'Tidak Ada Data Aktivitas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Belum ada siswa yang menekan tombol aktivitas atau filter tidak cocok.',
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
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    DateTime? dt;
                    try {
                      dt = DateTime.parse(log.timestamp);
                    } catch (_) {}

                    final formattedDateTime = dt != null
                        ? DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(dt)
                        : log.timestamp;

                    final isSholat = log.activityType.toLowerCase().contains('sholat');
                    final isBelajar = log.activityType.toLowerCase().contains('belajar');

                    return Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSholat
                                    ? const Color(0xFFECFDF5)
                                    : (isBelajar ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSholat
                                    ? Icons.mosque_rounded
                                    : (isBelajar ? Icons.menu_book_rounded : Icons.star_rounded),
                                color: isSholat
                                    ? AppTheme.accentGreen
                                    : (isBelajar ? AppTheme.secondaryColor : AppTheme.accentAmber),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nama Siswa (Sesuai Permintaan)
                                  Text(
                                    log.studentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'NIS: ${log.nis} • Aktivitas: ${log.activityType}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.primaryColor),
                                      const SizedBox(width: 4),
                                      // Waktu Tersimpan
                                      Text(
                                        '$formattedDateTime WIB',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorColor),
                              onPressed: () {
                                if (log.id != null) {
                                  _deleteSingleLog(log.id!, log.studentName);
                                }
                              },
                              tooltip: 'Hapus log ini',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = label);
          _loadData();
        }
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}
