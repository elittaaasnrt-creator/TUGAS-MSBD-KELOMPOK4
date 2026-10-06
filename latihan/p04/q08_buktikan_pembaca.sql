-- Diminta: Membuktikan perilaku non-blocking pada REFRESH CONCURRENTLY dibandingkan REFRESH biasa.
-- Dipilih: Menjalankan REFRESH CONCURRENTLY bersamaan dengan SELECT di dua sesi psql terpisah.
-- Alternatif: Memakai LOCK TABLE manual; tidak dipilih karena tidak mensimulasikan mekanisme refresh bawaan PostgreSQL.

-- Sesi 1: Penambahan 200.000 data baru dan eksekusi refresh
INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1, now(), 'web'
FROM generate_series(1, 200000);

-- Pengujian A: REFRESH biasa (memblokir Sesi 2)
-- REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;

-- Pengujian B: REFRESH CONCURRENTLY (tidak memblokir Sesi 2)
-- REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- Sesi 2 (Dijalankan bersamaan di terminal kedua):
-- SELECT count(*) FROM lab4.ringkasan_akses;