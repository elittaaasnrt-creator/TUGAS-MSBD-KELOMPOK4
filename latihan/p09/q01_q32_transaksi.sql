-- =====================================================
-- LATIHAN P09 - Transaksi & Konkurensi (Kelompok 4)
-- Reset data: jalankan ulang q00_setup.sql
-- [A] = Sesi A, [B] = Sesi B
-- =====================================================


-- =====================================================
-- Q1-Q5 (Jelita)
-- =====================================================

-- Q1: kondisi awal dan total saldo
SELECT * FROM lab9.rekening ORDER BY rekening_id;
SELECT SUM(saldo) AS total_saldo FROM lab9.rekening;

-- Q2: perubahan sebelum COMMIT
-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1;
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani 900000
-- [B]
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani masih 1000000

-- Q3a: COMMIT
-- [A]
COMMIT;
-- [B]
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani 900000 (bertahan)

-- Q3b: ROLLBACK (data direset dulu lewat q00_setup.sql)
-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1;
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani 900000
ROLLBACK;
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani kembali 1000000

-- Q4: SAVEPOINT
-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1;
SAVEPOINT sp1;
UPDATE lab9.rekening SET saldo = saldo - 200000 WHERE rekening_id = 2;
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani 900000, Budi 800000
ROLLBACK TO SAVEPOINT sp1;
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani 900000, Budi 1000000
COMMIT;
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani 900000, Budi 1000000

-- Q5: atomicity dan consistency (CHECK saldo >= 0)
-- [A]
\set VERBOSITY verbose
BEGIN;
UPDATE lab9.rekening SET saldo = saldo - 100000 WHERE rekening_id = 1;      -- berhasil
UPDATE lab9.rekening SET saldo = saldo - 99999999 WHERE rekening_id = 2;    -- ERROR 23514
SELECT * FROM lab9.rekening ORDER BY rekening_id;                           -- ERROR 25P02
ROLLBACK;
SELECT * FROM lab9.rekening ORDER BY rekening_id;   -- Ani 900000, Budi 1000000
\set VERBOSITY default

-- =====================================================
-- Q6-Q11 (Mael)
-- =====================================================

-- Q6: Non-repeatable Read pada READ COMMITTED
-- [A]
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [B]
BEGIN;
UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1;
COMMIT;
-- [A]
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; -- Nilai berubah (Non-repeatable read terjadi)
COMMIT;

-- Q7: Pencegahan pada REPEATABLE READ
-- [A]
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [B]
BEGIN;
UPDATE lab9.rekening SET saldo = 1500000 WHERE rekening_id = 1;
COMMIT;
-- [A]
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; -- Nilai tetap konsisten
COMMIT;

-- Q8: Phantom Read
-- Skenario READ COMMITTED:
-- [A]
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT COUNT(*) FROM lab9.rekening WHERE saldo >= 1000000;
-- [B]
INSERT INTO lab9.rekening VALUES (3, 'Citra', 2000000);
-- [A]
SELECT COUNT(*) FROM lab9.rekening WHERE saldo >= 1000000; -- Baris bertambah
COMMIT;

-- Skenario REPEATABLE READ:
-- [A]
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM lab9.rekening WHERE saldo >= 1000000;
-- [B]
INSERT INTO lab9.rekening VALUES (4, 'Doni', 2500000);
-- [A]
SELECT COUNT(*) FROM lab9.rekening WHERE saldo >= 1000000; -- Baris tetap konsisten
COMMIT;

-- Q9: Dirty Read (PostgreSQL treat READ UNCOMMITTED as READ COMMITTED)
-- [A]
BEGIN;
UPDATE lab9.rekening SET saldo = 5000000 WHERE rekening_id = 1;
-- [B]
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; -- Data uncommitted tidak terbaca
COMMIT;
-- [A]
ROLLBACK;

-- Q10: Lost Update
UPDATE lab9.rekening SET saldo = 1000000 WHERE rekening_id = 1;
-- [A]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [B]
BEGIN;
SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;
-- [A] Aplikasi menghitung 1000000 + 200000
UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1;
COMMIT;
-- [B] Aplikasi menghitung 1000000 - 100000
UPDATE lab9.rekening SET saldo = 900000 WHERE rekening_id = 1;
COMMIT;
-- Verifikasi (Lost update terjadi: update transaksi A hilang)
SELECT * FROM lab9.rekening WHERE rekening_id = 1;

-- =====================================================
-- Q18-Q23 (Azkha)
-- =====================================================
-- Catatan: Teori matriks konflik (Q18), analisis inspeksi lock (Q22), 
-- dan tabel parameter timeout (Q23) selengkapnya terdapat pada laporan.md.

-- -----------------------------------------------------
-- Q19: Penguncian baris yang sama (Row-level Lock Conflict)
-- -----------------------------------------------------
-- Sesi [A]: Mulai transaksi dan kunci baris rekening 1
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Sesi [B]: Coba kunci baris yang sama (akan terhalang / menggantung)
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Sesi [A]: Lepas kuncian
COMMIT;

-- Sesi [B]: Setelah kuncian terlepas, eksekusi selesai lalu commit
COMMIT;


-- -----------------------------------------------------
-- Q20: Deadlock Saling Menunggu (SQLSTATE 40P01)
-- -----------------------------------------------------
-- Sesi [A]: Kunci rekening 1
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Sesi [B]: Kunci rekening 2
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;

-- Sesi [A]: Coba kunci rekening 2 (menunggu Sesi B)
SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;

-- Sesi [B]: Coba kunci rekening 1 (memicu Deadlock Detection, Sesi B menjadi korban)
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Pembersihan kedua sesi
-- Sesi [A]:
ROLLBACK;
-- Sesi [B]:
ROLLBACK;


-- -----------------------------------------------------
-- Q21: Pencegahan Deadlock dengan Urutan Penguncian Konsisten
-- -----------------------------------------------------
-- Sesi [A]: Kunci rekening 1 lebih dulu
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Sesi [B]: Ikut mengantre pada rekening 1 (menunggu Sesi A selesai secara teratur)
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Sesi [A]: Lanjut kunci rekening 2 lalu commit
SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
COMMIT;

-- Sesi [B]: Lanjut kunci rekening 2 setelah giliran tiba, lalu commit tanpa terjadi deadlock
SELECT * FROM lab9.rekening WHERE rekening_id = 2 FOR UPDATE;
COMMIT;


-- -----------------------------------------------------
-- Q22: Deadlock vs Antrean Lock Panjang (Inspeksi Monitoring)
-- -----------------------------------------------------
-- Sesi [A]: Kunci baris tanpa commit (menahan lock)
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Sesi [B]: Mencoba mengakses baris yang sama (menggantung dalam antrean)
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Sesi [C] / Sesi Monitoring: Cek aktivitas proses pemblokiran dan kuncian yang belum diberikan
SELECT 
    pid, 
    state, 
    wait_event_type, 
    wait_event, 
    pg_blocking_pids(pid) AS diblokir_oleh, 
    left(query, 40) AS query
FROM pg_stat_activity 
WHERE datname = current_database() 
  AND pid <> pg_backend_pid();

SELECT 
    locktype, 
    mode, 
    granted, 
    pid 
FROM pg_locks 
WHERE NOT granted;

-- Pembersihan Sesi [A] dan [B]
-- Sesi [A]:
ROLLBACK;
-- Sesi [B]:
ROLLBACK;


-- -----------------------------------------------------
-- Q23: Pengujian Parameter Timeout
-- -----------------------------------------------------
-- 1. Pengecekan nilai konfigurasi default
SHOW deadlock_timeout;
SHOW lock_timeout;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

-- 2. Uji statement_timeout (dibatalkan setelah 1 detik)
BEGIN;
SET LOCAL statement_timeout = '1s';
SELECT pg_sleep(3);
ROLLBACK;

-- 3. Uji lock_timeout
-- Sesi [A]: Kunci baris rekening 1
BEGIN;
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;

-- Sesi [B]: Pasang batas waktu tunggu lock 2 detik (menghasilkan ERROR saat waktu habis)
BEGIN;
SET LOCAL lock_timeout = '2s';
SELECT * FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
ROLLBACK;

-- Sesi [A]: Bersihkan transaksi
ROLLBACK;

-- 4. Uji idle_in_transaction_session_timeout
-- Transaksi terputus (FATAL) jika dibiarkan idle melebihi 5 detik
BEGIN;
SET LOCAL idle_in_transaction_session_timeout = '5s';
-- (Tunggu lebih dari 5 detik sebelum mengeksekusi query berikutnya)
SELECT 1;


-- =====================================================
-- Q24-Q29, Q31 (Syifa)
-- =====================================================

-- Setup tabel antrean tugas (Q24-Q25)
CREATE TABLE IF NOT EXISTS lab9.antrean_tugas (
    id SERIAL PRIMARY KEY,
    deskripsi TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING'
);
INSERT INTO lab9.antrean_tugas (deskripsi) VALUES ('Tugas 1'), ('Tugas 2');

-- Q24: SKIP LOCKED
-- [A] Kunci ID 1
BEGIN;
SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE;
-- [B] Ambil antrean bebas (lompati yang dikunci A)
BEGIN;
SELECT * FROM lab9.antrean_tugas WHERE status = 'PENDING' FOR UPDATE SKIP LOCKED LIMIT 1;  -- Mengembalikan ID 2
COMMIT;
-- [A] Selesaikan transaksi
COMMIT;


-- Q25: NOWAIT
-- [A] Kunci ID 1
BEGIN;
SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE;
-- [B] Coba kunci ID 1 tanpa menunggu
BEGIN;
SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE NOWAIT;  -- ERROR 55P03 (lock_not_available)
ROLLBACK;
-- [A] Selesaikan transaksi
COMMIT;


-- Setup tabel dokter jaga (Q26-Q27)
CREATE TABLE IF NOT EXISTS lab9.dokter_jaga (
    id SERIAL PRIMARY KEY,
    nama TEXT NOT NULL,
    aktif BOOLEAN NOT NULL DEFAULT TRUE
);
INSERT INTO lab9.dokter_jaga (nama, aktif) VALUES ('Dr. Alice', true), ('Dr. Bob', true);

-- Q26: Write skew pada REPEATABLE READ
-- [A]
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;  -- Hasil: 2
-- [B]
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;  -- Hasil: 2
-- [A] Alice menonaktifkan diri
UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Alice';
COMMIT;
-- [B] Bob menonaktifkan diri
UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Bob';
COMMIT;
-- Verifikasi (terjadi Write Skew: 0 dokter aktif)
SELECT * FROM lab9.dokter_jaga;


-- Q27: Penanganan Write Skew dengan SERIALIZABLE
-- Reset data dokter
UPDATE lab9.dokter_jaga SET aktif = true;
-- [A]
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;  -- Hasil: 2
-- [B]
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;  -- Hasil: 2
-- [A] Alice menonaktifkan diri
UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Alice';
COMMIT;  -- SUKSES
-- [B] Bob menonaktifkan diri
UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Bob';
COMMIT;  -- ERROR 40001 (could not serialize access)
ROLLBACK;
-- Verifikasi (Dr. Alice false, Dr. Bob tetap true)
SELECT * FROM lab9.dokter_jaga;