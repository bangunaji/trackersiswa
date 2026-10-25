# SMANDA Activity - Aplikasi Mobile Pencatatan Aktivitas Siswa

Aplikasi mobile berbasis **Flutter** untuk pencatatan aktivitas harian siswa (Belajar & Sholat) dengan validasi database NIS sekolah serta fitur ekspor laporan ke format Microsoft Excel (`.xlsx`) untuk Administrator / Guru.

---

## 🌟 Fitur Utama

### 1. Pendaftaran Akun Berbasis Validasi NIS
* **Validasi Database Resmi**: Siswa mendaftar dengan **NIS (Nomor Induk Siswa)** dan **Kata Sandi**.
* **Pengecekan Otomatis**:
  * ✅ **Bila NIS ada di database sekolah**: Pendaftaran **BERHASIL**, akun diaktifkan dan langsung terhubung dengan data nama resmi siswa.
  * ❌ **Bila NIS tidak ada di database sekolah**: Pendaftaran **GAGAL** dengan pesan peringatan bahwa NIS tidak terdaftar.
  * ⚠️ **Pencegahan Akun Ganda**: Jika NIS sudah terdaftar sebelumnya, sistem akan menyarankan siswa untuk langsung login.

### 2. Dashboard Siswa & Nama Siswa di Pojok Kiri Atas
* **Identitas Siswa (Top-Left Corner)**: Sesuai instruksi, pada bagian pojok kiri atas aplikasi ditampilkan secara jelas:
  * **Nama Lengkap Siswa** sesuai NIS yang terdaftar di database.
  * Nomor Induk Siswa (NIS) dan Kelas / Jurusan.
* **Tombol Cepat Aktivitas (One-Tap Click)**:
  * 📘 **Tombol Belajar**: Klik saat memulai belajar (pilihan: Belajar Mandiri, Tugas/PR, Belajar di Kelas, Perpustakaan, dsb).
  * 🕌 **Tombol Sholat**: Klik saat melaksanakan sholat (pilihan: Sholat Dzuhur, Dhuha, Ashar, Berjamaah di Masjid, dsb).
  * ⭐ **Tombol Aktivitas Lainnya**: Untuk kegiatan positif seperti ekskul, upacara, atau literasi.
* **Penyimpanan Data Otomatis**:
  * Saat tombol diklik, sistem secara otomatis mencatat **Waktu (Tanggal, Jam, Menit, Detik)** bersama **Nama Siswa** dan **NIS**.
* **Riwayat Harian**: Siswa dapat melihat daftar aktivitas yang sudah tersimpan pada hari ini.

### 3. Dashboard Admin & Ekspor ke Excel (.xlsx)
* **Login Khusus Admin**: Masuk melalui tab/portal admin.
* **Statistik Aktivitas**: Ringkasan total catatan aktivitas, jumlah aktivitas belajar, dan sholat.
* **Pencarian & Filter**: Filter berdasarkan jenis aktivitas (Semua / Belajar / Sholat) atau cari nama siswa / NIS secara langsung.
* 📊 **Fitur Ekspor ke Excel (.xlsx)**:
  * Menghasilkan file Excel resmi berformat `.xlsx`.
  * Memuat kolom: **No**, **Waktu & Tanggal**, **Nama Siswa**, **NIS**, **Jenis Aktivitas**, dan **Keterangan**.
  * Dilengkapi tombol kirim/bagikan (Share) langsung via WhatsApp, Email, Google Drive, atau simpan ke memori perangkat.
* **Kelola Master Data Siswa**: Admin dapat melihat daftar seluruh NIS yang terdaftar di sekolah dan menambahkan siswa baru ke database.

---

## 📱 Data Uji Coba Bawaan (Pre-Seeded Master Data)

Untuk memudahkan pengujian langsung tanpa perlu input database manual:

### 1. Akun Admin
* **NIS / Username**: `admin`
* **Kata Sandi**: `admin`

### 2. Contoh NIS Resmi di Database (Bisa digunakan untuk Daftar Akun Siswa):
| NIS | Nama Siswa | Kelas | Keterangan |
| :--- | :--- | :--- | :--- |
| `2024001` | Ahmad Fauzi | X MIPA 1 | Terdaftar di Database Sekolah |
| `2024002` | Siti Nurhaliza | X MIPA 1 | Terdaftar di Database Sekolah |
| `2024003` | Budi Pratama | X MIPA 2 | Terdaftar di Database Sekolah |
| `2024004` | Dewi Lestari | XI MIPA 1 | Terdaftar di Database Sekolah |
| `2024005` | Rian Hidayat | XI IPS 1 | Terdaftar di Database Sekolah |
| `2024006` | Anisa Rahma | XII MIPA 2 | Terdaftar di Database Sekolah |

> 💡 **Uji Coba Gagal Daftar**: Coba daftar akun dengan NIS sembarang (contoh: `9999999`). Sistem akan menolak pendaftaran karena NIS tidak ditemukan di database sekolah.

---

## 🛠️ Struktur Direktori Proyek

```
lib/
├── main.dart                      # Inisialisasi aplikasi, database SQLite & localization
├── models/
│   ├── student.dart               # Model Master Data Siswa (NIS, Nama, Kelas)
│   ├── user_account.dart          # Model Akun Terdaftar (NIS, Password, Role)
│   └── activity_log.dart          # Model Log Aktivitas (Waktu, Nama Siswa, NIS, Aktivitas)
├── services/
│   ├── database_helper.dart       # SQLite Database (CRUD Master Siswa, Autentikasi, Log)
│   └── excel_service.dart         # Pembuatan & Ekspor file Excel (.xlsx) serta Share
├── theme/
│   └── app_theme.dart             # Styling tema modern, tipografi Google Fonts, dan palet warna
└── screens/
    ├── login_screen.dart          # Halaman masuk untuk Siswa & Admin + panduan demo
    ├── register_screen.dart       # Pendaftaran siswa dengan validasi NIS real-time
    ├── student_home_screen.dart   # Dashboard Siswa: Nama di pojok kiri atas, tombol Belajar & Sholat
    ├── admin_dashboard_screen.dart# Panel Admin: Rekap data & tombol Ekspor ke Excel
    └── master_students_screen.dart# Kelola data master NIS siswa
```

---

## 🚀 Cara Menjalankan Aplikasi

Pastikan Flutter SDK sudah terpasang. Dari direktori `d:\smanda`:

1. **Jalankan di Android Emulator / Device**:
   ```bash
   flutter run
   ```

2. **Jalankan di Windows Desktop (untuk uji coba cepat di PC)**:
   ```bash
   flutter run -d windows
   ```

3. **Build APK Android Lokal**:
   ```bash
   flutter build apk --release
   ```
   *(File APK akan berada di folder `build/app/outputs/flutter-apk/app-release.apk`)*

4. **Menjalankan Pengujian Otomatis**:
   ```bash
   flutter test
   ```

---

## ⚙️ CI/CD dengan GitHub Actions

Repository ini telah dikonfigurasi dengan alur kerja **GitHub Actions** otomatis pada folder `.github/workflows/`:

1. **`build.yml` (Otomatis saat Push & Pull Request)**:
   * Menguji kode secara otomatis (`flutter analyze` & `flutter test`).
   * Melakukan build **Release APK** untuk Android (`universal` dan `split-per-abi`).
   * Mengunggah APK ke **GitHub Actions Artifacts** sehingga bisa langsung diunduh dari browser tanpa perlu compile di komputer lokal.
   * Mendukung tombol **Run workflow** manual melalui tab *Actions* di GitHub.

2. **`release.yml` (Otomatis saat Push Tag Versi)**:
   * Memicu pembuatan **GitHub Release** otomatis saat Anda membuat tag git baru (contoh: `v1.0.0`).
   * Menghasilkan file `app-release.apk` dan `app-release.aab` (Google Play Store Bundle) dan otomatis menempelkannya ke halaman rilis GitHub.

### Langkah-langkah Push ke GitHub:
```bash
git add .
git commit -m "feat: complete smanda mobile app with github actions CI/CD"
git remote add origin https://github.com/USERNAME/REPO-ANDA.git
git branch -M main
git push -u origin main
```
Setelah push, buka tab **Actions** di repository GitHub Anda untuk melihat proses build otomatis dan mengunduh APK hasil build!

