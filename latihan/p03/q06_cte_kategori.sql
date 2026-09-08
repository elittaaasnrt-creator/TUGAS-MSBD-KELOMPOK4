-- Diminta: Kategori dengan > 60 film, jumlah film, dan rata-rata tarif sewa.
-- Dipilih: Dua CTE berurutan agar logika agregasi jumlah dan rata-rata terpisah rapi.
-- Alternatif: Derived table di FROM; tidak dipilih karena membuat query utama terlalu menjorok ke dalam (nested) dan sulit dibaca.

WITH CatCount AS (
    SELECT c.category_id, c.name AS nama_kategori, COUNT(fc.film_id) AS jumlah_film
    FROM category c
    JOIN film_category fc ON c.category_id = fc.category_id
    GROUP BY c.category_id, c.name 
    HAVING COUNT(fc.film_id) > 60
),
CatAvg AS (
    SELECT cc.nama_kategori, cc.jumlah_film, AVG(f.rental_rate) AS rata_rata_tarif
    FROM CatCount cc
    JOIN film_category fc ON cc.category_id = fc.category_id
    JOIN film f ON fc.film_id = f.film_id
    GROUP BY cc.nama_kategori, cc.jumlah_film
)
SELECT * FROM CatAvg ORDER BY jumlah_film DESC;