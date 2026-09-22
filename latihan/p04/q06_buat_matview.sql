-- Diminta: Membuat materialized view lab4.ringkasan_akses WITH NO DATA, menguji SELECT, lalu me-refresh biasa.
-- Dipilih: Opsi WITH NO DATA untuk mengamati status unpopulated dan mengukur waktu REFRESH awal.
-- Alternatif: Dibuat langsung dengan data (default); tidak dipilih karena soal meminta pembuktian kondisi sebelum refresh.

CREATE MATERIALIZED VIEW lab4.ringkasan_akses AS
SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2
WITH NO DATA;

-- 1. Coba baca sebelum di-refresh (Akan menghasilkan galat)
SELECT * FROM lab4.ringkasan_akses;

-- 2. Lakukan refresh biasa dan ukur waktunya
\timing on 
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;