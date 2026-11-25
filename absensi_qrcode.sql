-- phpMyAdmin SQL Dump
-- version 4.8.5
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 17, 2026 at 09:03 AM
-- Server version: 5.7.33
-- PHP Version: 7.4.19

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `absensi_qrcode`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_catat_kehadiran` (IN `p_id_sesi` VARCHAR(36), IN `p_uid` VARCHAR(36), IN `p_token` VARCHAR(64), IN `p_id_perangkat` VARCHAR(100), IN `p_lat` DECIMAL(9,6), IN `p_lng` DECIMAL(9,6), IN `p_durasi_ms` INT)  proc: BEGIN
  DECLARE v_kelas    INT DEFAULT NULL;
  DECLARE v_status   VARCHAR(10);
  DECLARE v_buka     DATETIME(3);
  DECLARE v_batas    SMALLINT;
  DECLARE v_tok      VARCHAR(64);
  DECLARE v_tok_lama VARCHAR(64);
  DECLARE v_lat      DECIMAL(9,6);
  DECLARE v_lng      DECIMAL(9,6);
  DECLARE v_radius   SMALLINT;
  DECLARE v_dev      VARCHAR(100);
  DECLARE v_jarak    DOUBLE;

  SELECT s.id_kelas, s.status, s.waktu_buka, s.batas_waktu_menit, s.token_aktif,
         s.token_sebelumnya, k.lat_ruang, k.lng_ruang, k.radius_m
    INTO v_kelas, v_status, v_buka, v_batas, v_tok,
         v_tok_lama, v_lat, v_lng, v_radius
    FROM sesi s
    JOIN kelas k ON k.id_kelas = s.id_kelas
   WHERE s.id_sesi = p_id_sesi;

  -- Lapis 1: akun terdaftar sebagai peserta kelas
  IF v_kelas IS NULL OR NOT EXISTS (
       SELECT 1 FROM peserta_kelas
        WHERE id_kelas = v_kelas AND uid_mahasiswa = p_uid) THEN
    SELECT 'DITOLAK: bukan peserta kelas' AS hasil;
    LEAVE proc;
  END IF;

  -- Lapis 2: pengikatan perangkat
  IF EXISTS (SELECT 1 FROM pengguna
              WHERE id_perangkat = p_id_perangkat AND uid <> p_uid) THEN
    SELECT 'DITOLAK: perangkat dipakai akun lain' AS hasil;
    LEAVE proc;
  END IF;
  SELECT id_perangkat INTO v_dev FROM pengguna WHERE uid = p_uid;
  IF v_dev IS NULL THEN
    UPDATE pengguna SET id_perangkat = p_id_perangkat WHERE uid = p_uid;  -- login pertama
  ELSEIF v_dev <> p_id_perangkat THEN
    SELECT 'DITOLAK: perangkat tidak sesuai' AS hasil;
    LEAVE proc;
  END IF;

  -- Lapis 3: status dan batas waktu sesi
  IF v_status <> 'buka' OR NOW(3) > DATE_ADD(v_buka, INTERVAL v_batas MINUTE) THEN
    SELECT 'DITOLAK: sesi sudah ditutup' AS hasil;
    LEAVE proc;
  END IF;

  -- Lapis 4: token aktif atau token sebelumnya
  IF p_token <> v_tok AND (v_tok_lama IS NULL OR p_token <> v_tok_lama) THEN
    SELECT 'DITOLAK: token kedaluwarsa' AS hasil;
    LEAVE proc;
  END IF;

  -- Lapis 5: radius lokasi (Haversine)
  SET v_jarak = haversine_m(p_lat, p_lng, v_lat, v_lng);
  IF v_jarak > v_radius THEN
    SELECT CONCAT('DITOLAK: di luar radius (', ROUND(v_jarak), ' m)') AS hasil;
    LEAVE proc;
  END IF;

  -- Lapis 6: duplikasi
  IF EXISTS (SELECT 1 FROM kehadiran
              WHERE id_sesi = p_id_sesi AND uid_mahasiswa = p_uid) THEN
    SELECT 'DITOLAK: sudah absen' AS hasil;
    LEAVE proc;
  END IF;

  -- Lapis 7: cap waktu diambil dari server (DEFAULT CURRENT_TIMESTAMP(3))
  INSERT INTO kehadiran (id_kehadiran, id_sesi, uid_mahasiswa, latitude, longitude,
                         jarak_m, id_perangkat, durasi_proses_ms, status)
  VALUES (CONCAT(p_id_sesi, '_', p_uid), p_id_sesi, p_uid, p_lat, p_lng,
          v_jarak, p_id_perangkat, p_durasi_ms, 'hadir');

  SELECT 'BERHASIL' AS hasil;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_perbarui_token` (IN `p_id_sesi` VARCHAR(36), IN `p_token_baru` VARCHAR(64))  BEGIN
  UPDATE sesi
     SET token_sebelumnya = token_aktif,
         token_aktif      = p_token_baru,
         token_diperbarui = NOW(3)
   WHERE id_sesi = p_id_sesi AND status = 'buka';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_tutup_sesi_kedaluwarsa` ()  BEGIN
  UPDATE sesi
     SET status = 'tutup', waktu_tutup = NOW(3)
   WHERE status = 'buka'
     AND NOW(3) > DATE_ADD(waktu_buka, INTERVAL batas_waktu_menit MINUTE);
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `haversine_m` (`lat1` DOUBLE, `lng1` DOUBLE, `lat2` DOUBLE, `lng2` DOUBLE) RETURNS DOUBLE BEGIN
  RETURN 2 * 6371000 * ASIN(SQRT(
      POWER(SIN(RADIANS(lat2 - lat1) / 2), 2) +
      COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
      POWER(SIN(RADIANS(lng2 - lng1) / 2), 2)));
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `kehadiran`
--

CREATE TABLE `kehadiran` (
  `id_kehadiran` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Dibentuk dari id_sesi + _ + uid_mahasiswa',
  `id_sesi` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uid_mahasiswa` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `waktu_server` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'Cap waktu server, bukan perangkat',
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  `jarak_m` decimal(8,2) DEFAULT NULL COMMENT 'Jarak ke ruang kuliah (meter)',
  `id_perangkat` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `durasi_proses_ms` int(11) DEFAULT NULL COMMENT 'Pemindaian s.d. data tersimpan (KF-14)',
  `status` enum('hadir','izin','sakit','alfa') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'hadir'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kehadiran`
--

INSERT INTO `kehadiran` (`id_kehadiran`, `id_sesi`, `uid_mahasiswa`, `waktu_server`, `latitude`, `longitude`, `jarak_m`, `id_perangkat`, `durasi_proses_ms`, `status`) VALUES
('sesi-001_u-mhs1', 'sesi-001', 'u-mhs1', '2026-09-07 08:01:10.000', '5.178010', '96.680010', '1.57', 'dev-A', 820, 'hadir'),
('sesi-001_u-mhs2', 'sesi-001', 'u-mhs2', '2026-09-07 08:01:25.000', '5.178020', '96.680000', '2.22', 'dev-B', 910, 'hadir'),
('sesi-001_u-mhs3', 'sesi-001', 'u-mhs3', '2026-09-07 08:02:05.000', '5.178000', '96.680030', '3.33', 'dev-C', 1100, 'hadir'),
('sesi-001_u-mhs4', 'sesi-001', 'u-mhs4', '2026-09-07 08:02:40.000', '5.177990', '96.680010', '1.57', 'dev-D', 760, 'hadir'),
('sesi-002_u-mhs1', 'sesi-002', 'u-mhs1', '2026-09-14 08:01:02.000', '5.178010', '96.680000', '1.11', 'dev-A', 880, 'hadir'),
('sesi-002_u-mhs2', 'sesi-002', 'u-mhs2', '2026-09-14 08:01:30.000', '5.178000', '96.680020', '2.22', 'dev-B', 1350, 'hadir'),
('sesi-002_u-mhs3', 'sesi-002', 'u-mhs3', '2026-09-14 08:02:11.000', '5.178010', '96.680010', '1.57', 'dev-C', 990, 'hadir'),
('sesi-002_u-mhs5', 'sesi-002', 'u-mhs5', '2026-09-14 08:03:00.000', '5.178020', '96.680020', '3.14', 'dev-E', 2400, 'hadir'),
('sesi-003_u-mhs1', 'sesi-003', 'u-mhs1', '2026-09-21 08:01:00.000', '5.178000', '96.680010', '1.11', 'dev-A', 800, 'hadir'),
('sesi-003_u-mhs2', 'sesi-003', 'u-mhs2', '2026-09-21 08:01:45.000', '5.178010', '96.680010', '1.57', 'dev-B', 940, 'hadir'),
('sesi-003_u-mhs4', 'sesi-003', 'u-mhs4', '2026-09-21 08:02:20.000', '5.178000', '96.680000', '0.00', 'dev-D', 870, 'hadir'),
('sesi-003_u-mhs5', 'sesi-003', 'u-mhs5', '2026-09-21 08:02:50.000', '5.178010', '96.680020', '2.48', 'dev-E', 3100, 'hadir');

--
-- Triggers `kehadiran`
--
DELIMITER $$
CREATE TRIGGER `trg_log_status` AFTER UPDATE ON `kehadiran` FOR EACH ROW BEGIN
  IF OLD.status <> NEW.status THEN
    INSERT INTO log_perubahan (id_kehadiran, uid_pengubah, status_lama, status_baru, alasan)
    VALUES (NEW.id_kehadiran, COALESCE(@uid_pengubah, 'sistem'),
            OLD.status, NEW.status, COALESCE(@alasan, 'tanpa alasan'));
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `kelas`
--

CREATE TABLE `kelas` (
  `id_kelas` int(11) NOT NULL,
  `id_mk` int(11) NOT NULL,
  `uid_dosen` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `semester` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'mis. 2026/2027 Ganjil',
  `ruang` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lat_ruang` decimal(9,6) NOT NULL,
  `lng_ruang` decimal(9,6) NOT NULL,
  `radius_m` smallint(6) NOT NULL DEFAULT '30' COMMENT 'Radius validasi lokasi (meter)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kelas`
--

INSERT INTO `kelas` (`id_kelas`, `id_mk`, `uid_dosen`, `semester`, `ruang`, `lat_ruang`, `lng_ruang`, `radius_m`) VALUES
(1, 1, 'u-dosen1', '2026/2027 Ganjil', 'Lab Komputer 1', '5.178000', '96.680000', 30);

-- --------------------------------------------------------

--
-- Table structure for table `kuesioner_likert`
--

CREATE TABLE `kuesioner_likert` (
  `id_jawaban` bigint(20) NOT NULL,
  `id_responden` int(11) NOT NULL,
  `peran` enum('dosen','mahasiswa') COLLATE utf8mb4_unicode_ci NOT NULL,
  `variabel` enum('efisiensi','keaslian','kemudahan') COLLATE utf8mb4_unicode_ci NOT NULL,
  `butir` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'mis. E1, K2, U3',
  `skor` tinyint(4) NOT NULL COMMENT 'Skala 1-5'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kuesioner_likert`
--

INSERT INTO `kuesioner_likert` (`id_jawaban`, `id_responden`, `peran`, `variabel`, `butir`, `skor`) VALUES
(1, 1, 'mahasiswa', 'efisiensi', 'E1', 5),
(2, 1, 'mahasiswa', 'efisiensi', 'E2', 4),
(3, 1, 'mahasiswa', 'keaslian', 'K1', 4),
(4, 1, 'mahasiswa', 'keaslian', 'K2', 5),
(5, 1, 'mahasiswa', 'kemudahan', 'U1', 5),
(6, 1, 'mahasiswa', 'kemudahan', 'U2', 4),
(7, 2, 'mahasiswa', 'efisiensi', 'E1', 4),
(8, 2, 'mahasiswa', 'efisiensi', 'E2', 4),
(9, 2, 'mahasiswa', 'keaslian', 'K1', 5),
(10, 2, 'mahasiswa', 'keaslian', 'K2', 4),
(11, 2, 'mahasiswa', 'kemudahan', 'U1', 4),
(12, 2, 'mahasiswa', 'kemudahan', 'U2', 3),
(13, 3, 'dosen', 'efisiensi', 'E1', 5),
(14, 3, 'dosen', 'efisiensi', 'E2', 5),
(15, 3, 'dosen', 'keaslian', 'K1', 4),
(16, 3, 'dosen', 'keaslian', 'K2', 4),
(17, 3, 'dosen', 'kemudahan', 'U1', 4),
(18, 3, 'dosen', 'kemudahan', 'U2', 5);

-- --------------------------------------------------------

--
-- Table structure for table `kuesioner_sus`
--

CREATE TABLE `kuesioner_sus` (
  `id_responden` int(11) NOT NULL,
  `peran` enum('dosen','mahasiswa') COLLATE utf8mb4_unicode_ci NOT NULL,
  `q1` tinyint(4) NOT NULL,
  `q2` tinyint(4) NOT NULL,
  `q3` tinyint(4) NOT NULL,
  `q4` tinyint(4) NOT NULL,
  `q5` tinyint(4) NOT NULL,
  `q6` tinyint(4) NOT NULL,
  `q7` tinyint(4) NOT NULL,
  `q8` tinyint(4) NOT NULL,
  `q9` tinyint(4) NOT NULL,
  `q10` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kuesioner_sus`
--

INSERT INTO `kuesioner_sus` (`id_responden`, `peran`, `q1`, `q2`, `q3`, `q4`, `q5`, `q6`, `q7`, `q8`, `q9`, `q10`) VALUES
(1, 'mahasiswa', 4, 2, 5, 1, 4, 2, 5, 2, 4, 2),
(2, 'mahasiswa', 5, 1, 4, 2, 5, 1, 4, 1, 5, 2),
(3, 'mahasiswa', 4, 2, 4, 2, 4, 2, 4, 2, 4, 3),
(4, 'dosen', 4, 1, 5, 1, 4, 2, 4, 1, 4, 2),
(5, 'dosen', 5, 2, 4, 2, 4, 1, 5, 2, 5, 1);

-- --------------------------------------------------------

--
-- Table structure for table `log_perubahan`
--

CREATE TABLE `log_perubahan` (
  `id_log` bigint(20) NOT NULL,
  `id_kehadiran` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uid_pengubah` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status_lama` enum('hadir','izin','sakit','alfa') COLLATE utf8mb4_unicode_ci NOT NULL,
  `status_baru` enum('hadir','izin','sakit','alfa') COLLATE utf8mb4_unicode_ci NOT NULL,
  `alasan` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `waktu` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `log_perubahan`
--

INSERT INTO `log_perubahan` (`id_log`, `id_kehadiran`, `uid_pengubah`, `status_lama`, `status_baru`, `alasan`, `waktu`) VALUES
(1, 'sesi-003_u-mhs5', 'u-dosen1', 'hadir', 'sakit', 'Mahasiswa sakit, ada surat keterangan', '2026-11-17 16:03:26.345'),
(2, 'sesi-003_u-mhs5', 'u-dosen1', 'sakit', 'hadir', 'Mahasiswa sakit, ada surat keterangan', '2026-11-17 16:03:26.347');

-- --------------------------------------------------------

--
-- Table structure for table `mata_kuliah`
--

CREATE TABLE `mata_kuliah` (
  `id_mk` int(11) NOT NULL,
  `kode_mk` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama_mk` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sks` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `mata_kuliah`
--

INSERT INTO `mata_kuliah` (`id_mk`, `kode_mk`, `nama_mk`, `sks`) VALUES
(1, 'IF301', 'Pemrograman Mobile', 3);

-- --------------------------------------------------------

--
-- Table structure for table `pengguna`
--

CREATE TABLE `pengguna` (
  `uid` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nomor_induk` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'NPM (mahasiswa) atau NIP/NIDN (dosen/admin)',
  `nama` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `peran` enum('admin','dosen','mahasiswa') COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_perangkat` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Pengikatan akun ke satu perangkat (KF-03)',
  `dibuat_pada` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pengguna`
--

INSERT INTO `pengguna` (`uid`, `nomor_induk`, `nama`, `email`, `password_hash`, `peran`, `id_perangkat`, `dibuat_pada`) VALUES
('u-admin1', '198001012010011001', 'Admin Prodi', 'admin@contoh.ac.id', 'GANTI_DENGAN_HASH', 'admin', NULL, '2026-11-17 09:03:26'),
('u-dosen1', '1305079901', 'Dosen Contoh', 'dosen@contoh.ac.id', 'GANTI_DENGAN_HASH', 'dosen', NULL, '2026-11-17 09:03:26'),
('u-mhs1', '235520110065', 'Mahasiswa Satu', 'mhs1@contoh.ac.id', 'GANTI_DENGAN_HASH', 'mahasiswa', 'dev-A', '2026-11-17 09:03:26'),
('u-mhs2', '235520110066', 'Mahasiswa Dua', 'mhs2@contoh.ac.id', 'GANTI_DENGAN_HASH', 'mahasiswa', 'dev-B', '2026-11-17 09:03:26'),
('u-mhs3', '235520110067', 'Mahasiswa Tiga', 'mhs3@contoh.ac.id', 'GANTI_DENGAN_HASH', 'mahasiswa', 'dev-C', '2026-11-17 09:03:26'),
('u-mhs4', '235520110068', 'Mahasiswa Empat', 'mhs4@contoh.ac.id', 'GANTI_DENGAN_HASH', 'mahasiswa', 'dev-D', '2026-11-17 09:03:26'),
('u-mhs5', '235520110069', 'Mahasiswa Lima', 'mhs5@contoh.ac.id', 'GANTI_DENGAN_HASH', 'mahasiswa', 'dev-E', '2026-11-17 09:03:26');

-- --------------------------------------------------------

--
-- Table structure for table `pengukuran_waktu`
--

CREATE TABLE `pengukuran_waktu` (
  `id_ukur` int(11) NOT NULL,
  `id_kelas` int(11) NOT NULL,
  `pertemuan_ke` tinyint(4) NOT NULL,
  `jumlah_mahasiswa` smallint(6) NOT NULL,
  `t_manual_detik` decimal(8,2) NOT NULL COMMENT 'Lembar diedarkan s.d. kembali ke dosen',
  `t_qr_detik` decimal(8,2) NOT NULL COMMENT 'QR tampil s.d. mahasiswa terakhir tercatat',
  `rekap_manual_detik` decimal(8,2) DEFAULT NULL,
  `rekap_qr_detik` decimal(8,2) DEFAULT NULL,
  `catatan` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pengukuran_waktu`
--

INSERT INTO `pengukuran_waktu` (`id_ukur`, `id_kelas`, `pertemuan_ke`, `jumlah_mahasiswa`, `t_manual_detik`, `t_qr_detik`, `rekap_manual_detik`, `rekap_qr_detik`, `catatan`) VALUES
(1, 1, 1, 30, '420.00', '130.00', '600.00', '5.00', 'dummy'),
(2, 1, 2, 30, '390.00', '118.00', '580.00', '4.00', 'dummy'),
(3, 1, 3, 28, '360.00', '125.00', '540.00', '4.00', 'dummy'),
(4, 1, 4, 30, '445.00', '140.00', '610.00', '6.00', 'dummy'),
(5, 1, 5, 29, '405.00', '122.00', '570.00', '5.00', 'dummy');

-- --------------------------------------------------------

--
-- Table structure for table `peserta_kelas`
--

CREATE TABLE `peserta_kelas` (
  `id_kelas` int(11) NOT NULL,
  `uid_mahasiswa` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `peserta_kelas`
--

INSERT INTO `peserta_kelas` (`id_kelas`, `uid_mahasiswa`) VALUES
(1, 'u-mhs1'),
(1, 'u-mhs2'),
(1, 'u-mhs3'),
(1, 'u-mhs4'),
(1, 'u-mhs5');

-- --------------------------------------------------------

--
-- Table structure for table `sesi`
--

CREATE TABLE `sesi` (
  `id_sesi` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_kelas` int(11) NOT NULL,
  `pertemuan_ke` tinyint(4) NOT NULL,
  `waktu_buka` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `waktu_tutup` datetime(3) DEFAULT NULL,
  `batas_waktu_menit` smallint(6) NOT NULL DEFAULT '15' COMMENT 'Sesi tertutup otomatis (KF-06)',
  `status` enum('buka','tutup') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'buka',
  `token_aktif` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_sebelumnya` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Toleransi saat pergantian token',
  `interval_detik` smallint(6) NOT NULL DEFAULT '30',
  `token_diperbarui` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sesi`
--

INSERT INTO `sesi` (`id_sesi`, `id_kelas`, `pertemuan_ke`, `waktu_buka`, `waktu_tutup`, `batas_waktu_menit`, `status`, `token_aktif`, `token_sebelumnya`, `interval_detik`, `token_diperbarui`) VALUES
('sesi-001', 1, 1, '2026-09-07 08:00:00.000', '2026-09-07 08:15:00.000', 15, 'tutup', 'tok001', NULL, 30, '2026-11-17 16:03:26.336'),
('sesi-002', 1, 2, '2026-09-14 08:00:00.000', '2026-09-14 08:15:00.000', 15, 'tutup', 'tok002', NULL, 30, '2026-11-17 16:03:26.336'),
('sesi-003', 1, 3, '2026-09-21 08:00:00.000', '2026-09-21 08:15:00.000', 15, 'tutup', 'tok003', NULL, 30, '2026-11-17 16:03:26.336');

-- --------------------------------------------------------

--
-- Table structure for table `uji_keaslian`
--

CREATE TABLE `uji_keaslian` (
  `id_uji` int(11) NOT NULL,
  `kode_skenario` enum('S1','S2','S3','S4','S5','S6','S7') COLLATE utf8mb4_unicode_ci NOT NULL,
  `percobaan_ke` smallint(6) NOT NULL,
  `ditolak` tinyint(1) NOT NULL COMMENT '1 = ditolak sistem (hasil yang diharapkan)',
  `keterangan` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `waktu_uji` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `uji_keaslian`
--

INSERT INTO `uji_keaslian` (`id_uji`, `kode_skenario`, `percobaan_ke`, `ditolak`, `keterangan`, `waktu_uji`) VALUES
(1, 'S1', 1, 1, 'dummy', '2026-11-17 16:03:26'),
(2, 'S1', 2, 1, 'dummy', '2026-11-17 16:03:26'),
(3, 'S1', 3, 1, 'dummy', '2026-11-17 16:03:26'),
(4, 'S1', 4, 1, 'dummy', '2026-11-17 16:03:26'),
(5, 'S1', 5, 1, 'dummy', '2026-11-17 16:03:26'),
(6, 'S2', 1, 1, 'dummy', '2026-11-17 16:03:26'),
(7, 'S2', 2, 1, 'dummy', '2026-11-17 16:03:26'),
(8, 'S2', 3, 1, 'dummy', '2026-11-17 16:03:26'),
(9, 'S2', 4, 1, 'dummy', '2026-11-17 16:03:26'),
(10, 'S2', 5, 1, 'dummy', '2026-11-17 16:03:26'),
(11, 'S3', 1, 1, 'dummy', '2026-11-17 16:03:26'),
(12, 'S3', 2, 1, 'dummy', '2026-11-17 16:03:26'),
(13, 'S3', 3, 1, 'dummy', '2026-11-17 16:03:26'),
(14, 'S3', 4, 1, 'dummy', '2026-11-17 16:03:26'),
(15, 'S3', 5, 1, 'dummy', '2026-11-17 16:03:26'),
(16, 'S4', 1, 1, 'dummy', '2026-11-17 16:03:26'),
(17, 'S4', 2, 1, 'dummy', '2026-11-17 16:03:26'),
(18, 'S4', 3, 1, 'dummy', '2026-11-17 16:03:26'),
(19, 'S4', 4, 1, 'dummy', '2026-11-17 16:03:26'),
(20, 'S4', 5, 1, 'dummy', '2026-11-17 16:03:26'),
(21, 'S5', 1, 1, 'dummy', '2026-11-17 16:03:26'),
(22, 'S5', 2, 1, 'dummy', '2026-11-17 16:03:26'),
(23, 'S5', 3, 1, 'dummy', '2026-11-17 16:03:26'),
(24, 'S5', 4, 1, 'dummy', '2026-11-17 16:03:26'),
(25, 'S5', 5, 1, 'dummy', '2026-11-17 16:03:26'),
(26, 'S6', 1, 1, 'dummy', '2026-11-17 16:03:26'),
(27, 'S6', 2, 1, 'dummy', '2026-11-17 16:03:26'),
(28, 'S6', 3, 1, 'dummy', '2026-11-17 16:03:26'),
(29, 'S6', 4, 1, 'dummy', '2026-11-17 16:03:26'),
(30, 'S6', 5, 1, 'dummy', '2026-11-17 16:03:26'),
(31, 'S7', 1, 0, 'dummy: lolos', '2026-11-17 16:03:26'),
(32, 'S7', 2, 0, 'dummy: lolos', '2026-11-17 16:03:26'),
(33, 'S7', 3, 0, 'dummy: lolos', '2026-11-17 16:03:26'),
(34, 'S7', 4, 1, 'dummy', '2026-11-17 16:03:26'),
(35, 'S7', 5, 0, 'dummy: lolos', '2026-11-17 16:03:26');

-- --------------------------------------------------------

--
-- Table structure for table `uji_pemindaian`
--

CREATE TABLE `uji_pemindaian` (
  `id_uji` int(11) NOT NULL,
  `kondisi` enum('pencahayaan','jarak','jaringan') COLLATE utf8mb4_unicode_ci NOT NULL,
  `nilai_kondisi` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'mis. redup, 50 cm, 3G',
  `berhasil` tinyint(1) NOT NULL,
  `waktu_respons_ms` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `uji_pemindaian`
--

INSERT INTO `uji_pemindaian` (`id_uji`, `kondisi`, `nilai_kondisi`, `berhasil`, `waktu_respons_ms`) VALUES
(1, 'pencahayaan', 'terang', 1, 800),
(2, 'pencahayaan', 'terang', 1, 780),
(3, 'pencahayaan', 'terang', 1, 820),
(4, 'pencahayaan', 'redup', 1, 1300),
(5, 'pencahayaan', 'redup', 0, NULL),
(6, 'pencahayaan', 'redup', 1, 1450),
(7, 'jarak', '30 cm', 1, 760),
(8, 'jarak', '30 cm', 1, 790),
(9, 'jarak', '100 cm', 1, 1100),
(10, 'jarak', '100 cm', 0, NULL),
(11, 'jaringan', 'WiFi', 1, 700),
(12, 'jaringan', 'WiFi', 1, 730),
(13, 'jaringan', '4G', 1, 950),
(14, 'jaringan', '3G', 1, 2200),
(15, 'jaringan', '3G', 0, NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_efisiensi_waktu`
-- (See below for the actual view)
--
CREATE TABLE `v_efisiensi_waktu` (
`id_ukur` int(11)
,`id_kelas` int(11)
,`pertemuan_ke` tinyint(4)
,`jumlah_mahasiswa` smallint(6)
,`t_manual_detik` decimal(8,2)
,`t_qr_detik` decimal(8,2)
,`efisiensi_persen` decimal(15,2)
,`detik_per_mhs_manual` decimal(9,2)
,`detik_per_mhs_qr` decimal(9,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_keberhasilan_pemindaian`
-- (See below for the actual view)
--
CREATE TABLE `v_keberhasilan_pemindaian` (
`kondisi` enum('pencahayaan','jarak','jaringan')
,`nilai_kondisi` varchar(50)
,`percobaan` bigint(21)
,`berhasil_persen` decimal(31,2)
,`rata2_respons_ms` decimal(11,0)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_kinerja_sistem`
-- (See below for the actual view)
--
CREATE TABLE `v_kinerja_sistem` (
`rata2_durasi_ms` decimal(11,0)
,`min_ms` int(11)
,`max_ms` int(11)
,`memenuhi_target_3_detik` decimal(23,0)
,`total_absensi` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_persen_likert`
-- (See below for the actual view)
--
CREATE TABLE `v_persen_likert` (
`variabel` enum('efisiensi','keaslian','kemudahan')
,`jumlah_jawaban` bigint(21)
,`persen` decimal(31,2)
,`kategori` varchar(18)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_rekap_mahasiswa`
-- (See below for the actual view)
--
CREATE TABLE `v_rekap_mahasiswa` (
`id_kelas` int(11)
,`nama_mk` varchar(100)
,`nomor_induk` varchar(20)
,`nama` varchar(100)
,`jml_hadir` bigint(21)
,`jml_izin` bigint(21)
,`jml_sakit` bigint(21)
,`total_pertemuan` bigint(21)
,`persen_hadir` decimal(26,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_rekap_pertemuan`
-- (See below for the actual view)
--
CREATE TABLE `v_rekap_pertemuan` (
`id_kelas` int(11)
,`pertemuan_ke` tinyint(4)
,`waktu_buka` datetime(3)
,`jumlah_hadir` bigint(21)
,`jumlah_peserta` bigint(21)
,`persen_hadir` decimal(26,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_ringkasan_uji_t`
-- (See below for the actual view)
--
CREATE TABLE `v_ringkasan_uji_t` (
`n` bigint(21)
,`rata2_manual` decimal(9,2)
,`rata2_qr` decimal(9,2)
,`rata2_selisih` decimal(10,2)
,`sd_selisih` double(21,4)
,`t_hitung` double(21,4)
,`derajat_bebas` bigint(22)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_skor_sus`
-- (See below for the actual view)
--
CREATE TABLE `v_skor_sus` (
`id_responden` int(11)
,`peran` enum('dosen','mahasiswa')
,`skor_sus` decimal(15,1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_tingkat_penolakan`
-- (See below for the actual view)
--
CREATE TABLE `v_tingkat_penolakan` (
`kode_skenario` enum('S1','S2','S3','S4','S5','S6','S7')
,`total_percobaan` bigint(21)
,`jumlah_ditolak` decimal(25,0)
,`tingkat_penolakan_persen` decimal(31,2)
);

-- --------------------------------------------------------

--
-- Structure for view `v_efisiensi_waktu`
--
DROP TABLE IF EXISTS `v_efisiensi_waktu`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_efisiensi_waktu`  AS  select `pengukuran_waktu`.`id_ukur` AS `id_ukur`,`pengukuran_waktu`.`id_kelas` AS `id_kelas`,`pengukuran_waktu`.`pertemuan_ke` AS `pertemuan_ke`,`pengukuran_waktu`.`jumlah_mahasiswa` AS `jumlah_mahasiswa`,`pengukuran_waktu`.`t_manual_detik` AS `t_manual_detik`,`pengukuran_waktu`.`t_qr_detik` AS `t_qr_detik`,round((((`pengukuran_waktu`.`t_manual_detik` - `pengukuran_waktu`.`t_qr_detik`) / `pengukuran_waktu`.`t_manual_detik`) * 100),2) AS `efisiensi_persen`,round((`pengukuran_waktu`.`t_manual_detik` / `pengukuran_waktu`.`jumlah_mahasiswa`),2) AS `detik_per_mhs_manual`,round((`pengukuran_waktu`.`t_qr_detik` / `pengukuran_waktu`.`jumlah_mahasiswa`),2) AS `detik_per_mhs_qr` from `pengukuran_waktu` ;

-- --------------------------------------------------------

--
-- Structure for view `v_keberhasilan_pemindaian`
--
DROP TABLE IF EXISTS `v_keberhasilan_pemindaian`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_keberhasilan_pemindaian`  AS  select `uji_pemindaian`.`kondisi` AS `kondisi`,`uji_pemindaian`.`nilai_kondisi` AS `nilai_kondisi`,count(0) AS `percobaan`,round(((100 * sum(`uji_pemindaian`.`berhasil`)) / count(0)),2) AS `berhasil_persen`,round(avg(`uji_pemindaian`.`waktu_respons_ms`),0) AS `rata2_respons_ms` from `uji_pemindaian` group by `uji_pemindaian`.`kondisi`,`uji_pemindaian`.`nilai_kondisi` ;

-- --------------------------------------------------------

--
-- Structure for view `v_kinerja_sistem`
--
DROP TABLE IF EXISTS `v_kinerja_sistem`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_kinerja_sistem`  AS  select round(avg(`kehadiran`.`durasi_proses_ms`),0) AS `rata2_durasi_ms`,min(`kehadiran`.`durasi_proses_ms`) AS `min_ms`,max(`kehadiran`.`durasi_proses_ms`) AS `max_ms`,sum((`kehadiran`.`durasi_proses_ms` <= 3000)) AS `memenuhi_target_3_detik`,count(0) AS `total_absensi` from `kehadiran` where (`kehadiran`.`durasi_proses_ms` is not null) ;

-- --------------------------------------------------------

--
-- Structure for view `v_persen_likert`
--
DROP TABLE IF EXISTS `v_persen_likert`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_persen_likert`  AS  select `kuesioner_likert`.`variabel` AS `variabel`,count(0) AS `jumlah_jawaban`,round(((100 * sum(`kuesioner_likert`.`skor`)) / (count(0) * 5)),2) AS `persen`,(case when (((100 * sum(`kuesioner_likert`.`skor`)) / (count(0) * 5)) <= 20) then 'Sangat Tidak Layak' when (((100 * sum(`kuesioner_likert`.`skor`)) / (count(0) * 5)) <= 40) then 'Tidak Layak' when (((100 * sum(`kuesioner_likert`.`skor`)) / (count(0) * 5)) <= 60) then 'Cukup Layak' when (((100 * sum(`kuesioner_likert`.`skor`)) / (count(0) * 5)) <= 80) then 'Layak' else 'Sangat Layak' end) AS `kategori` from `kuesioner_likert` group by `kuesioner_likert`.`variabel` ;

-- --------------------------------------------------------

--
-- Structure for view `v_rekap_mahasiswa`
--
DROP TABLE IF EXISTS `v_rekap_mahasiswa`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_rekap_mahasiswa`  AS  select `k`.`id_kelas` AS `id_kelas`,`mk`.`nama_mk` AS `nama_mk`,`p`.`nomor_induk` AS `nomor_induk`,`p`.`nama` AS `nama`,count((case when (`h`.`status` = 'hadir') then 1 end)) AS `jml_hadir`,count((case when (`h`.`status` = 'izin') then 1 end)) AS `jml_izin`,count((case when (`h`.`status` = 'sakit') then 1 end)) AS `jml_sakit`,count(distinct `s`.`id_sesi`) AS `total_pertemuan`,round(((100 * count((case when (`h`.`status` = 'hadir') then 1 end))) / nullif(count(distinct `s`.`id_sesi`),0)),2) AS `persen_hadir` from (((((`kelas` `k` join `mata_kuliah` `mk` on((`mk`.`id_mk` = `k`.`id_mk`))) join `peserta_kelas` `pk` on((`pk`.`id_kelas` = `k`.`id_kelas`))) join `pengguna` `p` on((`p`.`uid` = `pk`.`uid_mahasiswa`))) left join `sesi` `s` on((`s`.`id_kelas` = `k`.`id_kelas`))) left join `kehadiran` `h` on(((`h`.`id_sesi` = `s`.`id_sesi`) and (`h`.`uid_mahasiswa` = `p`.`uid`)))) group by `k`.`id_kelas`,`mk`.`nama_mk`,`p`.`nomor_induk`,`p`.`nama` ;

-- --------------------------------------------------------

--
-- Structure for view `v_rekap_pertemuan`
--
DROP TABLE IF EXISTS `v_rekap_pertemuan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_rekap_pertemuan`  AS  select `s`.`id_kelas` AS `id_kelas`,`s`.`pertemuan_ke` AS `pertemuan_ke`,`s`.`waktu_buka` AS `waktu_buka`,count(`h`.`id_kehadiran`) AS `jumlah_hadir`,(select count(0) from `peserta_kelas` `pk` where (`pk`.`id_kelas` = `s`.`id_kelas`)) AS `jumlah_peserta`,round(((100 * count(`h`.`id_kehadiran`)) / nullif((select count(0) from `peserta_kelas` `pk` where (`pk`.`id_kelas` = `s`.`id_kelas`)),0)),2) AS `persen_hadir` from (`sesi` `s` left join `kehadiran` `h` on(((`h`.`id_sesi` = `s`.`id_sesi`) and (`h`.`status` = 'hadir')))) group by `s`.`id_kelas`,`s`.`pertemuan_ke`,`s`.`waktu_buka` ;

-- --------------------------------------------------------

--
-- Structure for view `v_ringkasan_uji_t`
--
DROP TABLE IF EXISTS `v_ringkasan_uji_t`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_ringkasan_uji_t`  AS  select count(0) AS `n`,round(avg(`pengukuran_waktu`.`t_manual_detik`),2) AS `rata2_manual`,round(avg(`pengukuran_waktu`.`t_qr_detik`),2) AS `rata2_qr`,round(avg((`pengukuran_waktu`.`t_manual_detik` - `pengukuran_waktu`.`t_qr_detik`)),2) AS `rata2_selisih`,round(std((`pengukuran_waktu`.`t_manual_detik` - `pengukuran_waktu`.`t_qr_detik`)),4) AS `sd_selisih`,round((avg((`pengukuran_waktu`.`t_manual_detik` - `pengukuran_waktu`.`t_qr_detik`)) / (std((`pengukuran_waktu`.`t_manual_detik` - `pengukuran_waktu`.`t_qr_detik`)) / sqrt(count(0)))),4) AS `t_hitung`,(count(0) - 1) AS `derajat_bebas` from `pengukuran_waktu` ;

-- --------------------------------------------------------

--
-- Structure for view `v_skor_sus`
--
DROP TABLE IF EXISTS `v_skor_sus`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_skor_sus`  AS  select `kuesioner_sus`.`id_responden` AS `id_responden`,`kuesioner_sus`.`peran` AS `peran`,(((((((((((`kuesioner_sus`.`q1` - 1) + (5 - `kuesioner_sus`.`q2`)) + (`kuesioner_sus`.`q3` - 1)) + (5 - `kuesioner_sus`.`q4`)) + (`kuesioner_sus`.`q5` - 1)) + (5 - `kuesioner_sus`.`q6`)) + (`kuesioner_sus`.`q7` - 1)) + (5 - `kuesioner_sus`.`q8`)) + (`kuesioner_sus`.`q9` - 1)) + (5 - `kuesioner_sus`.`q10`)) * 2.5) AS `skor_sus` from `kuesioner_sus` ;

-- --------------------------------------------------------

--
-- Structure for view `v_tingkat_penolakan`
--
DROP TABLE IF EXISTS `v_tingkat_penolakan`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_tingkat_penolakan`  AS  select `uji_keaslian`.`kode_skenario` AS `kode_skenario`,count(0) AS `total_percobaan`,sum(`uji_keaslian`.`ditolak`) AS `jumlah_ditolak`,round(((100 * sum(`uji_keaslian`.`ditolak`)) / count(0)),2) AS `tingkat_penolakan_persen` from `uji_keaslian` group by `uji_keaslian`.`kode_skenario` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `kehadiran`
--
ALTER TABLE `kehadiran`
  ADD PRIMARY KEY (`id_kehadiran`),
  ADD UNIQUE KEY `uq_sesi_mhs` (`id_sesi`,`uid_mahasiswa`),
  ADD KEY `idx_hadir_mhs` (`uid_mahasiswa`),
  ADD KEY `idx_hadir_waktu` (`waktu_server`);

--
-- Indexes for table `kelas`
--
ALTER TABLE `kelas`
  ADD PRIMARY KEY (`id_kelas`),
  ADD UNIQUE KEY `uq_kelas` (`id_mk`,`uid_dosen`,`semester`,`ruang`),
  ADD KEY `idx_kelas_dosen` (`uid_dosen`);

--
-- Indexes for table `kuesioner_likert`
--
ALTER TABLE `kuesioner_likert`
  ADD PRIMARY KEY (`id_jawaban`),
  ADD UNIQUE KEY `uq_jawaban` (`id_responden`,`butir`);

--
-- Indexes for table `kuesioner_sus`
--
ALTER TABLE `kuesioner_sus`
  ADD PRIMARY KEY (`id_responden`);

--
-- Indexes for table `log_perubahan`
--
ALTER TABLE `log_perubahan`
  ADD PRIMARY KEY (`id_log`),
  ADD KEY `fk_log_hadir` (`id_kehadiran`);

--
-- Indexes for table `mata_kuliah`
--
ALTER TABLE `mata_kuliah`
  ADD PRIMARY KEY (`id_mk`),
  ADD UNIQUE KEY `uq_kode_mk` (`kode_mk`);

--
-- Indexes for table `pengguna`
--
ALTER TABLE `pengguna`
  ADD PRIMARY KEY (`uid`),
  ADD UNIQUE KEY `uq_nomor_induk` (`nomor_induk`),
  ADD UNIQUE KEY `uq_email` (`email`),
  ADD UNIQUE KEY `uq_id_perangkat` (`id_perangkat`);

--
-- Indexes for table `pengukuran_waktu`
--
ALTER TABLE `pengukuran_waktu`
  ADD PRIMARY KEY (`id_ukur`),
  ADD KEY `fk_ukur_kelas` (`id_kelas`);

--
-- Indexes for table `peserta_kelas`
--
ALTER TABLE `peserta_kelas`
  ADD PRIMARY KEY (`id_kelas`,`uid_mahasiswa`),
  ADD KEY `fk_peserta_mhs` (`uid_mahasiswa`);

--
-- Indexes for table `sesi`
--
ALTER TABLE `sesi`
  ADD PRIMARY KEY (`id_sesi`),
  ADD UNIQUE KEY `uq_sesi_pertemuan` (`id_kelas`,`pertemuan_ke`),
  ADD KEY `idx_sesi_status` (`status`);

--
-- Indexes for table `uji_keaslian`
--
ALTER TABLE `uji_keaslian`
  ADD PRIMARY KEY (`id_uji`),
  ADD UNIQUE KEY `uq_uji` (`kode_skenario`,`percobaan_ke`);

--
-- Indexes for table `uji_pemindaian`
--
ALTER TABLE `uji_pemindaian`
  ADD PRIMARY KEY (`id_uji`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `kelas`
--
ALTER TABLE `kelas`
  MODIFY `id_kelas` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `kuesioner_likert`
--
ALTER TABLE `kuesioner_likert`
  MODIFY `id_jawaban` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `kuesioner_sus`
--
ALTER TABLE `kuesioner_sus`
  MODIFY `id_responden` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `log_perubahan`
--
ALTER TABLE `log_perubahan`
  MODIFY `id_log` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `mata_kuliah`
--
ALTER TABLE `mata_kuliah`
  MODIFY `id_mk` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `pengukuran_waktu`
--
ALTER TABLE `pengukuran_waktu`
  MODIFY `id_ukur` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `uji_keaslian`
--
ALTER TABLE `uji_keaslian`
  MODIFY `id_uji` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `uji_pemindaian`
--
ALTER TABLE `uji_pemindaian`
  MODIFY `id_uji` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `kehadiran`
--
ALTER TABLE `kehadiran`
  ADD CONSTRAINT `fk_hadir_mhs` FOREIGN KEY (`uid_mahasiswa`) REFERENCES `pengguna` (`uid`),
  ADD CONSTRAINT `fk_hadir_sesi` FOREIGN KEY (`id_sesi`) REFERENCES `sesi` (`id_sesi`) ON DELETE CASCADE;

--
-- Constraints for table `kelas`
--
ALTER TABLE `kelas`
  ADD CONSTRAINT `fk_kelas_dosen` FOREIGN KEY (`uid_dosen`) REFERENCES `pengguna` (`uid`),
  ADD CONSTRAINT `fk_kelas_mk` FOREIGN KEY (`id_mk`) REFERENCES `mata_kuliah` (`id_mk`);

--
-- Constraints for table `log_perubahan`
--
ALTER TABLE `log_perubahan`
  ADD CONSTRAINT `fk_log_hadir` FOREIGN KEY (`id_kehadiran`) REFERENCES `kehadiran` (`id_kehadiran`) ON DELETE CASCADE;

--
-- Constraints for table `pengukuran_waktu`
--
ALTER TABLE `pengukuran_waktu`
  ADD CONSTRAINT `fk_ukur_kelas` FOREIGN KEY (`id_kelas`) REFERENCES `kelas` (`id_kelas`);

--
-- Constraints for table `peserta_kelas`
--
ALTER TABLE `peserta_kelas`
  ADD CONSTRAINT `fk_peserta_kelas` FOREIGN KEY (`id_kelas`) REFERENCES `kelas` (`id_kelas`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_peserta_mhs` FOREIGN KEY (`uid_mahasiswa`) REFERENCES `pengguna` (`uid`) ON DELETE CASCADE;

--
-- Constraints for table `sesi`
--
ALTER TABLE `sesi`
  ADD CONSTRAINT `fk_sesi_kelas` FOREIGN KEY (`id_kelas`) REFERENCES `kelas` (`id_kelas`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
