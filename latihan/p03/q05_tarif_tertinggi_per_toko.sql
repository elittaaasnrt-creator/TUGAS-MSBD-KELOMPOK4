-- Diminta: untuk setiap toko, judul film dengan tarif sewa tertinggi di
-- toko tersebut, diselesaikan tanpa window function.
-- Dipilih: subquery skalar berkorelasi dengan MAX, karena tiap film
-- terhubung ke toko lewat inventory, dan 'tarif tertinggi per toko' paling
-- natural dinyatakan sebagai perbandingan terhadap nilai MAX yang dihitung
-- ulang per store_id baris luar.
-- Alternatif: rental_rate >= ALL (...) dipertimbangkan karena secara
-- logika setara dengan MAX, tapi tidak dipilih sebagai versi utama karena
-- MAX() lebih eksplisit dan lebih mudah dibaca maksudnya.

SELECT DISTINCT i.store_id, f.title, f.rental_rate
FROM film f
JOIN inventory i ON i.film_id = f.film_id
WHERE f.rental_rate = (
    SELECT MAX(f2.rental_rate)
    FROM film f2
    JOIN inventory i2 ON i2.film_id = f2.film_id
    WHERE i2.store_id = i.store_id
)
ORDER BY i.store_id, f.title;

-- Catatan hasil: karena rental_rate hanya punya 3 nilai berbeda di Pagila
-- (0.99, 2.99, 4.99), banyak film yang seri (tie) di nilai tarif tertinggi
-- yang sama per toko, sehingga hasilnya bisa lebih dari satu judul per
-- toko. Ini normal dan sesuai definisi soal (bukan bug).
