-- Diminta: satu query yang menghasilkan jumlah film dan rata-rata tarif untuk
-- setiap pasangan kategori-rating, subtotal per kategori, dan grand total
-- dalam satu hasil.
-- Dipilih: GROUP BY ROLLUP(kategori, rating) karena ROLLUP menghasilkan tepat
-- tiga tingkat agregasi yang diminta secara hierarkis: rincian per
-- (kategori, rating), subtotal per kategori, dan grand total -- semuanya dalam
-- satu pass tanpa UNION manual. GROUPING() dipakai untuk membedakan baris
-- subtotal/grand total dari baris data biasa, lalu CASE mengganti nilai NULL
-- bawaan ROLLUP dengan label 'SEMUA'.
-- Alternatif: menyusun tiga query terpisah (per kategori-rating, per kategori,
-- grand total) lalu digabung UNION ALL; tidak dipilih karena ROLLUP lebih
-- ringkas, satu kali scan, dan tidak berisiko rumus agregatnya tidak konsisten
-- antar bagian UNION.

SELECT
    CASE WHEN grouping(c.name) = 1 THEN 'SEMUA' ELSE c.name END        AS kategori,
    CASE WHEN grouping(f.rating) = 1 THEN 'SEMUA' ELSE f.rating::text END AS rating,
    count(*)                                                            AS jumlah_film,
    round(avg(f.rental_rate), 2)                                        AS rata_rata_tarif,
    grouping(c.name)                                                    AS is_subtotal_kategori,
    grouping(f.rating)                                                  AS is_subtotal_rating
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c        ON c.category_id = fc.category_id
GROUP BY ROLLUP (c.name, f.rating)
ORDER BY c.name NULLS LAST, f.rating NULLS LAST;