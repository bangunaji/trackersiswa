import 'package:flutter_test/flutter_test.dart';
import 'package:smanda_app/models/activity_log.dart';
import 'package:smanda_app/models/student.dart';
import 'package:smanda_app/services/database_helper.dart';
import 'package:smanda_app/services/excel_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  test('Validasi Pendaftaran Akun Berdasarkan NIS di Database', () async {
    final db = DatabaseHelper.instance;
    final rawDb = await db.database;
    await rawDb.delete('user_accounts', where: 'nis = ?', whereArgs: ['2024001']);

    // 1. Coba daftar dengan NIS yang TIDAK ada di database -> HARUS GAGAL
    final failResult = await db.registerUser(
      nis: '9999999', // NIS fiktif tidak ada di master
      password: 'password123',
    );
    expect(failResult['success'], false);
    expect(failResult['message'].toString().contains('tidak terdaftar di database'), true);

    // 2. Coba daftar dengan NIS yang ADA di database master (cth: 2024001 - Ahmad Fauzi) -> HARUS BERHASIL
    final successResult = await db.registerUser(
      nis: '2024001',
      password: 'mypassword',
    );
    expect(successResult['success'], true);
    final student = successResult['student'] as Student;
    expect(student.name, 'Ahmad Fauzi');

    // 3. Coba daftar ulang NIS yang sama -> HARUS DITOLAK karena sudah terdaftar
    final duplicateResult = await db.registerUser(
      nis: '2024001',
      password: 'mypassword',
    );
    expect(duplicateResult['success'], false);
    expect(duplicateResult['message'].toString().contains('sudah memiliki akun'), true);
  });

  test('Pencatatan Aktivitas (Waktu dan Nama Siswa) dan Export ke Excel', () async {
    final db = DatabaseHelper.instance;

    // Catat aktivitas Belajar
    final nowIso = DateTime.now().toIso8601String();
    await db.insertActivityLog(ActivityLog(
      nis: '2024001',
      studentName: 'Ahmad Fauzi',
      activityType: 'Belajar',
      timestamp: nowIso,
    ));

    // Catat aktivitas Sholat
    await db.insertActivityLog(ActivityLog(
      nis: '2024001',
      studentName: 'Ahmad Fauzi',
      activityType: 'Sholat Dzuhur',
      timestamp: DateTime.now().toIso8601String(),
    ));

    // Catat aktivitas dengan nama spesifik seperti di aplikasi
    await db.insertActivityLog(ActivityLog(
      nis: '2024001',
      studentName: 'Ahmad Fauzi',
      activityType: 'Belajar Mandiri',
      timestamp: DateTime.now().toIso8601String(),
    ));

    await db.insertActivityLog(ActivityLog(
      nis: '2024001',
      studentName: 'Ahmad Fauzi',
      activityType: 'Sholat Berjamaah di Masjid',
      timestamp: DateTime.now().toIso8601String(),
    ));

    await db.insertActivityLog(ActivityLog(
      nis: '2024001',
      studentName: 'Ahmad Fauzi',
      activityType: 'Kegiatan Ekstrakurikuler',
      timestamp: DateTime.now().toIso8601String(),
    ));

    // Uji Filter Belajar
    final belajarLogs = await db.getAllActivities(activityFilter: 'Belajar');
    expect(belajarLogs.isNotEmpty, true);
    expect(belajarLogs.every((l) => l.activityType.toLowerCase().contains('belajar') || l.activityType.toLowerCase().contains('tugas')), true);

    // Uji Filter Sholat
    final sholatLogs = await db.getAllActivities(activityFilter: 'Sholat');
    expect(sholatLogs.isNotEmpty, true);
    expect(sholatLogs.every((l) => l.activityType.toLowerCase().contains('sholat')), true);

    // Uji Filter Lainnya
    final lainnyaLogs = await db.getAllActivities(activityFilter: 'Lainnya');
    expect(lainnyaLogs.isNotEmpty, true);
    expect(lainnyaLogs.every((l) => !l.activityType.toLowerCase().contains('belajar') && !l.activityType.toLowerCase().contains('sholat')), true);

    // Ambil semua data log
    final logs = await db.getAllActivities();
    expect(logs.isNotEmpty, true);

    // Verifikasi Pembuatan File Excel
    final excelPath = await ExcelService.exportActivityLogsToExcel(logs);
    expect(excelPath, isNotNull);
    expect(excelPath!.endsWith('.xlsx'), true);
  });

  test('Pemisahan dan Filter Data Siswa per Kelas (10, 11, 12)', () async {
    final db = DatabaseHelper.instance;

    // Siswa 2024004: Dewi Lestari - XI MIPA 1 (Kelas 11)
    // Siswa 2024006: Anisa Rahma - XII MIPA 2 (Kelas 12)
    await db.insertActivityLog(ActivityLog(
      nis: '2024004',
      studentName: 'Dewi Lestari',
      activityType: 'Belajar Kimia',
      timestamp: DateTime.now().toIso8601String(),
    ));

    await db.insertActivityLog(ActivityLog(
      nis: '2024006',
      studentName: 'Anisa Rahma',
      activityType: 'Sholat Ashar',
      timestamp: DateTime.now().toIso8601String(),
    ));

    // Test filter kelas 10
    final logs10 = await db.getAllActivities(classFilter: 'Kelas 10');
    expect(logs10.isNotEmpty, true);
    expect(logs10.every((l) => l.gradeLevel == 10), true);

    // Test filter kelas 11
    final logs11 = await db.getAllActivities(classFilter: 'Kelas 11');
    expect(logs11.isNotEmpty, true);
    expect(logs11.every((l) => l.gradeLevel == 11), true);

    // Test filter kelas 12
    final logs12 = await db.getAllActivities(classFilter: 'Kelas 12');
    expect(logs12.isNotEmpty, true);
    expect(logs12.every((l) => l.gradeLevel == 12), true);

    // Master students grade level test
    final masterList = await db.getAllMasterStudents();
    final count10 = masterList.where((s) => s.gradeLevel == 10).length;
    final count11 = masterList.where((s) => s.gradeLevel == 11).length;
    final count12 = masterList.where((s) => s.gradeLevel == 12).length;
    expect(count10 > 0, true);
    expect(count11 > 0, true);
    expect(count12 > 0, true);
  });
}

