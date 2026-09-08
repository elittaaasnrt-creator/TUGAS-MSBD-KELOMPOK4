-- Diminta: judul film yang tidak pernah disewa, ditulis dalam dua versi
-- (NOT IN dan NOT EXISTS) untuk dibandingkan.
-- Dipilih: NOT EXISTS sebagai versi utama karena aman terhadap NULL pada
-- subquery, sedangkan NOT IN dipertahankan sebagai versi pembanding sesuai
-- instruksi soal.
-- Alternatif: LEFT JOIN ... WHERE kolom_kanan IS NULL; tidak dipilih
-- sebagai versi utama karena soal secara eksplisit meminta bentuk NOT IN
-- vs NOT EXISTS, bukan pola anti-join lain.

-- Versi 1: NOT IN
SELECT title
FROM film f
WHERE f.film_id NOT IN (
    SELECT i.film_id
    FROM inventory i
    JOIN rental r ON r.inventory_id = i.inventory_id
)
ORDER BY title;

-- Versi 2: NOT EXISTS
SELECT title
FROM film f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i
    JOIN rental r ON r.inventory_id = i.inventory_id
    WHERE i.film_id = f.film_id
)
ORDER BY title;

-- Catatan hasil: kedua versi menghasilkan baris yang sama pada Pagila,
-- karena i.film_id (hasil subquery pada versi NOT IN) tidak pernah NULL --
-- ia berasal dari kolom inventory.film_id yang bertipe NOT NULL. NOT IN
-- baru akan berbeda hasilnya dari NOT EXISTS jika subquery pada NOT IN
-- bisa menghasilkan nilai NULL, misalnya jika kita memilih kolom yang
-- boleh kosong (nullable) sebagai daftar pembanding.
