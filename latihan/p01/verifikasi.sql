-- Verifikasi — Latihan Pertemuan 1 (MSBD)
-- Dijalankan di database "pagila" setelah restore dari pagila.dump

-- V1: Jumlah tabel pada skema public
-- Hasil: 21 tabel (sesuai nilai rujukan modul)
SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';


-- V2: Sepuluh tabel terbesar beserta ukurannya
-- Hasil: rental (2352 kB) adalah tabel terbesar
SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS ukuran
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;


-- V3: Lima film dengan jumlah penyewaan terbanyak
-- Hasil: BUCKET BROTHERHOOD (34x) paling banyak disewa
SELECT f.title, count(*) AS total_sewa
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY total_sewa DESC
LIMIT 5;


-- V4: Melihat rencana eksekusi query (EXPLAIN ANALYZE)
-- Hasil: Execution Time 15.668 ms, pakai HashAggregate + Hash Join
EXPLAIN ANALYZE
SELECT f.title, count(*)
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title;


-- ============================================================
-- TANTANGAN TAMBAHAN: Index dan Optimasi Query
-- ============================================================

-- Buat tabel dengan 2 juta baris data acak
-- Waktu eksekusi: 9160.763 ms
CREATE TABLE besar AS
SELECT g AS id,
       md5(g::text) AS nilai
FROM generate_series(1, 2000000) g;

-- Ambil satu contoh nilai untuk dipakai sebagai kunci pencarian
-- Hasil: c4ca4238a0b923820dcc509a6f75849b (id = 1)
SELECT nilai FROM besar LIMIT 1;

-- Pencarian SEBELUM ada index
-- Waktu eksekusi: 198.061 ms (sequential scan, cek satu-satu dari 2 juta baris)
SELECT * FROM besar WHERE nilai = 'c4ca4238a0b923820dcc509a6f75849b';

-- Buat index pada kolom nilai
-- Waktu eksekusi: 8750.863 ms
CREATE INDEX ON besar(nilai);

-- Pencarian SESUDAH ada index (query yang sama persis seperti sebelumnya)
-- Waktu eksekusi: 3.555 ms (±56x lebih cepat dibanding sebelum index)
SELECT * FROM besar WHERE nilai = 'c4ca4238a0b923820dcc509a6f75849b';
