import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';

class MasterStudentsScreen extends StatefulWidget {
  const MasterStudentsScreen({super.key});

  @override
  State<MasterStudentsScreen> createState() => _MasterStudentsScreenState();
}

class _MasterStudentsScreenState extends State<MasterStudentsScreen> {
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getAllMasterStudents();
    if (mounted) {
      setState(() {
        _students = list.where((s) => s.nis != 'admin').toList();
        _isLoading = false;
      });
    }
  }

  void _showAddStudentDialog() {
    final nisController = TextEditingController();
    final nameController = TextEditingController();
    final classController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Data Siswa Resmi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nisController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nomor Induk Siswa (NIS)',
                  hintText: 'cth: 2024010',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'NIS wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Siswa',
                  hintText: 'cth: Farhan Maulana',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: classController,
                decoration: const InputDecoration(
                  labelText: 'Kelas / Jurusan',
                  hintText: 'cth: X MIPA 3',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Kelas wajib diisi' : null,
              ),
            ],
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
                      content: Text('Siswa ${student.name} berhasil ditambahkan ke database!'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
          : _students.isEmpty
              ? const Center(child: Text('Belum ada data siswa.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            student.name.isNotEmpty ? student.name[0] : 'S',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('NIS: ${student.nis} • Kelas: ${student.className}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                          onPressed: () => _deleteStudent(student.nis, student.name),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
