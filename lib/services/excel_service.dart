import 'dart:io';
import 'dart:ui';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/activity_log.dart';

class ExcelService {
  /// Mengekspor daftar log aktivitas ke file Excel (.xlsx) dan membukanya via Share
  static Future<String?> exportActivityLogsToExcel(List<ActivityLog> logs) async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'Log Aktivitas Siswa';
      
      // Ambil sheet pertama atau default
      final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheet, sheetName);
      final sheet = excel[sheetName];

      // Format tanggal cetak
      final now = DateTime.now();
      String printDateStr;
      try {
        printDateStr = DateFormat('dd MMMM yyyy, HH:mm:ss', 'id_ID').format(now);
      } catch (_) {
        printDateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      }

      // Header Judul Laporan
      sheet.appendRow([
        TextCellValue('LAPORAN DATA AKTIVITAS SISWA SMANDA'),
      ]);
      sheet.appendRow([
        TextCellValue('Waktu Cetak: $printDateStr WIB'),
      ]);
      sheet.appendRow([
        TextCellValue('Total Data: ${logs.length} catatan aktivitas'),
      ]);
      sheet.appendRow([
        TextCellValue(''), // Baris kosong
      ]);

      // Baris Header Tabel
      sheet.appendRow([
        TextCellValue('No'),
        TextCellValue('Waktu & Tanggal'),
        TextCellValue('Nama Siswa'),
        TextCellValue('NIS'),
        TextCellValue('Kelas'),
        TextCellValue('Jenis Aktivitas'),
        TextCellValue('Keterangan'),
      ]);

      // Styling Header Kolom (Baris ke-5, index 4)
      final headerCellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      for (int col = 0; col < 7; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 4));
        cell.cellStyle = headerCellStyle;
      }

      // Masukkan baris data
      int index = 1;
      for (final log in logs) {
        // Format waktu agar mudah dibaca di Excel
        String formattedTime = log.timestamp;
        try {
          final dt = DateTime.parse(log.timestamp);
          formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
        } catch (_) {
          // gunakan string asli jika parsing gagal
        }

        sheet.appendRow([
          IntCellValue(index),
          TextCellValue(formattedTime),
          TextCellValue(log.studentName),
          TextCellValue(log.nis),
          TextCellValue(log.className.isEmpty ? '-' : log.className),
          TextCellValue(log.activityType),
          TextCellValue(log.notes.isEmpty ? '-' : log.notes),
        ]);
        index++;
      }

      // Encode ke bytes
      final fileBytes = excel.save();
      if (fileBytes == null) return null;

      // Dapatkan direktori penyimpanan
      Directory outputDir;
      if (Platform.isAndroid || Platform.isIOS) {
        outputDir = await getApplicationDocumentsDirectory();
      } else {
        // Windows / Desktop
        outputDir = await getApplicationDocumentsDirectory();
      }

      final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'rekap_aktivitas_siswa_$timeStamp.xlsx';
      final filePath = p.join(outputDir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return filePath;
    } catch (e) {
      // ignore: avoid_print
      print('Gagal export excel: $e');
      return null;
    }
  }

  /// Membagikan file excel melalui sistem share OS (WhatsApp, Drive, Email, dll)
  static Future<void> shareExcelFile(String filePath, {Rect? sharePositionOrigin}) async {
    final xFile = XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    await Share.shareXFiles(
      [xFile],
      text: 'Berikut adalah Rekap Aktivitas Siswa SMANDA (Excel).',
      subject: 'Rekap Aktivitas Siswa SMANDA',
      sharePositionOrigin: sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
    );
  }
}
