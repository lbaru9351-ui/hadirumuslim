---
name: absensi-qrcode-almuslim
description: Panduan alur, tampilan layar (splash, login, menu, pindai QR, sesi dosen, rekap), aturan validasi, dan pemetaan penelitian untuk aplikasi absensi mahasiswa berbasis QR Code di Universitas Almuslim (skripsi M Hafizh, Prodi Informatika). Gunakan skill ini setiap kali pengguna menyebut aplikasi absensi QR Code, presensi mahasiswa, alur aplikasi absensi, desain atau mockup layar absensi, QR dinamis, validasi lokasi/perangkat, skema database absensi, kode Flutter untuk absensi, atau menulis Bab III/IV/V skripsi tentang kinerja absensi QR Code, walaupun pengguna tidak menyebut nama skill ini.
---

# Absensi QR Code - Universitas Almuslim

Skill ini adalah sumber acuan tunggal untuk aplikasi absensi mahasiswa berbasis QR Code pada skripsi
"Analisis Kinerja Aplikasi Absensi Mahasiswa Berbasis QR Code terhadap Efisiensi dan Keaslian Informasi
di Universitas Almuslim". Pakai isi skill ini agar jawaban, desain, kode, dan teks skripsi tetap konsisten
dengan Bab I - III yang sudah ditulis.

## Cara memakai skill ini

1. Tentukan kebutuhan pengguna: desain layar, kode aplikasi, database, atau teks skripsi.
2. Ikuti bagian yang relevan di bawah. Jangan menambah fitur di luar yang tercantum kecuali diminta.
3. Bila pengguna meminta sesuatu yang bertentangan dengan bagian "Keputusan yang masih terbuka",
   tanyakan satu pertanyaan singkat, atau pilih default dan sebutkan asumsinya dalam satu kalimat.
4. Bahasa keluaran: Bahasa Indonesia baku, kecuali pengguna memakai bahasa lain.

## Tujuan dan batas

- Variabel penelitian: **kinerja sistem**, **efisiensi proses absensi**, **keaslian informasi kehadiran**.
- Platform: aplikasi Android (Flutter + Dart), satu basis kode dengan menu menyesuaikan peran.
- Metode pengembangan: Prototype (communication, quick plan, quick design, construction, deployment/feedback).
- Standar mutu: ISO/IEC 25010 (performance efficiency, usability, security: authenticity dan integrity).

## Peran pengguna

| Peran | Hak akses utama |
| --- | --- |
| Admin | Kelola data master (pengguna, mata kuliah, kelas, peserta, koordinat dan radius ruang); reset pengikatan perangkat |
| Dosen | Buka dan tutup sesi, tampilkan QR dinamis, pantau jumlah hadir, rekap, ubah status dengan alasan |
| Mahasiswa | Pindai QR Code, lihat riwayat kehadiran sendiri |

## Alur utama

**Umum:** Splash screen -> Login (NPM/NIP + kata sandi) -> Menu sesuai peran.

**Mahasiswa:** Beranda -> Pindai QR -> validasi 7 lapis -> hasil (tercatat atau ditolak dengan alasan) -> Riwayat.

**Dosen:** Beranda -> Buka sesi (pilih kelas dan pertemuan ke-) -> QR dinamis tampil dan token berganti
berkala -> pantau jumlah hadir -> Tutup sesi (manual atau otomatis setelah batas waktu) -> Rekap dan ubah status.

**Admin:** Data master -> atur koordinat dan radius ruang -> reset pengikatan perangkat bila mahasiswa ganti HP.

## Tujuh lapis validasi (urutan tetap)

| Lapis | Pemeriksaan | Pesan bila ditolak |
| --- | --- | --- |
| 1 | Akun login dan terdaftar sebagai peserta kelas | Anda bukan peserta kelas ini |
| 2 | ID perangkat sama dengan perangkat yang terikat pada akun | Perangkat tidak sesuai dengan akun Anda |
| 3 | Sesi berstatus buka dan belum melewati batas waktu | Sesi sudah ditutup |
| 4 | Token pada QR sama dengan token aktif atau token sebelumnya | QR Code kedaluwarsa, pindai ulang |
| 5 | Jarak ke koordinat ruang (Haversine) tidak melebihi radius | Anda berada di luar ruang kuliah |
| 6 | Belum ada kehadiran untuk sesi dan mahasiswa yang sama | Anda sudah absen pada sesi ini |
| 7 | Cap waktu memakai waktu server, bukan jam perangkat | (tidak ditampilkan; diterapkan otomatis) |

Aturan tambahan:
- Koordinat ruang ditetapkan admin pada data kelas, tidak diambil dari lokasi dosen.
- Simpan koordinat, jarak, dan durasi proses pada setiap kehadiran sebagai bahan audit dan pengukuran kinerja.
- Pemeriksaan lokasi di sisi aplikasi dapat dilewati aplikasi fake GPS. Akui ini sebagai keterbatasan
  dan jangan mengklaim sistem "kebal" terhadap pemalsuan lokasi.

## Parameter default (sesuaikan saat uji coba)

- Interval pembaruan token: 30 detik; token sebelumnya tetap diterima satu siklus.
- Batas waktu sesi: 15 menit.
- Radius ruang: 30 meter.
- Target waktu pindai sampai tersimpan: 3 detik pada jaringan normal.

## Spesifikasi layar

Ukuran acuan: ponsel 390 x 844. Setiap layar harus punya satu aksi utama yang jelas.

1. **Splash screen** - logo QR, nama "Absensi QR", "Universitas Almuslim", indikator memuat, versi.
   Durasi 1,5 - 2 detik; setelah itu cek sesi login lalu arahkan ke Login atau Beranda.
2. **Login** - kolom NPM/NIP, kata sandi, tombol Masuk, catatan bahwa akun mahasiswa terikat satu perangkat.
   Tampilkan pesan kesalahan yang jelas bila kata sandi salah.
3. **Beranda mahasiswa (menu)** - sapaan, persentase kehadiran semester, daftar kelas hari ini dengan status sesi
   (dibuka / belum dibuka) dan tombol Pindai QR Code. Navigasi bawah: Beranda, Pindai, Riwayat, Profil.
4. **Pindai QR** - tampilan kamera dengan bingkai, status lokasi (jarak dan dalam/luar radius), status perangkat,
   hasil berupa kartu "Kehadiran tercatat" (waktu server, durasi proses) atau pesan penolakan dari tabel validasi.
   Bila izin kamera atau lokasi ditolak, minta ulang dan jelaskan kegunaannya.
5. **Riwayat mahasiswa** - daftar pertemuan per mata kuliah, status (hadir, izin, sakit, alfa), persentase kehadiran.
6. **Beranda dosen** - daftar kelas yang diampu, tombol Buka sesi, akses Rekap.
7. **Sesi aktif dosen** - QR dinamis, hitung mundur pergantian token, jumlah hadir (mis. 24 / 30), sisa waktu sesi,
   tombol Tutup sesi (gaya peringatan). Bila jaringan putus, beri peringatan bahwa QR tidak diperbarui.
8. **Rekap dosen** - ringkasan hadir/izin/sakit/alfa, daftar mahasiswa beserta jam, tombol Ubah status.
   Setiap perubahan wajib disertai alasan dan masuk log.
9. **Admin** - formulir dan daftar data master, lokasi ruang (koordinat dan radius), tombol reset perangkat.

Mockup acuan untuk layar 1, 2, 3, 4, 7, 8 dan diagram alur sudah dibuat pada desain canvas
"Desain Aplikasi Absensi QR Code - Universitas Almuslim". Layar 5, 6, dan 9 belum ada mockup-nya.

## Gaya visual




- Warna: hijau tua `#0F6B5C` (utama), latar `#F4F6F5`, teks `#14211F`, teks sekunder `#55635F`, garis `#E2E8E5`.
- Status: berhasil `#1B7F4B` di atas `#E3F3EA`; peringatan `#8A5A00` di atas `#FFF1D6`; gagal/tutup `#A32B2B` di atas `#FBE4E4`.
- Font Inter (400, 500, 600, 700). Sudut membulat 12 - 16 px. Tombol tinggi 52 px.
- Target sentuh minimal 44 px, kontras teks minimal 4,5:1.
- Jangan memakai emoji sebagai ikon, dan jangan menampilkan data palsu sebagai hasil penelitian.

## Data

- Skema SQL lengkap ada pada `absensi_qrcode_full.sql` (MySQL 8 / MariaDB): tabel inti, tabel pengukuran
  penelitian, prosedur `sp_catat_kehadiran`, fungsi `haversine_m`, trigger log, dan view laporan.
- Bab III saat ini mengasumsikan **Firebase (Firestore)**. Skema SQL adalah padanan relasionalnya.
  Pilih salah satu sebagai backend utama dan samakan Bab 3.5.1 serta 3.5.7.
- ID dokumen kehadiran = `idSesi_uidMahasiswa` sehingga satu mahasiswa hanya punya satu kehadiran per sesi.

## Pengukuran penelitian (untuk Bab IV dan V)

| Rumusan masalah | Data | Analisis |
| --- | --- | --- |
| Kinerja sistem | Durasi proses, keberhasilan pindai pada pencahayaan/jarak/jaringan, skor SUS | Statistik deskriptif, skor SUS (batas diterima sekitar 68) |
| Efisiensi | Waktu absensi dan rekap manual vs QR pada kelas yang sama | Efisiensi (%) = (T manual - T QR) / T manual x 100; paired t-test |
| Keaslian informasi | Skenario uji S1 - S7 | Tingkat penolakan (%) = ditolak / seluruh percobaan tidak sah x 100 |
| Kendala penerapan | Wawancara, observasi, pertanyaan terbuka | Pengelompokan temuan secara deskriptif |

Skenario uji keaslian: S1 QR dibagikan, S2 di luar radius, S3 satu perangkat dua akun, S4 absensi ganda,
S5 manipulasi jam perangkat, S6 pemindaian setelah sesi ditutup, S7 fake GPS (dicatat apa adanya sebagai keterbatasan).

## Urutan implementasi yang disarankan

1. Siapkan backend dan data master (pengguna, mata kuliah, kelas, peserta, koordinat ruang).
2. Login dan pengikatan perangkat.
3. Buka sesi dan QR dinamis (pembaruan token berkala).
4. Pindai QR dan tujuh lapis validasi.
5. Pantau, tutup sesi, rekap, ubah status dengan log.
6. Pencatatan durasi proses (KF-14) agar pengukuran kinerja otomatis.
7. Uji black box (Tabel 3.16), uji keaslian (Tabel 3.17), ukur waktu, sebar kuesioner SUS dan Likert.
8. Kumpulkan umpan balik, perbaiki, ulangi siklus Prototype.

Paket Flutter yang direncanakan: `mobile_scanner`, `qr_flutter`, `geolocator`, `firebase_auth`,
`cloud_firestore`, `device_info_plus`. Cek ulang nama, versi, dan izin Android di pub.dev sebelum dipakai.

## Aturan menulis untuk skripsi

- Jangan menulis angka hasil (persentase, rata-rata waktu, skor SUS, tingkat penolakan) yang belum diukur.
  Data contoh pada skema SQL dan mockup hanyalah ilustrasi.
- Setiap kutipan teori memerlukan sumber nyata. Jangan mengarang referensi; tandai `[sumber]` bila belum ada.
- Sebutkan keterbatasan secara jujur: fake GPS, ketergantungan jaringan, dan hasil persepsi yang berasal dari sampel terbatas.
- Gunakan istilah "keaslian informasi" secara konsisten sesuai judul; bila memakai "validitas data", jelaskan kaitannya.

## Keputusan yang masih terbuka

Tanyakan atau tetapkan default sebelum melanjutkan bila relevan:

1. **Membangun atau mengevaluasi?** Bab I menyebut hanya mengevaluasi sistem yang ada, sedangkan Bab III membangun aplikasi baru.
   Samakan cakupannya (batasan masalah, judul, dan metode).
2. **Backend:** Firebase atau MySQL + REST API.
3. **Ukuran sampel:** jumlah kelas, pertemuan, dan responden kuesioner, serta teknik pengambilan sampel.
4. **Versi Android minimum** dan jumlah perangkat uji.
