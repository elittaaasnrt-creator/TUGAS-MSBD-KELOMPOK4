-- Diminta: Menguji REFRESH MATERIALIZED VIEW CONCURRENTLY sebelum dan sesudah pembuatan unique index.
-- Dipilih: Membuat UNIQUE INDEX pada kombinasi kolom (bulan, kanal) yang menjamin keunikan baris matview.
-- Alternatif: Menggunakan REFRESH biasa tanpa CONCURRENTLY; tidak dipilih karena membutuhkan akses non-blocking bagi pembaca.

-- 1. Coba refresh secara concurrent (Akan galat karena belum ada index unik)
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- 2. Buat UNIQUE INDEX pada kolom kunci agregasi
CREATE UNIQUE INDEX ux_ringkasan_akses ON lab4.ringkasan_akses (bulan, kanal);

-- 3. Ulangi REFRESH CONCURRENTLY dan catat waktunya
\timing on
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;