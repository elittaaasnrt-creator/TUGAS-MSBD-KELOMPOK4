-- Diminta: per kategori, tampilkan jumlah film total, jumlah film rating G,
-- jumlah film rating PG-13, dan rata-rata durasi film yang lebih dari 90 menit
-- dalam satu baris.
-- Dipilih: agregat FILTER (WHERE ...) karena bentuknya paling eksplisit --
-- setiap agregat langsung menyatakan syaratnya sendiri (count(*) FILTER (WHERE
-- rating='G'), dst) tanpa mengubah nilai baris menjadi NULL/1/0 terlebih
-- dahulu seperti CASE WHEN. Query jadi lebih mudah dibaca untuk beberapa
-- kondisi berbeda dalam satu SELECT.
-- Alternatif: count(CASE WHEN rating='G' THEN 1 END) dan
-- avg(CASE WHEN length>90 THEN length END); tetap ditulis di bawah sebagai
-- pembanding karena soal meminta dua versi. Perbedaannya: pada AVG, FILTER dan
-- CASE WHEN...THEN length (tanpa ELSE, sehingga ELSE implisit NULL) akan
-- menghasilkan rata-rata yang SAMA karena keduanya mengecualikan baris yang
-- tidak memenuhi syarat dari pembilang maupun pembagi. Rata-rata baru berbeda
-- kalau versi CASE memakai ELSE 0 (menghitung baris tidak memenuhi syarat
-- sebagai 0, sehingga pembaginya ikut membesar dan rata-rata jadi lebih kecil).

-- Versi FILTER
SELECT
    c.name                                              AS kategori,
    count(*)                                             AS total_film,
    count(*) FILTER (WHERE f.rating = 'G')               AS jumlah_rating_g,
    count(*) FILTER (WHERE f.rating = 'PG-13')            AS jumlah_rating_pg13,
    round(avg(f.length) FILTER (WHERE f.length > 90), 2)  AS rata_durasi_lebih_90
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c        ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY c.name;

-- Versi CASE WHEN (pembanding)
SELECT
    c.name                                                          AS kategori,
    count(*)                                                         AS total_film,
    count(CASE WHEN f.rating = 'G' THEN 1 END)                       AS jumlah_rating_g,
    count(CASE WHEN f.rating = 'PG-13' THEN 1 END)                   AS jumlah_rating_pg13,
    round(avg(CASE WHEN f.length > 90 THEN f.length END), 2)         AS rata_durasi_lebih_90
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c        ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY c.name;