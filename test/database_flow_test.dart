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
}
