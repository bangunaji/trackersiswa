import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import 'student_detail_logs_screen.dart';

class MasterStudentsScreen extends StatefulWidget {
  const MasterStudentsScreen({super.key});

  @override
  State<MasterStudentsScreen> createState() => _MasterStudentsScreenState();
}

class _MasterStudentsScreenState extends State<MasterStudentsScreen> {
  List<Student> _allStudents = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedClassFilter = 'Semua'; // 'Semua', 'Kelas 10', 'Kelas 11', 'Kelas 12'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getAllMasterStudents();
    if (mounted) {
      setState(() {
        _allStudents = list.where((s) => s.nis != 'admin').toList();
        _isLoading = false;
      });
    }
  }

  List<Student> _getFilteredStudents() {
    return _allStudents.where((s) {
      // 1. Filter Kelas
      if (_selectedClassFilter == 'Kelas 10' && s.gradeLevel != 10) return false;
      if (_selectedClassFilter == 'Kelas 11' && s.gradeLevel != 11) return false;
      if (_selectedClassFilter == 'Kelas 12' && s.gradeLevel != 12) return false;

      // 2. Filter Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = s.name.toLowerCase().contains(q);
        final matchNis = s.nis.toLowerCase().contains(q);
        final matchClass = s.className.toLowerCase().contains(q);
        if (!matchName && !matchNis && !matchClass) return false;
      }

      return true;
    }).toList();
  }

  void _showAddStudentDialog() {
    final nisController = TextEditingController();
    final nameController = TextEditingController();
    final classController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final presetClasses = [
      'X MIPA 1',
      'X MIPA 2',
      'X IPS 1',
      'XI MIPA 1',
      'XI IPS 1',
      'XII MIPA 1',
      'XII IPS 1',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Tambah Data Siswa Resmi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nisController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Induk Siswa (NIS)',
                        hintText: 'cth: 2024010',
                        prefixIcon: Icon(Icons.badge_rounded, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'NIS wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Siswa',
                        hintText: 'cth: Farhan Maulana',
                        prefixIcon: Icon(Icons.person_rounded, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: classController,
                      decoration: const InputDecoration(
                        labelText: 'Kelas / Jurusan',
                        hintText: 'cth: X MIPA 3',
                        prefixIcon: Icon(Icons.school_rounded, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Kelas wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    const Text('Pilih Cepat Kelas:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: presetClasses.map((cls) {
                        return ActionChip(
                          label: Text(cls, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setDialogState(() {
                              classController.text = cls;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final student = Student(
                    nis: nisController.text.trim(),
                    name: nameController.text.trim(),
                    className: classController.text.trim(),
                  );

                  final success = await DatabaseHelper.instance.addMasterStudent(student);
                  if (ctx.mounted) Navigator.pop(ctx);

                  if (success) {
                    _loadStudents();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Siswa ${student.name} (${student.className}) berhasil disimpan!'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Simpan Siswa'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteStudent(String nis, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Siswa?'),
        content: Text('Apakah Anda yakin ingin menghapus data siswa "$name" (NIS: $nis) dari database?'),
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
      await DatabaseHelper.instance.deleteMasterStudent(nis);
      _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data siswa $name telah dihapus.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final count10 = _allStudents.where((s) => s.gradeLevel == 10).length;
    final count11 = _allStudents.where((s) => s.gradeLevel == 11).length;
    final count12 = _allStudents.where((s) => s.gradeLevel == 12).length;
    final filtered = _getFilteredStudents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadStudents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Siswa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PENCARIAN SISWA
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama siswa, NIS, atau kelas...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // FILTER PEMISAH TINGKAT KELAS
                    Row(
                      children: const [
                        Icon(Icons.folder_shared_rounded, size: 16, color: AppTheme.textSecondary),
                        SizedBox(width: 6),
                        Text(
                          'Pilih Tingkat Kelas:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _classChip('Semua', 'Semua (${_allStudents.length})', Icons.school_rounded),
                          const SizedBox(width: 8),
                          _classChip('Kelas 10', 'Kelas 10 ($count10)', Icons.looks_one_rounded),
                          const SizedBox(width: 8),
                          _classChip('Kelas 11', 'Kelas 11 ($count11)', Icons.looks_two_rounded),
                          const SizedBox(width: 8),
                          _classChip('Kelas 12', 'Kelas 12 ($count12)', Icons.looks_3_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // KONTEN DAFTAR SISWA (GROUPED / FILTERED)
                    if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.person_search_rounded, size: 48, color: AppTheme.textSecondary),
                            const SizedBox(height: 10),
                            const Text(
                              'Data Siswa Tidak Ditemukan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada siswa yang cocok dengan "$_searchQuery".'
                                  : 'Belum ada siswa yang terdaftar pada filter ini.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else if (_selectedClassFilter == 'Semua' && _searchQuery.isEmpty)
                      // TAMPILKAN TERPISAH PER KELAS DENGAN HEADER RESMI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (count10 > 0) ...[
                            _buildClassSectionHeader('Kelas 10 (Tingkat X)', count10, const Color(0xFF0F766E), const Color(0xFFCCFBF1)),
                            const SizedBox(height: 8),
                            ..._allStudents.where((s) => s.gradeLevel == 10).map((s) => _buildStudentCard(s)),
                            const SizedBox(height: 16),
                          ],
                          if (count11 > 0) ...[
                            _buildClassSectionHeader('Kelas 11 (Tingkat XI)', count11, const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),
                            const SizedBox(height: 8),
                            ..._allStudents.where((s) => s.gradeLevel == 11).map((s) => _buildStudentCard(s)),
                            const SizedBox(height: 16),
                          ],
                          if (count12 > 0) ...[
                            _buildClassSectionHeader('Kelas 12 (Tingkat XII)', count12, const Color(0xFF7E22CE), const Color(0xFFF3E8FF)),
                            const SizedBox(height: 8),
                            ..._allStudents.where((s) => s.gradeLevel == 12).map((s) => _buildStudentCard(s)),
                            const SizedBox(height: 16),
                          ],
                          if (_allStudents.any((s) => s.gradeLevel == 0)) ...[
                            _buildClassSectionHeader('Lainnya / Tanpa Kelas', _allStudents.where((s) => s.gradeLevel == 0).length, AppTheme.textPrimary, const Color(0xFFF1F5F9)),
                            const SizedBox(height: 8),
                            ..._allStudents.where((s) => s.gradeLevel == 0).map((s) => _buildStudentCard(s)),
                            const SizedBox(height: 16),
                          ],
                        ],
                      )
                    else
                      // TAMPILKAN HASIL FILTER KELAS TERTENTU / HASIL PENCARIAN
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedClassFilter != 'Semua' ? _selectedClassFilter : 'Hasil Pencarian'} (${filtered.length} Siswa)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...filtered.map((s) => _buildStudentCard(s)),
                        ],
                      ),

                    const SizedBox(height: 60), // Space for FAB
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildClassSectionHeader(String title, int count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.school_rounded, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count Siswa',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          // Buka riwayat aktivitas siswa ini
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailLogsScreen(
                nis: student.nis,
                studentName: student.name,
                className: student.className,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (student.className.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _gradeBadge(student.className, student.gradeLevel),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NIS: ${student.nis}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded, color: AppTheme.primaryColor),
                tooltip: 'Lihat Riwayat Aktivitas',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentDetailLogsScreen(
                        nis: student.nis,
                        studentName: student.name,
                        className: student.className,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                tooltip: 'Hapus Siswa',
                onPressed: () => _deleteStudent(student.nis, student.name),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classChip(String filterValue, String label, IconData icon) {
    final isSelected = _selectedClassFilter == filterValue;
    Color activeColor;
    if (filterValue == 'Kelas 10') {
      activeColor = const Color(0xFF0F766E);
    } else if (filterValue == 'Kelas 11') {
      activeColor = const Color(0xFF1D4ED8);
    } else if (filterValue == 'Kelas 12') {
      activeColor = const Color(0xFF7E22CE);
    } else {
      activeColor = AppTheme.primaryColor;
    }

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : activeColor,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedClassFilter = filterValue);
        }
      },
      selectedColor: activeColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _gradeBadge(String className, int gradeLevel) {
    Color textColor;
    Color bgColor;

    switch (gradeLevel) {
      case 10:
        textColor = const Color(0xFF0F766E);
        bgColor = const Color(0xFFCCFBF1);
        break;
      case 11:
        textColor = const Color(0xFF1D4ED8);
        bgColor = const Color(0xFFDBEAFE);
        break;
      case 12:
        textColor = const Color(0xFF7E22CE);
        bgColor = const Color(0xFFF3E8FF);
        break;
      default:
        textColor = AppTheme.primaryDark;
        bgColor = AppTheme.primaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        className,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
