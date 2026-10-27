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