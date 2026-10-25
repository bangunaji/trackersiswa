import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/student.dart';
import '../models/user_account.dart';
import '../models/activity_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smanda_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Inisialisasi FFI untuk desktop Windows/Linux/macOS
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appSupportDir = await getApplicationSupportDirectory();
      dbPath = join(appSupportDir.path, filePath);
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = join(databasesPath, filePath);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Master Data Siswa
    await db.execute('''
      CREATE TABLE master_students (
        nis TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        class_name TEXT NOT NULL
      )
    ''');

    // 2. Tabel Akun Pengguna
    await db.execute('''
      CREATE TABLE user_accounts (
        nis TEXT PRIMARY KEY,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'student',
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Tabel Log Aktivitas (Hanya waktu dan nama siswa sesuai permintaan, plus nis & jenis aktivitas)
    await db.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nis TEXT NOT NULL,
        student_name TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Seed data awal siswa resmi sekolah SMANDA
    final initialStudents = [
      {'nis': '2024001', 'name': 'Ahmad Fauzi', 'class_name': 'X MIPA 1'},
      {'nis': '2024002', 'name': 'Siti Nurhaliza', 'class_name': 'X MIPA 1'},
      {'nis': '2024003', 'name': 'Budi Pratama', 'class_name': 'X MIPA 2'},
      {'nis': '2024004', 'name': 'Dewi Lestari', 'class_name': 'XI MIPA 1'},
      {'nis': '2024005', 'name': 'Rian Hidayat', 'class_name': 'XI IPS 1'},
      {'nis': '2024006', 'name': 'Anisa Rahma', 'class_name': 'XII MIPA 2'},
      {'nis': 'admin', 'name': 'Administrator Sekolah', 'class_name': 'Staff Kurikulum'},
    ];

    for (var s in initialStudents) {
      await db.insert('master_students', s);
    }

    // Seed akun admin default
    await db.insert('user_accounts', {
      'nis': 'admin',
      'password': 'admin',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- Operasi Master Siswa ---
  Future<Student?> getStudentByNis(String nis) async {
    final db = await database;
    final res = await db.query(
      'master_students',
      where: 'nis = ?',
      whereArgs: [nis.trim()],
    );
    if (res.isNotEmpty) {
      return Student.fromMap(res.first);
    }
    return null;
  }

  Future<List<Student>> getAllMasterStudents() async {
    final db = await database;
    final res = await db.query('master_students', orderBy: 'nis ASC');
    return res.map((e) => Student.fromMap(e)).toList();
  }

  Future<bool> addMasterStudent(Student student) async {
    final db = await database;
    try {
      await db.insert(
        'master_students',
        student.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      debugPrint('Error addMasterStudent: $e');
      return false;
    }
  }

  Future<int> deleteMasterStudent(String nis) async {
    final db = await database;
    return await db.delete(
      'master_students',
      where: 'nis = ?',
      whereArgs: [nis],
    );
  }

  // --- Operasi Akun Pengguna ---
  Future<bool> isAccountRegistered(String nis) async {
    final db = await database;
    final res = await db.query(
      'user_accounts',
      where: 'nis = ?',
      whereArgs: [nis.trim()],
    );
    return res.isNotEmpty;
  }

  /// Pendaftaran Akun:
  /// Cek apakah NIS ada di master data siswa.
  /// Bila ada -> berhasil dibuat. Bila tidak ada -> gagal membuat akun.
  Future<Map<String, dynamic>> registerUser({
    required String nis,
    required String password,
  }) async {
    final cleanNis = nis.trim();
    final cleanPass = password.trim();

    if (cleanNis.isEmpty || cleanPass.isEmpty) {
      return {
        'success': false,
        'message': 'NIS dan kata sandi tidak boleh kosong.',
      };
    }

    // 1. Cek keberadaan NIS di database Master Siswa
    final student = await getStudentByNis(cleanNis);
    if (student == null) {
      return {
        'success': false,
        'message': 'Pendaftaran GAGAL! NIS "$cleanNis" tidak terdaftar di database sekolah.',
      };
    }

    // 2. Cek apakah NIS sudah pernah daftar akun
    final alreadyRegistered = await isAccountRegistered(cleanNis);
    if (alreadyRegistered) {
      return {
        'success': false,
        'message': 'NIS "$cleanNis" sudah memiliki akun. Silakan langsung login.',
      };
    }

    // 3. Simpan akun ke database
    final db = await database;
    await db.insert('user_accounts', {
      'nis': cleanNis,
      'password': cleanPass,
      'role': cleanNis == 'admin' ? 'admin' : 'student',
      'created_at': DateTime.now().toIso8601String(),
    });

    return {
      'success': true,
      'message': 'Pendaftaran BERHASIL! Selamat datang, ${student.name}.',
      'student': student,
    };
  }

  /// Login:
  Future<Map<String, dynamic>> loginUser({
    required String nis,
    required String password,
  }) async {
    final cleanNis = nis.trim();
    final cleanPass = password.trim();

    final db = await database;
    final res = await db.query(
      'user_accounts',
      where: 'nis = ? AND password = ?',
      whereArgs: [cleanNis, cleanPass],
    );

    if (res.isEmpty) {
      // Cek apakah NIS terdaftar di master
      final student = await getStudentByNis(cleanNis);
      if (student == null) {
        return {
          'success': false,
          'message': 'NIS tidak ditemukan di sistem sekolah.',
        };
      }
      return {
        'success': false,
        'message': 'NIS atau kata sandi salah, atau Anda belum mendaftar akun.',
      };
    }

    final account = UserAccount.fromMap(res.first);
    final student = await getStudentByNis(cleanNis);

    return {
      'success': true,
      'account': account,
      'student': student ?? Student(nis: cleanNis, name: 'Admin', className: 'Staff'),
    };
  }

  // --- Operasi Log Aktivitas ---
  Future<int> insertActivityLog(ActivityLog log) async {
    final db = await database;
    return await db.insert('activity_logs', log.toMap());
  }

  Future<List<ActivityLog>> getActivitiesForStudent(String nis) async {
    final db = await database;
    final res = await db.query(
      'activity_logs',
      where: 'nis = ?',
      whereArgs: [nis.trim()],
      orderBy: 'timestamp DESC',
    );
    return res.map((e) => ActivityLog.fromMap(e)).toList();
  }

  Future<List<ActivityLog>> getAllActivities({
    String? searchQuery,
    String? activityFilter,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause += '(student_name LIKE ? OR nis LIKE ?)';
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    if (activityFilter != null && activityFilter != 'Semua') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      if (activityFilter == 'Belajar') {
        whereClause += '(LOWER(activity_type) LIKE ? OR LOWER(activity_type) LIKE ?)';
        whereArgs.add('%belajar%');
        whereArgs.add('%tugas%');
      } else if (activityFilter == 'Sholat') {
        whereClause += 'LOWER(activity_type) LIKE ?';
        whereArgs.add('%sholat%');
      } else if (activityFilter == 'Lainnya') {
        whereClause += '(LOWER(activity_type) NOT LIKE ? AND LOWER(activity_type) NOT LIKE ?)';
        whereArgs.add('%belajar%');
        whereArgs.add('%sholat%');
      } else {
        whereClause += 'LOWER(activity_type) LIKE ?';
        whereArgs.add('%${activityFilter.toLowerCase()}%');
      }
    }

    final res = await db.query(
      'activity_logs',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
    );
    return res.map((e) => ActivityLog.fromMap(e)).toList();
  }

  Future<int> deleteActivityLog(int id) async {
    final db = await database;
    return await db.delete(
      'activity_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllActivities() async {
    final db = await database;
    await db.delete('activity_logs');
  }
}
