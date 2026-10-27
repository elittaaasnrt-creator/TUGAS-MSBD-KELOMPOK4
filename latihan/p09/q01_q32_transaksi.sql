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