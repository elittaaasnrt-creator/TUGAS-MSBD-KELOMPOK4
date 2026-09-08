-- Diminta: untuk setiap film, tampilkan judul, kategori, tarif sewa, dan tiga
-- peringkat tarif di dalam kategorinya sekaligus: ROW_NUMBER, RANK, dan DENSE_RANK.
-- Dipilih: satu klausa WINDOW w AS (PARTITION BY kategori ORDER BY tarif DESC)
-- dipakai ulang oleh ketiga fungsi peringkat, karena partisi dan urutannya sama
-- persis untuk ketiganya. Ini menghindari menulis PARTITION BY/ORDER BY tiga kali.
-- Alternatif: menulis OVER (PARTITION BY ... ORDER BY ...) penuh di masing-masing
-- kolom; tidak dipilih karena lebih panjang dan rawan salah ketik kalau kolom
-- partisi/urut berubah, sedangkan WINDOW w cukup diubah di satu tempat.

SELECT
    f.title                              AS judul,
    c.name                                AS kategori,
    f.rental_rate                         AS tarif,
    row_number() OVER w                   AS row_number_,
    rank()       OVER w                   AS rank_,
    dense_rank() OVER w                   AS dense_rank_
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id
JOIN category c        ON c.category_id = fc.category_id
WINDOW w AS (PARTITION BY c.name ORDER BY f.rental_rate DESC)
ORDER BY kategori, row_number_;