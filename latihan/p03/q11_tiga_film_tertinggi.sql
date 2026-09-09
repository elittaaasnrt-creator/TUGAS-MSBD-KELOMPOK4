-- Diminta: tampilkan tiga film dengan tarif sewa tertinggi di setiap kategori,
-- lalu bandingkan hasil dan bentuk query dengan Q5 (subquery berkorelasi tanpa
-- window function).
-- Dipilih: window function ROW_NUMBER dihitung lebih dulu di dalam CTE
-- (peringkat), baru disaring rn <= 3 pada SELECT lapisan luar. Ini dipilih
-- karena PostgreSQL tidak mengizinkan hasil window function langsung disaring
-- di WHERE pada lapisan yang sama (window function baru dievaluasi setelah
-- WHERE), sehingga perlu lapisan tambahan.
-- Alternatif: menggunakan LATERAL join dengan LIMIT 3 per kategori (mirip pola
-- Q5); tidak dipilih di sini karena tujuan latihan Q11 memang berlatih window
-- function dan CTE dua-lapis, bukan subquery berkorelasi seperti Q5.

WITH peringkat AS (
    SELECT
        f.title                       AS judul,
        c.name                         AS kategori,
        f.rental_rate                  AS tarif,
        row_number() OVER (
            PARTITION BY c.name
            ORDER BY f.rental_rate DESC, f.title
        ) AS rn
    FROM film f
    JOIN film_category fc ON fc.film_id = f.film_id
    JOIN category c        ON c.category_id = fc.category_id
)
SELECT judul, kategori, tarif, rn AS peringkat
FROM peringkat
WHERE rn <= 3
ORDER BY kategori, rn;