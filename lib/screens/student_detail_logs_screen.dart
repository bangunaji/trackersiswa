import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_log.dart';
import '../services/database_helper.dart';
import '../services/excel_service.dart';
import '../theme/app_theme.dart';

class StudentDetailLogsScreen extends StatefulWidget {
  final String nis;
  final String studentName;
  final String? className;

  const StudentDetailLogsScreen({
    super.key,
    required this.nis,
    required this.studentName,
    this.className,
  });

  @override
  State<StudentDetailLogsScreen> createState() => _StudentDetailLogsScreenState();
}

class _StudentDetailLogsScreenState extends State<StudentDetailLogsScreen> {
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _selectedFilter = 'Semua'; // 'Semua', 'Belajar', 'Sholat', 'Lainnya'
  String _displayClassName = '';

  @override
  void initState() {
    super.initState();
    _displayClassName = widget.className ?? '';
    _loadStudentLogs();
  }

  Future<void> _loadStudentLogs() async {
    setState(() => _isLoading = true);
    final logs = await DatabaseHelper.instance.getActivitiesForStudent(widget.nis);
    if (_displayClassName.isEmpty) {
      if (logs.isNotEmpty && logs.first.className.isNotEmpty) {
        _displayClassName = logs.first.className;
      } else {
        final s = await DatabaseHelper.instance.getStudentByNis(widget.nis);
        if (s != null) _displayClassName = s.className;
      }
    }
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  List<ActivityLog> get _filteredLogs {
    if (_selectedFilter == 'Semua') return _logs;
    if (_selectedFilter == 'Belajar') {
      return _logs.where((l) {
        final a = l.activityType.toLowerCase();
        return a.contains('belajar') || a.contains('tugas') || a.contains('buku');
      }).toList();
    }
    if (_selectedFilter == 'Sholat') {
      return _logs.where((l) => l.activityType.toLowerCase().contains('sholat')).toList();
    }
    return _logs.where((l) {
      final a = l.activityType.toLowerCase();
      return !a.contains('belajar') && !a.contains('sholat') && !a.contains('tugas');
    }).toList();
  }

  Future<void> _handleExportStudentExcel() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data aktivitas untuk diekspor.'),
          backgroundColor: AppTheme.accentAmber,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final filePath = await ExcelService.exportActivityLogsToExcel(
        _filteredLogs.isNotEmpty ? _filteredLogs : _logs,
      );

      if (!mounted) return;
      setState(() => _isExporting = false);

      if (filePath != null) {
        _showExportSuccessDialog(filePath);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ekspor: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  void _showExportSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF107C41), size: 26),
            SizedBox(width: 8),
            Text('Ekspor Berhasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text('File Excel aktivitas untuk ${widget.studentName} berhasil dibuat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ExcelService.shareExcelFile(filePath);
            },
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Kirim File'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF107C41)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLog(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan aktivitas ini?'),
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
      _loadStudentLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBelajar = _logs.where((l) {
      final a = l.activityType.toLowerCase();
      return a.contains('belajar') || a.contains('tugas') || a.contains('buku');
    }).length;
    final totalSholat = _logs.where((l) => l.activityType.toLowerCase().contains('sholat')).length;
    final displayLogs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas Siswa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudentLogs,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KARTU PROFIL SISWA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Text(
                              widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.studentName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  children: [
                                    Text(
                                      'NIS: ${widget.nis}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_displayClassName.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _displayClassName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 16),

                    // KARTU STATISTIK SISWA
                    Row(
                      children: [
                        Expanded(
                          child: _statCard('Total', '${_logs.length}', Icons.list_alt_rounded, AppTheme.secondaryColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard('Belajar', '$totalBelajar', Icons.menu_book_rounded, AppTheme.secondaryColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard('Sholat', '$totalSholat', Icons.mosque_rounded, AppTheme.accentGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // TOMBOL EKSPOR KHUSUS SISWA INI KE EXCEL
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExporting ? null : _handleExportStudentExcel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF107C41),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isExporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.table_view_rounded, size: 20),
                        label: Text(
                          _isExporting ? 'Mengekspor...' : 'Ekspor Aktivitas ${widget.studentName} ke Excel',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // FILTER CHIPS
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('Semua'),
                          const SizedBox(width: 8),
                          _filterChip('Belajar'),
                          const SizedBox(width: 8),
                          _filterChip('Sholat'),
                          const SizedBox(width: 8),
                          _filterChip('Lainnya'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // DAFTAR LOG AKTIVITAS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Catatan Aktivitas (${displayLogs.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (displayLogs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.inbox_rounded, size: 40, color: AppTheme.textSecondary),
                            const SizedBox(height: 8),
                            Text(
                              'Tidak ada aktivitas untuk kategori $_selectedFilter',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final log = displayLogs[index];
                          DateTime? dt;
                          try {
                            dt = DateTime.parse(log.timestamp);
                          } catch (_) {}

                          final timeStr = dt != null
                              ? DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(dt)
                              : log.timestamp;

                          final isSholat = log.activityType.toLowerCase().contains('sholat');
                          final isBelajar = log.activityType.toLowerCase().contains('belajar') ||
                              log.activityType.toLowerCase().contains('tugas');

                          return Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
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
                                        Text(
                                          log.activityType,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.primaryColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$timeStr WIB',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (log.notes.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Catatan: ${log.notes}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorColor),
                                    onPressed: () {
                                      if (log.id != null) {
                                        _deleteLog(log.id!);
                                      }
                                    },
                                    tooltip: 'Hapus catatan ini',
                                  ),
                                ],
                              ),
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

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
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
        }
      },
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
