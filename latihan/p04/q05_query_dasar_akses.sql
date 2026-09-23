-- Diminta: Menjalankan query agregasi bulanan per kanal dari lab4.jejak_akses dengan \timing on.
-- Dipilih: Menggunakan \timing on untuk mencatat durasi eksekusi query dasar sebagai baseline.
-- Alternatif: Menggunakan EXPLAIN ANALYZE; tidak dipilih karena soal meminta waktu eksekusi aktual via \timing.

\timing on 

SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2;